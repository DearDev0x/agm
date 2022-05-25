import 'dart:async';
import 'package:agm/providers/auth.dart';
import 'package:agm/widgets/dialogAlert.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:connectivity/connectivity.dart';
import 'package:http/http.dart';
import 'package:flutter/services.dart' show PlatformException, rootBundle;
import 'package:web3dart/web3dart.dart';
import 'package:web_socket_channel/io.dart';

import '../providers/meetings.dart';

import '../views/termConclude.dart';
import '../views/termVote.dart';
import '../views/home.dart';

class TermWaitPage extends StatefulWidget {
  static const routeName = '/Term-wait';
  final setting;
  TermWaitPage(this.setting);

  @override
  _TermWaitPageState createState() => _TermWaitPageState();
}

class _TermWaitPageState extends State<TermWaitPage>
    with WidgetsBindingObserver {
  var _client =
      Web3Client("https://rpc.xchain.asia", Client(), socketConnector: () {
    return IOWebSocketChannel.connect("wss://ws.xchain.asia").cast<String>();
  });
  String abiCode;
  bool _isInit = true;
  bool _isEnd = false;
  Timer timerReport;
  int agendarLength;
  StreamSubscription<FilterEvent> _voteStartSubscription;
  Timer _timerWait;
  String nowContract = '';
  String prevContract = '';
  final oCcy = new NumberFormat("#,##0", "en_US");
  String _prevVote = '';
  Color _prevColor;

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult> _connectivitySubscription;

  Future<void> connectionEvent(String contractAddress) async {
    try {
      print('ws entry termWait');
      final EthereumAddress contractAddr =
          EthereumAddress.fromHex(contractAddress);
      final contract = DeployedContract(
          ContractAbi.fromJson(abiCode, 'Ballot'), contractAddr);
      final voteStart = contract.event('voteStarted');
      _voteStartSubscription = _client
          .events(FilterOptions.events(contract: contract, event: voteStart))
          .take(1)
          .listen((event) async {
        print("listen...");
        _isEnd = true;
        await Navigator.of(context).pushNamedAndRemoveUntil(
            TermVotePage.routeName, (Route<dynamic> route) => false,
            arguments: {
              'color': widget.setting['color'],
              'meetingId': widget.setting['meetingId'],
              'indexOrder': widget.setting['indexOrder']
            });
      });
      await _voteStartSubscription.asFuture();
      await _voteStartSubscription.cancel();
    } catch (err) {
      print('error connection');
    }
  }

  reConnectWs(String contractAddress) {
    _timerWait =
        Timer.periodic(const Duration(seconds: 50), (Timer timer) async {
      try {
        await _voteStartSubscription.cancel();
        if (!_isEnd) {
          print('reConnect termWait : ' + timer.tick.toString());
          await connectionEvent(contractAddress);
        }
      } catch (err) {}
    });
  }

  Future<dynamic> checkAgendar(String contractAddress) async {
    try {
      final EthereumAddress contractAddr =
          EthereumAddress.fromHex(contractAddress);
      final contract = DeployedContract(
          ContractAbi.fromJson(abiCode, 'Ballot'), contractAddr);
      final state = contract.function('state');
      final stateData =
          await _client.call(contract: contract, function: state, params: []);
      return stateData;
    } catch (err) {
      return [0];
    }
  }

  Future<String> loadAbi() async {
    return await rootBundle.loadString('assets/abi.json');
  }

  Future<void> startWaitProcess(String contractAddress) async {
    var check = await checkAgendar(contractAddress);
    print(check);
    if (check.toString() == '[1]') {
      await Future.delayed(const Duration(milliseconds: 500));
      await Navigator.of(context).pushNamedAndRemoveUntil(
          TermVotePage.routeName, (Route<dynamic> route) => false,
          arguments: {
            'color': widget.setting['color'],
            'meetingId': widget.setting['meetingId'],
            'indexOrder': widget.setting['indexOrder']
          });
    } else if (check.toString() == '[2]') {
      await Future.delayed(const Duration(milliseconds: 500));
      if (widget.setting['indexOrder'] == (agendarLength - 1)) {
        await Navigator.of(context).pushNamedAndRemoveUntil(
          TermConcludePage.routeName,
          (Route<dynamic> route) => false,
          arguments: {
            'color': widget.setting['color'],
            'meetingId': widget.setting['meetingId'],
          },
        );
      } else {
        var index = widget.setting['indexOrder'] + 1;
        await Navigator.of(context).pushNamedAndRemoveUntil(
          TermWaitPage.routeName,
          (Route<dynamic> route) => false,
          arguments: {
            'color': widget.setting['color'],
            'indexOrder': index,
            'meetingId': widget.setting['meetingId']
          },
        );
      }
    } else if (check.toString() == '[0]') {
      connectionEvent(contractAddress);
      reConnectWs(contractAddress);
    }
  }

  Future<dynamic> finalResult(String contractAddress) async {
    try {
      final EthereumAddress contractAddr =
          EthereumAddress.fromHex(contractAddress);
      final contract = DeployedContract(
          ContractAbi.fromJson(abiCode, 'Ballot'), contractAddr);
      final finalResults = contract.function('finalResults');
      final totalWeightVoter = contract.function('totalWeightVoter');
      final totalWeight = contract.function('totalWeight');
      final totalSignWeight = contract.function('totalSignWeight');
      final finalResultsDataAgree = await _client.call(
          contract: contract, function: finalResults, params: [BigInt.from(1)]);
      final finalResultsDataDisAgree = await _client.call(
          contract: contract, function: finalResults, params: [BigInt.from(2)]);
      final finalResultsDataNoVote = await _client.call(
          contract: contract, function: finalResults, params: [BigInt.from(0)]);
      final totalWeightVoterData = await _client
          .call(contract: contract, function: totalWeightVoter, params: []);
      final totalWeightData = await _client
          .call(contract: contract, function: totalWeight, params: []);
      final totalSignWeightData = await _client
          .call(contract: contract, function: totalSignWeight, params: []);
      final noActionAll = totalWeightVoterData[0] - totalWeightData[0];
      final abadon = totalWeightVoterData[0] - totalSignWeightData[0];
      final noAction = noActionAll - abadon;
      print(noActionAll);
      print(abadon);
      print(noAction);

      var obj = {
        "agree": finalResultsDataAgree[0] + noAction,
        "disAgree": finalResultsDataDisAgree[0],
        "noVote": finalResultsDataNoVote[0],
      };
      return obj;
    } catch (err) {
      print(err);
      var obj = {
        "agree": 0,
        "disAgree": 0,
        "noVote": 0,
      };
      return obj;
    }
  }

  Future<void> startReport(String contractAddress) async {
    var obj = await finalResult(contractAddress);
    print(obj);
    try {
      Provider.of<Meetings>(context, listen: false).setAgendarReport(
        widget.setting['meetingId'],
        contractAddress,
        obj['agree'].toInt(),
        obj['disAgree'].toInt(),
        obj['noVote'].toInt(),
      );
    } catch (err) {}
  }

  Future<void> getStatePrevAgenda(String contractAddress) async {
    var address = Provider.of<Auth>(context, listen: false).address;
    final EthereumAddress contractAddr =
        EthereumAddress.fromHex(contractAddress);
    final EthereumAddress voterAddress = EthereumAddress.fromHex(address);
    final contract =
        DeployedContract(ContractAbi.fromJson(abiCode, 'Ballot'), contractAddr);
    final voterRegister = contract.function('voterRegister');
    final voterRegisterData = await _client.call(
        contract: contract, function: voterRegister, params: [voterAddress]);
    var voteResult = voterRegisterData[3].toInt();
    var signed = voterRegisterData[4];
    setState(() {
      if (voteResult == 0) {
        _prevVote = 'No Vote';
        _prevColor = Color(0xfffb8c00);
      } else if (voteResult == 1) {
        _prevVote = 'Agree';
        _prevColor = Colors.green;
      } else if (voteResult == 2) {
        _prevVote = 'Disagree';
        _prevColor = Colors.red;
      } else {
        if (signed) {
          _prevVote = 'No Action';
          _prevColor = Color(0xff795548);
        } else {
          _prevVote = 'Abandon';
          _prevColor = Colors.grey;
        }
      }
    });
  }

  Future<bool> _onPopScope() async {
    return false;
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void initState() {
    super.initState();
    checkConnectivity();
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> checkConnectivity() async {
    ConnectivityResult result;
    try {
      result = await _connectivity.checkConnectivity();
    } on PlatformException catch (e) {
      print(e.toString());
    }
    if (!mounted) {
      return Future.value(null);
    }
    return _updateConnectionStatus(result);
  }

  @override
  void dispose() {
    print('before dispose wait ${widget.setting["indexOrder"]}');
    try {
      print(_timerWait.isActive);
      _timerWait.cancel();
    } catch (err) {
      print('timer never been wait ${widget.setting["indexOrder"]}');
    }
    try {
      _voteStartSubscription.cancel();
    } catch (err) {}
    try {
      _client.dispose();
    } catch (err) {}
    WidgetsBinding.instance.removeObserver(this);
    try {
      _connectivitySubscription.cancel();
    } catch (err) {
      print('sub connectiviry never been wait ${widget.setting["indexOrder"]}');
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.paused:
        print("paused");
        await _onPause();
        break;
      case AppLifecycleState.inactive:
        print('inactive');
        await _onPause();
        break;
      case AppLifecycleState.resumed:
        print('resumed');
        await startWaitProcess(nowContract);
        break;
      default:
    }
  }

  Future<void> _onPause() async {
    try {
      _timerWait.cancel();
    } catch (err) {}
    try {
      await _voteStartSubscription.cancel();
    } catch (err) {}
  }

  Future<Null> _refresh() async {
    try {
      if (prevContract != '') {
        await startReport(prevContract);
      }
    } catch (err) {}
    try {
      print('refresh...');
      var check = await checkAgendar(nowContract);
      print(check);
      if (check.toString() == '[1]') {
        _isEnd = true;
        await Navigator.of(context).pushNamedAndRemoveUntil(
            TermVotePage.routeName, (Route<dynamic> route) => false,
            arguments: {
              'color': widget.setting['color'],
              'meetingId': widget.setting['meetingId'],
              'indexOrder': widget.setting['indexOrder']
            });
      } else if (check.toString() == '[2]') {
        _isEnd = true;
        if (widget.setting['indexOrder'] == (agendarLength - 1)) {
          await Navigator.of(context).pushNamedAndRemoveUntil(
            TermConcludePage.routeName,
            (Route<dynamic> route) => false,
            arguments: {
              'color': widget.setting['color'],
              'meetingId': widget.setting['meetingId'],
            },
          );
        } else {
          var index = widget.setting['indexOrder'] + 1;
          await Navigator.of(context).pushNamedAndRemoveUntil(
            TermWaitPage.routeName,
            (Route<dynamic> route) => false,
            arguments: {
              'color': widget.setting['color'],
              'indexOrder': index,
              'meetingId': widget.setting['meetingId']
            },
          );
        }
      }
    } catch (err) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    double statusBarHeight = MediaQuery.of(context).padding.top;
    final args = widget.setting;
    var data = Provider.of<Meetings>(context, listen: true)
        .meetingById(args['meetingId']);
    var agendars = data.agendars;
    var length = agendars.length;
    print("build termWait context");
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      if (_isInit) {
        if (agendars[args['indexOrder']].contractAddress == null) {
          return await showDialog(
              context: context,
              builder: (_) => DialogAlert(
                    type: 'error',
                    header: 'Failed !',
                    subtitle: 'You can\'t rights to vote.',
                    done: () async {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushNamedAndRemoveUntil(
                          HomePage.routeName, (route) => false);
                    },
                  ));
        }
        var file = await loadAbi();
        abiCode = file.toString();
        agendarLength = length;
        _isInit = false;
        nowContract = agendars[args['indexOrder']].contractAddress;
        startWaitProcess(agendars[args['indexOrder']].contractAddress);
        if (args['indexOrder'] > 0) {
          prevContract = agendars[args['indexOrder'] - 1].contractAddress;
          startReport(agendars[args['indexOrder'] - 1].contractAddress);
          getStatePrevAgenda(agendars[args['indexOrder'] - 1].contractAddress);
        }
      }
    });
    return WillPopScope(
      onWillPop: _onPopScope,
      child: length > 0
          ? Scaffold(
              body: RefreshIndicator(
                displacement: 100,
                color: Colors.redAccent,
                onRefresh: _refresh,
                child: SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: Container(
                    height: size.height,
                    child: Column(
                      children: <Widget>[
                        Container(
                          width: size.width,
                          padding: EdgeInsets.only(top: statusBarHeight),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.only(
                                bottomLeft: const Radius.circular(24.0),
                                bottomRight: const Radius.circular(24.0)),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: args['color'],
                            ),
                          ),
                          child: Stack(
                            children: <Widget>[
                              Container(
                                padding: const EdgeInsets.all(15),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          left: 30.0, right: 10),
                                      child: Text(
                                        data.company ?? '',
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 12),
                                      ),
                                    ),
                                    SizedBox(
                                      height: 20,
                                    ),
                                    Container(
                                      child: Center(
                                        child: Container(
                                          child: Text(
                                            data.title,
                                            style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.white,
                                                height: 1.2),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      height: 10,
                                    ),
                                    Divider(
                                      indent: 20,
                                      endIndent: 20,
                                      thickness: 1,
                                      color: Colors.white.withOpacity(0.3),
                                    ),
                                    SizedBox(
                                      height: 12,
                                    ),
                                    Text(
                                      data.address ?? '',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 12),
                                    ),
                                    SizedBox(
                                      height: 12,
                                    ),
                                    Row(
                                      children: <Widget>[
                                        Text(
                                          data.scheduleTime ?? '' + ' น.',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12),
                                        ),
                                        Text(
                                          '    |    ',
                                          style: TextStyle(
                                            color:
                                                Colors.white.withOpacity(0.3),
                                            fontSize: 20,
                                          ),
                                        ),
                                        Text(
                                          data.getDateTh ?? '',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (data.logoUrl != '')
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
                                        imageUrl: data.logoUrl,
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
                                    showDialog(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                              title:
                                                  const Text('Please confirm'),
                                              content: const Text(
                                                  'Do you want to leave this meeting ?'),
                                              actions: <Widget>[
                                                FlatButton(
                                                  child: Text(
                                                    "OK",
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  onPressed: () async {
                                                    _isEnd = true;
                                                    await Navigator.of(context)
                                                        .pushNamedAndRemoveUntil(
                                                            HomePage.routeName,
                                                            (Route<dynamic>
                                                                    route) =>
                                                                false);
                                                  },
                                                ),
                                                FlatButton(
                                                  child: Text(
                                                    "Cancel",
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                )
                                              ],
                                            ));
                                  },
                                  child: Container(
                                    padding: EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white),
                                    child: Icon(
                                      Icons.close,
                                      color: Colors.black.withOpacity(0.3),
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.only(
                                top: 20, bottom: 20, left: 10, right: 10),
                            constraints: BoxConstraints(maxWidth: 400),
                            child: Center(
                              child: ListView(
                                shrinkWrap: true,
                                padding: const EdgeInsets.all(0),
                                children: <Widget>[
                                  if (args['indexOrder'] == 0 ||
                                      !agendars[args['indexOrder'] - 1].canVote)
                                    SizedBox(
                                      height: 30,
                                    ),
                                  Image.asset(
                                    'assets/Image/hourglass.png',
                                    height: 120,
                                  ),
                                  SizedBox(
                                    height: 20,
                                  ),
                                  Text(
                                    'Waiting for the agenda ' +
                                        agendars[args['indexOrder']]
                                            .order
                                            .toString(),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  SizedBox(
                                    height: 20,
                                  ),
                                  if (args['indexOrder'] > 0 &&
                                      agendars[args['indexOrder'] - 1].canVote)
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: <Widget>[
                                        Card(
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                                vertical: 10, horizontal: 15),
                                            child: Column(
                                              children: <Widget>[
                                                Text(
                                                  'Votes of agenda ' +
                                                      agendars[args[
                                                                  'indexOrder'] -
                                                              1]
                                                          .order
                                                          .toString(),
                                                  style: TextStyle(
                                                      fontSize: 17,
                                                      fontWeight:
                                                          FontWeight.w800),
                                                ),
                                                SizedBox(
                                                  height: 10,
                                                ),
                                                Column(
                                                  children: <Widget>[
                                                    Row(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: <Widget>[
                                                        Text(
                                                          'Agree (เห็นด้วย) ',
                                                          style: TextStyle(
                                                            fontSize: 15,
                                                            fontWeight:
                                                                FontWeight.w800,
                                                            color: Colors.green,
                                                          ),
                                                        ),
                                                        Flexible(
                                                          child: Container(
                                                            padding:
                                                                const EdgeInsets
                                                                        .only(
                                                                    left: 10),
                                                            child: Text(
                                                              agendars[args['indexOrder'] -
                                                                              1]
                                                                          .agree ==
                                                                      null
                                                                  ? '0'
                                                                  : oCcy
                                                                      .format(agendars[args['indexOrder'] -
                                                                              1]
                                                                          .agree)
                                                                      .toString(),
                                                              textAlign:
                                                                  TextAlign
                                                                      .right,
                                                              style: TextStyle(
                                                                  fontSize: 15,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600),
                                                            ),
                                                          ),
                                                        )
                                                      ],
                                                    ),
                                                    Row(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: <Widget>[
                                                        Text(
                                                          'Disagree (ไม่เห็นด้วย) ',
                                                          style: TextStyle(
                                                            fontSize: 15,
                                                            fontWeight:
                                                                FontWeight.w800,
                                                            color: Colors.red,
                                                          ),
                                                        ),
                                                        Flexible(
                                                          child: Container(
                                                            padding:
                                                                const EdgeInsets
                                                                        .only(
                                                                    left: 10),
                                                            child: Text(
                                                              agendars[args['indexOrder'] -
                                                                              1]
                                                                          .agree ==
                                                                      null
                                                                  ? '0'
                                                                  : oCcy
                                                                      .format(agendars[args['indexOrder'] -
                                                                              1]
                                                                          .disAgree)
                                                                      .toString(),
                                                              textAlign:
                                                                  TextAlign
                                                                      .right,
                                                              style: TextStyle(
                                                                  fontSize: 15,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600),
                                                            ),
                                                          ),
                                                        )
                                                      ],
                                                    ),
                                                    Row(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: <Widget>[
                                                        Text(
                                                          'No Vote (งดออกเสียง) ',
                                                          style: TextStyle(
                                                            fontSize: 15,
                                                            fontWeight:
                                                                FontWeight.w800,
                                                            color: Color(
                                                                0xfffb8c00),
                                                          ),
                                                        ),
                                                        Flexible(
                                                          child: Container(
                                                            padding:
                                                                const EdgeInsets
                                                                        .only(
                                                                    left: 10),
                                                            child: Text(
                                                              agendars[args['indexOrder'] -
                                                                              1]
                                                                          .agree ==
                                                                      null
                                                                  ? '0'
                                                                  : oCcy
                                                                      .format(agendars[args['indexOrder'] -
                                                                              1]
                                                                          .noVote)
                                                                      .toString(),
                                                              textAlign:
                                                                  TextAlign
                                                                      .right,
                                                              style: TextStyle(
                                                                  fontSize: 15,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600),
                                                            ),
                                                          ),
                                                        )
                                                      ],
                                                    ),
                                                  ],
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          height: 15,
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: <Widget>[
                                            Text(
                                              'Action of agenda ' +
                                                  agendars[args['indexOrder'] -
                                                          1]
                                                      .order
                                                      .toString() +
                                                  ' : ',
                                              style: TextStyle(
                                                  fontSize: 16,
                                                  color: Color(0xffa3a3a3)),
                                            ),
                                            Text(
                                              _prevVote,
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: _prevColor,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            )
          : Text(''),
    );
  }

  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    if (result == ConnectivityResult.wifi ||
        result == ConnectivityResult.mobile) {
    } else if (result == ConnectivityResult.none) {
      showDialog(
        context: context,
        builder: (_) => DialogAlert(
          header: 'Connection lost !',
          subtitle: 'Please connect to the internet and try again.',
          type: 'error',
          done: () {
            Navigator.of(context)
                .pushNamedAndRemoveUntil(HomePage.routeName, (route) => false);
          },
        ),
      );
    }
  }
}
