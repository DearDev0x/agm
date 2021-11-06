import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import '../views/onloadProxyvote.dart';
import '../widgets/layout.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_mobile_vision/qr_camera.dart';
import 'package:qr_code_tools/qr_code_tools.dart';

class ScanProxyVoterPage extends StatefulWidget {
  static const routeName = "/scanproxyvoter";
  final setting;
  ScanProxyVoterPage(this.setting);
  @override
  _ScanProxyVoterPageState createState() => _ScanProxyVoterPageState();
}

class _ScanProxyVoterPageState extends State<ScanProxyVoterPage> {
  File _storedImage;
  bool showCamera = true;
  Future<dynamic> decode(String file) async {
    String data = await QrCodeToolsPlugin.decodeFrom(file);
    return data;
  }

  Future<void> getImage() async {
    File file = await FilePicker.getFile(
      type: FileType.image,
    );
    var code = await decode(file.path);
    await _onScanned(code, widget.setting['meetingId']);
  }

  Future<void> _onScanned(String code, String meetingId) async {
    setState(() {
      showCamera = false;
    });
    try {
      if (isJSON(code)) {
        var output = await jsonDecode(code);
        var voterAddress = output['voterAddress'];
        var hashId = output['hashId'];
        var meetingId = widget.setting['meetingId'];
        if (voterAddress == '' || hashId == '' || meetingId == '') {
          print('param incorrect');
          Flushbar(
            margin: EdgeInsets.all(8),
            borderRadius: 8,
            message: "Invalid QR Code!",
            icon: Icon(
              Icons.clear,
              size: 28.0,
              color: Colors.red[300],
            ),
            duration: Duration(seconds: 2),
          )..show(context);
        } else {
          Navigator.of(context).pushNamed(
            OnloadProxy.routeName,
            arguments: {
              'color': widget.setting['color'],
              'voterAddress': voterAddress,
              'hashId': hashId,
              'meetingId': meetingId,
            },
          );
        }
      } else {
        print("not json");
        Flushbar(
          margin: EdgeInsets.all(8),
          borderRadius: 8,
          message: "Invalid QR Code!",
          icon: Icon(
            Icons.clear,
            size: 28.0,
            color: Colors.red[300],
          ),
          duration: Duration(seconds: 2),
        )..show(context);
      }
      await Future.delayed(const Duration(milliseconds: 1000), () {
        setState(() {
          showCamera = true;
        });
      });
    } catch (err) {
      Flushbar(
        margin: EdgeInsets.all(8),
        borderRadius: 8,
        message: "Invalid QR Code!",
        icon: Icon(
          Icons.clear,
          size: 28.0,
          color: Colors.red[300],
        ),
        duration: Duration(seconds: 2),
      )..show(context);
    }
  }

  bool isJSON(str) {
    try {
      jsonDecode(str);
    } catch (e) {
      return false;
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context).settings.arguments as Map<String, dynamic>;
    Size size = MediaQuery.of(context).size;
    double statusBarHeight = MediaQuery.of(context).padding.top;
    double layoutHeader = 90.00 + statusBarHeight + 40;
    Widget body = Container(
      width: size.width,
      height: size.height - layoutHeader,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            height: 300,
            width: 300,
            child: Stack(
              children: <Widget>[
                Positioned(
                  top: 0,
                  left: 0,
                  child: Image.asset(
                    'assets/Image/58653.png',
                    width: 90,
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationY(math.pi),
                    child: Image.asset(
                      'assets/Image/58653.png',
                      width: 90,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationX(math.pi),
                    child: Image.asset(
                      'assets/Image/58653.png',
                      width: 90,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationX(math.pi),
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.rotationY(math.pi),
                      child: Image.asset(
                        'assets/Image/58653.png',
                        width: 90,
                      ),
                    ),
                  ),
                ),
                Center(
                  child: showCamera
                      ? Container(
                          height: 294,
                          width: 294,
                          child: new QrCamera(
                            notStartedBuilder: (_) {
                              return Container(
                                height: 294,
                                width: 294,
                                color: Colors.white,
                                child: Center(
                                  child: Text("Loading Camera"),
                                ),
                              );
                            },
                            offscreenBuilder: (_) {
                              return Container(
                                height: 294,
                                width: 294,
                                color: Colors.white,
                                child: Center(
                                  child: Text("Loading Camera"),
                                ),
                              );
                            },
                            fit: BoxFit.cover,
                            qrCodeCallback: (code) {
                              _onScanned(code, args['meetingId']);
                              setState(() {
                                showCamera = false;
                              });
                            },
                          ),
                        )
                      : Container(
                          height: 294,
                          width: 294,
                          color: Colors.white,
                          child: Center(
                            child: Text("Loading Camera"),
                          ),
                        ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 40,
          ),
          GestureDetector(
            onTap: () async {
              await getImage();
            },
            child: Column(
              children: <Widget>[
                Icon(
                  Icons.photo_library,
                  size: 40,
                ),
                SizedBox(
                  height: 5,
                ),
                const Text("Browse"),
                if (_storedImage != null)
                  Image.file(
                    _storedImage,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
    return Layout(
      popClose: true,
      header: "Grant voting rights",
      logo: false,
      logoUrl: '',
      color: args['color'],
      body: body,
    );
  }
}
