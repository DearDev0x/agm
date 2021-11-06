import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class Layout extends StatelessWidget {
  final bool popClose;
  final bool logo;
  final Widget body;
  final String header;
  final List<Color> color;
  final String logoUrl;

  Layout({
    this.popClose,
   @required this.logo,
    this.body,
    this.header,
    this.color,
    this.logoUrl,
  });

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    double statusBarHeight = MediaQuery.of(context).padding.top;
    double layoutHeader = 90.00 + statusBarHeight;
    if(logo) {
      layoutHeader += 40;
    }
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          child: Column(
            children: <Widget>[
              Container(
                width: size.width,
                height: layoutHeader,
                padding: EdgeInsets.only(top: statusBarHeight),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: color,
                  ),
                ),
                child: Stack(
                  children: <Widget>[
                    if (logo && logoUrl != '')
                      Positioned(
                        right: 0,
                        width: 110,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              bottomLeft: const Radius.circular(24.0),
                            ),
                          ),
                          child: Center(
                            child: CachedNetworkImage(
                              height: 25,
                              imageUrl: logoUrl,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    if (popClose)
                      Positioned(
                        left: 10,
                        top: 10,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Container(
                            padding: EdgeInsets.all(2),
                            decoration: BoxDecoration(
                                shape: BoxShape.circle, color: Colors.white),
                            child: Icon(
                              Icons.close,
                              color: Colors.black.withOpacity(0.3),
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    Padding(
                      padding: EdgeInsets.only(
                          top: logo ? 60 : 30, left: 15, right: 15),
                      child: Container(
                        height: 60,
                        child: Center(
                          child: SingleChildScrollView(
                            child: Container(
                              child: Text(
                                header,
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                    height: 1.2),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                color: Colors.white,
                width: size.width,
                constraints: BoxConstraints(maxWidth: 800),
                height: size.height - layoutHeader,
                child: SingleChildScrollView(
                  child: body,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
