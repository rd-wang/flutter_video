import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:roobo_video/custom_video_player/custom_video_control.dart';
import 'package:roobo_video/custom_video_player/custom_video_player.dart';
import 'package:roobo_video/custom_video_player/widget_process_load.dart';
import 'package:roobo_video/video_widget/media_listener.dart';
import 'package:video_player/video_player.dart';

typedef OnVideoPlay = void Function();
typedef OnVideoPause = void Function(Duration pauseTime, Duration totalTime);
typedef OnVideoPlaying = void Function(Duration pauseTime, Duration totalTime);
typedef OnVideoPrepared = void Function(Duration totalTime);
typedef OnVideoPreparing = void Function();
typedef OnVideoFinished = void Function();
typedef OnVideoError = void Function(int);

class RooboVideoStateListener {
  OnVideoPlay onVideoStart;
  OnVideoPause onVideoPause;
  OnVideoPreparing onVideoPreparing;
  OnVideoPrepared onVideoPrepared;
  OnVideoFinished onVideoFinished;
  OnVideoPlaying onVideoPlaying;
  OnVideoError onVideoError;

  RooboVideoStateListener({this.onVideoPreparing, this.onVideoPrepared, this.onVideoPause, this.onVideoStart, this.onVideoFinished, this.onVideoPlaying, this.onVideoError});
}

typedef NetNone = bool Function();
typedef Progress = Function(Duration total, Duration current);

class RooboVideoWidget extends StatefulWidget {
  final String url;
  final String title;
  final MediaStartPlay startPlay;
  final double height;
  final NetNone isNoNet;
  final Progress progress;
  final RooboVideoStateListener videoListener;

  /// isNoNet  该参数  是为了剔除对网络状态的判断的依赖，
  /// 一般情况下 此处返回当前是否有网络，此方法依赖网络连接状态，
  /// 故需要外部传入
  /// 一般如下:
  /// isNoNet: () {
  ///                     return NetState.getInstance.netResult == NetConnectResult.none;
  ///                   },
  const RooboVideoWidget({
    Key key,
    this.url,
    this.title,
    this.startPlay,
    this.height = 190,
    this.progress,
    @required this.isNoNet,
    this.videoListener,
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
  bool isHideBottom = true;

  @override
  void initState() {
    super.initState();
    mediaController = MediaController();
    mediaController.addListener(MediaWidgetListener(videoStopPlay: () {
      _videoPlayerController.pause();
    }));
    widget.videoListener ??
        RooboVideoStateListener(
            onVideoPreparing: () {},
            onVideoPrepared: (time) {},
            onVideoStart: () {},
            onVideoPlaying: (pauseTime, totalTime) async {},
            onVideoPause: (pauseTime, totalTime) {},
            onVideoFinished: () {},
            onVideoError: (int code) {});
    initializePlayer(widget.videoListener);
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
            icon: Image.asset(
              "res/img/icon_page_video_play.png",
              package: 'roobo_video',
            ),
            onPressed: () {
              _videoPlayerController.play();
            },
          ),
          visible: !isPlay,
        )),
      ],
    );
  }

  bool startedPlaying = false;
  static const int VIDEO_URL_NULL = -1;

  initializePlayer(RooboVideoStateListener listener) async {
    if (widget.url.isEmpty) {
      listener.onVideoError?.call(VIDEO_URL_NULL);
      setState(() {
        _playStatus = _error;
      });
      return;
    }
    _videoPlayerController = VideoPlayerController.network(widget.url);

    await _videoPlayerController.initialize();

    bool oldPlayStatus = false;
    bool _oldInitStatus = false;
    bool videoHasEnd = false;
    bool isFirstPlay = true;
    listener.onVideoPreparing?.call();
    _videoPlayerController?.addListener(() async {
      addUIStateListener();
      if (_videoPlayerController.value.isInitialized) {
        if (_oldInitStatus != _videoPlayerController.value.isInitialized) {
          _oldInitStatus = _videoPlayerController.value.isInitialized;
          // print("lesson______VideoHelper: _____初始化完成______");
          listener.onVideoPrepared?.call(_videoPlayerController.value.duration);
        } else {
          if (videoHasEnd) {
            return;
          }
          if (_videoPlayerController.value.position.inSeconds == _videoPlayerController.value.duration.inSeconds) {
            videoHasEnd = true;
            // print("lesson______VideoHelper: _____结束______");
            listener.onVideoFinished?.call();
            return;
          }
          if (_videoPlayerController.value.isPlaying) {
            if (isFirstPlay) {
              startedPlaying = true;
              listener.onVideoStart?.call();
              isFirstPlay = false;
            }
            // print("lesson______VideoHelper: _____播放______");
            oldPlayStatus = _videoPlayerController.value.isPlaying;
            await listener?.onVideoPlaying?.call(_videoPlayerController.value.position, _videoPlayerController.value.duration);
          }

          if (startedPlaying && !_videoPlayerController.value.isPlaying && oldPlayStatus != _videoPlayerController.value.isPlaying) {
            oldPlayStatus = _videoPlayerController.value.isPlaying;
            // print("lesson______VideoHelper: _____暂停______");
            listener?.onVideoPause?.call(_videoPlayerController.value.position, _videoPlayerController.value.duration);
          }
        }
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

  void addUIStateListener() {
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
        if (isHideBottom) {
          _customVideoController?.showVideoControllers(false);
          isHideBottom = false;
        }
      });
    } else if (_videoPlayerController.value.isPlaying) {
      setState(() {
        isPlay = true;
        if (!isHideBottom) {
          _customVideoController?.showVideoControllers(true);
          isHideBottom = true;
        }
        if (widget.startPlay != null) {
          widget.startPlay(mediaController);
        }
        // _customVideoController.showControls = true;
      });
    }
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
        initializePlayer(widget.videoListener);
      },
      child: Container(
        color: Colors.black,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'res/img/video_refresh.png',
              package: 'roobo_video',
            ),
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
          initializePlayer(widget.videoListener);
        },
        child: Center(
          child: Container(
            color: Colors.black,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'res/img/video_refresh.png',
                  package: 'roobo_video',
                ),
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
