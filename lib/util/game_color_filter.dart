import 'package:bonfire/base/rpg_game.dart';
import 'package:flame/components/mixins/has_game_ref.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';

class GameColorFilter with HasGameRef<RPGGame> {
  Color color;
  BlendMode blendMode;
  ColorTween _tween;

  GameColorFilter({this.color, this.blendMode});

  bool get enable => color != null && blendMode != null;

  void animateTo(
    Color color,
    BlendMode blendMode, {
    Duration duration = const Duration(milliseconds: 500),
    Curve curve = Curves.decelerate,
  }) {
    this.blendMode = blendMode;
    _tween = ColorTween(begin: this.color ?? Colors.transparent, end: color);

    gameRef.getValueGenerator(
      duration ?? Duration(seconds: 1),
      onChange: (value) {
        this.color = _tween.transform(value);
      },
      onFinish: () {
        this.color = color;
      },
      curve: curve,
    ).start();
  }
}