import 'package:flutter/material.dart';

class InfoScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
      ),
      body: Center(
        child: Column(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(top: 40.0, bottom: 20),
              child: CircleAvatar(
                radius: 100.0,
                backgroundImage: NetworkImage(
                    'https://avatars1.githubusercontent.com/u/43314374?s=460&u=10544aa618c0bf5d24cebd4977489a09521e721f&v=4'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
