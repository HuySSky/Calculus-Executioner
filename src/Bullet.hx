package;

import ceramic.Quad;
import ceramic.Scene;

class Bullet extends Quad {
	// Properties
	private final baseSpeed:Float = 625.0; // pixels per second
	private final lifespan:Float = 0.75; // seconds

	public var damage(get, null):Float = 1; // Fixed damage

	// Bullet size
	private final bulletWidth:Float = 8.0;
	private final bulletHeight:Float = 8.0;

	// Stop timer
	var _killBullet:() -> Void = null;

	public function new(x:Float = 0, y:Float = 0, angle:Float = 0) {
		super();

		initArcadePhysics();

		this.x = x;
		this.y = y;
		anchor(0.5, 0.5);

		// Create visual representation
		width = bulletWidth;
		height = bulletHeight;
		color = 0xFFFF00; // Yellow color for bullets

		_killBullet = Timer.delay(this, lifespan, destroy);
		velocity(baseSpeed, 0);
		setDirection(angle);
	}

	override public function destroy() {
		super.destroy();
	}

	function get_damage():Float {
		return damage;
	}

	public function setDirection(angle:Float) {
		var speedX = velocityX;
		var speedY = velocityY;

		this.rotation = angle * 180 / Math.PI;
		this.velocityX = Math.cos(angle) * speedX - Math.sin(angle) * speedY;
		this.velocityY = Math.sin(angle) * speedX + Math.cos(angle) * speedY;
	}

	public function triggerTimer() {
		if (_killBullet != null) {
			_killBullet();
		}
	}
}
