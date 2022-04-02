typedef MediaEnablePlay = void Function(bool canPlay);
typedef MediaStopPlay = Future<void> Function();
typedef MediaInitCompleted = void Function(MediaController mediaController);
typedef MediaStartPlay = void Function(MediaController mediaController);

class MediaWidgetListener {
  MediaEnablePlay videoEnablePlay;
  MediaStopPlay videoStopPlay;

  MediaWidgetListener({this.videoEnablePlay, this.videoStopPlay});
}

// 外部控制
class MediaController {
  MediaWidgetListener _videoWidgetListener;

  setMediaEnablePlay(bool canPlay) {
    if (this._videoWidgetListener != null) {
      if (this._videoWidgetListener.videoEnablePlay != null) {
        this._videoWidgetListener.videoEnablePlay(canPlay);
      }
    }
  }

  Future<void> stopMediaPlay() async {
    if (this._videoWidgetListener != null) {
      if (this._videoWidgetListener.videoStopPlay != null) {
        await this._videoWidgetListener.videoStopPlay();
      }
    }
  }

  dfasdf() {
    // fff
  }

  addListener(MediaWidgetListener listener) {
    this._videoWidgetListener = listener;
  }
}
