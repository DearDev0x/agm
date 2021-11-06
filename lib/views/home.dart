import 'dart:async';
import 'dart:convert';

import 'package:agm/utils/http_ssl_check.dart';
import 'package:agm/views/OTP/termService.dart';

import '../widgets/dialogAlert.dart';
import '../widgets/drawer.dart';
import '../widgets/loading.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as Http;

import '../providers/meetings.dart';
import '../providers/auth.dart';

import './lobby.dart';
import '../widgets/content_loading.dart';
import '../widgets/list_item.dart';

class HomePage extends StatefulWidget {
  static const routeName = '/Home';

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _loadingState = true;
  var _isInit = true;
  var _scaffoldKey = GlobalKey<ScaffoldState>();
  Map<String, String> headers = {};
  void updateCookie(Http.Response response) {
    String rawCookie = response.headers['set-cookie'];
    if (rawCookie != null) {
      int index = rawCookie.indexOf(';');
      headers['cookie'] =
          (index == -1) ? rawCookie : rawCookie.substring(0, index);
    }
  }

  void getData() async {
    try {
      await Provider.of<Meetings>(context, listen: false).getMeetings();
      var address =
          await Provider.of<Auth>(context, listen: false).getWalletAddress();
      checkTerm();
      addGas(address);
      setState(() {
        _loadingState = false;
      });
    } catch (err) {
      setState(() {
        _loadingState = false;
      });
      print('err getData');
    }
  }

  Future<void> addGas(String address) async {
    try {
      var url = 'https://agm-api.jfin.network/faucet';
      bool check = await HttpSslCheck(url: url).check();
      print(check);
      if (!check) {
        throw 500;
      }
      var sessionToken =
          await Provider.of<Auth>(context, listen: false).getSessionToken();
      var headers = {
        'content-type': 'application/json',
        'X-Parse-Application-Id': '928f24ed35d8876dee76d0a5460ef078',
        'x-api-key': 'l487kBwGEf09JmSF02Q5wVnuXcTHvZYz',
        'X-Parse-Session-Token': sessionToken
      };
      var params = {"address": address};
      var response =
          await Http.post(url, body: jsonEncode(params), headers: headers);
      await json.decode(response.body);
      print('added gas');
    } catch (err) {}
  }

  Future<Null> _refresh() async {
    try {
      await Provider.of<Meetings>(context, listen: false).getMeetings();
    } catch (err) {}
    return null;
  }

  Future<void> checkTerm() async {
    try {
      var phonex = await Provider.of<Auth>(context, listen: false)
          .userData['authData']['paa']['id'];
      var url = "https://cmp-api.jfin.network/api/v1/consent/check_consent/" +
          phonex +
          "/SeIX6BDzwj";
      bool check = await HttpSslCheck(url: url).check();
      print(check);
      if (!check) {
        throw 500;
      }
      var headers = {
        'content-type': 'application/json',
        "X-Parse-Application-Id": "928f24ed35d8876dee76d0a5460ef078",
      };
      var response = await Http.get(url, headers: headers);
      var body = json.decode(response.body);
      if (body['statusCode'] != 200) {
        throw 400;
      }
      var checkConsent = body['data']['is_accept'];
      if (!checkConsent) {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  TermServicePage({'phoneNo': phonex, 'isPage': false})),
        );
      }
    } catch (err) {
      print(err);
    }
  }

  @override
  void initState() {
    super.initState();
    if (_isInit) {
      getData();
      _isInit = false;
    }
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
    var meetingItems = Provider.of<Meetings>(context).meetings;
    Member member = Provider.of<Auth>(context).member;
    return Scaffold(
      key: _scaffoldKey,
      endDrawer: DrawerWidget(),
      body: Stack(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                constraints: BoxConstraints(maxWidth: 700),
                width: size.width,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                margin: EdgeInsets.only(top: statusBarHeight + 20),
                child: Column(
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        const Text(
                          'Meeting List',
                          textAlign: TextAlign.start,
                          style: TextStyle(
                              fontSize: 30, fontWeight: FontWeight.w600),
                        ),
                        GestureDetector(
                            onTap: () {
                              _scaffoldKey.currentState.openEndDrawer();
                            },
                            child: Icon(
                              Icons.menu,
                              size: 30,
                              color: Color(0xffc3c3c3),
                            ))
                      ],
                    ),
                    if (_loadingState) ContentLoading(),
                    if (!_loadingState && meetingItems.length > 0)
                      Expanded(
                        child: RefreshIndicator(
                          color: Colors.redAccent,
                          onRefresh: _refresh,
                          child: ListView(
                            padding: const EdgeInsets.only(top: 25),
                            children: <Widget>[
                              for (var i = 0; i < meetingItems.length; i++)
                                GestureDetector(
                                  onTap: () {
                                    if (member != Member.Gold) {
                                      showDialog(
                                          context: context,
                                          builder: (_) => DialogAlert(
                                                header:
                                                    "You don't have right to access",
                                                type: 'error',
                                                subtitle:
                                                    'Please dipchip to be \n The Gold member before.',
                                                done: () {
                                                  Navigator.of(context).pop();
                                                },
                                              ));
                                      return;
                                    }
                                    var colorSelected = colors[i % 4];
                                    Navigator.of(context).pushNamed(
                                        LobbyPage.routeName,
                                        arguments: {
                                          'color': colorSelected,
                                          'meetingId': meetingItems[i].meetingId
                                        });
                                  },
                                  child: ListItem(
                                    key: ValueKey(meetingItems[i].objectId),
                                    company: meetingItems[i].company ?? '',
                                    title: meetingItems[i].title ?? '',
                                    address: meetingItems[i].address ?? '',
                                    timex: meetingItems[i].scheduleTime ??
                                        '' + '  น.',
                                    datex: meetingItems[i].getDateTh ?? '',
                                    logoUrl: meetingItems[i].logoUrl,
                                    color: colors[i % 4],
                                  ),
                                )
                            ],
                          ),
                        ),
                      ),
                    if (!_loadingState && meetingItems.length == 0)
                      Expanded(
                        child: RefreshIndicator(
                          color: Colors.redAccent,
                          onRefresh: _refresh,
                          child: ListView(
                            padding: const EdgeInsets.only(top: 25),
                            children: <Widget>[
                              Container(
                                  height: 120,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 15, vertical: 30),
                                  decoration:
                                      BoxDecoration(color: Colors.grey[200]),
                                  child: Center(
                                    child: const Text(
                                      'No List . . . ',
                                      style: TextStyle(
                                          color: Colors.black, fontSize: 16),
                                    ),
                                  )),
                            ],
                          ),
                        ),
                      )
                  ],
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
    );
  }
}
