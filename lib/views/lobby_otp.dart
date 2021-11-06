import 'dart:async';
import 'dart:convert';

import 'package:agm/providers/auth.dart';
import 'package:agm/utils/http_ssl_check.dart';
import 'package:agm/views/lobby_rp.dart';
import 'package:agm/widgets/dialogAlert.dart';
import 'package:agm/widgets/loading.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as Http;
import 'package:provider/provider.dart';

class LobbyOtpPage extends StatefulWidget {
  static const routeName = 'lobby-otp';
  final setting;
  LobbyOtpPage(this.setting);
  @override
  _LobbyOtpPageState createState() => _LobbyOtpPageState();
}

class _LobbyOtpPageState extends State<LobbyOtpPage> {
  bool _loadingState = false;
  var _otpFocusnode = FocusNode();
  var _initValueOtp = '';
  var _formOtpKey = GlobalKey<FormState>();
  bool _resendInd = false;
  String _otpRef = '';

  Future<void> _resend() async {
    try {
      setState(() {
        _loadingState = true;
      });
      var otpRef = await sendEmail();
      if (otpRef == "") {
        setState(() {
          _loadingState = false;
        });
        await showDialog(
            context: context,
            builder: (_) => DialogAlert(
                  type: 'error',
                  header: "Failed !",
                  subtitle: "Sent email failed. \nPlease try again.",
                  done: () {
                    Navigator.of(context).pop();
                  },
                ));
      } else {
        setState(() {
          _loadingState = false;
          _otpRef = otpRef;
          _resendInd = true;
        });
      }
    } catch (err) {}
  }

  Future<String> sendEmail() async {
    try {
      var sessionToken =
          await Provider.of<Auth>(context, listen: false).getSessionToken();
      var url = 'https://agm-api.jfin.network/send_otp';
      bool check = await HttpSslCheck(url: url).check();
      print(check);
      if (!check) {
        throw 500;
      }
      var headers = {
        'content-type': 'application/json',
        'x-api-key': 'l487kBwGEf09JmSF02Q5wVnuXcTHvZYz',
        'X-Parse-Session-Token': sessionToken
      };
      var params = {
        "email": widget.setting['email'],
        "meetingId": widget.setting['meetingId'],
      };
      var response =
          await Http.post(url, body: json.encode(params), headers: headers);
      var body = json.decode(response.body);

      return body['otp_ref'];
    } catch (err) {
      print(err);
      print("err sendmail email");
      return "";
    }
  }

  Future<void> _onSubmit() async {
    setState(() {
      _loadingState = true;
    });
    final isValid = _formOtpKey.currentState.validate();
    if (!isValid) {
      return;
    }
    try {
      await Future.delayed(const Duration(milliseconds: 250));
      _formOtpKey.currentState.save();
      bool sendOTP = await _sendOTP();
      if (sendOTP) {
        setState(() {
          _loadingState = false;
        });

        Navigator.of(context).pushNamed(LobbyRpPage.routeName, arguments: {
          "color": widget.setting['color'],
          "meetingId": widget.setting['meetingId'],
        });
      } else {
        setState(() {
          _loadingState = false;
        });
        await showDialog(
            context: context,
            builder: (_) => DialogAlert(
                  type: 'error',
                  header: "Failed !",
                  subtitle: "OTP number has invalid. \nPlease try again.",
                  done: () {
                    Navigator.of(context).pop();
                  },
                ));
      }
    } catch (err) {
      setState(() {
        _loadingState = false;
      });
      await showDialog(
          context: context,
          builder: (_) => DialogAlert(
                type: 'error',
                header: "Failed !",
                subtitle: "Please check connection and try again.",
                done: () {
                  Navigator.of(context).pop();
                },
              ));
    }
  }

  Future<bool> _sendOTP() async {
    try {
      var sessionToken =
          await Provider.of<Auth>(context, listen: false).getSessionToken();
      var url = 'https://agm-api.jfin.network/verify_otp';
      bool check = await HttpSslCheck(url: url).check();
      print(check);
      if (!check) {
        throw 500;
      }
      var headers = {
        'content-type': 'application/json',
        'x-api-key': 'l487kBwGEf09JmSF02Q5wVnuXcTHvZYz',
        'X-Parse-Session-Token': sessionToken
      };

      var otpRefX = widget.setting['otpRef'];
      if (_resendInd) {
        otpRefX = _otpRef;
      }
      var params = {
        "email": widget.setting['email'],
        "otp_ref": otpRefX,
        "otp": _initValueOtp,
        "meetingId": widget.setting['meetingId']
      };
      var response =
          await Http.post(url, body: json.encode(params), headers: headers);
      var body = json.decode(response.body);

      if (body['success'] != null && body['success'] == true) {
        return true;
      } else {
        return false;
      }
    } catch (err) {
      return false;
    }
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
                                    "Please check your E-mail",
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
                                  'Please enter received OTP.',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(
                                  height: 30,
                                ),
                                Form(
                                  key: _formOtpKey,
                                  child: Column(
                                    children: <Widget>[
                                      TextFormField(
                                        focusNode: _otpFocusnode,
                                        initialValue: _initValueOtp,
                                        textAlign: TextAlign.center,
                                        keyboardType: TextInputType.number,
                                        textInputAction: TextInputAction.next,
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
                                          focusedErrorBorder:
                                              OutlineInputBorder(
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
                                          _onSubmit();
                                        },
                                        onSaved: (value) {
                                          _initValueOtp = value;
                                        },
                                        validator: (value) {
                                          if (value.isEmpty) {
                                            return '  Please enter valid number !';
                                          }
                                          return null;
                                        },
                                      ),
                                      SizedBox(
                                        height: 20,
                                      ),
                                      Text(
                                        'OTP Ref:' +
                                            (_resendInd
                                                ? _otpRef
                                                : widget.setting['otpRef']),
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15),
                                      ),
                                      SizedBox(
                                        height: 50,
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          _resend();
                                        },
                                        child: Text(
                                          'Resend OTP again',
                                          style: TextStyle(
                                              color: Colors.teal,
                                              decoration:
                                                  TextDecoration.underline,
                                              fontSize: 17,
                                              fontWeight: FontWeight.w800),
                                        ),
                                      ),
                                      SizedBox(
                                        height: 50,
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
