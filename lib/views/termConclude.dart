import 'dart:async';
import 'dart:convert';

import 'package:agm/providers/auth.dart';
import 'package:agm/utils/http_ssl_check.dart';
import 'package:agm/widgets/loading.dart';
import 'package:intl/intl.dart';

import '../providers/meetings.dart';
import '../views/home.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as Http;
//import 'package:http/http.dart';
import 'package:flutter/services.dart' show rootBundle;
//import 'package:web3dart/web3dart.dart';
//import 'package:web_socket_channel/io.dart';

import '../widgets/layout.dart';

import '../widgets/step_lobby_list.dart';

class TermConcludePage extends StatefulWidget {
  static const routeName = '/Term-conclude';
  final setting;
  TermConcludePage(this.setting);

  @override
  _TermConcludePageState createState() => _TermConcludePageState();
}

class _TermConcludePageState extends State<TermConcludePage> {
  bool _isInit = true;
  Timer timerReportConclude;
  int _agree = 0;
  int _disAgree = 0;
  int _novote = 0;
  int _abandon = 0;
  int _noaction = 0;
  bool _loadingState = false;
  final oCcy = new NumberFormat("#,##0", "en_US");

  Future<String> loadAbi() async {
    return await rootBundle.loadString('assets/abi.json');
  }

  _saveMeeting(String meetingId) async {
    print("update parse ...");
    try {
      var sessionToken =
          await Provider.of<Auth>(context, listen: false).getSessionToken();
      var url = 'https://agm-api.jfin.network/update_voter_voted';
      bool check = await HttpSslCheck(url: url).check();
      print(check);
      if (!check) {
        throw 500;
      }
      var headers = {
        'content-type': 'application/json',
        'X-Parse-Application-Id': '928f24ed35d8876dee76d0a5460ef078',
        'X-Parse-Session-Token': sessionToken,
      };
      var params = {"meetingId": meetingId};
      await Http.post(Uri.parse(url),
          body: jsonEncode(params), headers: headers);
      await Navigator.of(context).pushNamedAndRemoveUntil(
          HomePage.routeName, (Route<dynamic> route) => false);
    } catch (err) {
      print(err);
    }
  }

  Future<bool> _onPopScope() async {
    return false;
  }

  @override
  void dispose() {
    super.dispose();
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
    double layoutHeader = 90.00 + statusBarHeight;
    final args =
        ModalRoute.of(context).settings.arguments as Map<String, dynamic>;
    var data = Provider.of<Meetings>(context, listen: false)
        .meetingById(args['meetingId']);
    var lobbyList = data.agendars;
    print('build widget conclude');
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      if (_isInit) {
        for (var i in lobbyList) {
          if (i.vote == null) {
          } else if (i.vote == 1) {
            setState(() {
              _agree++;
            });
          } else if (i.vote == 2) {
            setState(() {
              _disAgree++;
            });
          } else if (i.vote == 0) {
            setState(() {
              _novote++;
            });
          } else if (i.vote == 4 || !i.canVote) {
            setState(() {
              _noaction++;
            });
          } else {
            if (i.canVote) {
              setState(() {
                _abandon++;
              });
            }
          }
        }
        setState(() {
          //_list = lobbyList;
          _isInit = false;
        });
        //await getReport();
      }
    });

    Widget body = SingleChildScrollView(
      child: Container(
        height: size.height - layoutHeader,
        child: Column(
          children: <Widget>[
            Container(
              constraints: BoxConstraints(maxHeight: size.height * 0.45),
              child: SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.only(
                          left: 20, right: 20, top: 25, bottom: 15),
                      child: Text(
                        'Thanks for your votes ' + data.title ?? '',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            height: 1.5),
                        textAlign: TextAlign.start,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.only(left: 10, right: 10),
                      color: Colors.white,
                      child: Wrap(
                        children: <Widget>[
                          Container(
                            child: Card(
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Container(
                                      height: 19,
                                      width: 19,
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                          child: Icon(
                                        Icons.done,
                                        color: Colors.white,
                                        size: 17,
                                      )),
                                    ),
                                    SizedBox(
                                      width: 5,
                                    ),
                                    Text(
                                      'Agree (เห็นด้วย) ' + _agree.toString(),
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Container(
                            child: Card(
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Container(
                                      height: 19,
                                      width: 19,
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.clear,
                                        color: Colors.white,
                                        size: 17,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 5,
                                    ),
                                    Text(
                                      'Disagree (ไม่เห็นด้วย) ' +
                                          _disAgree.toString(),
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Container(
                            child: Card(
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Container(
                                      height: 19,
                                      width: 19,
                                      decoration: BoxDecoration(
                                          color: Color(0xfffb8c00),
                                          shape: BoxShape.circle),
                                    ),
                                    SizedBox(
                                      width: 5,
                                    ),
                                    Text(
                                      'No Vote (งดออกเสียง) ' +
                                          _novote.toString(),
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Container(
                            child: Card(
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Container(
                                      height: 19,
                                      width: 19,
                                      decoration: BoxDecoration(
                                          color: Color(0xff795548),
                                          shape: BoxShape.circle),
                                    ),
                                    SizedBox(
                                      width: 5,
                                    ),
                                    Text(
                                      'No Action (เพิกเฉย) ' +
                                          _noaction.toString(),
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Container(
                            child: Card(
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Container(
                                      height: 19,
                                      width: 19,
                                      decoration: BoxDecoration(
                                          color: Color(0xffDDE1FF),
                                          shape: BoxShape.circle),
                                    ),
                                    SizedBox(
                                      width: 5,
                                    ),
                                    Text(
                                      'Abandon (ไม่เข้าร่วม) ' +
                                          _abandon.toString(),
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 20,
            ),
            Container(
              padding: const EdgeInsets.only(right: 8),
              height: 30,
              width: size.width,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.center,
                  colors: [
                    Color(0xff000000).withOpacity(0.04),
                    Color(0xff000000).withOpacity(0.025),
                    Color(0xff000000).withOpacity(0),
                  ],
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Text(
                    'Share : ' + oCcy.format(data.share ?? 0).toString(),
                    style: TextStyle(
                      color: Color(0xff469fb8),
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 15.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'total ' + lobbyList.length.toString() + ' agenda',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 25,
            ),
            Expanded(
              child: SingleChildScrollView(
                child: StepLobbyList(
                  list: lobbyList,
                  type: 'conclude',
                ),
              ),
            ),
            SizedBox(
              height: 30,
            ),
            Container(
              constraints: BoxConstraints(maxWidth: 400),
              width: size.width * 0.8,
              height: 48.0,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: args['color'],
                ),
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
                  onTap: () {
                    setState(() {
                      _loadingState = true;
                    });
                    _saveMeeting(data.meetingId);
                  },
                  child: Center(
                    child: Container(
                      width: size.width,
                      child: Center(
                        child: const Text(
                          'Done',
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
              ),
            ),
            SizedBox(
              height: 20,
            ),
          ],
        ),
      ),
    );
    return WillPopScope(
      onWillPop: _onPopScope,
      child: Container(
        height: size.height,
        width: size.width,
        child: Stack(
          children: <Widget>[
            Layout(
              popClose: false,
              logo: false,
              logoUrl: '',
              body: body,
              header: 'Completed',
              color: args['color'],
            ),
            if (_loadingState)
              Positioned(
                top: 0,
                child: LoadingWidget(),
              ),
          ],
        ),
      ),
    );
  }
}
