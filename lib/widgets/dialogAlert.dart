import 'package:flutter/material.dart';

class DialogAlert extends StatelessWidget {
  final String header;
  final String subtitle;
  final String type;
  final Function done;
  DialogAlert({
    this.header,
    this.subtitle,
    @required this.type,
    @required this.done,
  });
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Container(
        height: header == '' ? 210 : 230,
        child: Column(
          mainAxisAlignment: header == '' ? MainAxisAlignment.spaceAround : MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            if(header != '')
            Text(
              header,
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19,),
            ),
            if (type == 'error')
              Icon(
                Icons.error,
                size: 90,
                color: Colors.red,
              ),
            if (type == 'success')
              Icon(
                Icons.check_circle,
                size: 90,
                color: Colors.green,
              ),
            Flexible(
              child: Text(
                subtitle ?? '',
                textAlign: TextAlign.center,
              ),
            )
          ],
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      actions: [
        FlatButton(
          child: Text(
            "OK",
            style: TextStyle(
              fontSize: 16,
            ),
          ),
          onPressed: () async {
            done();
          },
        )
      ],
    );
  }
}
