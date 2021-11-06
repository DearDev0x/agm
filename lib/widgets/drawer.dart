import 'dart:io';
import 'package:agm/utils/http_ssl_check.dart';
import 'package:http/http.dart' as Http;
import '../providers/auth.dart';
import '../views/Password/oldPassword.dart';
import 'package:provider/provider.dart';

import '../views/OTP/phoneVerify.dart';
import '../views/qrcode.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DrawerWidget extends StatelessWidget {
  Future<void> _logout(BuildContext context) async {
    String sessionToken =
        await Provider.of<Auth>(context, listen: false).getSessionToken();
    try {
      var url = "https://api.jfin.network/parse/logout";
      bool check = await HttpSslCheck(url: url).check();
      print(check);
      if (!check) {
        throw 500;
      }
      var headers = {
        "X-Parse-Application-Id": "928f24ed35d8876dee76d0a5460ef078",
        "X-Parse-Session-Token": sessionToken,
        "content-type": "application/json",
      };
      await Http.post(url, headers: headers);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      // await prefs.remove('AgendarStateVote');
      // await prefs.remove('idCard');
      // await prefs.remove('meetingsAAL');
      // await prefs.remove('savedOTP');
      // await prefs.remove('sessionToken');
      await prefs.clear();
    } catch (err) {}
    final Directory directory = await getApplicationDocumentsDirectory();
    final File file = File('${directory.path}/wallet.json');
    file.deleteSync(recursive: true);
    Navigator.of(context).pop();
    await Navigator.of(context).pushNamedAndRemoveUntil(
        PhoneVerifyPage.routeName, (Route<dynamic> route) => false);
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    double statusBarHeight = MediaQuery.of(context).padding.top;
    return Container(
      constraints: BoxConstraints(maxWidth: 350),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff8A0304), Color(0xffEC1C24)],
        ),
      ),
      height: size.height,
      width: size.width * 0.7,
      child: Stack(
        children: <Widget>[
          ListView(
            padding: EdgeInsets.only(left: 10),
            children: [
              SizedBox(
                height: statusBarHeight + 30,
              ),
              ListTile(
                title: Text(
                  "Menu",
                  style: TextStyle(color: Colors.white, fontSize: 28),
                ),
              ),
              SizedBox(
                height: 40,
              ),
              ListTile(
                title: Row(
                  children: <Widget>[
                    Image.asset(
                      'assets/Image/qr_menu.png',
                      height: 30,
                    ),
                    SizedBox(
                      width: 15,
                    ),
                    Text(
                      "QR Code",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushNamed(QrcodePage.routeName);
                },
              ),
              SizedBox(
                height: 20,
              ),
              ListTile(
                title: Row(
                  children: <Widget>[
                    Image.asset(
                      'assets/Image/pin_menu.png',
                      height: 30,
                    ),
                    SizedBox(
                      width: 15,
                    ),
                    Text(
                      "Edit pin code",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushNamed(OldPasswordPage.routeName);
                },
              ),
              SizedBox(
                height: 20,
              ),
              ListTile(
                title: Row(
                  children: <Widget>[
                    Image.asset(
                      'assets/Image/logout_menu.png',
                      height: 30,
                    ),
                    SizedBox(
                      width: 15,
                    ),
                    Text(
                      "Logout",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                onTap: () async {
                  await Provider.of<Auth>(context, listen: false).setLogout();
                  await _logout(context);
                },
              )
            ],
          ),
          Positioned(
              bottom: 5,
              right: 10,
              child:
                  const Text('V 1.1.5', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
  }
}
