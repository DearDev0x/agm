import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as Http;
import 'package:flutter_html/flutter_html.dart';

import '../../views/OTP/otpVerify.dart';
import '../../views/OTP/phoneVerify.dart';
import '../../widgets/dialogAlert.dart';

import '../../widgets/loading.dart';

import '../../utils/http_ssl_check.dart';

class TermServicePage extends StatefulWidget {
  static const routeName = '/term-service';
  final setting;
  TermServicePage(this.setting);
  @override
  _TermServicePageState createState() => _TermServicePageState();
}

class _TermServicePageState extends State<TermServicePage> {
  bool _loadingState = false;
  Timer _timer;
  int countdown = 31;
  // ignore: avoid_init_to_null
  var consent = null;
  Future<void> _onSubmit(String phoneNo, BuildContext context) async {
    setState(() {
      _loadingState = true;
    });
    try {
      await confirmTerm(phoneNo);
      if (widget.setting['isPage'] == false) {
        return Navigator.pop(context);
      }
      var url = "https://api.jfin.network/api/v2/paa/auth_phone";
      bool check = await HttpSslCheck(url: url).check();
      print(check);
      if (!check) {
        throw 500;
      }
      var headers = {
        'content-type': 'application/json',
        'X-API-KEY': 'OTPJFINzM8L6ZCmbIvce1BAFwihvDf3BF'
      };
      var params = {'phone_no': phoneNo};
      var response = await Http.post(Uri.parse(url),
          body: jsonEncode(params), headers: headers);
      var body = json.decode(response.body);
      if ((body['status_code']) == 200) {
        var otpRef = body['data']['otp_ref'];
        Navigator.of(context).pushNamed(OtpVerifyPage.routeName, arguments: {
          'phoneNo': phoneNo,
          'otpRef': otpRef,
        });
      } else {
        await showDialog(
            context: context,
            builder: (_) => DialogAlert(
                  type: 'error',
                  subtitle: 'Phone number is invalid \n Please try again.',
                  header: 'Failed !',
                  done: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushNamedAndRemoveUntil(
                        PhoneVerifyPage.routeName,
                        (Route<dynamic> route) => false);
                  },
                ));
      }
    } catch (err) {
      print(err);
      await showDialog(
          context: context,
          builder: (_) => DialogAlert(
                type: 'error',
                subtitle: err == 413
                    ? 'Consent has failed \n Please try again.'
                    : 'OTP has failed \n Please try again.',
                header: 'Failed !',
                done: () {
                  if (widget.setting['isPage']) {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushNamedAndRemoveUntil(
                        PhoneVerifyPage.routeName,
                        (Route<dynamic> route) => false);
                  } else {
                    Navigator.of(context).pop();
                  }
                },
              ));
    }
    setState(() {
      _loadingState = false;
      timerStart();
    });
  }

  Future<void> getTerm() async {
    setState(() {
      _loadingState = true;
    });
    try {
      var url = "https://cmp-api.jfin.network/api/v1/consent/form/SeIX6BDzwj";
      bool check = await HttpSslCheck(url: url).check();
      print(check);
      if (!check) {
        throw 500;
      }
      var headers = {
        'content-type': 'application/json',
        "X-Parse-Application-Id": "928f24ed35d8876dee76d0a5460ef078",
      };
      var response = await Http.get(Uri.parse(url), headers: headers);
      var body = json.decode(response.body);
      if (body['statusCode'] != 200) {
        throw 400;
      }
      consent = body['data'];
      print(consent);
    } catch (err) {
      await showDialog(
          context: context,
          builder: (_) => DialogAlert(
                type: 'error',
                subtitle: 'Get term service has failed \n Please try again.',
                header: 'Failed !',
                done: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushNamedAndRemoveUntil(
                      PhoneVerifyPage.routeName,
                      (Route<dynamic> route) => false);
                },
              ));
    }
    setState(() {
      _loadingState = false;
    });
  }

  Future<void> confirmTerm(String phoneNo) async {
    try {
      var url = "https://cmp-api.jfin.network/api/v1/consent";
      bool check = await HttpSslCheck(url: url).check();
      print(check);
      if (!check) {
        throw 500;
      }
      var headers = {
        'content-type': 'application/json',
      };
      var params = {
        "message_id": consent['message_id'],
        "project_id": consent['project_id'],
        "form_id": consent['objectId'],
        "subject_id": phoneNo,
        "source": "AGM",
        "retention_until": "",
        "email": "",
        "note1": "",
        "note2": ""
      };
      var response = await Http.post(Uri.parse(url),
          body: jsonEncode(params), headers: headers);
      var body = json.decode(response.body);
      print('body post consent');
      print(body);
      if ((body['statusCode']) != 200) {
        throw 413;
      }
    } catch (err) {
      throw err;
    }
  }

  Future<bool> _onPopScope() async {
    return widget.setting['isPage'];
  }

  @override
  void initState() {
    super.initState();
    getTerm();
  }

  timerStart() {
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) async {
      setState(() {
        countdown = 31 - timer.tick;
      });
      if (countdown > 0) {
      } else {
        _timer.cancel();
        setState(() {
          countdown = 31;
        });
      }
    });
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    double statusBarHeight = MediaQuery.of(context).padding.top;
    double layoutHeader = 80.00 + statusBarHeight;
    return WillPopScope(
      onWillPop: _onPopScope,
      child: Scaffold(
        body: SingleChildScrollView(
          child: Container(
            height: size.height,
            width: size.width,
            color: Colors.white,
            child: Stack(
              children: <Widget>[
                Column(
                  children: <Widget>[
                    Container(
                      padding: EdgeInsets.only(top: statusBarHeight + 20),
                      height: layoutHeader,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xff8A0304), Color(0xffEC1C24)],
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Terms of service',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                    Container(
                      height: size.height - (layoutHeader + 20),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: <Widget>[
                          Expanded(
                              child: Container(
                            padding: const EdgeInsets.only(
                              top: 10,
                              bottom: 10,
                            ),
                            child: SingleChildScrollView(
                              child: consent == null
                                  ? Text('')
                                  : Html(data: consent['detail']),
                            ),
                          )),
                          Container(
                            constraints: BoxConstraints(maxWidth: 350),
                            height: 48.0,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(50.0),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xff8A0304), Color(0xffEC1C24)],
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  if (countdown == 31) {
                                    _onSubmit(
                                        widget.setting['phoneNo'], context);
                                  }
                                },
                                child: Center(
                                  child: Center(
                                    child: Text(
                                      countdown == 31
                                          ? 'Accept The terms of service'
                                          : countdown.toString(),
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
                    )
                  ],
                ),
                if (widget.setting['isPage'])
                  Positioned(
                    top: statusBarHeight + 10,
                    child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                        },
                        child: Icon(
                          Icons.chevron_left,
                          color: Colors.white,
                          size: 40,
                        )),
                  ),
                if (_loadingState)
                  Positioned(
                    top: 0,
                    child: LoadingWidget(),
                  )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
