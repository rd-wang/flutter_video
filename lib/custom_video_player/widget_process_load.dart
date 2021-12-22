import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

enum ProgressLoadType { ThreeBounce, Circle, FadingCircle, Ring, WhiteFadingCircle }

class ProgressLoadWidget extends StatelessWidget {
  final ProgressLoadType type;

  const ProgressLoadWidget({Key key, this.type}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case ProgressLoadType.ThreeBounce:
        return SpinKitThreeBounce(
          color: Colors.white,
          size: 50.0,
        );
      case ProgressLoadType.Circle:
        return SpinKitCircle(
          color: Colors.white,
          size: 50.0,
        );
      case ProgressLoadType.FadingCircle:
        return SpinKitFadingCircle(
          color: Colors.black38,
          size: 50.0,
        );
      case ProgressLoadType.WhiteFadingCircle:
        return SpinKitFadingCircle(
          color: Colors.white,
          size: 50.0,
        );
      case ProgressLoadType.Ring:
        return SpinKitRing(
          color: Colors.white,
          size: 50.0,
        );
    }
    return SpinKitFadingCircle(
      color: Colors.white,
      size: 50.0,
    );
  }
}
