import 'dart:async';
import 'dart:convert';

import 'package:agm/utils/http_ssl_check.dart';
import 'package:intl/intl.dart';

import '../views/lobby_otp.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/agendar.dart';
import '../providers/auth.dart';
import '../providers/meetings.dart';
import '../views/home.dart';
// import '../views/scanProxyVoter.dart';
import '../views/termWait.dart';
import '../widgets/dialogAlert.dart';
import '../widgets/loading.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uni_links/uni_links.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/layout.dart';
import '../widgets/step_lobby_list.dart';
import 'package:http/http.dart' as Http;

class LobbyPage extends StatefulWidget {
  static const routeName = '/lobby-page';
  final setting;
  LobbyPage(this.setting);

  @override
  _LobbyPageState createState() => _LobbyPageState();
}

class _LobbyPageState extends State<LobbyPage> {
  bool _loadingState = true;
  StreamSubscription _subRights;
  bool _isInitLobby = true;
  var _emailFocusnode = FocusNode();
  var _initValueEmail = '';
  var _formEmailKey = GlobalKey<FormState>();
  bool _canAccess = false;
  bool _otpAccess = false;
  bool liveness = false;
  final oCcy = new NumberFormat("#,##0", "en_US");
  Future<Null> initUniLinks(BuildContext context) async {
    _subRights = getUriLinksStream().listen((Uri uri) async {
      setState(() {
        _loadingState = true;
      });
      var segments = uri.pathSegments;
      var path = segments[0].trim();
      if (path == 'beforeVote') {
        setState(() {
          _loadingState = false;
        });
        await saveLastestAAL();
        List<Agendar> list = await getAgendars();
        Provider.of<Meetings>(context, listen: false)
            .addAgendarList(widget.setting['meetingId'], list);
        await Navigator.of(context).pushNamedAndRemoveUntil(
            TermWaitPage.routeName, (Route<dynamic> route) => false,
            arguments: {
              'color': widget.setting['color'],
              'meetingId': widget.setting['meetingId'],
              'indexOrder': 0,
            });
        await _subRights.cancel();
      }
    }, onError: (err) async {
      setState(() {
        _loadingState = false;
      });
      await _subRights.cancel();
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

  Future<void> launchURL(String url) async {
    if (!await launch(url, forceSafariVC: false, forceWebView: false))
      throw 'Could not launch $url';
  }

  Future<void> gotoIdp() async {
    setState(() {
      _loadingState = true;
    });
    String purpose = "Request%20The%20rights%20for%20vote%20on%20AGM%20Voting.";
    String callback = "https://jventuresagm.page.link/beforeVote";
    String sender = 'AGM';
    var requestId = await _requestRP();
    var hashId = Provider.of<Auth>(context, listen: false).hashId;
    setState(() {
      _loadingState = false;
    });
    var url =
        'https://jfinwallet.page.link/requestIdP?callback_url=$callback&purpose=$purpose&sender=$sender&hashId=$hashId&rpId=$requestId';
    try {
      await launchURL(url);
    } catch (err) {
      await showDialog(
        context: context,
        builder: (_) => DialogAlert(
          type: 'error',
          header: 'Failed !',
          subtitle: err.toString(),
          done: () {
            Navigator.pop(context);
            _loadingState = false;
          },
        ),
      );
    }
  }

  Future<List<Agendar>> getAgendars() async {
    try {
      var sessionToken =
          await Provider.of<Auth>(context, listen: false).getSessionToken();
      var url = 'https://agm-api.jfin.network/get_agenda';
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
      var params = {'meetingId': widget.setting['meetingId']};
      var response = await Http.post(Uri.parse(url),
          body: jsonEncode(params), headers: headers);
      var body = json.decode(response.body);
      liveness = body['liveness'];
      if (body['results'] == null || body['results'].toList().length == 0) {
        return [];
      } else {
        var list = body['results'].toList();
        List<Agendar> agendarsList = [];
        for (var i = 0; i < list.length; i++) {
          int vote = await getStateVote(list[i]['objectId']);
          Agendar agr;
          agr = Agendar(
            objectId: list[i]['objectId'],
            meetingId: list[i]['meetingId'],
            title: list[i]['title'],
            order: list[i]['order'],
            contractAddress: list[i]['contractAddress'],
            detail: list[i]['detail'],
            canVote: list[i]['canVote'],
            vote: vote,
          );
          agendarsList.add(agr);
        }
        return agendarsList;
      }
    } catch (err) {
      print(err);
      print('error get agendar');
      return [];
    }
  }

  Future<int> getStateVote(String objectId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> agInPrefs = prefs.getStringList('AgendarStateVote');
      int vote = 3;
      for (var j = 0; j < agInPrefs.length; j++) {
        var detail = jsonDecode(agInPrefs[j]);
        if (detail['agObjectId'] == objectId) {
          vote = detail['vote'];
        }
      }
      return vote;
    } catch (err) {
      return 3;
    }
  }

  Future<dynamic> getMeetingDetail(String meetingId) async {
    var sessionToken =
        await Provider.of<Auth>(context, listen: false).getSessionToken();
    try {
      var url = 'https://agm-api.jfin.network/get_voter';
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
      var params = {"meetingId": meetingId};
      var response = await Http.post(Uri.parse(url),
          body: jsonEncode(params), headers: headers);
      var body = json.decode(response.body);
      return body['results'][0];
    } catch (err) {
      print(err);
      print('err get meetingDetail');
      return {};
    }
  }

  void getData() async {
    try {
      var meeting = Provider.of<Meetings>(context, listen: false)
          .meetingById(widget.setting['meetingId']);
      print("meeting expired : " + meeting.isExpired.toString());

      var meetingDetail = await getMeetingDetail(widget.setting['meetingId']);

      Provider.of<Meetings>(context, listen: false)
          .addMeetingDetail(widget.setting['meetingId'], meetingDetail);

      if (meetingDetail['objectId'] != null) {
        List<Agendar> list = await getAgendars();

        Provider.of<Meetings>(context, listen: false)
            .addAgendarList(widget.setting['meetingId'], list);

        if (meetingDetail['smart_contract_added'] != null &&
            meetingDetail['smart_contract_added'] == true) {
          _canAccess = true;
          _otpAccess = true;
        } else {
          if (!meeting.isExpired) {
            _canAccess = true;
          }
        }
      }
    } catch (err) {
      print(err);
    }
    setState(() {
      _loadingState = false;
    });
  }

  @override
  void initState() {
    super.initState();
    if (_isInitLobby) {
      initUniLinks(context);
      getData();
      _isInitLobby = false;
    }
  }

  @override
  void dispose() {
    _subRights.cancel();
    super.dispose();
  }

  Future<String> _requestRP() async {
    try {
      String id = Provider.of<Auth>(context, listen: false).idCard;
      String purpose = "Request The rights for vote on AGM Voting.";
      String callback = "https://jventuresagm.page.link/beforeVote";
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
        "type": "2",
        "meetingId": widget.setting['meetingId']
      };
      var response = await Http.post(Uri.parse(url), body: params);
      var body = await json.decode(response.body);
      return body['request_id'];
    } catch (err) {
      print(err);
      throw 512;
    }
  }

  Future<void> _onSubmit() async {
    final isValid = _formEmailKey.currentState.validate();
    if (!isValid) {
      return;
    }
    _formEmailKey.currentState.save();
    setState(() {
      _loadingState = true;
    });
    await Future.delayed(const Duration(seconds: 2));
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
      await updateEmail();
      setState(() {
        _loadingState = false;
      });
      Navigator.of(context).pushNamed(LobbyOtpPage.routeName, arguments: {
        "email": _initValueEmail,
        "color": widget.setting['color'],
        "meetingId": widget.setting['meetingId'],
        "otpRef": otpRef,
      });
    }
  }

  Future<String> sendEmail() async {
    var sessionToken =
        await Provider.of<Auth>(context, listen: false).getSessionToken();
    try {
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
        "email": _initValueEmail,
        "meetingId": widget.setting['meetingId']
      };
      var response = await Http.post(Uri.parse(url),
          body: json.encode(params), headers: headers);
      var body = json.decode(response.body);
      return body['otp_ref'] ?? '';
    } catch (err) {
      print(err);
      print("err sendmail email");
      return "";
    }
  }

  Future<void> updateEmail() async {
    var sessionToken =
        await Provider.of<Auth>(context, listen: false).getSessionToken();
    try {
      var url = 'https://agm-api.jfin.network/update_voter_email';
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
      var params = {
        "email": _initValueEmail,
        "meetingId": widget.setting['meetingId']
      };
      await Http.post(Uri.parse(url),
          body: json.encode(params), headers: headers);
      print("success updated email");
    } catch (err) {
      print(err);
      print("err update sender email");
    }
  }

  Future<void> saveLastestAAL() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var oldValue = prefs.getStringList('meetingsAAL');
    dynamic obj = {
      'meetingId': widget.setting['meetingId'],
      'lastAAL': DateTime.now().toString(),
    };
    if (oldValue != null) {
      for (var i = 0; i < oldValue.length; i++) {
        if (json.decode(oldValue[i])['meetingId'] == obj['meetingId']) {
          oldValue.removeAt(i);
        }
      }
      oldValue.add(jsonEncode(obj));
    } else {
      oldValue = [jsonEncode(obj)];
    }
    await prefs.setStringList('meetingsAAL', oldValue);
  }

  Future<bool> getLastestAAL() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var oldValue = prefs.getStringList('meetingsAAL');
    if (oldValue != null) {
      try {
        var value = oldValue.firstWhere((element) =>
            json.decode(element)['meetingId'] == widget.setting['meetingId']);
        var decode = json.decode(value);
        var dateAAL = DateTime.parse(decode['lastAAL']);
        DateTime now = DateTime.now();
        DateTime endDate = dateAAL.add(Duration(minutes: 30));
        return now.isAfter(endDate);
      } catch (err) {
        return true;
      }
    } else {
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    double statusBarHeight = MediaQuery.of(context).padding.top;
    double layoutHeader = 90.00 + statusBarHeight;
    final args =
        ModalRoute.of(context).settings.arguments as Map<String, dynamic>;
    var data = Provider.of<Meetings>(context, listen: true)
        .meetingById(args['meetingId']);
    if (data == null) {
      Navigator.of(context).pushNamed(HomePage.routeName);
    }

    var lobbyList = data.agendars;
    Widget body = Container(
      height: size.height - (layoutHeader + 40),
      child: Column(
        children: <Widget>[
          Container(
            constraints: BoxConstraints(maxHeight: 145),
            color: Colors.white,
            padding:
                const EdgeInsets.only(top: 15, bottom: 15, left: 20, right: 20),
            child: SingleChildScrollView(
              child: Text(
                data.detail ?? '',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w800, height: 1.5),
              ),
            ),
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
          if (lobbyList.length > 0)
            Expanded(
              child: SingleChildScrollView(
                child: StepLobbyList(
                  list: lobbyList,
                  type: 'lobby',
                ),
              ),
            ),
          if (lobbyList.length == 0)
            Expanded(
              child: Container(),
            ),
          Container(
            width: size.width,
            color: Color(0xfff4f4f4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Column(
                  children: <Widget>[
                    SizedBox(
                      height: 10,
                    ),
                    Text(
                      'โปรดทราบ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 17,
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline),
                    ),
                    SizedBox(
                      height: 5,
                    ),
                    Text(
                      'ในกรณีที่ท่านไม่กดลงคะแนน ภายหลังการกด PIN\nจะถือว่าท่านเห็นด้วยกับวาระนี้',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 15,
                          color: Colors.red,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                SizedBox(
                  height: 10,
                ),
                Container(
                  constraints: BoxConstraints(maxWidth: 400),
                  width: size.width * 0.8,
                  height: 48.0,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: !data.rightVote
                          ? [Color(0xffAFAFAF), Color(0xffAFAFAF)]
                          : args['color'],
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
                      onTap: () async {
                        if (!data.rightVote) {
                        } else {
                          setState(() {
                            _loadingState = true;
                          });
                          bool gotoAAL = await getLastestAAL();
                          if (gotoAAL || !liveness) {
                            setState(() {
                              _loadingState = false;
                            });
                            gotoIdp();
                          } else {
                            await saveLastestAAL();
                            setState(() {
                              _loadingState = false;
                            });
                            await Navigator.of(context)
                                .pushNamed(TermWaitPage.routeName, arguments: {
                              'color': widget.setting['color'],
                              'meetingId': widget.setting['meetingId'],
                              'indexOrder': 0,
                            });
                          }
                        }
                      },
                      child: Center(
                        child: Container(
                          width: size.width,
                          child: Center(
                            child: Text(
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
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
              ],
            ),
          ),

          // GestureDetector(
          //   onTap: () async {
          //     if (!data.rightVote) {
          //     } else {
          //       Navigator.of(context)
          //           .pushNamed(ScanProxyVoterPage.routeName, arguments: {
          //         'color': args['color'],
          //         'meetingId': args['meetingId'],
          //       });
          //     }
          //   },
          //   child: Text(
          //     data.proxyAddress != null || data.voted == true
          //         ? 'Granted voting rights'
          //         : 'Grant voting rights',
          //     textAlign: TextAlign.start,
          //     style: TextStyle(
          //       fontSize: 15,
          //       fontWeight: FontWeight.w600,
          //       decoration: TextDecoration.underline,
          //       color: !data.rightVote ? Color(0xffAFAFAF) : Colors.black,
          //     ),
          //   ),
          // ),
          // SizedBox(
          //   height: 20,
          // ),
        ],
      ),
    );

    Widget otp = Container(
      height: size.height - layoutHeader,
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
                  'Please enter your E-mail.',
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
                  key: _formEmailKey,
                  child: Column(
                    children: <Widget>[
                      TextFormField(
                        focusNode: _emailFocusnode,
                        initialValue: _initValueEmail,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                          counterText: '',
                          errorStyle: TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                              fontWeight: FontWeight.w500),
                          hintText: 'E-mail',
                          hintStyle: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Color(0xffc3c3c3),
                              fontSize: 19),
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
                          FocusScope.of(context).requestFocus(FocusNode());
                          _onSubmit();
                        },
                        onChanged: (value) {
                          _formEmailKey.currentState.validate();
                        },
                        onSaved: (value) {
                          _initValueEmail = value;
                        },
                        validator: validateEmail,
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
                            colors: widget.setting['color'],
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
    );

    return Container(
      height: size.height,
      width: size.width,
      color: Color(0xfff0f0f0),
      child: Stack(
        children: <Widget>[
          if (_canAccess && !_otpAccess)
            Layout(
              popClose: true,
              logo: false,
              logoUrl: '',
              body: otp,
              header: 'Register to online voting',
              color: args['color'],
            ),
          if (_canAccess && _otpAccess)
            Layout(
              popClose: true,
              logo: true,
              logoUrl: data.logoUrl ?? '',
              body: body,
              header: data.title ?? '',
              color: args['color'],
            ),
          if (!_canAccess && !_loadingState)
            Layout(
              popClose: true,
              logo: true,
              logoUrl: data.logoUrl ?? '',
              body: Container(
                height: size.height - layoutHeader,
                child: Center(
                  child: Text(
                    'Sorry, you can\'t access to this meeting.',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              header: data.title ?? '',
              color: args['color'],
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

  String validateEmail(String value) {
    Pattern pattern =
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@';
    RegExp regex = new RegExp(pattern);
    if (!regex.hasMatch(value))
      return 'Please enter valid Email';
    else
      return null;
  }
}
