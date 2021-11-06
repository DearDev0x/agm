import 'package:flutter/material.dart';

class StepLobbyList extends StatelessWidget {
  final list;
  final type;
  StepLobbyList({
    @required this.list,
    @required this.type
  });
  @override
  Widget build(BuildContext context) {

    Widget indicator(int vote, bool canVote) {
      if (vote == 1) {
        return Container(
          height: 25,
          width: 25,
          decoration: BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
          ),
          child: Center(
              child: Icon(
            Icons.done,
            color: Colors.white,
            size: 21,
          )),
        );
      } else if (vote == 2) {
        return Container(
          height: 25,
          width: 25,
          decoration: BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.clear,
            color: Colors.white,
            size: 21,
          ),
        );
      } else {
        Color elseColor;
        if(vote == 0) {
          elseColor = Color(0xfffb8c00);
        } else if(vote == 4) {
          elseColor = Color(0xff795548);
        } else {
          if(canVote) {
            elseColor = Color(0xffDDE1FF);
          } else {
            if(type == 'conclude') {
              elseColor = Color(0xff795548);
            } else {
              elseColor = Color(0xffDDE1FF);
            }
          }
        }
        return Container(
          height: 25,
          width: 25,
          decoration:
              BoxDecoration(color: elseColor, shape: BoxShape.circle),
        );
      }
    }

    // Widget result(int agree, int disAgree) {
    //   if (agree == null && disAgree == null) {
    //     return Text('');
    //   } else {
    //     return Padding(
    //       padding: const EdgeInsets.only(
    //         top: 5,
    //         bottom: 5,
    //         left: 5,
    //         right: 5,
    //       ),
    //       child: Column(
    //         children: <Widget>[
    //           Row(
    //             mainAxisAlignment: MainAxisAlignment.spaceAround,
    //             children: <Widget>[
    //               Text(
    //                 'agree ' + agree.toString(),
    //                 style: TextStyle(
    //                   fontSize: 15,
    //                   fontWeight: FontWeight.w600,
    //                   color: Colors.green,
    //                 ),
    //               ),
    //               Text(
    //                 'disagree ' + disAgree.toString(),
    //                 style: TextStyle(
    //                   fontSize: 15,
    //                   fontWeight: FontWeight.w600,
    //                   color: Colors.red,
    //                 ),
    //               )
    //             ],
    //           ),
    //         ],
    //       ),
    //     );
    //   }
    // }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(
        right: 10,
        left: 10,
        top: 0,
        bottom: 0,
      ),
      child: Column(
        children: [
          for (var item in list)
            IntrinsicHeight(
              child: Container(
                constraints: BoxConstraints(minHeight: 50),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: 30,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          indicator(item.vote, item.canVote),
                          if ((item.order) != list[list.length - 1].order)
                            Expanded(
                              flex: 10,
                              child: Container(
                                width: 2.5,
                                decoration: new BoxDecoration(
                                  color: Color(0xffDDE1FF),
                                  shape: BoxShape.rectangle,
                                ),
                                child: Text(""),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      width: 80,
                      margin: const EdgeInsets.only(left: 5,top: 3),
                      child: Text(
                        ('Agenda ' + item.order.toString()),
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            height: 1.5),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(top: 3),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              item.title ?? '',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  height: 1.5),
                            ),
                            //result(item.agree,item.disAgree),
                          ],
                        ),
                      ),
                      flex: 9,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
