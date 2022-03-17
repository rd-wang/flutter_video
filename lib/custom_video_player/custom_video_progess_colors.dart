import 'package:flutter/material.dart';

class CustomVideoProgressColors {
  CustomVideoProgressColors({
    Color playedColor = const Color(0xFFFFFFFF),
    Color bufferedColor = Colors.transparent,
    Color handleColor = const Color(0xFFFFFFFF),
    Color backgroundColor = const  Color(0x80FFFFFF),
  })  : playedPaint = Paint()..color = playedColor,
        bufferedPaint = Paint()..color = bufferedColor,
        handlePaint = Paint()..color = handleColor,
        backgroundPaint = Paint()..color = backgroundColor;

  final Paint playedPaint;
  final Paint bufferedPaint;
  final Paint handlePaint;
  final Paint backgroundPaint;
}
