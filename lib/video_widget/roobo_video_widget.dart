import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:roobo_video/custom_video_player/custom_video_control.dart';
import 'package:roobo_video/custom_video_player/custom_video_player.dart';
import 'package:roobo_video/custom_video_player/widget_process_load.dart';
import 'package:roobo_video/video_widget/media_listener.dart';
import 'package:video_player/video_player.dart';

typedef NetNone = bool Function();
typedef Progress = Function(Duration total, Duration current);

class RooboVideoWidget extends StatefulWidget {
  final String url;
  final String title;
  final MediaStartPlay startPlay;
  final double height;
  final NetNone isNoNet;
  final Progress progress;

  const RooboVideoWidget({
    Key key,
    this.url,
    this.title,
    this.startPlay,
    this.height = 190,
    this.progress,
    @required this.isNoNet,
  }) : super(key: key);

  @override
  _RooboVideoWidgetState createState() => _RooboVideoWidgetState();
}

class _RooboVideoWidgetState extends State<RooboVideoWidget> {
  VideoPlayerController _videoPlayerController;
  CustomVideoController _customVideoController;
  final int _normal = 0;
  final int _noNet = 1;
  final int _error = 2;
  int _playStatus = 0;
  double progress = 0;
  bool isPlay = false;
  MediaController mediaController;

  @override
  void initState() {
    super.initState();
    mediaController = MediaController();
    mediaController.addListener(MediaWidgetListener(videoStopPlay: () {
      _videoPlayerController.pause();
    }));
    Future.delayed(Duration(milliseconds: 800)).then((value) {
      initializePlayer();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      height: widget.height,
      child: _customVideoController != null && _customVideoController.videoPlayerController.value.isInitialized ? videoWidget() : getOtherWidget(),
    );
  }

  videoWidget() {
    return Stack(
      children: [
        CustomVideoPlayer(
          controller: _customVideoController,
          title: widget.title,
        ),
        Positioned.fill(
            child: Visibility(
          child: IconButton(
            icon: Image.asset("res/img/icon_page_video_paly.png"),
            onPressed: () {
              _videoPlayerController.play();
            },
          ),
          visible: !isPlay,
        )),
      ],
    );
  }

  initializePlayer() async {
    _videoPlayerController = VideoPlayerController.network(widget.url);
    await _videoPlayerController.initialize();

    _videoPlayerController?.addListener(() {
      if (widget.progress != null) widget.progress(_videoPlayerController.value.duration, _videoPlayerController.value.position);

      if (_videoPlayerController.value.hasError) {
        if (widget.isNoNet != null && widget.isNoNet()) {
          setState(() {
            _playStatus = _noNet;
          });
        } else {
          setState(() {
            _playStatus = _error;
          });
        }
      }

      if (!_videoPlayerController.value.isPlaying) {
        setState(() {
          isPlay = false;
          _customVideoController.showVideoControllers(false);
        });
      } else if (_videoPlayerController.value.isPlaying) {
        setState(() {
          isPlay = true;
          _customVideoController.showVideoControllers(true);
          if (widget.startPlay != null) {
            widget.startPlay(mediaController);
          }
          // _customVideoController.showControls = true;
        });
      }
    });
    _customVideoController = CustomVideoController(
      videoPlayerController: _videoPlayerController,
      autoPlay: false,
      looping: false,
      customControls: VideoControlWidget(),
      showControls: false,
      errorBuilder: (context, string) {
        return getNoNetWidget();
      },
      deviceOrientationsOnEnterFullScreen: [DeviceOrientation.landscapeRight, DeviceOrientation.landscapeLeft],
      isNetNone: () {
        return widget.isNoNet != null && widget.isNoNet();
      },
    );
    setState(() {});
  }

  getNoNetWidget() {
    return GestureDetector(
      onTap: () async {
        if (widget.isNoNet != null && widget.isNoNet()) {
          setState(() {
            _playStatus = _noNet;
          });
          return;
        }
        setState(() {
          _playStatus = _normal;
        });
        if (_customVideoController.isFullScreen) {
          await Navigator.of(context, rootNavigator: true).pop();
        }
        initializePlayer();
      },
      child: Container(
        color: Colors.black,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('res/img/video_refresh.png'),
            SizedBox(
              height: 15,
              width: double.infinity,
            ),
            Text(
              '网络未连接，点击重新加载',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  getOtherWidget() {
    if (_playStatus == _noNet) {
      return getNoNetWidget();
    } else if (_playStatus == _error) {
      return GestureDetector(
        onTap: () {
          setState(() {
            _playStatus = _normal;
          });
          initializePlayer();
        },
        child: Center(
          child: Container(
            color: Colors.black,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('res/img/video_refresh.png'),
                SizedBox(
                  height: 15,
                  width: double.infinity,
                ),
                Text(
                  '网络未连接，点击重新加载',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      return Center(
        child: Container(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ProgressLoadWidget(type: ProgressLoadType.Circle),
              Text(
                '加载中',
                style: TextStyle(color: Colors.white),
              )
            ],
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _videoPlayerController?.removeListener(() {});
    _videoPlayerController?.dispose();
    _customVideoController?.dispose();
    super.dispose();
  }
}
