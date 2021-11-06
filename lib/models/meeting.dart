import 'package:intl/intl.dart';

import './agendar.dart';

enum RightVote { CanVote, NotCanVote }

class Meeting {
  final String objectId;
  final String meetingId;
  final String voterAddress;
  final String hashId;
  dynamic proxyAddress;
  dynamic proxyHashId;
  bool voted;
  List<Agendar> agendars;
  final String title;
  final String address;
  final String company;
  final String detail;
  final String scheduleDate;
  final String scheduleTime;
  final String logoUrl;
  final String expireDate;
  String meetingVoterId;
  bool smartContractAdded;
  int share;

  Meeting({
    this.objectId,
    this.meetingId,
    this.voterAddress,
    this.hashId,
    this.proxyAddress,
    this.proxyHashId,
    this.voted,
    this.agendars,
    this.title,
    this.address,
    this.company,
    this.detail,
    this.scheduleDate,
    this.scheduleTime,
    this.meetingVoterId,
    this.smartContractAdded,
    this.logoUrl,
    this.share,
    this.expireDate,
  });

  //setters
  //set name(String name) => _name = name; แบบย่อ
  String get getDateTh {
    try {
      DateTime dt = DateTime.parse(this.scheduleDate);
      List<String> allMonth = [
        "January",
        "February",
        "March",
        "April",
        "May",
        "June",
        "July",
        "August",
        "September",
        "October",
        "November",
        "December",
      ];
      String year = dt.year.toString();
      String month = (allMonth[dt.month - 1]);
      String day = dt.day.toString();
      return day + " " + month + " " + year;
    } catch (err) {
      return '';
    }
  }

  bool get rightVote {
    if (this.agendars.length == 0 ||
        this.proxyAddress != null ||
        this.voted == true) {
      return false;
    } else {
      return true;
    }
  }

  get isExpired {
    DateTime now = DateTime.now();
    var formatter = new DateFormat('yyyy-MM-dd');
    String formattedDate = formatter.format(now);
    DateTime dt = DateTime.parse(this.scheduleDate);
    DateTime endDate = dt.subtract(Duration(days: 2));
    DateTime nowDateOnly = DateTime.parse(formattedDate);
    var difference = nowDateOnly.isAfter(endDate);
    return difference;
  }
}
