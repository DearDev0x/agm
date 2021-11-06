import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:agm/providers/auth.dart';
import 'package:agm/utils/http_ssl_check.dart';
import 'package:agm/widgets/loading.dart';
import 'package:http/http.dart' as Http;
import 'package:provider/provider.dart';
import '../../views/home.dart';
import 'package:flutter/material.dart';

import '../../widgets/dialogAlert.dart';
import '../../widgets/list_item.dart';

class NewPasswordPage extends StatefulWidget {
  static const routeName = '/new-Password';

  @override
  _NewPasswordPageState createState() => _NewPasswordPageState();
}

class _NewPasswordPageState extends State<NewPasswordPage> {
  List<String> _pin = [];
  bool _loadingState = false;
  String _sessionToken = '';

  Future<void> setNewPin(String pin) async {
    try {
      var url = 'https://agm-api.jfin.network/set_new_pin';
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
      } else {
        throw 'err';
      }
    } catch (err) {
      print(err);
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
        await setNewPin(pinString);
        await showDialog(
          context: context,
          builder: (_) => DialogAlert(
            header: 'Success',
            type: "success",
            subtitle: "The password  is changed",
            done: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamedAndRemoveUntil(
                  HomePage.routeName, (Route<dynamic> route) => false);
            },
          ),
        );
      } catch (err) {
        await showDialog(
          context: context,
          builder: (_) => DialogAlert(
            type: "error",
            header: "Failed !",
            subtitle: "Set Pin failed\n Please try again.",
            done: () {
              Navigator.of(context).pop();
            },
          ),
        );
        print(err);
      }
      setState(() {
        _loadingState = false;
      });
      await waitPinHide();
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
  void didChangeDependencies() async {
    await Provider.of<Auth>(context, listen: false)
        .getSessionToken()
        .then((value) {
      _sessionToken = value;
    });
    super.didChangeDependencies();
  }

  @override
  void initState() {
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
      body: Stack(
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
                        'Edit PIN CODE \n Please enter new password.',
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
                                heroTag: "btnNEW1",
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
                                heroTag: "btnNEW2",
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
                                heroTag: "btnNEW3",
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
                                heroTag: "btnNEW4",
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
                                heroTag: "btnNEW5",
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
                                heroTag: "btnNEW6",
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
                                heroTag: "btnNEW7",
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
                                heroTag: "btnNEW8",
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
                                heroTag: "btnNEW9",
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
                                heroTag: "btnNEW10",
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
          Positioned(
            top: statusBarHeight + 10,
            left: 5,
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Icon(
                Icons.chevron_left,
                color: Colors.white,
                size: 40,
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
    );
  }
}
