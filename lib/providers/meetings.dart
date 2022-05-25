import 'package:agm/utils/http_ssl_check.dart';

import '../models/agendar.dart';
import '../models/meeting.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as Http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart' as crypto;
import '../utils/cryptojs_aes_encryption_helper.dart';

class Meetings with ChangeNotifier {
  List<Meeting> meetings = [];
  List<String> agendarsInStore = [];
  List<String> meetingsInStore = [];
  List<dynamic> agendarsX = [];
  //getters

  Meeting meetingById(String meetingId) {
    return meetings.firstWhere((q) => q.meetingId == meetingId,
        orElse: () => null);
  }

  //mutations
  void addMeetingDetail(String meetingId, dynamic meetingDetail) {
    final meetingIndex = meetings.indexWhere((q) => q.meetingId == meetingId);
    if (meetingIndex >= 0) {
      meetings[meetingIndex].voted = meetingDetail['voted'];
      meetings[meetingIndex].proxyAddress = meetingDetail['proxyAddress'];
      meetings[meetingIndex].meetingVoterId = meetingDetail['objectId'];
      meetings[meetingIndex].smartContractAdded =
          meetingDetail['smart_contract_added'];
      meetings[meetingIndex].share = meetingDetail['share'];
      notifyListeners();
    } else {
      print('error update meeting');
    }
  }

  void addAgendarList(String meetingId, List<Agendar> agendarList) {
    final meetingIndex = meetings.indexWhere((q) => q.meetingId == meetingId);
    if (meetingIndex >= 0) {
      meetings[meetingIndex].agendars = agendarList;
      notifyListeners();
    } else {
      print('error update meeting');
    }
  }

  Future<void> setAgendarVote(
      String meetingId, String contractAddress, int vote) async {
    Meeting mt = meetings.firstWhere((q) => q.meetingId == meetingId,
        orElse: () => null);
    Agendar ag = mt.agendars.firstWhere(
        (q) => q.contractAddress == contractAddress,
        orElse: () => null);
    ag.setVote(vote);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var oldValue = prefs.getStringList('AgendarStateVote');
    dynamic obj = {'agObjectId': ag.objectId, 'vote': vote};
    if (oldValue != null) {
      for (var i = 0; i < oldValue.length; i++) {
        if (json.decode(oldValue[i])['agObjectId'] == obj['agObjectId']) {
          oldValue.removeAt(i);
        }
      }
      oldValue.add(jsonEncode(obj));
    } else {
      oldValue = [jsonEncode(obj)];
    }
    await prefs.setStringList('AgendarStateVote', oldValue);
  }

  void setAgendarReport(String meetingId, String contractAddress, int agree,
      int disAgree, int noVote) {
    try {
      Meeting mt = meetings.firstWhere((q) => q.meetingId == meetingId,
          orElse: () => null);
      Agendar ag = mt.agendars.firstWhere(
          (q) => q.contractAddress == contractAddress,
          orElse: () => null);
      ag.setResult(agree, disAgree, noVote);
      notifyListeners();
    } catch (err) {}
  }

  void setMeeting(data) {
    this.meetings = data;
    notifyListeners();
  }

  void updateAgendarX(data) {
    final argIndex = this
        .agendarsX
        .indexWhere((q) => q['contractAddress'] == data['contractAddress']);
    if (argIndex >= 0) {
      var addition = {
        "agree": data['agree'],
        "disAgree": data['disAgree'],
      };
      this.agendarsX[argIndex].addAll(addition);
      notifyListeners();
    } else {
      print('error update agendars');
    }
  }

  void setAgendarsX(data) {
    agendarsX.add(data);
    notifyListeners();
  }

  void setAgendarsInStore(data) {
    this.agendarsInStore = data;
    notifyListeners();
  }

  // actions
  Future<String> getSessionToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String sessionToken = prefs.getString('sessionToken');
    var decrypted = decryptAESCryptoJS(sessionToken, "JventursP@ssW0rd");
    return decrypted;
  }

  generateMd5(String data) {
    var content = Utf8Encoder().convert(data);
    var md5 = crypto.md5;
    var digest = md5.convert(content);
    return hex.encode(digest.bytes);
  }

  Future<void> getMeetings() async {
    try {
      var sessionToken = await getSessionToken();
      var url = 'https://agm-api.jfin.network/get_meeting';
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
      var response = await Http.post(Uri.parse(url), headers: headers);
      var body = json.decode(response.body);
      List<Meeting> meetingsList = [];
      List list = body['results'];
      for (var i = 0; i < list.length; i++) {
        var url = '';
        if (list[i]['logo'] != null) {
          if (list[i]['logo']['url'] != null) {
            url = list[i]['logo']['url'];
          }
        }
        Meeting mt = Meeting(
          objectId: list[i]['objectId'],
          meetingId: list[i]['objectId'],
          voterAddress: list[i]['voterAddress'],
          hashId: list[i]['hashId'],
          proxyAddress: list[i]['proxyAddress'],
          proxyHashId: list[i]['proxyHashId'],
          voted: list[i]['voted'],
          agendars: [],
          title: list[i]['title'],
          company: list[i]['company'],
          address: list[i]['address'],
          detail: list[i]['detail'],
          scheduleDate: list[i]['scheduleDate'],
          scheduleTime: list[i]['scheduleTime'],
          logoUrl: url,
          expireDate: list[i]['expires'],
        );
        meetingsList.add(mt);
      }
      setMeeting(meetingsList);
    } catch (err) {
      print(err);
      print('error get meetings');
    }
  }

  Future<String> loadAbi() async {
    return await rootBundle.loadString('assets/abi.json');
  }
}
