package;

import arcade.World;
import Enemy.EnemyDifficulty;
import ceramic.Group;
import ceramic.Scene;

class MainScene extends Scene {
	// Entities
	var player:Player;
	var enemies:Group<Enemy>;

	// Quiz mechanic
	var quizScene:QuizScene;

	// UI
	var score:Float = 0;

	// Pause logic
	var pauseContainer:PauseCollection;

	override function preload() {
		// Add any asset you want to load here
	}

	override function create() {
		player = new Player(width / 2, height / 2);
		add(player);

		enemies = new Group<Enemy>();
		for (i in 0...5) {
			var isHard = Math.random() <= 0.5 ? true : false;
			var enemy = new Enemy(50 + i * 80, 50 + i * 40, player.get_playerSpeed(), isHard);
			enemy.target = player;

			add(enemy);
			enemies.add(enemy);
		}

		quizScene = new QuizScene();
		app.onUpdate(this, quizScene.update);
		quizScene.depth = 100;
		add(quizScene);

		pauseContainer = new PauseCollection();

		app.onUpdate(this, updateTimer);
	}

	override function update(delta:Float) {
		player.update(delta);
		for (enemy in enemies.items) {
			enemy.update(delta);
		}

		if (player.isDied) {
			toGameOverScene();
		}

		var world = app.arcade.world;

		overlapEnemiesAndBullet(world);
		overlapEnemiesAndPlayer(world);
	}

	override function resize(width:Float, height:Float) {
		// Called everytime the scene size has changed
	}

	override function destroy() {
		// Perform any cleanup before final destroy

		super.destroy();
	}

	// Pause and unpause

	/**
		Pause this scene should be call through this function
	**/
	public function pause() {
		paused = true;
		pauseContainer.add(player);
		for (enemy in enemies.items) {
			pauseContainer.add(enemy);
			enemy.triggerTimer();
		}
		for (bullet in player.bullets.items) {
			pauseContainer.add(bullet);
			bullet.triggerTimer();
		}

		app.onUpdate(this, pauseContainer.update);
	}

	public function unPause() {
		paused = false;
		for (enemy in enemies.items) {
			enemy.triggerTimer();
		}
		for (bullet in player.bullets.items) {
			bullet.triggerTimer();
		}

		pauseContainer.unpause();
		pauseContainer.clear();
		app.offUpdate(pauseContainer.update);
	}

	// Switch between scene

	function toGameOverScene() {
		app.scenes.main = new GameOverScene();
	}

	function toMenuScene() {
		app.scenes.main = new MenuScene();
	}

	// Timer loop
	function updateTimer(delta:Float) {
		@:privateAccess(Timer)
		Timer.update(delta, app.realDelta);
	}

	// Game event

	function overlapEnemiesAndBullet(world:World) {
		for (enemy in enemies.items) {
			for (bullet in player.bullets.items) {
				if (!world.overlap(enemy, bullet)) {
					continue;
				}

				enemy.takeDamage(bullet.damage);
				bullet.destroy();

				if (enemy.health <= 0) {
					handleEnemyDie(enemy);
					break;
				}
			}
		}
	}

	function overlapEnemiesAndPlayer(world:World) {
		for (enemy in enemies.items) {
			if (!world.overlap(enemy, player))
				continue;

			quizScene.setup(enemy, receiveAnswer);
			enemy.destroy();
			pause();
			break;
		}
	}

	// Question and Answer
	public function receiveAnswer(correct:Bool, difficulty:EnemyDifficulty) {
		if (correct) {
			handleCorrect(correct, difficulty);
		}

		if (!correct) {
			handleIncorrect(correct, difficulty);
		}

		unPause();
	}

	function handleCorrect(correct:Bool, difficulty:EnemyDifficulty) {
		switch (difficulty) {
			case EASY:
				{
					score += 0.5;
				}
			case HARD:
				{
					score += 1.0;
					player.heal(0.5);
				}
		}
	}

	function handleIncorrect(correct:Bool, difficulty:EnemyDifficulty) {
		switch (difficulty) {
			case EASY:
				{
					player.takeDamage(1);
				}
			case HARD:
				{
					player.takeDamage(2);
				}
		}
	}

	function handleEnemyDie(enemy:Enemy) {
		var difficulty = enemy.difficulty;
		switch (difficulty) {
			case EASY:
				{
					score += 0.5 * 0.25;
				}
			case HARD:
				{
					score += 1.0 * 0.25;
				}
		}
	}
}
