import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:agm/utils/http_ssl_check.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as Http;
import 'package:web3dart/web3dart.dart';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart' as crypto;
import '../utils/cryptojs_aes_encryption_helper.dart';

enum LoginStatus { Unlogin, Logedin }
enum Member { Gold, Silver, Bronze }

Future<Wallet> getWalletFunction(String content) async {
  Wallet wallet = Wallet.fromJson(content, "AGMp@ssw0rd");
  return wallet;
}

class Auth with ChangeNotifier {
  //State
  Map<String, dynamic> ekycData = {};
  Map<String, dynamic> userData = {};
  String address = '';
  String idCard = '';
  LoginStatus _status = LoginStatus.Unlogin;
  Member _member = Member.Bronze;

  //Getters
  LoginStatus get loginStatus => _status;
  Member get member => _member;
  String get hashId {
    var content = Utf8Encoder().convert(this.idCard);
    var md5 = crypto.md5;
    var digest = md5.convert(content);
    return hex.encode(digest.bytes);
  }

  //Mutations
  void setUserData(data) {
    this.userData = data;
  }

  void setEkycData(data) {
    print(data);
    print(data['IAL']);
    if (data['IAL'] == 2.3 || data['IAL'] == 1.2) {
      this._member = Member.Gold;
    } else {
      this._member = Member.Silver;
    }
    this.idCard = data['id'];
    this.ekycData = data;
    notifyListeners();
  }

  void setWallet(data) {
    this.address = data;
    notifyListeners();
  }

  void setLogedIn() {
    this._status = LoginStatus.Logedin;
  }

  Future<void> setLogout() async {
    this._status = LoginStatus.Unlogin;
    this._member = Member.Bronze;
    this.ekycData = {};
    this.userData = {};
    this.address = '';
    this.idCard = '';
  }

  //Actions
  Future<String> getSessionToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String sessionToken = prefs.getString('sessionToken');
    var decrypted = decryptAESCryptoJS(sessionToken, "JventursP@ssW0rd");
    return decrypted;
  }

  Future<String> getIdCard() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String id = prefs.getString('idCard');
    return id;
  }

  Future<String> getWalletAddress() async {
    print('getWallet');
    try {
      final Directory directory = await getApplicationDocumentsDirectory();
      String content =
          new File('${directory.path}/wallet.json').readAsStringSync();
      Wallet wallet = await compute(getWalletFunction, content);
      Credentials unlocked = wallet.privateKey;
      var address = await unlocked.extractAddress();
      setWallet(address.hex);
      return address.hex;
    } catch (err) {
      print(err);
      print('error get wallet');
      return '';
    }
  }

  Future<Credentials> getCredentials() async {
    final Directory directory = await getApplicationDocumentsDirectory();
    String content =
        new File('${directory.path}/wallet.json').readAsStringSync();
    Wallet wallet = await compute(getWalletFunction, content);
    Credentials unlocked = wallet.privateKey;
    return unlocked;
  }

  Future<void> getEkycData() async {
    var token = await getSessionToken();
    print(token);
    try {
      var url = "https://api.jfin.network/v2/ekyc_user";
      bool check = await HttpSslCheck(url: url).check();
      print(check);
      if (!check) {
        throw 500;
      }
      var headers = {
        'content-type': 'application/json',
        'X-API-KEY': 'P35QHlLqkVMVTqraaxeHQPDWfe1ysa4f',
        'x-parse-session-token': token
      };
      var response = await Http.get(url, headers: headers);
      var body = await json.decode(response.body);
      setEkycData(body);
    } catch (err) {
      print('error eKYC');
    }
  }
}
