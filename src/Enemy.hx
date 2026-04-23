package;

import tracker.Observable;
import ceramic.Color;
import ceramic.Visual;
import ceramic.Quad;

enum abstract EnemyDifficulty(Int) {
	var EASY = 0;
	var HARD = 1;

	@:to
	public function toString():String {
		return switch (cast this : EnemyDifficulty) {
			case EASY: 'easy';
			case HARD: 'hard';
			case _: 'unknown';
		}
	}

	public static function fromString(str:String):EnemyDifficulty {
		return str.toLowerCase() == "hard" ? HARD : EASY;
	}
}

class Enemy extends Quad implements Observable {
	// Health property with getter/setter
	@observe @:isVar public var health(get, set):Float = -1;

	var maxHealth:Float;
	var baseSpeed:Float;

	// Question data
	public var questionData(get, default) = new QuestionData("Question not loaded", "", EASY);

	// Visuals
	var defaultColor:Color;

	var healthBar:Quad;
	var healthBarBg:Quad;
	var enemySize:Float = 40.0;
	var healthBarWidth:Float = 40.0;
	var healthBarHeight:Float = 4.0;

	// Speed buff
	var hasSpeedBuff:Bool = false;

	var _buffTimer:() -> Void = null;
	var _currentBuff:() -> Void = null;

	// Attack logic
	public var target(default, set):Visual;

	public function new(x:Float, y:Float, playerBaseSpeed:Float, subject:String, isHard:Bool = false) {
		super();

		this.x = x;
		this.y = y;
		anchor(0.5, 0.5);

		initArcadePhysics();
		// Random health between 3-5
		maxHealth = Math.random() * 2 + 3;
		health = maxHealth;
		onHealthChange(this, updateHealthbar);
		onHealthChange(this, checkHealth);

		// Speed: 0.4x-0.6x player speed
		baseSpeed = playerBaseSpeed * (Math.random() * 0.2 + 0.4);

		// Enemy visual
		initHealthbar();
		initVisual(isHard);

		// Setup speed buff for hard difficulty
		if (isHard) {
			questionData.difficulty = HARD;
			_buffTimer = Timer.interval(this, 1, () -> {
				if (Math.random() <= 0.4) { // 40% chance
					activateSpeedBuff();
				}
			});
		}

		// Load question from QuestionPool
		loadQuestion(subject);
	}

	override public function destroy() {
		super.destroy();
	}

	public function update(delta:Float) {
		updateVelocity();
	}

	private function updateVelocity() {
		var dx = target.x - x;
		var dy = target.y - y;
		var length = Math.sqrt(dx * dx + dy * dy);
		dx /= length;
		dy /= length;

		var velX = baseSpeed * dx;
		var velY = baseSpeed * dy;

		if (hasSpeedBuff) {
			velX *= 3;
			velY *= 3;
		}

		velocity(velX, velY);
	}

	/**
		Load a random question from QuestionPool for this subject and difficulty
	**/
	function loadQuestion(subject:String) {
		var q = QuestionPool.getRandomQuestion(subject, questionData.difficulty);

		if (q == null) {
			log.error('ERROR: Could not load question for $subject ($q.difficulty)');
			// Destroy this enemy and add no score
			destroy();
			return;
		}

		questionData.question = q.question;
		questionData.answer = q.answer;
	}

	// Initialize sprite

	/**
		Display Health bar of the enemy
		%health: [50, 100] -> Green
		%health: [25, 50) -> Yellow
		%health: [0, 25) -> Red
	**/
	function initHealthbar() {
		// Create health bar background
		healthBarBg = new Quad();
		healthBarBg.width = healthBarWidth;
		healthBarBg.height = healthBarHeight;
		healthBarBg.color = 0x333333;
		healthBarBg.y = -15;
		add(healthBarBg);

		// Create health bar
		healthBar = new Quad();
		healthBar.width = healthBarWidth;
		healthBar.height = healthBarHeight;
		healthBar.color = 0x00FF00;
		healthBarBg.add(healthBar);
	}

	/**
		Display enemy texture
	**/
	function initVisual(isHard:Bool = false) {
		// Create main visual
		defaultColor = isHard ? 0xFF0000 : 0xFF6600;
		width = enemySize;
		height = enemySize;
		color = defaultColor;
		size(enemySize, enemySize);
	}

	// Speed buff logic

	/**
		Apply speed buff.
		Automatically remove the buff after 1 second.
	**/
	function activateSpeedBuff() {
		hasSpeedBuff = true;
		color = 0xFFFF00; // Visual feedback

		// Deactivate after 1 second
		_currentBuff = Timer.delay(this, 1, () -> {
			hasSpeedBuff = false;
			color = defaultColor;
			_currentBuff = null;
		});
	}

	// Health bar

	/**
		Update status of the health bar.
		Auto call on health change.
	**/
	private function updateHealthbar(pre:Float, cur:Float) {
		// Update health bar
		var percent = health / maxHealth;
		healthBar.width = healthBarWidth * percent;

		if (percent >= 0.5) {
			healthBar.color = 0x00FF00;
		} else if (percent > 0.25) {
			healthBar.color = 0xFFFF00;
		} else {
			healthBar.color = 0xFF0000;
		}
	}

	/**
		Check status of the enemy.
		If health <= 0: The enemy die.
	**/
	private function checkHealth(pre:Float, cur:Float) {
		if (cur <= 0) {
			destroy();
		}
	}

	/**
		Deal damage to the enemy. Return difficulty if enemy died.
	**/
	public function takeDamage(damage:Float) {
		health -= damage;
		if (health <= 0) {
			checkHealth(health + damage, health);
		}
	}

	// To string
	override public function toString() {
		var out:String = "";
		out += 'Question: ${questionData.question}\n';
		out += 'Answer: ${questionData.answer}\n';
		out += 'Health: $health\n';
		out += 'Difficulty: ${questionData.difficulty}\n';

		return out;
	}

	// Stop timer function
	public function triggerTimer() {
		if (_buffTimer != null) {
			_buffTimer();
		}

		if (_currentBuff != null) {
			_currentBuff();
		}
	}

	// Health property
	function get_health():Float {
		return health;
	}

	function set_health(value:Float):Float {
		health = value;
		return health;
	}

	function set_target(value:Visual):Visual {
		return target = value;
	}

	function get_questionData() {
		return questionData;
	}
}
