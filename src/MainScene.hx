package;

import elements.Im;
import ceramic.Sound;
import ceramic.SoundPlayer;
import ceramic.Color;
import ceramic.Quad;
import ceramic.Visual;
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
	var pausedFromSetting:Bool = false;

	// Game progress
	var spawnDelay:Float = 6;
	final spawnMax:Float = 6;
	final spawnMin:Float = 1.25;
	final spawnRampTime:Float = 5 * 60;
	var spawnRate:Float;
	var spawnProgress:Visual;
	var spawnBar:Quad;
	var spawnEnemyTime:Float = 2;

	var difficulty:Float = 0.3;
	final difficultyMin:Float = 0.3;
	final difficultyMax:Float = 1.0;
	final difficultyRampTime:Float = 10 * 60;
	var difficultyRate:Float;
	var difficultyProgress:Visual;
	var difficultyBar:Quad;

	// Setting button
	var setting:Setting;

	// Audio
	var backgroundMusic:SoundPlayer;
	var gunshotAudio:Sound;

	override function preload() {
		// Add any asset you want to load here
		assets.addAll(~/^Questions\/.*$/);
		assets.add(Sounds.BATTLE_THEME, null, {stream: true});
		assets.add(Sounds.GUN_SHOT_EFFECT_1_5X);
	}

	override function create() {
		QuestionPool.loadAllSubjects(assets);
		player = new Player(width / 2, height / 2);
		player.body.collideWorldBounds = true;
		add(player);

		enemies = new Group<Enemy>();

		quizScene = new QuizScene();
		app.onUpdate(this, quizScene.update);
		quizScene.depth = 100;
		add(quizScene);

		pauseContainer = new PauseCollection();
		setting = new Setting();
		setting.depth = 100;
		setting.onPaused(this, () -> {
			pausedFromSetting = true;
			quizScene.touchable = false;
			pause();
		});
		setting.onUnpaused(this, () -> {
			pausedFromSetting = false;
			quizScene.touchable = true;
			unPause();
		});
		add(setting);

		prepareAudio();

		initGameProgress();

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
		spawnEnemyTime -= delta;
		if (spawnEnemyTime <= 0) {
			spawnEnemyTime = spawnDelay;
			spawnEnemy();
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
		enemies.destroy();
		player.destroy();

		pauseContainer.clear();
		pauseContainer = null;

		super.destroy();
	}

	// Game audio

	function prepareAudio() {
		backgroundMusic = assets.sound(Sounds.BATTLE_THEME).play(0, true);
		gunshotAudio = assets.sound(Sounds.GUN_SHOT_EFFECT_1_5X);
		gunshotAudio.volume = 0.25;

		player.onShot(player, () -> {
			gunshotAudio.play();
		});

		app.onUpdate(this, delta -> {
			if (setting.settingScreen.active) {
				audioSetting();
			}
		});
	}

	function audioSetting() {
		Im.begin("Volume mixer", 250);
		Im.slideFloat("Background music", Im.float(backgroundMusic.volume), 0, 1, 100);
		Im.slideFloat("Gun shot effect", Im.float(gunshotAudio.volume), 0, 1, 100);
		Im.end();
	}

	// Game progress

	function initGameProgress() {
		spawnRate = (spawnMax - spawnMin) / spawnRampTime;
		difficultyRate = (difficultyMax - difficultyMin) / difficultyRampTime;

		initVisualGameProgress();
		app.onUpdate(this, (delta) -> {
			if (this.paused && this.pausedFromSetting)
				return;

			spawnDelay -= spawnRate * delta;
			if (spawnDelay < spawnMin) {
				spawnDelay = spawnMin;
			}

			difficulty += difficultyRate * delta;
			if (difficulty > difficultyMax) {
				difficulty = difficultyMax;
			}

			updateProgressbar();
		});
	}

	function initVisualGameProgress() {
		spawnProgress = new Visual();
		difficultyProgress = new Visual();

		var spawnBarBackground = new Quad();
		spawnBarBackground.color = 0x69777777;
		spawnBarBackground.size(width, height * .025);
		spawnProgress.add(spawnBarBackground);

		spawnBar = new Quad();
		spawnBar.size(0, height * .025);
		spawnBar.color = Color.LIME;
		spawnBar.y = (spawnBarBackground.height - spawnBar.height) / 2;
		spawnBarBackground.add(spawnBar);

		add(spawnProgress);
		spawnProgress.pos(0, height * .9);
		spawnProgress.depth = -1;

		var difficultyBarBackground = new Quad();
		difficultyBarBackground.color = 0x69777777;
		difficultyBarBackground.size(width, height * .025);
		difficultyProgress.add(difficultyBarBackground);

		difficultyBar = new Quad();
		difficultyBar.size(0, height * .025);
		difficultyBar.color = Color.ORANGE;
		difficultyBar.y = (difficultyBarBackground.height - difficultyBar.height) / 2;
		difficultyBarBackground.add(difficultyBar);

		add(difficultyProgress);
		difficultyProgress.pos(0, height * 0.95);
		difficultyProgress.depth = -1;
	}

	function updateProgressbar() {
		spawnBar.width = width * ((spawnMax - spawnDelay) / (spawnMax - spawnMin));
		difficultyBar.width = width * (difficulty / difficultyMax);
	}

	/**
		Spawn enemy
	**/
	function spawnEnemy() {
		var isHard = Math.random() <= difficulty ? true : false;
		var x = width;
		var y = height;

		if (Math.random() < 0.5) {
			x *= Math.random() < 0.5 ? 0 : 1;
			y *= Math.random();
		} else {
			x *= Math.random();
			y *= Math.random() < 0.5 ? 0 : 1;
		}

		var percentProgress = (spawnMax - spawnDelay) / (spawnMax - spawnMin);
		var enemySpeed = player.get_playerSpeed() * (1 + percentProgress / 3);
		var enemy = new Enemy(x, y, enemySpeed, QuestionPool.SUBJECTS[3], isHard);

		if (enemy.destroyed) {
			return;
		}

		enemy.target = player;

		add(enemy);
		enemies.add(enemy);
	}

	// Pause and unpause

	/**
		Pause this scene should be call through this function
	**/
	public function pause() {
		if (paused == true) {
			return;
		}

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
		if (quizScene.active == true || pausedFromSetting == true) {
			return;
		}

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
					player.heal(0.25);
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
		var difficulty = enemy.questionData.difficulty;
		switch (difficulty) {
			case EASY:
				{
					score += 0.5 * 0.2;
				}
			case HARD:
				{
					score += 1.0 * 0.2;
				}
		}
	}
}
