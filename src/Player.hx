package;

import ceramic.Sound;
import ceramic.Group;
import ceramic.Quad;
import ceramic.InputMap;

enum abstract PlayerInput(Int) {
	var LEFT;
	var UP;
	var DOWN;
	var RIGHT;
	var PRESS;
}

class Player extends Quad {
	// Properties
	private var health:Float = 3.0;
	private final baseSpeed:Float = 200.0; // pixels per second

	public var isDied(get, default):Bool = false;

	// Shooting properties
	private var shootCooldown:Float = 0.0;
	private final shootCooldownRate:Float = 0.325; // seconds

	@event function shot();

	// Bullets group
	@:isVar public var bullets(get, null):Group<Bullet> = new Group<Bullet>();

	// Position bounds
	private final playerWidth:Float = 32.0;
	private final playerHeight:Float = 32.0;

	// Player moving logic
	var input = new InputMap<PlayerInput>();

	public function new(x:Float = 0, y:Float = 0) {
		super();
		initArcadePhysics();

		this.x = x;
		this.y = y;

		anchor(0.5, 0.5);
		width = playerWidth;
		height = playerHeight;
		color = 0xFF0000;

		bindInput();
	}

	public function update(delta:Float) {
		// Handle movement
		handleMovement(delta);

		// Handle shooting
		handleShooting(delta);
	}

	/**
	 * Handle WASD movement
	 */
	private function handleMovement(delta:Float) {
		var moveX:Float = 0;
		var moveY:Float = 0;

		// W - Up
		if (input.pressed(UP)) {
			moveY -= baseSpeed;
		}

		// S - Down
		if (input.pressed(DOWN)) {
			moveY += baseSpeed;
		}

		// A - Left
		if (input.pressed(LEFT)) {
			moveX -= baseSpeed;
		}

		// D - Right
		if (input.pressed(RIGHT)) {
			moveX += baseSpeed;
		}

		// Apply velocity
		velocity(moveX, moveY);
	}

	/**
	 * Handle shooting with mouse clicks
	 */
	private function handleShooting(delta:Float) {
		// Update cooldown
		if (shootCooldown > 0) {
			shootCooldown -= delta;
		}

		if (input.pressed(PRESS)) {
			if (shootCooldown <= 0) {
				shoot();
				shootCooldown = shootCooldownRate;
			}
		}
	}

	/**
	 * Create and fire a bullet from player position
	 */
	private function shoot() {
		// Create bullet at player center position
		var x = app.screen.pointerX;
		var y = app.screen.pointerY;
		var angle = Math.atan2(y - this.y, x - this.x);
		var bullet = new Bullet(this.x, this.y, angle);
		bullet.depth = 100;

		// Add bullet to game
		if (parent != null) {
			parent.add(bullet);
		}
		bullets.add(bullet);
		emitShot();
	}

	/**
	 * Take damage from enemy
	 */
	public function takeDamage(damage:Float = 1.0) {
		health -= damage;

		if (health <= 0) {
			health = 0;
			die();
		}
	}

	// Trigger when player die.
	private function die() {
		isDied = true;
	}

	/**
	 * Heal player
	 */
	public function heal(amount:Float) {
		health += amount;
	}

	/**
		Set input key of player.
		Moving: WASD
		Fire bullets: Left mouse
	**/
	private function bindInput() {
		// Bind keyboard input
		input.bindScanCode(UP, KEY_W);
		input.bindScanCode(DOWN, KEY_S);
		input.bindScanCode(LEFT, KEY_A);
		input.bindScanCode(RIGHT, KEY_D);

		// Bind mouse input
		input.bindMouseButton(PRESS, 0);
	}

	public function get_playerSpeed() {
		return baseSpeed;
	}

	function get_bullets():Group<Bullet> {
		return bullets;
	}

	function get_isDied():Bool {
		return isDied;
	}
}
