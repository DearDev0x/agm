import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ContentLoading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Shimmer.fromColors(
          baseColor: Colors.grey[300],
          highlightColor: Colors.grey[200],
          enabled: true,
          child: ListView(
            padding: const EdgeInsets.only(top: 25),
            children: <Widget>[
              Card(
                clipBehavior: Clip.antiAlias,
                margin: const EdgeInsets.only(bottom: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Stack(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            '',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                            textAlign: TextAlign.start,
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          Text(
                            '',
                            style: TextStyle(color: Colors.white, fontSize: 20),
                            textAlign: TextAlign.start,
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          Divider(
                            indent: 20,
                            endIndent: 20,
                            thickness: 1,
                            color: Colors.white.withOpacity(0.3),
                          ),
                          SizedBox(
                            height: 8,
                          ),
                          Text('',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 12)),
                          SizedBox(
                            height: 8,
                          ),
                          Row(
                            children: <Widget>[
                              Text(
                                ' ',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 12),
                                textAlign: TextAlign.start,
                              ),
                              Text(
                                '  |  ',
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.3),
                                    fontSize: 20),
                              ),
                              Text(
                                ' ',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 12),
                                textAlign: TextAlign.start,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Card(
                clipBehavior: Clip.antiAlias,
                margin: const EdgeInsets.only(bottom: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Stack(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            '',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                            textAlign: TextAlign.start,
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          Text(
                            '',
                            style: TextStyle(color: Colors.white, fontSize: 20),
                            textAlign: TextAlign.start,
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          Divider(
                            indent: 20,
                            endIndent: 20,
                            thickness: 1,
                            color: Colors.white.withOpacity(0.3),
                          ),
                          SizedBox(
                            height: 8,
                          ),
                          Text('',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 12)),
                          SizedBox(
                            height: 8,
                          ),
                          Row(
                            children: <Widget>[
                              Text(
                                ' ',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 12),
                                textAlign: TextAlign.start,
                              ),
                              Text(
                                '  |  ',
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.3),
                                    fontSize: 20),
                              ),
                              Text(
                                ' ',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 12),
                                textAlign: TextAlign.start,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Card(
                clipBehavior: Clip.antiAlias,
                margin: const EdgeInsets.only(bottom: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Stack(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            '',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                            textAlign: TextAlign.start,
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          Text(
                            '',
                            style: TextStyle(color: Colors.white, fontSize: 20),
                            textAlign: TextAlign.start,
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          Divider(
                            indent: 20,
                            endIndent: 20,
                            thickness: 1,
                            color: Colors.white.withOpacity(0.3),
                          ),
                          SizedBox(
                            height: 8,
                          ),
                          Text('',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 12)),
                          SizedBox(
                            height: 8,
                          ),
                          Row(
                            children: <Widget>[
                              Text(
                                ' ',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 12),
                                textAlign: TextAlign.start,
                              ),
                              Text(
                                '  |  ',
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.3),
                                    fontSize: 20),
                              ),
                              Text(
                                ' ',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 12),
                                textAlign: TextAlign.start,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Card(
                clipBehavior: Clip.antiAlias,
                margin: const EdgeInsets.only(bottom: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Stack(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            '',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                            textAlign: TextAlign.start,
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          Text(
                            '',
                            style: TextStyle(color: Colors.white, fontSize: 20),
                            textAlign: TextAlign.start,
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          Divider(
                            indent: 20,
                            endIndent: 20,
                            thickness: 1,
                            color: Colors.white.withOpacity(0.3),
                          ),
                          SizedBox(
                            height: 8,
                          ),
                          Text('',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 12)),
                          SizedBox(
                            height: 8,
                          ),
                          Row(
                            children: <Widget>[
                              Text(
                                ' ',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 12),
                                textAlign: TextAlign.start,
                              ),
                              Text(
                                '  |  ',
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.3),
                                    fontSize: 20),
                              ),
                              Text(
                                ' ',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 12),
                                textAlign: TextAlign.start,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )),
    );
  }
}
