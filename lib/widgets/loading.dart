import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class LoadingWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Material(
      type: MaterialType.transparency,
      child: Container(
        color: Color.fromRGBO(0, 0, 0, 0.0),
        height: size.height,
        width: size.width,
        child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: 300),
            height: 45,
            width: 45,
            decoration: BoxDecoration(
              //color: Colors.black.withOpacity(0.3),
              //borderRadius: BorderRadius.circular(12),
            ),
            child: CircularProgressIndicator(
              strokeWidth: 5,
              backgroundColor: Colors.black.withOpacity(0.1),
              valueColor: new AlwaysStoppedAnimation<Color>(Colors.red),
            ),
          ),
        ),
      ),
    );
  }
}
