import 'dart:io';
import 'package:firebase_admob/firebase_admob.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:share_extend/share_extend.dart';
import 'package:video_editor/info_screen.dart';

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: AppHome(),
    );
  }
}

class AppHome extends StatefulWidget {
  @override
  _AppHomeState createState() => _AppHomeState();
}

class _AppHomeState extends State<AppHome> {
  bool _splitting = false;
  int _splitTime;
  String _fileName;
  String _path;
  Directory _appDir;
  BannerAd _bannerAd;
  List<String> _videoFileList = [];
  // TODO insert your appId and bannerId here
  final String _appId =
      "ca-app-pub-3940256099942544~3347511713"; //! This is sample appID
  final String _bannerId =
      "ca-app-pub-3940256099942544/6300978111"; //! This is sample bannerAdID
  final FlutterFFmpeg _flutterFFmpeg = FlutterFFmpeg();
  final TextEditingController _timeTxtController = TextEditingController();
  final AlertStyle _alertStyle = AlertStyle(
    isOverlayTapDismiss: false,
    backgroundColor: Colors.white,
    isCloseButton: false,
  );
  final TextStyle _buttonTextStyle = TextStyle(
    fontSize: 20.0,
    fontWeight: FontWeight.bold,
    wordSpacing: 5.0,
  );
  final MobileAdTargetingInfo _targetingInfo = MobileAdTargetingInfo(
    childDirected: false,
  );

  @override
  void initState() {
    super.initState();
    getExternalStorageDirectory().then((dir) {
      _appDir = Directory(
        dir.parent.parent.parent.parent.path + '/Video Splitter',
      );
    });
    FirebaseAdMob.instance.initialize(appId: _appId);

    _bannerAd = BannerAd(
      adUnitId: BannerAd.testAdUnitId,
      size: AdSize.smartBanner,
      targetingInfo: _targetingInfo,
      listener: (MobileAdEvent event) {
        print("BannerAd event is $event");
      },
    );

    _bannerAd
      ..load()
      ..show(anchorOffset: 10.0, anchorType: AnchorType.bottom);
    Future.delayed(Duration(seconds: 0), Permission.mediaLibrary.request);
  }

  ///[function for sharing multiple videos]
  _shareMultipleVideos() async {
    if (_videoFileList.isEmpty) return;
    ShareExtend.shareMultiple(_videoFileList, "video");
  }

  ///[function for starting video splitting]
  Future<void> startSplitting() async {
    if (_path == null) {
      Alert(
        context: context,
        title: "Video file not specified",
        desc: "Plese specify a video file 🤕",
        style: _alertStyle,
      ).show();
      return;
    }

    if (await Permission.mediaLibrary.request().isGranted) {
      try {
        _splitTime = int.parse(_timeTxtController.text.split('.').first);
      } catch (e) {
        Alert(
          context: context,
          title: "Split time not specified",
          desc: "Plese specify split time in seconds 🤕",
          style: _alertStyle,
        ).show();
        print(e);
        return;
      }

      setState(() => _splitting = true);

      if (!await _appDir.exists()) await Directory(_appDir.path).create();

      String fileExtension = _fileName.split('.').removeLast();
      String fName =
          _fileName.replaceAll('.' + fileExtension, '') + '-splitted';

      final videoDir = Directory('${_appDir.path}/$fName');

      if (await videoDir.exists()) await videoDir.delete(recursive: true);

      await Directory(videoDir.path).create(recursive: true);

      List<String> arguments = [
        "-i",
        "$_path",
        "-c",
        "copy",
        "-map",
        "0",
        "-segment_time",
        "$_splitTime",
        "-f",
        "segment",
        "-reset_timestamps",
        "1",
        "${videoDir.path}/$fName-%d.$fileExtension"
      ];

      _flutterFFmpeg.executeWithArguments(arguments).then((rc) {
        Alert(
          context: context,
          title: "Task Completed",
          desc: "Your Video is sucessfully splitted 👍",
          style: _alertStyle,
        ).show();
        print("FFmpeg process exited with rc $rc");
        setState(() {
          _splitting = false;
          _videoFileList =
              videoDir.listSync().map((file) => file.path).toList();
        });
      });
    }
  }

  ///[function for opening file explorer]
  Future<void> openFileExplorer() async {
    setState(() => _videoFileList = []);
    try {
      _path = await FilePicker.getFilePath(type: FileType.video);
      if (_path == null) {
        setState(() => _fileName = null);
        return;
      }
      setState(() => _fileName = _path.split('/').last);
    } on PlatformException catch (e) {
      print("Unsupported operation" + e.toString());
    }
    if (!mounted) return;
  }

  Widget _getFileNameShower() => Container(
        child: _splitting
            ? Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text('Splitting Video...'),
                  SizedBox(height: 20.0),
                  CircularProgressIndicator(),
                ],
              )
            : Container(
                width: 500.0,
                alignment: Alignment.center,
                child: Text(
                  _fileName ??= 'No Video File Selected...',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                ),
              ),
      );

  Widget _getVideoFileSelectorButton() => Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: 50.0,
        child: FlatButton(
          onPressed: openFileExplorer,
          color: Colors.red,
          child: Text('Select 🎞Video File', style: _buttonTextStyle),
        ),
      );

  Widget _getTimeInputField() => Container(
        padding: EdgeInsets.symmetric(horizontal: 20.0),
        child: TextField(
          keyboardType: TextInputType.number,
          controller: _timeTxtController,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Split ⏲time in seconds',
          ),
        ),
      );

  Widget _getSplittingButton() => Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: 50.0,
        child: FlatButton(
          onPressed: startSplitting,
          color: Colors.blueAccent,
          child: Text(
            'Start ✂️Splitting 🎞Video',
            style: _buttonTextStyle,
          ),
        ),
      );

  Widget _getShareButton() => _videoFileList.isEmpty
      ? Container()
      : Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: 60.0,
          child: FlatButton(
            onPressed: _shareMultipleVideos,
            color: Colors.lightGreen,
            child: Text(
              '👉 Share on Social Media 👈',
              style: _buttonTextStyle.copyWith(fontSize: 16.0),
            ),
          ),
        );

  Widget _getMainScreen() {
    return AbsorbPointer(
      absorbing: _splitting,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: <Widget>[
            _getFileNameShower(),
            SizedBox(height: 30),
            _getVideoFileSelectorButton(),
            SizedBox(height: 20),
            _getTimeInputField(),
            SizedBox(height: 20),
            _getSplittingButton(),
            SizedBox(height: 30),
            _getShareButton(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        elevation: 0.0,
        title: Center(child: Text(' 🎞Video ✂️Splitter')),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.info),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => InfoScreen(),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        color: Colors.black12,
        padding: EdgeInsets.only(top: 20.0, left: 15.0, right: 15.0),
        child: _getMainScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _timeTxtController.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }
}
