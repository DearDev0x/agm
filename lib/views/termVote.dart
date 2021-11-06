import 'dart:async';
import 'dart:convert';
import 'package:agm/utils/http_ssl_check.dart';
import 'package:agm/widgets/dialogAlert.dart';
import 'package:connectivity/connectivity.dart';
import 'package:intl/intl.dart';

import '../views/home.dart';
import '../views/termWait.dart';
import '../widgets/pin_confirm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart' show PlatformException, rootBundle;
import 'package:http/http.dart' as Http;
import 'package:web3dart/web3dart.dart';
import 'package:web_socket_channel/io.dart';
import '../widgets/layout.dart';
import '../widgets/loading.dart';
import '../views/termConclude.dart';

import '../providers/meetings.dart';
import '../providers/auth.dart';

class TermVotePage extends StatefulWidget {
  static const routeName = '/Term-vote';
  final setting;
  TermVotePage(this.setting);

  @override
  _TermVotePageState createState() => _TermVotePageState();
}

class _TermVotePageState extends State<TermVotePage>
    with WidgetsBindingObserver {
  bool _loadingState = false;
  bool _isInit = true;
  bool _isEndVote = false;
  int agendarLength;
  String abiCode;
  Timer _timerVote;
  StreamSubscription<FilterEvent> _voteEndedSubscription;
  bool _showPin = true;
  int _share;
  bool _signed = false;
  final oCcy = new NumberFormat("#,##0", "en_US");
  var _clientVote =
      Web3Client("https://rpc.dome.cloud", Client(), socketConnector: () {
    return IOWebSocketChannel.connect("wss://ws.dome.cloud").cast<String>();
  });
  String nowContract = "";

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult> _connectivitySubscription;

  Future<void> vote(int vote, String contractAddress, String meetingId) async {
    if (_share == 0) {
      setState(() {
        _loadingState = false;
      });
      await showDialog(
          context: context,
          builder: (_) => DialogAlert(
                type: "error",
                header: "Cannot vote!",
                subtitle: "Please contact staff.",
                done: () {
                  Navigator.of(context).pop();
                },
              ));
    } else {
      String id = Provider.of<Auth>(context, listen: false).idCard;
      try {
        var credentials =
            await Provider.of<Auth>(context, listen: false).getCredentials();
        var address = await credentials.extractAddress();

        EtherAmount balance = await _clientVote.getBalance(address);

        final EthereumAddress contractAddr =
            EthereumAddress.fromHex(contractAddress);
        final contract = DeployedContract(
            ContractAbi.fromJson(abiCode, 'Ballot'), contractAddr);
        final doVote = contract.function('doVote');
        var gasPrice = EtherAmount.fromUnitAndValue(EtherUnit.gwei, 3);

        var result = await _clientVote.sendTransaction(
          credentials,
          Transaction.callContract(
              contract: contract,
              function: doVote,
              parameters: [BigInt.from(vote)],
              maxGas: 1356000,
              gasPrice: gasPrice),
          chainId: 7,
        );

        final voteDone = contract.event('voteDone');
        var _voteDoneSubscription = _clientVote
            .events(FilterOptions.events(contract: contract, event: voteDone))
            .take(1)
            .listen((event) async {
          print("listen");
          print("voteDone");

          setState(() {
            _loadingState = false;
          });
          String textVote = '';
          Color textcolor;
          if (vote == 0) {
            textVote = 'No Vote';
            textcolor = Color(0xfffb8c00);
          } else if (vote == 1) {
            textVote = 'Agree';
            textcolor = Color(0xff00917B);
          } else if (vote == 2) {
            textVote = 'Disagree';
            textcolor = Color(0xffEC1C24);
          }
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Text("Success !"),
                  ],
                ),
                content: Container(
                  height: 170,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        SizedBox(
                          height: 8,
                        ),
                        Icon(
                          Icons.check_circle,
                          size: 80,
                          color: Colors.green,
                        ),
                        SizedBox(
                          height: 30,
                        ),
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                              style: TextStyle(
                                  color: Colors.black,
                                  fontFamily: 'Sukhumvit',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400),
                              children: [
                                TextSpan(text: 'คุณได้โหวต '),
                                TextSpan(
                                    text: textVote,
                                    style: TextStyle(
                                        color: textcolor, fontSize: 17)),
                                TextSpan(
                                    text:
                                        ' แล้ว\nเป็นจำนวน ${_share.toString()} หุ้น'),
                              ]),
                        ),
                      ],
                    ),
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                actions: <Widget>[
                  FlatButton(
                    child: Text(
                      "Close",
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    onPressed: () async {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
        });

        await _voteDoneSubscription.asFuture();
        await _voteDoneSubscription.cancel();

        saveVote(meetingId, contractAddress, vote);
        await saveLog(contractAddress, 'success');
      } catch (err) {
        await saveLog(contractAddress, 'failed');
        print('error vote');
        print(err);
        setState(() {
          _loadingState = false;
        });
        await showDialog(
            context: context,
            builder: (_) => DialogAlert(
                  type: "error",
                  header: "Vote Failed!",
                  subtitle: "Please try again.",
                  done: () {
                    Navigator.of(context).pop();
                  },
                ));
      }
    }
  }

  Future<dynamic> checkAgendar(String contractAddress) async {
    try {
      final EthereumAddress contractAddr =
          EthereumAddress.fromHex(contractAddress);
      final contract = DeployedContract(
          ContractAbi.fromJson(abiCode, 'Ballot'), contractAddr);
      final state = contract.function('state');
      final stateData = await _clientVote
          .call(contract: contract, function: state, params: []);
      return stateData;
    } catch (err) {
      return [0];
    }
  }

  Future<void> wsVoteEndedConnection(String contractAddress) async {
    try {
      final EthereumAddress contractAddr =
          EthereumAddress.fromHex(contractAddress);
      final contract = DeployedContract(
          ContractAbi.fromJson(abiCode, 'Ballot'), contractAddr);
      final voteEnded = contract.event('voteEnded');
      _voteEndedSubscription = _clientVote
          .events(FilterOptions.events(contract: contract, event: voteEnded))
          .take(1)
          .listen((event) async {
        print("listen");
        _isEndVote = true;
        var index = widget.setting['indexOrder'];
        if (index == (agendarLength - 1)) {
          await Navigator.of(context).pushNamedAndRemoveUntil(
            TermConcludePage.routeName,
            (Route<dynamic> route) => false,
            arguments: {
              'color': widget.setting['color'],
              'meetingId': widget.setting['meetingId']
            },
          );
        } else {
          await Navigator.of(context).pushNamedAndRemoveUntil(
            TermWaitPage.routeName,
            (Route<dynamic> route) => false,
            arguments: {
              'color': widget.setting['color'],
              'indexOrder': index + 1,
              'meetingId': widget.setting['meetingId']
            },
          );
        }
      });
      await _voteEndedSubscription.asFuture();
      await _voteEndedSubscription.cancel();
    } catch (err) {
      print('ws error');
      print('err');
    }
  }

  reConnectWs(String contractAddress) {
    _timerVote =
        Timer.periodic(const Duration(seconds: 50), (Timer timer) async {
      try {
        await _voteEndedSubscription.cancel();
        if (!_isEndVote) {
          print('reConnect termVote : ' + timer.tick.toString());
          wsVoteEndedConnection(contractAddress);
        }
      } catch (err) {}
    });
  }

  Future<void> saveVote(
      String meetingId, String contractAddress, int vote) async {
    await Provider.of<Meetings>(context, listen: false)
        .setAgendarVote(meetingId, contractAddress, vote);
  }

  Future<String> loadAbi() async {
    return await rootBundle.loadString('assets/abi.json');
  }

  Future<bool> _onPopScope() async {
    return false;
  }

  Future<void> startProcessVote(String contractAddress) async {
    var check = await checkAgendar(contractAddress);
    if (check.toString() == '[2]') {
      print('vote end');
      if (widget.setting['indexOrder'] == (agendarLength - 1)) {
        await Navigator.of(context).pushNamedAndRemoveUntil(
          TermConcludePage.routeName,
          (Route<dynamic> route) => false,
          arguments: {
            'color': widget.setting['color'],
            'meetingId': widget.setting['meetingId'],
          },
        );
      } else {
        var index = widget.setting['indexOrder'] + 1;
        await Navigator.of(context).pushNamedAndRemoveUntil(
          TermWaitPage.routeName,
          (Route<dynamic> route) => false,
          arguments: {
            'color': widget.setting['color'],
            'indexOrder': index,
            'meetingId': widget.setting['meetingId']
          },
        );
      }
    } else {
      wsVoteEndedConnection(contractAddress);
      reConnectWs(contractAddress);
    }
  }

  Future<void> saveLog(String contractAddress, String status) async {
    try {
      var sessionToken =
          await Provider.of<Auth>(context, listen: false).getSessionToken();
      var url = "https://agm-api.jfin.network/log_voted";
      bool check = await HttpSslCheck(url: url).check();
      print(check);
      if (!check) {
        throw 500;
      }
      var headers = {
        'content-type': 'application/json',
        'X-Parse-Application-Id': '928f24ed35d8876dee76d0a5460ef078',
        'X-Parse-Session-Token': sessionToken
      };
      var params = {'contractAddress': contractAddress, 'status': status};
      await Http.post(url, body: jsonEncode(params), headers: headers);
      print('success keep log');
    } catch (err) {
      print('error');
    }
  }

  Future<void> checkConnectivity() async {
    ConnectivityResult result;
    try {
      result = await _connectivity.checkConnectivity();
    } on PlatformException catch (e) {
      print(e.toString());
    }
    if (!mounted) {
      return Future.value(null);
    }
    return _updateConnectionStatus(result);
  }

  Future<void> updateSigned(String contractAddress) async {
    try {
      var credentials =
          await Provider.of<Auth>(context, listen: false).getCredentials();
      var address = await credentials.extractAddress();

      EtherAmount balance = await _clientVote.getBalance(address);

      final EthereumAddress contractAddr =
          EthereumAddress.fromHex(contractAddress);
      final contract = DeployedContract(
          ContractAbi.fromJson(abiCode, 'Ballot'), contractAddr);
      final sign = contract.function('sign');
      var gasPrice = EtherAmount.fromUnitAndValue(EtherUnit.gwei, 3);

      var result = await _clientVote.sendTransaction(
        credentials,
        Transaction.callContract(
            contract: contract,
            function: sign,
            parameters: [],
            maxGas: 1356000,
            gasPrice: gasPrice),
        chainId: 7,
      );
      final signDone = contract.event('signDone');
      var _signDoneSubscription = _clientVote
          .events(FilterOptions.events(contract: contract, event: signDone))
          .take(1)
          .listen((event) async {
        print("listen");
        print("signDone");
        setState(() {
          _loadingState = false;
        });
      });
      await _signDoneSubscription.asFuture();
      await _signDoneSubscription.cancel();
      await saveVote(widget.setting['meetingId'], contractAddress, 4);
    } catch (err) {
      print('error sign');
      print(err);
      setState(() {
        _loadingState = false;
      });
      await showDialog(
          context: context,
          builder: (_) => DialogAlert(
                type: "error",
                header: "Sign Failed!",
                subtitle: "Please tap to button for try again.",
                done: () async {
                  Navigator.of(context).pop();
                  setState(() {
                    _loadingState = true;
                  });
                  await updateSigned(contractAddress);
                },
              ));
    }
  }

  Future<void> getShare(String contractAddress) async {
    var address = Provider.of<Auth>(context, listen: false).address;
    final EthereumAddress contractAddr =
        EthereumAddress.fromHex(contractAddress);
    final EthereumAddress voterAddress = EthereumAddress.fromHex(address);
    final contract =
        DeployedContract(ContractAbi.fromJson(abiCode, 'Ballot'), contractAddr);
    final voterRegister = contract.function('voterRegister');
    final voterRegisterData = await _clientVote.call(
        contract: contract, function: voterRegister, params: [voterAddress]);
    _signed = voterRegisterData[4];
    setState(() {
      _share = voterRegisterData[2].toInt();
    });
  }

  @override
  void initState() {
    super.initState();
    checkConnectivity();
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    print('before dispose vote');
    try {
      _timerVote.cancel();
    } catch (err) {
      print('timer never been vote');
    }
    try {
      _voteEndedSubscription.cancel();
    } catch (err) {}
    try {
      _clientVote.dispose();
    } catch (err) {}
    try {
      _connectivitySubscription.cancel();
    } catch (err) {
      print('sub connectiviry never been vote');
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.paused:
        print("paused");
        await _onPause();
        break;
      case AppLifecycleState.inactive:
        print('inactive');
        await _onPause();
        break;
      case AppLifecycleState.resumed:
        print('resumed');
        await startProcessVote(nowContract);
        break;
      default:
    }
  }

  Future<void> _onPause() async {
    try {
      _timerVote.cancel();
    } catch (err) {}
    try {
      await _voteEndedSubscription.cancel();
    } catch (err) {}
  }

  Future<Null> _refresh() async {
    try {
      print("refresh");
      var check = await checkAgendar(nowContract);
      if (check.toString() == '[2]') {
        _isEndVote = true;
        print('vote end');
        if (widget.setting['indexOrder'] == (agendarLength - 1)) {
          await Navigator.of(context).pushNamedAndRemoveUntil(
            TermConcludePage.routeName,
            (Route<dynamic> route) => false,
            arguments: {
              'color': widget.setting['color'],
              'meetingId': widget.setting['meetingId'],
            },
          );
        } else {
          var index = widget.setting['indexOrder'] + 1;
          await Navigator.of(context).pushNamedAndRemoveUntil(
            TermWaitPage.routeName,
            (Route<dynamic> route) => false,
            arguments: {
              'color': widget.setting['color'],
              'indexOrder': index,
              'meetingId': widget.setting['meetingId']
            },
          );
        }
      }
    } catch (err) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final args = widget.setting;
    var data = Provider.of<Meetings>(context, listen: false)
        .meetingById(args['meetingId']);
    var agendars = data.agendars;
    var length = agendars.length;
    Size size = MediaQuery.of(context).size;
    double statusBarHeight = MediaQuery.of(context).padding.top;
    double layoutHeader = 90.00 + statusBarHeight + 40;
    print("build termVote context");
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      if (_isInit) {
        if (agendars[args['indexOrder']].contractAddress == null) {
          return await showDialog(
              context: context,
              builder: (_) => DialogAlert(
                    type: 'error',
                    header: 'Failed !',
                    subtitle: 'You can\'t rights to vote.',
                    done: () async {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushNamedAndRemoveUntil(
                          HomePage.routeName, (route) => false);
                    },
                  ));
        }
        var file = await loadAbi();
        abiCode = file.toString();
        await getShare(agendars[args['indexOrder']].contractAddress);
        nowContract = agendars[args['indexOrder']].contractAddress;
        startProcessVote(agendars[args['indexOrder']].contractAddress);
        agendarLength = length;
        _isInit = false;
      }
    });
    Widget body = Container(
      height: size.height - layoutHeader,
      color: Color(0xfff4f4f4),
      child: Column(
        children: <Widget>[
          Expanded(
            child: Container(
              color: Colors.white,
              child: ListView(
                padding: const EdgeInsets.only(top: 8, bottom: 5),
                children: <Widget>[
                  if (agendars[args['indexOrder']].canVote && _share != null)
                    Container(
                      height: 31,
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          Text(
                            'Share : ' + oCcy.format(_share).toString(),
                            style: TextStyle(
                              color: Color(0xff469fb8),
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Agenda ' +
                              agendars[args['indexOrder']].order.toString(),
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.start,
                        ),
                        SizedBox(
                          height: 15,
                        ),
                        Text(
                          agendars[args['indexOrder']].title ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                          textAlign: TextAlign.start,
                        ),
                        SizedBox(
                          height: 15,
                        ),
                        Text(
                          agendars[args['indexOrder']].detail ?? '',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Color(0xff888888)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (agendars[args['indexOrder']].canVote)
            Container(
              constraints: BoxConstraints(maxWidth: 600),
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  SizedBox(
                    height: 10,
                  ),
                  Text(
                    'ในกรณีที่ท่านไม่กดลงคะแนน\nจะถือว่าท่านเห็นด้วยกับวาระนี้',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 15,
                        color: Colors.red,
                        fontWeight: FontWeight.w600),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Row(
                    children: <Widget>[
                      Expanded(
                        flex: 4,
                        child: Container(
                          height: 48.0,
                          decoration: BoxDecoration(
                            color: Color(0xff00917B),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey[500],
                                offset: Offset(0.0, 1.5),
                                blurRadius: 1.5,
                              ),
                            ],
                            borderRadius: BorderRadius.circular(50.0),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () async {
                                if (_loadingState == true) {
                                  return;
                                }
                                setState(() {
                                  _loadingState = true;
                                });
                                await vote(
                                  1,
                                  agendars[args['indexOrder']].contractAddress,
                                  args['meetingId'],
                                );
                              },
                              child: Container(
                                width: size.width,
                                padding:
                                    const EdgeInsets.only(left: 5, right: 5),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    if (agendars[args['indexOrder']].vote == 1)
                                      Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 36.0,
                                      ),
                                    if (agendars[args['indexOrder']].vote == 1)
                                      SizedBox(
                                        width: 8,
                                      ),
                                    Flexible(
                                      child: const Text(
                                        'Agree (เห็นด้วย)',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Expanded(
                        flex: 4,
                        child: Container(
                          height: 40.0,
                          decoration: BoxDecoration(
                            color: Color(0xffEC1C24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey[500],
                                offset: Offset(0.0, 1.5),
                                blurRadius: 1.5,
                              ),
                            ],
                            borderRadius: BorderRadius.circular(50.0),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () async {
                                if (_loadingState == true) {
                                  return;
                                }
                                setState(() {
                                  _loadingState = true;
                                });
                                await vote(
                                  2,
                                  agendars[args['indexOrder']].contractAddress,
                                  args['meetingId'],
                                );
                              },
                              child: Container(
                                padding:
                                    const EdgeInsets.only(left: 2, right: 2),
                                width: size.width,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: <Widget>[
                                    if (agendars[args['indexOrder']].vote == 2)
                                      Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 25,
                                      ),
                                    if (agendars[args['indexOrder']].vote == 2)
                                      SizedBox(
                                        width: 5,
                                      ),
                                    Flexible(
                                      child: const Text(
                                        'Disagree (ไม่เห็นด้วย)',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        flex: 4,
                        child: Container(
                          height: 40.0,
                          decoration: BoxDecoration(
                            color: Color(0xfffb8c00),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey[500],
                                offset: Offset(0.0, 1.5),
                                blurRadius: 1.5,
                              ),
                            ],
                            borderRadius: BorderRadius.circular(50.0),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () async {
                                if (_loadingState == true) {
                                  return;
                                }
                                setState(() {
                                  _loadingState = true;
                                });
                                await vote(
                                  0,
                                  agendars[args['indexOrder']].contractAddress,
                                  args['meetingId'],
                                );
                              },
                              child: Container(
                                width: size.width,
                                padding:
                                    const EdgeInsets.only(left: 2, right: 2),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    if (agendars[args['indexOrder']].vote == 0)
                                      Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 25,
                                      ),
                                    if (agendars[args['indexOrder']].vote == 0)
                                      SizedBox(width: 5),
                                    Flexible(
                                      child: const Text(
                                        'No Vote (งดออกเสียง)',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 10,
                  ),
                ],
              ),
            ),
        ],
      ),
    );

    return WillPopScope(
      onWillPop: _onPopScope,
      child: Scaffold(
        body: RefreshIndicator(
          displacement: 100,
          color: Colors.redAccent,
          onRefresh: _refresh,
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: Container(
              height: size.height,
              child: Stack(
                children: <Widget>[
                  Layout(
                    popClose: false,
                    logo: true,
                    logoUrl: data.logoUrl ?? '',
                    body: length > 0 ? body : Text(''),
                    header: data.title ?? '',
                    color: args['color'],
                  ),
                  Positioned(
                    left: 10,
                    top: statusBarHeight + 10,
                    child: GestureDetector(
                      onTap: () {
                        showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                                  title: const Text('Please confirm'),
                                  content: const Text(
                                      'Do you want to leave this meeting ?'),
                                  actions: <Widget>[
                                    FlatButton(
                                      child: Text(
                                        "OK",
                                        style: TextStyle(
                                          fontSize: 16,
                                        ),
                                      ),
                                      onPressed: () async {
                                        _isEndVote = true;
                                        await Navigator.of(context)
                                            .pushNamedAndRemoveUntil(
                                                HomePage.routeName,
                                                (Route<dynamic> route) =>
                                                    false);
                                      },
                                    ),
                                    FlatButton(
                                      child: Text(
                                        "Cancel",
                                        style: TextStyle(
                                          fontSize: 16,
                                        ),
                                      ),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                    )
                                  ],
                                ));
                      },
                      child: Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                            shape: BoxShape.circle, color: Colors.white),
                        child: Icon(
                          Icons.close,
                          color: Colors.black.withOpacity(0.3),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  if (_loadingState)
                    Positioned(
                      child: LoadingWidget(),
                      top: 0,
                    ),
                  if (_showPin)
                    PinConfirmWidget(
                      done: () async {
                        await Future.delayed(Duration(milliseconds: 500));
                        setState(() {
                          _showPin = false;
                        });
                        setState(() {
                          _loadingState = true;
                        });
                        if (!_signed && agendars[args['indexOrder']].canVote) {
                          await updateSigned(
                              agendars[args['indexOrder']].contractAddress);
                        } else {
                          setState(() {
                            _loadingState = false;
                          });
                        }
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    if (result == ConnectivityResult.wifi ||
        result == ConnectivityResult.mobile) {
    } else if (result == ConnectivityResult.none) {
      showDialog(
        context: context,
        builder: (_) => DialogAlert(
          header: 'Connection lost !',
          subtitle: 'Please connect to the internet and try again.',
          type: 'error',
          done: () {
            Navigator.of(context)
                .pushNamedAndRemoveUntil(HomePage.routeName, (route) => false);
          },
        ),
      );
    }
  }
}
