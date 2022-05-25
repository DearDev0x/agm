import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:async';

import '../providers/auth.dart';
import '../widgets/layout.dart';
// import 'package:flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
// import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:convert/convert.dart';
// import 'package:image_picker_saver/image_picker_saver.dart';

class QrcodePage extends StatefulWidget {
  static const routeName = '/qrcode-read';
  @override
  _QrcodePageState createState() => _QrcodePageState();
}

class _QrcodePageState extends State<QrcodePage> {
  generateMd5(String data) {
    var content = Utf8Encoder().convert(data);
    var md5 = crypto.md5;
    var digest = md5.convert(content);
    return hex.encode(digest.bytes);
  }

  GlobalKey screen = new GlobalKey();

  Future<void> _captureAndSharePng(BuildContext context) async {
    // try {
    //   RenderRepaintBoundary boundary = screen.currentContext.findRenderObject();
    //   var image = await boundary.toImage(pixelRatio: 1);

    //   ByteData byteData =
    //       await image.toByteData(format: ui.ImageByteFormat.png);
    //   Uint8List pngBytes = byteData.buffer.asUint8List();

    //   await ImagePickerSaver.saveFile(fileData: pngBytes).then((onValue) {
    //     Flushbar(
    //       margin: EdgeInsets.all(8),
    //       borderRadius: 8,
    //       message: "Saved QR Code to your Device!",
    //       icon: Icon(
    //         Icons.info_outline,
    //         size: 28.0,
    //         color: Colors.blue[300],
    //       ),
    //       duration: Duration(seconds: 3),
    //     )..show(context);
    //   });
    // } catch (e) {
    //   print(e.toString());
    // }
  }

  @override
  Widget build(BuildContext context) {
    var address = Provider.of<Auth>(context).address;
    var idCard = Provider.of<Auth>(context).idCard;
    var hashId = generateMd5(idCard);
    Size size = MediaQuery.of(context).size;
    var params = {'voterAddress': address, 'hashId': hashId};
    var qrDataEncode = jsonEncode(params);
    double statusBarHeight = MediaQuery.of(context).padding.top;
    double layoutHeader = 90.00 + statusBarHeight + 40;
    Widget body = Container(
      width: size.width,
      height: size.height - layoutHeader,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
              decoration: BoxDecoration(
                border: Border.all(width: 2, color: Colors.red),
              ),
              child: RepaintBoundary(
                key: screen,
                child: QrImage(
                  backgroundColor: Colors.white,
                  padding: EdgeInsets.all(20),
                  data: qrDataEncode,
                  version: QrVersions.auto,
                  size: 300,
                  gapless: false,
                ),
              )),
          SizedBox(
            height: 20,
          ),
          // GestureDetector(
          //   child: Column(
          //     children: <Widget>[
          //       Icon(
          //         Icons.save_alt,
          //         size: 35,
          //       ),
          //       SizedBox(
          //         height: 5,
          //       ),
          //       const Text("Save to Device")
          //     ],
          //   ),
          //   onTap: () {
          //     _captureAndSharePng(context);
          //   },
          // )
        ],
      ),
    );
    return Stack(
      children: <Widget>[
        Layout(
          popClose: true,
          body: body,
          header: 'QR Code',
          logo: false,
          logoUrl: '',
          color: [Color(0xff8A0304), Color(0xffEC1C24)],
        ),
      ],
    );
  }
}
