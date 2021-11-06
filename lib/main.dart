import 'package:agm/widgets/loading.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';
import 'dart:io' show exit;

import './views/loadingPage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import './route.dart';
import 'providers/auth.dart';
import 'providers/meetings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isModified;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    bool jailbroken;
    bool developerMode;

    try {
      jailbroken = await FlutterJailbreakDetection.jailbroken;
      developerMode = await FlutterJailbreakDetection.developerMode;
    } on PlatformException {
      jailbroken = true;
      developerMode = true;
    }
    if (!mounted) return;

    setState(() {
      if (jailbroken || developerMode) {
        setState(() {
          _isModified = false;
        });
      } else {
        setState(() {
          _isModified = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    var mainApp = MultiProvider(
      providers: [
        ChangeNotifierProvider.value(
          value: Auth(),
        ),
        ChangeNotifierProvider.value(
          value: Meetings(),
        ),
      ],
      child: MaterialApp(
        builder: (context, child) {
          final mediaQueryData = MediaQuery.of(context);
          return MediaQuery(
            data: mediaQueryData.copyWith(textScaleFactor: 1.0),
            child: child,
          );
        },
        title: 'AGM Voting',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
            fontFamily: 'Sukhumvit',
            cupertinoOverrideTheme:
                CupertinoThemeData(brightness: Brightness.dark)),
        home: LoadingPage(),
        onGenerateRoute: Routing().onRoute,
      ),
    );

    Widget whenBroken = MaterialApp(
        builder: (context, child) {
          final mediaQueryData = MediaQuery.of(context);
          return MediaQuery(
            data: mediaQueryData.copyWith(textScaleFactor: 1.0),
            child: child,
          );
        },
        title: 'AGM Voting',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
            fontFamily: 'Sukhumvit',
            cupertinoOverrideTheme:
                CupertinoThemeData(brightness: Brightness.dark)),
        home: _isModified == null
            ? Scaffold(
                body: LoadingWidget(),
              )
            : JailPage());

    return _isModified == null || _isModified ? whenBroken : mainApp;
  }
}

class JailPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    double statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: SingleChildScrollView(
        child: Stack(
          children: <Widget>[
            Container(
              padding:
                  EdgeInsets.only(left: 30, right: 30, top: statusBarHeight),
              height: size.height,
              width: size.width,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/Image/bg.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  Container(
                      constraints: BoxConstraints(maxWidth: 450),
                      width: size.width * 0.6,
                      child: Image.asset('assets/Image/logo-02.png')),
                  Container(
                    child: Column(
                      children: <Widget>[
                        Text(
                          "This application isn't suppot modified Device",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.white),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Text(
                          '(Jailbreak/Root) for safety of your information',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              wordSpacing: 2,
                              letterSpacing: 2),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    constraints: BoxConstraints(maxWidth: 320),
                    width: size.width * 0.8,
                    child: Column(
                      children: <Widget>[
                        SizedBox(
                          height: 20,
                        ),
                        Container(
                          height: 48.0,
                          decoration: BoxDecoration(
                            color: Color(0xffFFFFFFF),
                            borderRadius: BorderRadius.circular(50.0),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                exit(0);
                              },
                              child: Center(
                                child: Center(
                                  child: const Text(
                                    'Close App',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
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
            Positioned(
                bottom: 5,
                right: 10,
                child: Text('V 1.1.5', style: TextStyle(color: Colors.grey))),
          ],
        ),
      ),
    );
  }
}
