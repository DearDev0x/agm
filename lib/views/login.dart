import 'dart:async';
import 'dart:ui';
import 'package:agm/utils/http_ssl_check.dart';
import 'package:agm/views/OTP/phoneVerify.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as Http;

import '../providers/auth.dart';
import '../widgets/dialogAlert.dart';
import '../widgets/list_item.dart';
import '../widgets/loading.dart';

import '../views/home.dart';

class LoginPage extends StatefulWidget {
  static const routeName = '/login';

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  List<String> _pin = [];
  String _sessionToken;
  Function eq = const ListEquality().equals;
  bool _loadingState = false;

  Future<List> getPin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List pinAccess = prefs.getStringList('pin');
    return pinAccess;
  }

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

  Future<void> _pinPress(String pinput, BuildContext ctx) async {
    if (_pin.length > 5) {
      return;
    }
    setState(() {
      _pin.add(pinput);
    });
    if (_pin.length == 6) {
      try {
        setState(() {
          _loadingState = true;
        });
        String pinString = '';
        for (var i in _pin) {
          pinString = pinString + (i.toString());
        }
        await verifyPin(pinString);
        await _login();
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

  Future<void> _login() async {
    setState(() {
      _loadingState = true;
    });
    try {
      var me = await _getMe();
      Provider.of<Auth>(context, listen: false).setUserData(me);
      var idCard = me['idCard'];
      if (idCard != null) {
        await Provider.of<Auth>(context, listen: false).getEkycData();
      }
      Provider.of<Auth>(context, listen: false).setLogedIn();
      await Navigator.of(context).pushNamedAndRemoveUntil(
          HomePage.routeName, (Route<dynamic> route) => false);
    } catch (err) {
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
    setState(() {
      _loadingState = false;
    });
  }

  Future<dynamic> _getMe() async {
    var url = "https://api.jfin.network/parse/users/me";
    bool check = await HttpSslCheck(url: url).check();
    print(check);
    if (!check) {
      throw 500;
    }
    var headers = {
      "X-Parse-Application-Id": "928f24ed35d8876dee76d0a5460ef078",
      "X-Parse-Session-Token": _sessionToken,
      "content-type": "application/json"
    };
    var response = await Http.get(url, headers: headers);
    var body = await json.decode(response.body);
    return body;
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
    List colors = [
      [Color(0xff8A0304), Color(0xffEC1C24)],
      [Color(0xff11998E), Color(0xff38EF7D)],
      [Color(0xff36D1DC), Color(0xff5B86E5)],
      [Color(0xffFC5C7D), Color(0xff6A82FB)],
    ];
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          height: size.height,
          width: size.width,
          child: Stack(
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    constraints: BoxConstraints(maxWidth: 700),
                    width: size.width,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    margin: EdgeInsets.only(top: statusBarHeight),
                    child: Column(
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            const Text(
                              '',
                              textAlign: TextAlign.start,
                              style: TextStyle(
                                  fontSize: 30, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.only(top: 25),
                            children: <Widget>[
                              for (var i = 0; i < 5; i++)
                                ListItem(
                                  company: '',
                                  title: "",
                                  address: "",
                                  timex: "",
                                  datex: "",
                                  logoUrl: "",
                                  color: colors[i % 4],
                                )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
                            'Please confirm \n The security password',
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
                                                color: Colors.white,
                                                width: 10.0),
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
                                                color: Colors.white,
                                                width: 10.0),
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
                                                color: Colors.white,
                                                width: 10.0),
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
                                                color: Colors.white,
                                                width: 10.0),
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
                                                color: Colors.white,
                                                width: 10.0),
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
                                                color: Colors.white,
                                                width: 10.0),
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
                                    heroTag: "btnLOG1",
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
                                    heroTag: "btnLOG2",
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
                                    heroTag: "btnLOG3",
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
                                    heroTag: "btnLOG4",
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
                                    heroTag: "btnLOG5",
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
                                    heroTag: "btnLOG6",
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
                                    heroTag: "btnLOG7",
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
                                    heroTag: "btnLOG8",
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
                                    heroTag: "btnLOG9",
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
                                    heroTag: "btnLOG10",
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

  void updateSessionToken(String sessionToken) {
    setState(() {
      this._sessionToken = sessionToken;
    });
  }
}
