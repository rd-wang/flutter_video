import 'dart:async';

import 'package:flutter/material.dart';
import 'package:roobo_video/custom_video_player/tool_overscorll_behavior.dart';
import 'package:roobo_video/custom_video_player/widget_process_load.dart';
import 'package:video_player/video_player.dart';
import 'custom_video_player.dart';
import 'custom_video_progress_bar.dart';
import 'utils.dart';

class VideoControlWidget extends StatefulWidget {
  const VideoControlWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _VideoControlWidgetState();
  }
}

class _VideoControlWidgetState extends State<VideoControlWidget> with TickerProviderStateMixin {
  late VideoPlayerValue _latestValue;
  double? _latestVolume;
  bool _hideStuff = true;
  Timer? _hideTimer;
  Timer? _initTimer;
  Timer? _showAfterExpandCollapseTimer;
  bool _dragging = false;
  bool _displayTapped = false;

  final barHeight = 28.0;
  final marginSize = 5.0;

  VideoPlayerController? controller;
  CustomVideoController? _customController;

  bool _isShowSpeedSelect = false;

  // We know that _chewieController is set in didChangeDependencies
  CustomVideoController? get customVideoController => _customController;
  late AnimationController playPauseIconAnimationController;
  late AnimationController speedController;

  @override
  void initState() {
    super.initState();
    playPauseIconAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      reverseDuration: const Duration(milliseconds: 400),
    );
    speedController = AnimationController(vsync: this, duration: Duration(milliseconds: 300));
  }

  double? _selected;

  @override
  Widget build(BuildContext context) {
    // debugPrint("MediaQuery.of(context).padding.top / 2:${MediaQuery.of(context).padding.top / 2}");
    _selected = _latestValue.playbackSpeed;
    if (_latestValue.hasError) {
      return customVideoController!.errorBuilder?.call(
            context,
            customVideoController!.videoPlayerController!.value.errorDescription,
          ) ??
          const Center(
            child: Icon(
              Icons.error,
              color: Colors.white,
              size: 42,
            ),
          );
    }
    return Stack(
      children: [
        MouseRegion(
          onHover: (_) {
            _cancelAndRestartTimer();
          },
          child: GestureDetector(
            onTap: () => _cancelAndRestartTimer(),
            child: AbsorbPointer(
              absorbing: _hideStuff,
              child: Stack(
                children: [
                  Container(
                    alignment: Alignment.bottomCenter,
                    child: Visibility(
                      visible: customVideoController!.showControls,
                      child: _buildBottomBar(context),
                    ),
                  ),
                  if (_latestValue.isBuffering)
                    Container(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ProgressLoadWidget(type: ProgressLoadType.Circle),
                          Text(
                            "加载中",
                            style: TextStyle(color: Colors.white,fontSize: 12),
                          ),
                        ],
                      ),
                    )
                  else
                    _buildHitArea(),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 0,
          bottom: 0,
          right: 0,
          left: 0,
          child: SlideTransition(
            position: Tween(begin: Offset(1.5, 0), end: Offset(0.0, 0)).animate(speedController),
            child: Visibility(
              visible: _isShowSpeedSelect,
              child: GestureDetector(
                onTap: () {
                  _isShowSpeedSelect = false;
                  if (_latestValue.isPlaying) {
                    _startHideTimer();
                  }
                },
                child: Container(
                  alignment: Alignment.centerRight,
                  color: Color(0x77000000),
                  child: Container(
                    width: 67,
                    margin: EdgeInsets.only(bottom: MediaQuery.of(context).padding.top / 2, right: 25),
                    child: ScrollConfiguration(
                      behavior: OverScrollBehavior(),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemBuilder: (context, index) {
                          final _speed = customVideoController!.playbackSpeeds[index];
                          return GestureDetector(
                            onTap: () async {
                              await controller!.setPlaybackSpeed(_speed);
                              _isShowSpeedSelect = false;
                              speedController.reset();
                              if (_latestValue.isPlaying) {
                                _startHideTimer();
                              }
                            },
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: customVideoController!.isFullScreen ? 15.5 : 7),
                              child: Center(
                                child: Text(
                                  _speed.toString() + "x",
                                  style: TextStyle(color: _speed == _selected ? Color(0xFFFE6102) : Colors.white, fontSize: 14),
                                ),
                              ),
                            ),
                          );
                        },
                        itemCount: customVideoController!.playbackSpeeds.length,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }

  void _dispose() {
    controller!.removeListener(_updateState);
    _hideTimer?.cancel();
    _initTimer?.cancel();
    _showAfterExpandCollapseTimer?.cancel();
  }

  @override
  void didChangeDependencies() {
    final _oldController = _customController;
    _customController = CustomVideoController.of(context);
    controller = customVideoController!.videoPlayerController;

    if (_oldController != customVideoController) {
      _dispose();
      _initialize();
    }

    super.didChangeDependencies();
  }

  AnimatedOpacity _buildBottomBar(
    BuildContext context,
  ) {
    return AnimatedOpacity(
      opacity: _hideStuff ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        height: barHeight+20,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            end: Alignment.bottomCenter,
            begin: Alignment.topCenter,
            colors: [Color(0x0000000), Color(0x33000000)],
          ),
        ),
        child: Row(
          children: <Widget>[
            _buildPlayPause(controller!),
            if (customVideoController!.isLive) const Expanded(child: Text('LIVE')) else _buildStartPosition(_latestValue.position),
            if (customVideoController!.isLive) const SizedBox() else _buildProgressBar(),
            if (customVideoController!.isLive) const Expanded(child: Text('LIVE')) else _buildEndPosition(_latestValue.duration),
            if (customVideoController!.allowPlaybackSpeedChanging) _buildSpeedButton(controller),
//            if (chewieController.allowMuting) _buildMuteButton(controller),
            if (customVideoController!.allowFullScreen) _buildExpandButton(),
          ],
        ),
      ),
    );
  }

  GestureDetector _buildExpandButton() {
    return GestureDetector(
      onTap: _onExpandCollapse,
      child: AnimatedOpacity(
        opacity: _hideStuff ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          height: barHeight,
          margin: const EdgeInsets.only(left: 10, right: 10),
          child: Center(
            child: customVideoController!.isFullScreen
                ? Image.asset(
                    'res/img/video_player_no_full.png',
                    package: 'roobo_video',
                  )
                : Image.asset(
                    'res/img/video_player_full.png',
                    package: 'roobo_video',
                  ),
          ),
        ),
      ),
    );
  }

   _buildHitArea() {
    final bool isFinished = _latestValue.position >= _latestValue.duration;

    return GestureDetector(
      onTap: () {
        if (_latestValue.isPlaying) {
          if (_displayTapped) {
            setState(() {
              _hideStuff = true;
            });
          } else {
            _cancelAndRestartTimer();
          }
        } else {
          _playPause();

          setState(() {
            _hideStuff = true;
          });
        }
      },
      child: Container(
        child: Center(
          child: AnimatedOpacity(
            opacity: !_latestValue.isPlaying && !_dragging ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: GestureDetector(
              child: Container(
                child: IconButton(
                    icon: isFinished
                        ? Visibility(visible: false, child: const Icon(Icons.replay, size: 32.0))
                        : Visibility(
                            visible: false,
                            child: AnimatedIcon(
                              icon: AnimatedIcons.play_pause,
                              progress: playPauseIconAnimationController,
                              size: 32.0,
                            ),
                          ),
                    onPressed: () {
                      _playPause();
                    }),
              ),
            ),
          ),
        ),
      ),
    );
  }

  //加速按钮
  Widget _buildSpeedButton(
    VideoPlayerController? controller,
  ) {
    return GestureDetector(
      onTap: () async {
        if (speedController.isAnimating) {
          return;
        }
        _hideTimer?.cancel();
        setState(() {
          _isShowSpeedSelect = !_isShowSpeedSelect;
          if (_isShowSpeedSelect == false) {
            speedController.reset();
          }
        });
        speedController.forward();
      },
      child: AnimatedOpacity(
        opacity: _hideStuff ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 300),
        child: ClipRect(
          child: Container(
            height: barHeight,
            alignment: Alignment.center,
            padding: EdgeInsets.only(
              left: 8.0,
            ),
            child: Text(
              '${_latestValue.playbackSpeed == 1.0 ? "倍速" : _latestValue.playbackSpeed.toString() + "x"}',
              textAlign: TextAlign.start,
              style: const TextStyle(fontSize: 10.0, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  //音量按钮
  GestureDetector _buildMuteButton(
    VideoPlayerController controller,
  ) {
    return GestureDetector(
      onTap: () {
        _cancelAndRestartTimer();

        if (_latestValue.volume == 0) {
          controller.setVolume(_latestVolume ?? 0.5);
        } else {
          _latestVolume = controller.value.volume;
          controller.setVolume(0.0);
        }
      },
      child: AnimatedOpacity(
        opacity: _hideStuff ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 300),
        child: ClipRect(
          child: Container(
            height: barHeight,
            padding: const EdgeInsets.only(
              left: 8.0,
              right: 8.0,
            ),
            child: Icon(
              _latestValue.volume > 0 ? Icons.volume_up : Icons.volume_off,
            ),
          ),
        ),
      ),
    );
  }

  GestureDetector _buildPlayPause(VideoPlayerController controller) {
    return GestureDetector(
      onTap: _playPause,
      child: Container(
        height: barHeight,
        color: Colors.transparent,
        margin: const EdgeInsets.only(left: 10.0, right: 10.0),
        child: !controller.value.isPlaying
            ? Image.asset(
                'res/img/video_player_play.png',
                package: 'roobo_video',
              )
            : Image.asset(
                'res/img/video_player_pause.png',
                package: 'roobo_video',
              ),
      ),
    );
  }

  //开始时间
  Widget _buildStartPosition(Duration duration) {
    return Text(
      '${formatDuration(duration)}',
      textAlign: TextAlign.start,
      style: const TextStyle(fontSize: 10.0, color: Colors.white),
    );
  }

  Widget _buildEndPosition(Duration duration) {
    return Text(
      '${formatDuration(duration)}',
      textAlign: TextAlign.start,
      style: const TextStyle(fontSize: 10.0, color: Colors.white),
    );
  }

  void _cancelAndRestartTimer() {
    _hideTimer?.cancel();
    _startHideTimer();

    setState(() {
      _hideStuff = false;
      _displayTapped = true;
    });
  }

  Future<void> _initialize() async {
    controller!.addListener(_updateState);

    _updateState();

    if (controller!.value.isPlaying || customVideoController!.autoPlay) {
      _startHideTimer();
    }

    if (customVideoController!.showControlsOnInitialize) {
      _initTimer = Timer(const Duration(milliseconds: 200), () {
        setState(() {
          _hideStuff = false;
        });
      });
    }
  }

  void _onExpandCollapse() {
    setState(() {
      _hideStuff = true;

      customVideoController!.toggleFullScreen();
      _showAfterExpandCollapseTimer = Timer(const Duration(milliseconds: 300), () {
        setState(() {
          _cancelAndRestartTimer();
        });
      });
    });
  }

  void _playPause() {
    final isFinished = _latestValue.position >= _latestValue.duration;
    if (_customController!.isNetNone != null) {
      if (_customController!.isNetNone!()) {
        return;
      }
    }
    setState(() {
      if (controller!.value.isPlaying) {
        playPauseIconAnimationController.reverse();
        _hideStuff = false;
        _hideTimer?.cancel();
        controller!.pause();
      } else {
        _cancelAndRestartTimer();

        if (!controller!.value.isInitialized) {
          controller!.initialize().then((_) {
            controller!.play();
            playPauseIconAnimationController.forward();
          });
        } else {
          if (isFinished) {
            controller!.seekTo(const Duration());
          }
          playPauseIconAnimationController.forward();
          controller!.play();
        }
      }
    });
  }

  void _startHideTimer() {
    _hideTimer = Timer(const Duration(seconds: 3), () {
      setState(() {
        _hideStuff = true;
      });
    });
  }

  void _updateState() {
    setState(() {
      _latestValue = controller!.value;
    });
  }

  Widget _buildProgressBar() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(left: 5, right: 5),
        child: CustomVideoProgressBar(
          controller,
          onDragStart: () {
            setState(() {
              _dragging = true;
            });

            _hideTimer?.cancel();
          },
          onDragEnd: () {
            setState(() {
              _dragging = false;
            });

            _startHideTimer();
          },
          colors: customVideoController!.materialProgressColors,
        ),
      ),
    );
  }
}

class _PlaybackSpeedDialog extends StatelessWidget {
  const _PlaybackSpeedDialog({
    Key? key,
    required List<double> speeds,
    required double selected,
  })  : _speeds = speeds,
        _selected = selected,
        super(key: key);

  final List<double> _speeds;
  final double _selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.bottomRight,
      child: Container(
        color: Color(0x77000000),
        width: 67,
        child: ListView.builder(
          shrinkWrap: true,
          physics: const ScrollPhysics(),
          itemBuilder: (context, index) {
            final _speed = _speeds[index];
            return ListTile(
              dense: true,
              title: Text(
                _speed.toString() + "x",
                style: TextStyle(color: _speed == _selected ? Color(0xFFFE6102) : Colors.white),
              ),
              selected: _speed == _selected,
              onTap: () {
                Navigator.of(context).pop(_speed);
              },
            );
          },
          itemCount: _speeds.length,
        ),
      ),
    );
  }
}
