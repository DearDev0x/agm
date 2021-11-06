import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:agm/providers/auth.dart';
import 'package:agm/utils/http_ssl_check.dart';
import 'package:agm/widgets/loading.dart';
import 'package:http/http.dart' as Http;
import 'package:agm/views/OTP/phoneVerify.dart';
import 'package:provider/provider.dart';

import '../widgets/dialogAlert.dart';
import 'package:flutter/material.dart';

class PinConfirmWidget extends StatefulWidget {
  final Function done;
  PinConfirmWidget({this.done});
  @override
  _PinConfirmWidgetState createState() => _PinConfirmWidgetState();
}

class _PinConfirmWidgetState extends State<PinConfirmWidget> {
  List<String> _pin = [];
  bool _visible = true;
  bool _loadingState = false;
  String _sessionToken;

  Future<String> getSessionToken() async {
    var sessionToken =
        await Provider.of<Auth>(context, listen: false).getSessionToken();
    return sessionToken;
  }

  Future<void> verifyPin(String pin) async {
    try {
      var url = 'https://agm-api.jfin.network/verify_pin';
      bool check = await HttpSslCheck(url: url).check();
      print(check);
      if (!check) {
        throw 500;
      }
      var headers = {"X-Parse-Session-Token": _sessionToken};
      var params = {"pin": pin};
      var response = await Http.post(url, body: params, headers: headers);
      var body = jsonDecode(response.body);

      if (body['status'] == 200) {
        widget.done();
      } else if (body['status'] == 400) {
        if (body['lock'] <= 0) {
          await showDialog(
            context: context,
            builder: (_) => DialogAlert(
              type: "error",
              header: "Failed !",
              subtitle: "Pin invalid\n" + "attemped ${body['attempted']}/3",
              done: () {
                Navigator.of(context).pop();
              },
            ),
          );
        } else {
          await showDialog(
              context: context,
              builder: (_) => DialogAlert(
                    type: "error",
                    header: "Failed !",
                    subtitle: "Please try again\n" + "in ${body['lock']} sec.",
                    done: () {
                      Navigator.of(context).pop();
                    },
                  ));
        }
        throw 400;
      } else {
        await showDialog(
          context: context,
          builder: (_) => DialogAlert(
            type: "error",
            header: "Failed !",
            subtitle: "Pin notfound\n" + "Please re-verify otp.",
            done: () async {
              Navigator.of(context).pop();
              await Navigator.of(context).pushNamedAndRemoveUntil(
                  PhoneVerifyPage.routeName, (Route<dynamic> route) => false);
            },
          ),
        );
        throw 400;
      }
    } catch (err) {
      throw err;
    }
  }

  void _pinPress(String pinput, BuildContext ctx) async {
    if (_pin.length > 5) {
      return;
    }
    setState(() {
      _pin.add(pinput);
    });
    if (_pin.length == 6) {
      setState(() {
        _loadingState = true;
      });
      try {
        String pinString = '';
        for (var i in _pin) {
          pinString = pinString + (i.toString());
        }
        await verifyPin(pinString);
      } catch (err) {
        print('main error ' + err.toString());
        if (err != 400) {
          await showDialog(
            context: context,
            builder: (_) => DialogAlert(
              type: "error",
              header: "Failed !",
              subtitle: "Verify failed \n Please try again.",
              done: () {
                Navigator.of(context).pop();
              },
            ),
          );
        }
      }
      await waitPinHide();
      setState(() {
        _loadingState = false;
      });
    }
  }

  waitPinHide() {
    return Timer(Duration(milliseconds: 200), () {
      setState(() {
        _pin = [];
      });
    });
  }

  @override
  void initState() {
    getSessionToken().then(updateSessionToken);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    double statusBarHeight = MediaQuery.of(context).padding.top;
    return AnimatedOpacity(
      opacity: _visible ? 1.0 : 0.0,
      duration: Duration(milliseconds: 300),
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                color: Colors.black.withOpacity(0.5),
                width: size.width,
                child: Container(
                  height: size.height,
                  width: size.width,
                  child: Column(
                    children: <Widget>[
                      SizedBox(
                        height: statusBarHeight + size.height * 0.08,
                      ),
                      Text(
                        'Please specify a 6-digit \n security password.',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 22,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(
                        height: size.height * 0.04,
                      ),
                      Container(
                        width: 200,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Container(
                              padding: const EdgeInsets.all(5),
                              margin: const EdgeInsets.only(left: 7),
                              height: 35,
                              width: 25,
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                      width: 2.0, color: Colors.white),
                                ),
                              ),
                              child: _pin.asMap().containsKey(0)
                                  ? Container(
                                      height: 5,
                                      width: 5,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: Border.all(
                                            color: Colors.white, width: 10.0),
                                        shape: BoxShape.circle,
                                      ),
                                    )
                                  : Text(""),
                            ),
                            Container(
                              padding: const EdgeInsets.all(5),
                              margin: const EdgeInsets.only(left: 7),
                              height: 35,
                              width: 25,
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                      width: 2.0, color: Colors.white),
                                ),
                              ),
                              child: _pin.asMap().containsKey(1)
                                  ? Container(
                                      height: 5,
                                      width: 5,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: Border.all(
                                            color: Colors.white, width: 10.0),
                                        shape: BoxShape.circle,
                                      ),
                                    )
                                  : Text(""),
                            ),
                            Container(
                              padding: const EdgeInsets.all(5),
                              margin: const EdgeInsets.only(left: 7),
                              height: 35,
                              width: 25,
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                      width: 2.0, color: Colors.white),
                                ),
                              ),
                              child: _pin.asMap().containsKey(2)
                                  ? Container(
                                      height: 5,
                                      width: 5,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: Border.all(
                                            color: Colors.white, width: 10.0),
                                        shape: BoxShape.circle,
                                      ),
                                    )
                                  : Text(""),
                            ),
                            Container(
                              padding: const EdgeInsets.all(5),
                              margin: const EdgeInsets.only(left: 7),
                              height: 35,
                              width: 25,
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                      width: 2.0, color: Colors.white),
                                ),
                              ),
                              child: _pin.asMap().containsKey(3)
                                  ? Container(
                                      height: 5,
                                      width: 5,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: Border.all(
                                            color: Colors.white, width: 10.0),
                                        shape: BoxShape.circle,
                                      ),
                                    )
                                  : Text(""),
                            ),
                            Container(
                              padding: const EdgeInsets.all(5),
                              margin: const EdgeInsets.only(left: 7),
                              height: 35,
                              width: 25,
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                      width: 2.0, color: Colors.white),
                                ),
                              ),
                              child: _pin.asMap().containsKey(4)
                                  ? Container(
                                      height: 5,
                                      width: 5,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: Border.all(
                                            color: Colors.white, width: 10.0),
                                        shape: BoxShape.circle,
                                      ),
                                    )
                                  : Text(""),
                            ),
                            Container(
                              padding: const EdgeInsets.all(5),
                              margin: const EdgeInsets.only(left: 7),
                              height: 35,
                              width: 25,
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                      width: 2.0, color: Colors.white),
                                ),
                              ),
                              child: _pin.asMap().containsKey(5)
                                  ? Container(
                                      height: 5,
                                      width: 5,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: Border.all(
                                            color: Colors.white, width: 10.0),
                                        shape: BoxShape.circle,
                                      ),
                                    )
                                  : Text(""),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: size.height * 0.04 + 20,
                      ),
                      Expanded(
                        child: Container(
                          constraints: BoxConstraints(maxWidth: 480),
                          child: GridView.count(
                            physics: NeverScrollableScrollPhysics(),
                            childAspectRatio: 1,
                            padding: EdgeInsets.symmetric(horizontal: 60),
                            crossAxisCount: 3,
                            mainAxisSpacing: 25,
                            crossAxisSpacing: 25,
                            children: <Widget>[
                              FloatingActionButton(
                                heroTag: "btnPConW1",
                                elevation: 0,
                                backgroundColor:
                                    Color(0xffb5b5b5).withOpacity(0.5),
                                child: Text(
                                  '1',
                                  style: TextStyle(
                                      fontSize: 25,
                                      fontWeight: FontWeight.w600),
                                ),
                                onPressed: () {
                                  _pinPress("1", context);
                                },
                              ),
                              FloatingActionButton(
                                heroTag: "btnPConW2",
                                elevation: 0,
                                backgroundColor:
                                    Color(0xffb5b5b5).withOpacity(0.5),
                                child: Text(
                                  '2',
                                  style: TextStyle(
                                      fontSize: 25,
                                      fontWeight: FontWeight.w600),
                                ),
                                onPressed: () {
                                  _pinPress("2", context);
                                },
                              ),
                              FloatingActionButton(
                                heroTag: "btnPConW3",
                                elevation: 0,
                                backgroundColor:
                                    Color(0xffb5b5b5).withOpacity(0.5),
                                child: Text(
                                  '3',
                                  style: TextStyle(
                                      fontSize: 25,
                                      fontWeight: FontWeight.w600),
                                ),
                                onPressed: () {
                                  _pinPress("3", context);
                                },
                              ),
                              FloatingActionButton(
                                heroTag: "btnPConW4",
                                elevation: 0,
                                backgroundColor:
                                    Color(0xffb5b5b5).withOpacity(0.5),
                                child: Text(
                                  '4',
                                  style: TextStyle(
                                      fontSize: 25,
                                      fontWeight: FontWeight.w600),
                                ),
                                onPressed: () {
                                  _pinPress("4", context);
                                },
                              ),
                              FloatingActionButton(
                                heroTag: "btnPConW5",
                                elevation: 0,
                                backgroundColor:
                                    Color(0xffb5b5b5).withOpacity(0.5),
                                child: Text(
                                  '5',
                                  style: TextStyle(
                                      fontSize: 25,
                                      fontWeight: FontWeight.w600),
                                ),
                                onPressed: () {
                                  _pinPress("5", context);
                                },
                              ),
                              FloatingActionButton(
                                heroTag: "btnPConW6",
                                elevation: 0,
                                backgroundColor:
                                    Color(0xffb5b5b5).withOpacity(0.5),
                                child: Text(
                                  '6',
                                  style: TextStyle(
                                      fontSize: 25,
                                      fontWeight: FontWeight.w600),
                                ),
                                onPressed: () {
                                  _pinPress("6", context);
                                },
                              ),
                              FloatingActionButton(
                                heroTag: "btnPConW7",
                                elevation: 0,
                                backgroundColor:
                                    Color(0xffb5b5b5).withOpacity(0.5),
                                child: Text(
                                  '7',
                                  style: TextStyle(
                                      fontSize: 25,
                                      fontWeight: FontWeight.w600),
                                ),
                                onPressed: () {
                                  _pinPress("7", context);
                                },
                              ),
                              FloatingActionButton(
                                heroTag: "btnPConW8",
                                elevation: 0,
                                backgroundColor:
                                    Color(0xffb5b5b5).withOpacity(0.5),
                                child: Text(
                                  '8',
                                  style: TextStyle(
                                      fontSize: 25,
                                      fontWeight: FontWeight.w600),
                                ),
                                onPressed: () {
                                  _pinPress("8", context);
                                },
                              ),
                              FloatingActionButton(
                                heroTag: "btnPConW9",
                                elevation: 0,
                                backgroundColor:
                                    Color(0xffb5b5b5).withOpacity(0.5),
                                child: Text(
                                  '9',
                                  style: TextStyle(
                                      fontSize: 25,
                                      fontWeight: FontWeight.w600),
                                ),
                                onPressed: () {
                                  _pinPress("9", context);
                                },
                              ),
                              Text(''),
                              FloatingActionButton(
                                heroTag: "btnPConW10",
                                elevation: 0,
                                backgroundColor:
                                    Color(0xffb5b5b5).withOpacity(0.5),
                                child: Text(
                                  '0',
                                  style: (TextStyle(
                                      fontSize: 25,
                                      fontWeight: FontWeight.w600)),
                                ),
                                onPressed: () {
                                  _pinPress("0", context);
                                },
                              ),
                              GestureDetector(
                                onTap: () {
                                  if (_pin.length <= 0) {
                                    return;
                                  }
                                  setState(() {
                                    _pin.removeLast();
                                  });
                                },
                                child: Container(
                                  child: Center(
                                    child: Icon(
                                      Icons.backspace,
                                      size: 35,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_loadingState) ...[
            Positioned(
              top: 0,
              child: LoadingWidget(),
            ),
          ]
        ],
      ),
    );
  }

  void updateSessionToken(String sessionToken) {
    setState(() {
      this._sessionToken = sessionToken;
    });
  }
}
