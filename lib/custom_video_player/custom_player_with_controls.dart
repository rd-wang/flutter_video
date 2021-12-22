import 'package:flutter/material.dart';
import 'package:roobo_video/custom_video_player/custom_video_player.dart';
import 'package:video_player/video_player.dart';

import 'custom_video_control.dart';

class CustomPlayerWithControls extends StatelessWidget {
  const CustomPlayerWithControls({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final CustomVideoController customVideoController = CustomVideoController.of(context);

    double _calculateAspectRatio(BuildContext context) {
      final size = MediaQuery.of(context).size;
      final width = size.width;
      final height = size.height;

      return width > height ? width / height : height / width;
    }

    Widget _buildControls(
      BuildContext context,
      CustomVideoController customVideoController,
    ) {
      final controls = VideoControlWidget();
      return customVideoController.showControls ? customVideoController.customControls ?? controls : Container();
    }

    Stack _buildPlayerWithControls(CustomVideoController customVideoController, BuildContext context) {
      return Stack(
        children: <Widget>[
          customVideoController.placeholder ?? Container(),
          Center(
            child: AspectRatio(
              aspectRatio: customVideoController.aspectRatio ?? customVideoController.videoPlayerController.value.aspectRatio,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Center(child: VideoPlayer(customVideoController.videoPlayerController)),
                  // _buildControls(context, customVideoController),
                ],
              ),
            ),
          ),
          // customVideoController.overlay ?? Container(),
          // if (!customVideoController.isFullScreen)
          _buildControls(context, customVideoController)
          // else
          //   SafeArea(
          //     child: _buildControls(context, customVideoController),
          //   ),
        ],
      );
    }

    return Center(
      child: SizedBox(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: AspectRatio(
          aspectRatio: _calculateAspectRatio(context),
          child: _buildPlayerWithControls(customVideoController, context),
        ),
      ),
    );
  }
}
