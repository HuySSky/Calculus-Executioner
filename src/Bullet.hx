package;

import ceramic.Assets;
import ceramic.SpriteSheet;
import ceramic.Sprite;
import ceramic.StateMachine;

using ceramic.SpritePlugin;

enum State {
	idle;
	splash;
}

class Bullet extends Sprite {
	// Properties
	private final baseSpeed:Float = 625.0; // pixels per second
	private final lifespan:Float = 0.75; // seconds

	public var damage(get, null):Float;

	// Bullet size
	private final bulletWidth:Float = 8.0;
	private final bulletHeight:Float = 8.0;

	// Stop timer
	var _killBullet:() -> Void = null;
	var _endSplash:() -> Void = null;

	@component var machine = new StateMachine<State>();

	public function new(assets:Assets, x:Float = 0, y:Float = 0, angle:Float = 0) {
		if (assets == null) {
			log.error('Failed to shoot bullet, assets not found');
			return;
		}

		super();

		initArcadePhysics();

		this.x = x;
		this.y = y;
		anchor(0.5, 0.5);

		sheet = assets.sheet(Sprites.INK);
		loop = true;
		animation = 'idle';

		_killBullet = Timer.delay(this, lifespan, () -> {
			machine.state = splash;
		});
		velocity(baseSpeed, 0);
		setDirection(angle);

		machine.state = idle;
		onOverlap(this, (visual1, visual2) -> {
			machine.state = splash;
		});
	}

	override public function destroy() {
		super.destroy();
	}

	function get_damage():Float {
		return Math.random() * 0.25 + 0.75;
	}

	public function setDirection(angle:Float) {
		var speedX = velocityX;
		var speedY = velocityY;

		this.rotation = angle * 180 / Math.PI + 90;
		this.velocityX = Math.cos(angle) * speedX - Math.sin(angle) * speedY;
		this.velocityY = Math.sin(angle) * speedX + Math.cos(angle) * speedY;
	}

	public function triggerTimer() {
		if (_killBullet != null) {
			_killBullet();
		}
		if (_endSplash != null) {
			_endSplash();
		}
		paused = !paused;
	}

	function idle_enter() {
		loop = true;
		animation = "idle";
	}

	function splash_enter() {
		stop();

		loop = false;
		animation = "splash";
		_endSplash = Timer.delay(this, 0.7, () -> {
			destroy();
		});
	}
}
