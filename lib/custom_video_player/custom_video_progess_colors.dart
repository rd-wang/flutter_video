import 'package:flutter/material.dart';

class CustomVideoProgressColors {
  CustomVideoProgressColors({
    Color playedColor = const Color.fromRGBO(255, 98, 0, 1),
    Color bufferedColor = Colors.transparent,
    Color handleColor = const Color.fromRGBO(255, 98, 0, 1),
    Color backgroundColor = const Color.fromRGBO(34, 34, 34, 0.9),
  })  : playedPaint = Paint()..color = playedColor,
        bufferedPaint = Paint()..color = bufferedColor,
        handlePaint = Paint()..color = handleColor,
        backgroundPaint = Paint()..color = backgroundColor;

  final Paint playedPaint;
  final Paint bufferedPaint;
  final Paint handlePaint;
  final Paint backgroundPaint;
}
