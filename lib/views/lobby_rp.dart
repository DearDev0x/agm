import 'dart:async';
import 'dart:convert';

import 'package:agm/providers/auth.dart';
import 'package:agm/utils/http_ssl_check.dart';
import 'package:agm/views/home.dart';
import 'package:agm/widgets/dialogAlert.dart';
import 'package:agm/widgets/loading.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uni_links/uni_links.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as Http;

class LobbyRpPage extends StatefulWidget {
  static const routeName = 'lobby-rp';
  final setting;
  LobbyRpPage(this.setting);
  @override
  _LobbyRpPageState createState() => _LobbyRpPageState();
}

class _LobbyRpPageState extends State<LobbyRpPage> {
  bool _isinit = true;
  StreamSubscription _subOTPRights;
  bool _loadingState = false;

  Future<Null> initUniLinks() async {
    _subOTPRights = getUriLinksStream().listen((Uri uri) async {
      try {
        setState(() {
          _loadingState = true;
        });
        var segments = uri.pathSegments;
        var path = segments[0].trim();
        if (path == 'beforeDeployContract') {
          var address = Provider.of<Auth>(context, listen: false).address;
          await queueVoter(address);
          setState(() {
            _loadingState = false;
          });
          await Navigator.of(context).pushNamedAndRemoveUntil(
            HomePage.routeName,
            (Route<dynamic> route) => false,
          );
          await _subOTPRights.cancel();
        }
      } catch (err) {
        setState(() {
          _loadingState = false;
        });
        await _subOTPRights.cancel();
        print(err);
        await showDialog(
            context: context,
            builder: (_) => DialogAlert(
                  type: 'error',
                  header: 'Failed !',
                  subtitle: 'Register failed !. \n Please try again.',
                  done: () async {
                    Navigator.of(context).pop();
                  },
                ));
      }
    }, onError: (err) async {
      setState(() {
        _loadingState = false;
      });
      await _subOTPRights.cancel();
      print(err);
      await showDialog(
          context: context,
          builder: (_) => DialogAlert(
                type: 'error',
                header: 'Failed !',
                subtitle: 'You can\'t rights to vote.',
                done: () async {
                  Navigator.of(context).pop();
                },
              ));
    });
  }

  Future<void> queueVoter(String voterAddress) async {
    try {
      String sessionToken =
          await Provider.of<Auth>(context, listen: false).getSessionToken();
      var url = "https://agm-api.jfin.network/add_queue_voter";
      bool check = await HttpSslCheck(url: url).check();
      print(check);
      if (!check) {
        throw 500;
      }
      var headers = {
        'content-type': 'application/json',
        'X-Parse-Application-Id': '928f24ed35d8876dee76d0a5460ef078',
        'x-api-key': 'l487kBwGEf09JmSF02Q5wVnuXcTHvZYz',
        'X-Parse-Session-Token': sessionToken,
      };
      var params = {
        "voter_address": voterAddress,
        "meetingId": widget.setting['meetingId']
      };
      var response =
          await Http.post(url, body: jsonEncode(params), headers: headers);
      var body = await json.decode(response.body);
      print('add voter');
      print('end add voter');
      if (body['success']) {
      } else {
        throw 412;
      }
    } catch (err) {
      throw 404;
    }
  }

  Future<void> _onSubmit() async {
    setState(() {
      _loadingState = true;
    });

    await _gotoIdp();

    setState(() {
      _loadingState = false;
    });
  }

  Future<void> _gotoIdp() async {
    setState(() {
      _loadingState = true;
    });
    try {
      String purpose =
          "Request%20to%20register%20online%20vote%20on%20AGM%20Voting.";
      String callback = "https://jventuresagm.page.link/beforeDeployContract";
      String sender = 'AGM';
      var hashId = Provider.of<Auth>(context, listen: false).hashId;
      var requestId = await _requestRP();
      var url =
          'https://jfinwallet.page.link/requestIdP?callback_url=$callback&purpose=$purpose&sender=$sender&hashId=$hashId&rpId=$requestId';
      if (await canLaunch(url)) {
        await launch(url, forceSafariVC: false, forceWebView: false);
      } else {
        await showDialog(
            context: context,
            builder: (_) => DialogAlert(
                  type: 'error',
                  header: 'Failed !',
                  subtitle: 'You can\'t rights to vote.',
                  done: () {
                    Navigator.pop(context);
                    _loadingState = false;
                  },
                ));
      }
    } catch (err) {
      if (err == 512) {
        await showDialog(
            context: context,
            builder: (_) => DialogAlert(
                  type: 'error',
                  header: 'Failed !',
                  subtitle: 'Request RP failed \n Please try again.',
                  done: () {
                    Navigator.pop(context);
                    _loadingState = false;
                  },
                ));
      } else {
        await showDialog(
            context: context,
            builder: (_) => DialogAlert(
                  type: 'error',
                  header: 'Failed !',
                  subtitle: 'You can\'t rights to vote.',
                  done: () {
                    Navigator.pop(context);
                    _loadingState = false;
                  },
                ));
      }
    }
    setState(() {
      _loadingState = false;
    });
  }

  Future<String> _requestRP() async {
    try {
      String id = Provider.of<Auth>(context, listen: false).idCard;
      String purpose = "Request to register online vote on AGM Voting.";
      String callback = "https://jventuresagm.page.link/beforeDeployContract";
      var url = 'https://agm-api.jfin.network/send_request';
      bool check = await HttpSslCheck(url: url).check();
      print(check);
      if (!check) {
        throw 500;
      }
      var params = {
        "id_card": id,
        "purpose": purpose,
        "callback": callback,
        "type": "1",
        "meetingId": widget.setting['meetingId']
      };
      var response = await Http.post(url, body: params);
      var body = await json.decode(response.body);
      return body['request_id'];
    } catch (err) {
      print(err);
      throw 512;
    }
  }

  @override
  void initState() {
    super.initState();
    if (_isinit) {
      initUniLinks();
      _isinit = false;
    }
  }

  @override
  void dispose() {
    try {
      _subOTPRights.cancel();
    } catch (err) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    double statusBarHeight = MediaQuery.of(context).padding.top;
    var logoUrl = '';
    double layoutHeader = 90.00 + statusBarHeight;
    List<Color> color = widget.setting['color'];
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          child: Stack(
            children: <Widget>[
              Column(
                children: <Widget>[
                  Container(
                    width: size.width,
                    height: layoutHeader,
                    padding: EdgeInsets.only(top: statusBarHeight),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: color,
                      ),
                    ),
                    child: Stack(
                      children: <Widget>[
                        if (logoUrl != '')
                          Positioned(
                            right: 0,
                            width: 110,
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.only(
                                  bottomLeft: const Radius.circular(24.0),
                                ),
                              ),
                              child: Center(
                                child: CachedNetworkImage(
                                  height: 25,
                                  imageUrl: logoUrl,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        Positioned(
                          left: 10,
                          top: 10,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: Icon(
                              Icons.arrow_back_ios,
                              color: Colors.white,
                              size: 25,
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(
                              top: logoUrl != '' ? 60 : 30,
                              left: 15,
                              right: 15),
                          child: Container(
                            height: 60,
                            child: Center(
                              child: SingleChildScrollView(
                                child: Container(
                                  child: Text(
                                    "Register to online voting",
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                        height: 1.2),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    color: Colors.white,
                    width: size.width,
                    constraints: BoxConstraints(maxWidth: 800),
                    height: size.height - layoutHeader,
                    child: SingleChildScrollView(
                      child: Column(
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            constraints: BoxConstraints(maxWidth: 380),
                            width: size.width,
                            child: Column(
                              children: <Widget>[
                                SizedBox(
                                  height: 38,
                                ),
                                Text(
                                  'กรุณายืนยันตัวตน',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(
                                  height: 15,
                                ),
                                Column(
                                  children: <Widget>[
                                    Text(
                                      'ตามมาตรฐานความน่าเชื่อถือของสิ่งที่ใช้ยืนยันตัวตน\nAuthenticator Assurance Level: AAL 2.2',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(
                                      height: 30,
                                    ),
                                    Container(
                                      constraints:
                                          BoxConstraints(maxWidth: 350),
                                      height: 48.0,
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(50.0),
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: color,
                                        ),
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () {
                                            _onSubmit();
                                          },
                                          child: Center(
                                            child: Center(
                                              child: const Text(
                                                'Next',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (_loadingState)
                Positioned(
                  top: 0,
                  child: LoadingWidget(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
