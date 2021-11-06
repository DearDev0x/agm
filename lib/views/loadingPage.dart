import '../views/OTP/phoneVerify.dart';
import '../views/login.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

import '../widgets/loading.dart';

class LoadingPage extends StatefulWidget {
  static const routeName = '';
  LoadingPage({Key key, this.uri}) : super(key: key);
  final Uri uri;
  @override
  _LoadingPageState createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  Future<String> getSessionToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String sessionToken = prefs.getString('sessionToken');
    return sessionToken;
  }

  Future<String> getSavedOTP() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String savedOTP = prefs.getString('savedOTP');
    return savedOTP;
  }

  bool _loadfirstPage = false;

  @override
  Widget build(BuildContext context) {
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      if (_loadfirstPage == false) {
        setState(() {
          _loadfirstPage = true;
        });
        String token = await getSessionToken();
        String savedOTP = await getSavedOTP();
        if (token == null || savedOTP == null) {
          await Navigator.of(context).pushNamedAndRemoveUntil(
              PhoneVerifyPage.routeName, (Route<dynamic> route) => false);
        } else {
          await Navigator.of(context).pushNamedAndRemoveUntil(
              LoginPage.routeName, (Route<dynamic> route) => false);
        }
      }
    });
    return Scaffold(
      body: Container(
        child: LoadingWidget(),
      ),
    );
  }
}
