import 'dart:async';
import 'dart:convert';

import 'package:agm/utils/http_ssl_check.dart';
import 'package:agm/views/OTP/phoneVerify.dart';
import '../../views/OTP/pinAccess.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as Http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/cryptojs_aes_encryption_helper.dart';

import '../../widgets/dialogAlert.dart';
import '../../widgets/loading.dart';

class OtpVerifyPage extends StatefulWidget {
  static const routeName = '/otp-verify';
  @override
  _OtpVerifyPageState createState() => _OtpVerifyPageState();
}

class _OtpVerifyPageState extends State<OtpVerifyPage> {
  bool _loadingState = false;
  String otpRefAgain;
  bool sendAgain = false;
  var _otpFocusnode = FocusNode();
  var _initValueOtp = '';
  var _formOtpKey = GlobalKey<FormState>();
  Timer _timer;
  int countdown = 31;
  int countAttemped = 0;

  Future<void> _onSubmit(String phoneNo, BuildContext context, otpRef) async {
    final isValid = _formOtpKey.currentState.validate();
    if (!isValid) {
      return;
    }
    setState(() {
      _loadingState = true;
    });
    try {
      await Future.delayed(const Duration(milliseconds: 250));
      _formOtpKey.currentState.save();
      String accessToken = await _getAccessToken(phoneNo, otpRef);
      var sessionToken = await _login(phoneNo, accessToken);
      if (sessionToken == null) {
        countAttemped = countAttemped + 1;
        await showDialog(
          context: context,
          builder: (_) => DialogAlert(
            type: "error",
            header: "OTP Incorrect !",
            subtitle: "Please try again.\nattempted $countAttemped/3",
            done: () {
              Navigator.of(context).pop();
              if (countAttemped == 3) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                    PhoneVerifyPage.routeName, (route) => false);
              }
              setState(() {
                _loadingState = false;
              });
            },
          ),
        );
        return;
      }
      await saveSessionToken(sessionToken);
      await Navigator.of(context).pushNamed(PinAccessPage.routeName);
      _formOtpKey.currentState.reset();
    } catch (err) {
      await showDialog(
        context: context,
        builder: (_) => DialogAlert(
          type: "error",
          header: "Failed !",
          subtitle: "OTP failed \n Please try again.",
          done: () {
            Navigator.of(context).pop();
          },
        ),
      );
    }
    setState(() {
      _loadingState = false;
    });
  }

  Future<void> saveSessionToken(String token) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var encrypt = encryptToken(token);
    prefs.setString('sessionToken', encrypt);
  }

  encryptToken(String plainText) {
    var encrypted = encryptAESCryptoJS(plainText, "JventursP@ssW0rd");
    return encrypted;
  }

  Future<void> _resend(String phoneNo) async {
    try {
      print('resend');
      setState(() {
        _loadingState = true;
      });
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
        setState(() {
          otpRefAgain = body['data']['otp_ref'];
          sendAgain = true;
        });
      } else {
        await showDialog(
          context: context,
          builder: (_) => DialogAlert(
            type: "error",
            header: "Failed !",
            subtitle: "Send OTP failed \n Please check connection.",
            done: () {
              Navigator.of(context).pop();
            },
          ),
        );
      }
    } catch (err) {
      await showDialog(
        context: context,
        builder: (_) => DialogAlert(
          type: "error",
          header: "Failed !",
          subtitle: "Send OTP failed \n Please check connection.",
          done: () {
            Navigator.of(context).pop();
          },
        ),
      );
      print(err);
    }
    setState(() {
      _loadingState = false;
      timerStart();
    });
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

  Future<String> _getAccessToken(phoneNo, otpRef) async {
    var url = "https://api.jfin.network/api/v2/paa/verify_otp";
    bool check = await HttpSslCheck(url: url).check();
    print(check);
    if (!check) {
      throw 500;
    }
    var headers = {
      'content-type': 'application/json',
      'X-API-KEY': 'OTPJFINzM8L6ZCmbIvce1BAFwihvDf3BF'
    };
    var params = {'phone_no': phoneNo, 'otp_ref': otpRef, 'otp': _initValueOtp};
    var response = await Http.post(Uri.parse(url),
        body: jsonEncode(params), headers: headers);
    var body = await json.decode(response.body);
    if ((body['status_code']) == 200) {
      return await body['access_token'];
    } else {
      return '';
    }
  }

  Future<String> _login(phoneNo, accessToken) async {
    var url = "https://api.jfin.network/parse/users";
    bool check = await HttpSslCheck(url: url).check();
    print(check);
    if (!check) {
      throw 500;
    }
    var headers = {
      "content-type": "application/json",
      "X-Parse-Application-Id": "928f24ed35d8876dee76d0a5460ef078",
    };
    var params = {
      "authData": {
        "paa": {"id": phoneNo, "access_token": accessToken}
      }
    };
    var response = await Http.post(Uri.parse(url),
        body: jsonEncode(params), headers: headers);
    var body = await json.decode(response.body);
    return body['sessionToken'];
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context).settings.arguments as Map<String, dynamic>;
    Size size = MediaQuery.of(context).size;
    double statusBarHeight = MediaQuery.of(context).padding.top;
    double layoutHeader = 145.00 + statusBarHeight;
    return Scaffold(
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
                    padding: EdgeInsets.only(top: statusBarHeight + 15),
                    height: layoutHeader,
                    width: size.width,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xff8A0304), Color(0xffEC1C24)],
                      ),
                    ),
                    child: Column(
                      children: <Widget>[
                        Text(
                          'OTP',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(
                          height: 25,
                        ),
                        Text(
                          'Sent a sms to you.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Please specify the received number.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    constraints: BoxConstraints(maxWidth: 380),
                    width: size.width,
                    child: Column(
                      children: <Widget>[
                        Container(
                            height: size.height - (layoutHeader + 20),
                            child: Form(
                              key: _formOtpKey,
                              child: Column(
                                children: <Widget>[
                                  SizedBox(
                                    height: 50,
                                  ),
                                  TextFormField(
                                    focusNode: _otpFocusnode,
                                    initialValue: _initValueOtp,
                                    textAlign: TextAlign.center,
                                    keyboardType: TextInputType.number,
                                    textInputAction: TextInputAction.next,
                                    maxLength: 6,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                    decoration: InputDecoration(
                                      contentPadding:
                                          EdgeInsets.symmetric(vertical: 8),
                                      counterText: '',
                                      errorStyle: TextStyle(
                                          color: Colors.red,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500),
                                      hintText: 'OTP number',
                                      hintStyle: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xffc3c3c3),
                                          fontSize: 21),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(50.0),
                                        ),
                                        borderSide: BorderSide(
                                          color: Color(0xffc3c3c3),
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(50.0),
                                        ),
                                        borderSide: BorderSide(
                                          color: Color(0xffc3c3c3),
                                        ),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(50.0),
                                        ),
                                        borderSide: BorderSide(
                                          color: Color(0xffc3c3c3),
                                        ),
                                      ),
                                      focusedErrorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(50.0),
                                        ),
                                        borderSide: BorderSide(
                                          color: Color(0xffc3c3c3),
                                        ),
                                      ),
                                    ),
                                    onFieldSubmitted: (_) {
                                      FocusScope.of(context)
                                          .requestFocus(FocusNode());
                                      _onSubmit(
                                          args['phoneNo'],
                                          context,
                                          sendAgain
                                              ? otpRefAgain
                                              : args['otpRef']);
                                    },
                                    onSaved: (value) {
                                      _initValueOtp = value;
                                    },
                                    validator: (value) {
                                      if (value.isEmpty) {
                                        return ' Please enter valid number !';
                                      }
                                      return null;
                                    },
                                  ),
                                  SizedBox(
                                    height: 20,
                                  ),
                                  Text(
                                    'OTP Ref: ' +
                                        (sendAgain
                                            ? otpRefAgain
                                            : args['otpRef']),
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15),
                                  ),
                                  SizedBox(
                                    height: 50,
                                  ),
                                  if (countdown != 31) ...[
                                    Text('Resend again in ' +
                                        countdown.toString())
                                  ],
                                  GestureDetector(
                                    onTap: () {
                                      if (countdown == 31) {
                                        _resend(args['phoneNo']);
                                      }
                                    },
                                    child: Text(
                                      'Resend OTP again',
                                      style: TextStyle(
                                          color: Colors.teal,
                                          decoration: TextDecoration.underline,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                  SizedBox(
                                    height: 50,
                                  ),
                                  Container(
                                    constraints: BoxConstraints(maxWidth: 350),
                                    height: 48.0,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(50.0),
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color(0xff8A0304),
                                          Color(0xffEC1C24)
                                        ],
                                      ),
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () {
                                          _onSubmit(
                                              args['phoneNo'],
                                              context,
                                              sendAgain
                                                  ? otpRefAgain
                                                  : args['otpRef']);
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
                            )),
                      ],
                    ),
                  )
                ],
              ),
              Positioned(
                top: statusBarHeight + 10,
                child: GestureDetector(
                    onTap: () async {
                      FocusScope.of(context).requestFocus(new FocusNode());
                      await Future.delayed(const Duration(milliseconds: 250))
                          .then((x) {
                        Navigator.of(context).pop();
                      });
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
    );
  }
}
