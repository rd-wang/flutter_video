# roobo_video

自定义样式的videoplayer

## Getting Started

## use
```text
            RooboVideoWidget(
                  url: items.record.url,
                  title: items.record.name,
                  isNoNet: () {
                    return NetState.getInstance.netResult == NetConnectResult.none;
                  },
                  videoListener: RooboVideoStateListener(
                    onVideoPause: (pauseTime, totalTime) {
                      int currentProgress = (pauseTime.inMilliseconds / totalTime.inMilliseconds) as int;
                      if (currentProgress > items.progress.progress) {
                        uploadProgress(items.recordID, currentProgress, items.id).then((value) {
                          setState(() {
                            progressMap[items.recordID] = value;
                          });
                        });
                      }
                    },
                    onVideoFinished: () {},
                  ),
                  startPlay: (MediaController controller) {
                    // stop
                    if (_preMediaController == null) {
                      _preMediaController = controller;
                    } else {
                      if (_preMediaController != controller) {
                        _preMediaController.stopMediaPlay();
                        Future.delayed(Duration(milliseconds: 50), () {
                          _preMediaController = controller;
                        });
                      }
                    }
                  },
                ),
```
