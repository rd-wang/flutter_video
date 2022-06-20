import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:video_player/video_player.dart';
import 'custom_video_progess_colors.dart';

class CustomVideoProgressBar extends StatefulWidget {
  CustomVideoProgressBar(
    this.controller, {
    CustomVideoProgressColors? colors,
    this.onDragEnd,
    this.onDragStart,
    this.onDragUpdate,
    Key? key,
  })  : colors = colors ?? CustomVideoProgressColors(),
        super(key: key);

  final VideoPlayerController? controller;
  final CustomVideoProgressColors colors;
  final Function()? onDragStart;
  final Function()? onDragEnd;
  final Function()? onDragUpdate;

  @override
  _CustomVideoProgressBarState createState() {
    return _CustomVideoProgressBarState();
  }
}

class _CustomVideoProgressBarState extends State<CustomVideoProgressBar> {
  void listener() {
    if (!mounted) return;
    setState(() {});
  }

  bool _controllerWasPlaying = false;

  VideoPlayerController? get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    controller!.addListener(listener);
  }

  @override
  void deactivate() {
    controller!.removeListener(listener);
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    void seekToRelativePosition(Offset globalPosition) {
      final box = context.findRenderObject() as RenderBox;
      final Offset tapPos = box.globalToLocal(globalPosition);
      final double relative = tapPos.dx / box.size.width;
      final Duration position = controller!.value.duration * relative;
      controller!.seekTo(position);
    }

    return GestureDetector(
      onHorizontalDragStart: (DragStartDetails details) {
        if (!controller!.value.isInitialized) {
          return;
        }
        _controllerWasPlaying = controller!.value.isPlaying;
        // if (_controllerWasPlaying) {
        //   controller.pause();
        // }

        widget.onDragStart?.call();
      },
      onHorizontalDragUpdate: (DragUpdateDetails details) {
        if (!controller!.value.isInitialized) {
          return;
        }
        seekToRelativePosition(details.globalPosition);

        widget.onDragUpdate?.call();
      },
      onHorizontalDragEnd: (DragEndDetails details) {
        // if (_controllerWasPlaying) {
        //   controller.play();
        // }

        widget.onDragEnd?.call();
      },
      onTapDown: (TapDownDetails details) {
        if (!controller!.value.isInitialized) {
          return;
        }
        seekToRelativePosition(details.globalPosition);
      },
      child: Container(
        height: MediaQuery.of(context).size.height / 2,
        width: MediaQuery.of(context).size.width,
        child: CustomPaint(
          painter: _ProgressBarPainter(
            controller!.value,
            widget.colors,
          ),
        ),
      ),
    );
  }
}

class _ProgressBarPainter extends CustomPainter {
  _ProgressBarPainter(this.value, this.colors);

  VideoPlayerValue value;
  CustomVideoProgressColors colors;

  @override
  bool shouldRepaint(CustomPainter painter) {
    return true;
  }

  @override
  void paint(Canvas canvas, Size size) {
    const height = 2.0;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromPoints(
          Offset(0.0, size.height / 2),
          Offset(size.width, size.height / 2 + height),
        ),
        const Radius.circular(4.0),
      ),
      colors.backgroundPaint,
    );
    if (!value.isInitialized) {
      return;
    }
    final double playedPartPercent = value.position.inMilliseconds / value.duration.inMilliseconds;
    final double playedPart = playedPartPercent > 1 ? size.width : playedPartPercent * size.width;
    final double play = playedPartPercent > 1 ? (size.width - 13) : playedPartPercent * (size.width - 13);

    for (final DurationRange range in value.buffered) {
      final double start = range.startFraction(value.duration) * size.width;
      final double end = range.endFraction(value.duration) * size.width;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromPoints(
            Offset(start, size.height / 2),
            Offset(end, size.height / 2 + height),
          ),
          const Radius.circular(4.0),
        ),
        colors.bufferedPaint,
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromPoints(
          Offset(0.0, size.height / 2),
          Offset(playedPart, size.height / 2 + height),
        ),
        const Radius.circular(4.0),
      ),
      colors.playedPaint,
    );
    Offset offset = Offset(playedPart + 6.5, size.height / 2 + height / 2);
    if (playedPart > 1) {
      offset = Offset(playedPart - 6.5, size.height / 2 + height / 2);
    }
    // canvas.drawRRect(
    //   RRect.fromRectAndRadius(
    //     Rect.fromCenter(center: Offset(play + 6.5, size.height / 2 + height / 2), width: 13, height: 17),
    //     const Radius.circular(9.0),
    //   ),
    //   colors.handlePaint,
    // );

   canvas.drawCircle(
     Offset(playedPart+.5, size.height / 2 + height / 2),
     height * 2,
     colors.handlePaint,
   );
  }
}
