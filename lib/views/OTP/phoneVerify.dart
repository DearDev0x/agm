import 'package:flutter/material.dart';

import '../../views/OTP/termService.dart';

import '../../widgets/loading.dart';

// Future<Wallet> saveWalletFunction(obj) async {
//   Wallet wallet =
//       Wallet.createNew(obj['credentials'], "AGMp@ssw0rd", obj['rng']);
//   return wallet;
// }

class PhoneVerifyPage extends StatefulWidget {
  static const routeName = '/phonerVerify';

  @override
  _PhoneVerifyPageState createState() => _PhoneVerifyPageState();
}

class _PhoneVerifyPageState extends State<PhoneVerifyPage> {
  bool loadingState = false;
  //StreamSubscription _subLogging;
  final phoneController = TextEditingController();
  final _phoneFocusNode = FocusNode();
  String _phoneNo = '';
  final _formPhoneVerify = GlobalKey<FormState>();

  // Future<Null> initUniLinks() async {
  //   _subLogging = getUriLinksStream().listen((Uri uri) async {
  //     setState(() {
  //       loadingState = true;
  //     });
  //     print(uri);
  //     print('load uri from login');
  //     var segments = uri.pathSegments;
  //     var path = segments[0].trim();
  //     var query = uri.queryParameters;
  //     print(path);
  //     if (path == 'loginfromidp') {
  //       await gotoLogin(query['idCard'].trim(), query['token'].trim());
  //     } else {
  //       setState(() {
  //         loadingState = false;
  //       });
  //     }
  //   }, onError: (err) {
  //     print(err);
  //     _subLogging.cancel();
  //   });
  // }

  void _onSubmit() async {
    final isValid = _formPhoneVerify.currentState.validate();
    if (!isValid) {
      return;
    }
    _formPhoneVerify.currentState.save();
    //var _phoneNo = phoneController.text;
    // if(_phoneNo.startsWith('+66')) {
    //   _phoneNo = '0' + _phoneNo.substring(3);
    // }
    await Future.delayed(const Duration(milliseconds: 250));
    await Navigator.of(context).pushNamed(TermServicePage.routeName,
        arguments: {'phoneNo': _phoneNo, 'isPage': true});
  }

  @override
  void initState() {
    super.initState();
    //initUniLinks();
  }

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    double statusBarHeight = MediaQuery.of(context).padding.top;
    return Scaffold(
      body: SingleChildScrollView(
        child: Stack(
          children: <Widget>[
            Container(
              padding:
                  EdgeInsets.only(left: 30, right: 30, top: statusBarHeight),
              height: size.height,
              width: size.width,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/Image/bg.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  Container(
                      constraints: BoxConstraints(maxWidth: 450),
                      width: size.width * 0.6,
                      child: Image.asset('assets/Image/logo-02.png')),
                  Container(
                    child: Column(
                      children: <Widget>[
                        Text(
                          "Thailand's first AGM voting",
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.white),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Text(
                          'on Blockchain technology',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              wordSpacing: 2,
                              letterSpacing: 2),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    constraints: BoxConstraints(maxWidth: 320),
                    width: size.width * 0.8,
                    child: Form(
                      key: _formPhoneVerify,
                      child: Column(
                        children: <Widget>[
                          TextFormField(
                            textAlign: TextAlign.center,
                            initialValue: _phoneNo,
                            focusNode: _phoneFocusNode,
                            textInputAction: TextInputAction.next,
                            keyboardType: TextInputType.phone,
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withOpacity(0.8)),
                            decoration: InputDecoration(
                              contentPadding:
                                  EdgeInsets.symmetric(vertical: 13),
                              counterText: '',
                              errorStyle: TextStyle(color: Colors.black),
                              hintText: 'Mobile number',
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.4),
                              hintStyle: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(50.0),
                                ),
                                borderSide: BorderSide(
                                  color: Colors.transparent,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(50.0),
                                ),
                                borderSide: BorderSide(
                                  color: Colors.transparent,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(50.0),
                                ),
                                borderSide: BorderSide(
                                  color: Colors.transparent,
                                ),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(50.0),
                                ),
                                borderSide: BorderSide(
                                  color: Colors.transparent,
                                ),
                              ),
                            ),
                            onFieldSubmitted: (_) {
                              FocusScope.of(context).requestFocus(FocusNode());
                              _onSubmit();
                            },
                            onSaved: (value) {
                              _phoneNo = value;
                            },
                            validator: (value) {
                              if (value.isEmpty) {
                                return '  Please enter valid number !';
                              }
                              return null;
                            },
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          Container(
                            height: 48.0,
                            decoration: BoxDecoration(
                              color: Color(0xffFFFFFFF),
                              borderRadius: BorderRadius.circular(50.0),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  _onSubmit();
                                },
                                child: Center(
                                  child: Center(
                                    child: const Text(
                                      'Next',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (loadingState)
              Positioned(
                top: 0,
                child: LoadingWidget(),
              ),
            Positioned(
                bottom: 5,
                right: 10,
                child: Text('V 1.1.5', style: TextStyle(color: Colors.grey))),
          ],
        ),
      ),
    );
  }
}
