import 'package:agm/views/lobby_otp.dart';
import 'package:agm/views/lobby_rp.dart';

import './views/OTP/otpVerify.dart';
import './views/OTP/phoneVerify.dart';
import './views/OTP/termService.dart';
import './views/Password/newPassword.dart';
import './views/Password/oldPassword.dart';
import './views/login.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import './views/loadingPage.dart';
import './views/home.dart';
import './views/lobby.dart';
import './views/termWait.dart';
import './views/termVote.dart';
import './views/termConclude.dart';
import './views/onloadProxyvote.dart';
import './views/OTP/pinAccess.dart';
import './views/OTP/pinVerify.dart';
import './views/qrcode.dart';
import './views/scanProxyVoter.dart';

class Routing {
  // ignore: missing_return
  Route<dynamic> onRoute(RouteSettings settings) {
    switch (settings.name) {
      case LoadingPage.routeName:
        return CupertinoPageRoute(
          builder: (_) => LoadingPage(),
          settings: settings,
        );
      case LoginPage.routeName:
        return CupertinoPageRoute(
          builder: (_) => LoginPage(),
          settings: settings,
        );
      case PhoneVerifyPage.routeName:
        return CupertinoPageRoute(
          builder: (_) => PhoneVerifyPage(),
          settings: settings,
        );
      case TermServicePage.routeName:
        return CupertinoPageRoute(
          builder: (_) => TermServicePage(settings.arguments),
          settings: settings,
        );
      case OtpVerifyPage.routeName:
        return CupertinoPageRoute(
          builder: (_) => OtpVerifyPage(),
          settings: settings,
        );
      case PinAccessPage.routeName:
        return CupertinoPageRoute(
          builder: (_) => PinAccessPage(),
          settings: settings,
        );
      case PinVerifyPage.routeName:
        return CupertinoPageRoute(
          builder: (_) => PinVerifyPage(),
          settings: settings,
        );
      case HomePage.routeName:
        return CupertinoPageRoute(
          builder: (_) => HomePage(),
          settings: settings,
        );
      case LobbyPage.routeName:
        return MaterialPageRoute(
          builder: (_) => LobbyPage(settings.arguments),
          settings: settings,
        );
      case LobbyOtpPage.routeName:
        return CupertinoPageRoute(
          builder: (_) => LobbyOtpPage(settings.arguments),
          settings: settings,
        );
      case LobbyRpPage.routeName:
        return CupertinoPageRoute(
          builder: (_) => LobbyRpPage(settings.arguments),
          settings: settings,
        );
      case TermWaitPage.routeName:
        return CupertinoPageRoute(
          builder: (_) => TermWaitPage(settings.arguments),
          settings: settings,
        );
      case TermVotePage.routeName:
        return CupertinoPageRoute(
          builder: (_) => TermVotePage(settings.arguments),
          settings: settings,
        );
      case TermConcludePage.routeName:
        return CupertinoPageRoute(
          builder: (_) => TermConcludePage(settings.arguments),
          settings: settings,
        );
      case QrcodePage.routeName:
        return CupertinoPageRoute(
          builder: (_) => QrcodePage(),
          settings: settings,
        );
      case OnloadProxy.routeName:
        return CupertinoPageRoute(
          builder: (_) => OnloadProxy(settings.arguments),
          settings: settings,
        );
      case ScanProxyVoterPage.routeName:
        return CupertinoPageRoute(
          builder: (_) => ScanProxyVoterPage(settings.arguments),
          settings: settings,
        );
      case OldPasswordPage.routeName:
        return CupertinoPageRoute(
          builder: (_) => OldPasswordPage(),
          settings: settings,
        );
      case NewPasswordPage.routeName:
        return CupertinoPageRoute(
          builder: (_) => NewPasswordPage(),
          settings: settings,
        );
    }
  }
}
