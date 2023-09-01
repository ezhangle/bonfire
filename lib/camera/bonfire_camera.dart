import 'dart:math';

import 'package:bonfire/bonfire.dart';
import 'package:bonfire/camera/camera_effects.dart';
import 'package:flame/experimental.dart';

// Custom implmentation of Flame's `CameraComponent`
class BonfireCamera extends CameraComponent with BonfireHasGameRef {
  double _spacingMap = 32.0;
  final CameraConfig config;
  BonfireCamera({
    required super.world,
    required this.config,
    super.hudComponents,
    super.viewport,
  }) {
    viewfinder.zoom = config.zoom;
    viewfinder.angle = config.angle;
    if (config.target != null) {
      follow(config.target!, snap: true);
    }
  }

  Rect get cameraRectWithSpacing => visibleWorldRect.inflate(_spacingMap);

  Vector2 get position => viewfinder.position;
  set position(Vector2 position) => viewfinder.position = position;
  Vector2 get topleft => visibleWorldRect.positionVector2;

  double get zoom => viewfinder.zoom;
  set zoom(double scale) => viewfinder.zoom = scale;

  bool canSeeWithMargin(PositionComponent component) {
    return cameraRectWithSpacing.overlaps(component.toAbsoluteRect());
  }

  void updateSpacingVisibleMap(double space) {
    _spacingMap = space;
  }

  void moveTop(double displacement) {
    position = position.translated(0, displacement * -1);
  }

  void moveRight(double displacement) {
    position = position.translated(displacement, 0);
  }

  void moveLeft(double displacement) {
    position = position.translated(displacement * -1, 0);
  }

  void moveDown(double displacement) {
    position = position.translated(0, displacement);
  }

  void moveUp(double displacement) {
    position = position.translated(displacement * -1, 0);
  }

  void moveToPositionAnimated({
    required Vector2 position,
    EffectController? effectController,
    double? zoom,
    double? angle,
    Function()? onComplete,
  }) {
    stop();
    var controller = effectController ?? EffectController(duration: 1);
    final moveToEffect = MoveToEffect(
      position,
      controller,
      onComplete: onComplete,
    );
    viewfinder.add(moveToEffect);
    if (zoom != null) {
      final zoomEffect = ScaleEffect.to(
        Vector2.all(zoom),
        controller,
      );
      zoomEffect.removeOnFinish = true;
      viewfinder.add(zoomEffect);
    }
    if (angle != null) {
      final rotateEffect = RotateEffect.to(
        angle,
        controller,
      );
      rotateEffect.removeOnFinish = true;
      viewfinder.add(rotateEffect);
    }
  }

  void moveToTargetAnimated({
    required PositionComponent target,
    EffectController? effectController,
    double? zoom,
    double? angle,
    Function()? onComplete,
    bool followTarget = true,
  }) {
    moveToPositionAnimated(
      position: target.position,
      effectController: effectController,
      zoom: zoom,
      angle: angle,
      onComplete: () {
        if (followTarget) {
          follow(target);
        }
        onComplete?.call();
      },
    );
  }

  void moveToPlayer({
    bool snap = true,
  }) {
    gameRef.player.let((i) {
      follow(i, snap: snap);
    });
  }

  @override
  void follow(
    PositionProvider target, {
    double maxSpeed = double.infinity,
    bool horizontalOnly = false,
    bool verticalOnly = false,
    bool snap = false,
  }) {
    stop();
    viewfinder.add(
      MyFollowBehavior(
        target: target,
        owner: viewfinder,
        maxSpeed: config.speed,
        movementWindow: config.movementWindow,
      ),
    );
    if (snap) {
      viewfinder.position = target.position;
    }
  }

  void moveToPlayerAnimated({
    required EffectController effectController,
    Function()? onComplete,
    double? zoom,
    double? angle,
  }) {
    gameRef.player.let((i) {
      moveToTargetAnimated(
        target: i,
        effectController: effectController,
        zoom: zoom,
        angle: angle,
        onComplete: () {
          onComplete?.call();
          follow(i);
        },
      );
    });
  }

  void animateZoom({
    required Vector2 zoom,
    required EffectController effectController,
    Function()? onComplete,
  }) {
    final zoomEffect = ScaleEffect.to(
      zoom,
      effectController,
      onComplete: onComplete,
    );
    zoomEffect.removeOnFinish = true;
    viewfinder.add(zoomEffect);
  }

  void animateAngle({
    required double angle,
    required EffectController effectController,
    Function()? onComplete,
  }) {
    final rotateEffect = RotateEffect.to(
      angle,
      effectController,
      onComplete: onComplete,
    );
    rotateEffect.removeOnFinish = true;
    viewfinder.add(rotateEffect);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    updatesetBounds(size);
  }

  void updatesetBounds(Vector2? size) {
    Vector2 sizeScreen = size ?? viewport.size;
    switch (config.initialMapZoomFit) {
      case InitialMapZoomFitEnum.none:
        break;
      case InitialMapZoomFitEnum.fitWidth:
        zoom = sizeScreen.x / gameRef.map.getMapSize().x;
        break;
      case InitialMapZoomFitEnum.fitHeight:
        zoom = sizeScreen.y / gameRef.map.getMapSize().y;
        break;
      case InitialMapZoomFitEnum.cover:
        double minScreenDimension = min(sizeScreen.x, sizeScreen.y);
        double minMapDimension = min(
          gameRef.map.getMapSize().x,
          gameRef.map.getMapSize().y,
        );
        zoom = minScreenDimension / minMapDimension;
        break;
    }
    if (config.moveOnlyMapArea && viewfinder.isMounted) {
      setBounds(
        Rectangle.fromRect(
          gameRef.map.getMapRect().deflatexy(
                visibleWorldRect.width / 2,
                visibleWorldRect.height / 2,
              ),
        ),
      );
    }
  }

  Vector2 worldToScreen(Vector2 worldPosition) {
    return (worldPosition - topleft) * zoom;
  }

  Vector2 screenToWorld(Vector2 position) {
    return topleft + (position / zoom);
  }

  void shake({double intensity = 10.0, Duration? duration}) {
    viewfinder.add(
      ShakeEffect(
        intensity: intensity,
        duration: duration ?? const Duration(milliseconds: 300),
      ),
    );
  }
}
