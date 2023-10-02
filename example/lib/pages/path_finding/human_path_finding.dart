import 'package:bonfire/bonfire.dart';
import 'package:example/pages/enemy/human_with_collision.dart';

class HumanPathFinding extends HumanWithCollision with PathFinding, TapGesture {
  HumanPathFinding({required Vector2 position}) : super(position: position) {
    setupMoveToPositionAlongThePath(
      pathLineStrokeWidth: 2,
    );
  }

  @override
  void onTap() {}

  @override
  void onTapDownScreen(TapGestureEvent event) {
    moveToPositionWithPathFinding(event.worldPosition);
    super.onTapDownScreen(event);
  }
}
