# roobo_video

自定义样式的videoplayer

## Getting Started

## use
```text
 VideoPlayerController _videoPlayerController;
    CustomVideoController _customVideoController;

    _videoPlayerController = VideoPlayerController.network(widget.urlString);
    await _videoPlayerController.initialize();
    _customVideoController = CustomVideoController(
      videoPlayerController: _videoPlayerController,
      autoPlay: true,
      looping: false,
      customControls: VideoControlWidget(),
      showControls: true,
    );
```
