import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ListItem extends StatelessWidget {
  final String company;
  final String title;
  final String address;
  final String timex;
  final String datex;
  final List<Color> color;
  final String logoUrl;
  ListItem({
    Key key,
    @required this.company,
    @required this.title,
    @required this.address,
    @required this.timex,
    @required this.datex,
    this.color,
    this.logoUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      key: key,
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Stack(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: color,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(right: logoUrl != '' ? 90.0 : 0.00),
                  child: Text(
                    company,
                    style: TextStyle(color: Colors.white, fontSize: 12),
                    textAlign: TextAlign.start,
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                Text(
                  title,
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
                Text(address,
                    style: TextStyle(color: Colors.white, fontSize: 12)),
                SizedBox(
                  height: 8,
                ),
                Row(
                  children: <Widget>[
                    Text(
                      timex,
                      style: TextStyle(color: Colors.white, fontSize: 12),
                      textAlign: TextAlign.start,
                    ),
                    Text(
                      '  |  ',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.3), fontSize: 20),
                    ),
                    Text(
                      datex,
                      style: TextStyle(color: Colors.white, fontSize: 12),
                      textAlign: TextAlign.start,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (logoUrl != '')
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
        ],
      ),
    );
  }
}
