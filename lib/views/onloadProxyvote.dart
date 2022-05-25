import 'dart:async';
import 'dart:convert';

import 'package:agm/utils/http_ssl_check.dart';

import '../providers/auth.dart';
import '../providers/meetings.dart';
import '../views/home.dart';
import '../widgets/loading.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import 'package:uni_links/uni_links.dart';
import 'package:http/http.dart' as Http;
import 'package:url_launcher/url_launcher.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web_socket_channel/io.dart';
import 'package:flutter/services.dart' show rootBundle;

class OnloadProxy extends StatefulWidget {
  static const routeName = '/onload-proxy';
  final setting;
  OnloadProxy(this.setting);
  @override
  _OnloadProxyState createState() => _OnloadProxyState();
}

class _OnloadProxyState extends State<OnloadProxy> {
  bool _isInit = true;
  StreamSubscription _subProxy;
  bool _loadingState = true;
  var clientDeploy =
      Web3Client("https://rpc.xchain.asia", Client(), socketConnector: () {
    return IOWebSocketChannel.connect("wss://ws.tch.in.th").cast<String>();
  });

  Future<Null> initUniLinksProxy() async {
    _subProxy = getUriLinksStream().listen((Uri uri) async {
      var segments = uri.pathSegments;
      var path = segments[0].trim();
      if (path == 'proxyfromidp') {
        await deployAgendar();
        await _subProxy.cancel();
      }
    }, onError: (err) async {
      print(err);
      print('alert error unitlink error');
      await showAlert();
    });
  }

  Future<void> checkProxyVoter() async {
    try {
      String meetingId = widget.setting['meetingId'];
      String voterAddress = widget.setting['voterAddress'];
      var url =
          'https://api.jfin.network/parse/classes/AGMMeetingProxy_Test?where={"meetingId":"$meetingId","contractAddress":"$voterAddress"}';
      bool check = await HttpSslCheck(url: url).check();
      print(check);
      if (!check) {
        throw 500;
      }
      var headers = {
        'content-type': 'application/json',
        'X-Parse-Application-Id': '928f24ed35d8876dee76d0a5460ef078'
      };
      var response = await Http.get(Uri.parse(url), headers: headers);
      var body = await json.decode(response.body);

      print('check proxy');
      if (body['results'].length == 0) {
        print('cant proxy');
        await showAlert();
      } else {
        gotoIdp();
      }
    } catch (err) {
      print('cant proxy');
      await showAlert();
    }
  }

  showAlert() {
    setState(() {
      _loadingState = false;
    });
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text("Failed !"),
            ],
          ),
          content: Container(
            height: 170,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Icon(
                  Icons.error,
                  size: 80,
                  color: Colors.red,
                ),
                SizedBox(
                  height: 30,
                ),
                Text("Can't granted"),
                SizedBox(
                  height: 5,
                ),
                Text("Please try again."),
              ],
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          actions: [
            FlatButton(
              child: Text(
                "OK",
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
              onPressed: () async {
                try {
                  await clientDeploy.dispose();
                } catch (err) {}
                Navigator.pop(context);
                await Navigator.of(context).pushNamedAndRemoveUntil(
                    HomePage.routeName, (Route<dynamic> route) => false);
              },
            )
          ],
        );
      },
    );
  }

  Future<void> gotoIdp() async {
    String purpose =
        "Request%20The%20rights%20for%20tranfers%20vote%20on%20AGM%20Voting.";
    String callback = "https://jventuresagm.page.link/proxyfromidp";
    String sender = 'AGM';
    var url =
        'https://jfinwallet.page.link/requestIdP?callback_url=$callback&purpose=$purpose&sender=$sender';
    if (await canLaunch(url)) {
      await launch(url, forceSafariVC: false, forceWebView: false);
    } else {
      print('cannont idp');
      await showAlert();
    }
  }

  Future<void> deployAgendar() async {
    try {
      var meetingById = Provider.of<Meetings>(context)
          .meetingById(widget.setting['meetingId']);
      var lobbyList = meetingById.agendars;
      for (var item in lobbyList) {
        await deploy(item.contractAddress);
      }
      await clientDeploy.dispose();
      await updateParse(meetingById.meetingVoterId);
    } catch (err) {
      print('error tran');
      showAlert();
    }
  }

  Future<void> deploy(String contractAddress) async {
    var credentials = await Provider.of<Auth>(context).getCredentials();
    var file = await loadAbi();
    var abiCode = file.toString();
    final EthereumAddress contractAddr =
        EthereumAddress.fromHex(contractAddress);
    final contract =
        DeployedContract(ContractAbi.fromJson(abiCode, 'Ballot'), contractAddr);
    final addProxy = contract.function('addProxy');
    var gasPrice2 = EtherAmount.fromUnitAndValue(EtherUnit.gwei, 3);
    final EthereumAddress proxyAddr =
        EthereumAddress.fromHex(widget.setting['voterAddress']);
    await clientDeploy.sendTransaction(
      credentials,
      Transaction.callContract(
          contract: contract,
          function: addProxy,
          parameters: [proxyAddr],
          maxGas: 20000000,
          gasPrice: gasPrice2),
      chainId: 35,
    );
  }

  Future<void> updateParse(String meetingVoterId) async {
    String proxyAddress = widget.setting['voterAddress'];
    try {
      var url = 'https://api.jfin.network/parse/classes/AGMMeetingVoter_Test/' +
          meetingVoterId;
      bool check = await HttpSslCheck(url: url).check();
      print(check);
      if (!check) {
        throw 500;
      }
      var headers = {
        'content-type': 'application/json',
        'X-Parse-Application-Id': '928f24ed35d8876dee76d0a5460ef078'
      };
      var params = {
        "proxyAddress": proxyAddress,
      };
      var response = await Http.put(Uri.parse(url),
          body: jsonEncode(params), headers: headers);
      await json.decode(response.body);

      setState(() {
        _loadingState = false;
      });
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text("Completed !"),
              ],
            ),
            content: Container(
              height: 170,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    Icons.check_circle,
                    size: 80,
                    color: Colors.green,
                  ),
                  SizedBox(
                    height: 30,
                  ),
                  Text("Granted voting rights."),
                ],
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            actions: [
              FlatButton(
                child: Text(
                  "OK",
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.of(context).pushNamedAndRemoveUntil(
                      HomePage.routeName, (Route<dynamic> route) => false);
                },
              )
            ],
          );
        },
      );
    } catch (err) {
      print('alert update parse');
      showAlert();
    }
  }

  Future<String> loadAbi() async {
    return await rootBundle.loadString('assets/abi.json');
  }

  @override
  void initState() {
    super.initState();
    initUniLinksProxy();
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void didChangeDependencies() async {
    if (_isInit) {
      await checkProxyVoter();
      _isInit = false;
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loadingState ? LoadingWidget() : Text(''),
    );
  }
}
