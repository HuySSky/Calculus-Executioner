package;

import ceramic.Json;
import ceramic.Files;
import ceramic.Text;
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

using ceramic.SpritePlugin;

typedef LevelData = {
	var subject:Array<String>;
	var level:String;
}

typedef Result = {
	var score:Float;
	var rating:String;
}

class MainScene extends Scene {
	// Entities
	var player:Player;
	var enemies:Group<Enemy>;

	// Quiz mechanic
	var quizScene:QuizScene;
	var levelData:LevelData;

	// UI and Background
	@observe var score:Float = 0;

	// Pause logic
	var pauseContainer:PauseCollection;
	var pausedFromSetting:Bool = false;

	// Setting button
	var setting:Setting;

	public function new(levelData:LevelData) {
		super();
		this.levelData = levelData;
		log.success("Loaded level: " + levelData.subject);
	}

	override function preload() {
		// Add any asset you want to load here
		assets.add(Sounds.BATTLE_THEME, null, {stream: true});
		assets.add(Sounds.GUN_SHOT_EFFECT_1_5X);
		assets.addAll(~/^Notebook\/.*$/);
		assets.add(Sprites.INK);
	}

	override function create() {
		clip = this;
		initEntities();
		setupEntities();
		prepareAudio();
		initGameUI();
		initGameProgress();

		app.onUpdate(this, updateTimer);
		app.onUpdate(this, setting.update);
	}

	override function update(delta:Float) {
		player.update(delta);
		for (enemy in enemies.items) {
			enemy.update(delta);
		}
		if (grid != null) {
			grid.update(delta * 0.85);
		}

		if (player.isDied) {
			toGameOverScene();
		}
		spawnEnemyTime -= delta;
		if (spawnEnemyTime <= 0) {
			spawnEnemyTime = spawnDelay;
			spawnEnemy();
		}

		if (app.input.keyJustReleased(KEY_P)) {
			score += 0.5;
		}

		var world = app.arcade.world;

		overlapEnemiesAndBullet(world);
		overlapEnemiesAndPlayer(world);
	}

	override function fadeOut(done:() -> Void) {
		save();

		done();
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
		app.offUpdate(updateTimer);
		app.offUpdate(setting.update);

		super.destroy();
	}

	// Init game entity
	var grid:GridBackground;

	function initEntities() {
		player = new Player(width / 2, height / 2);
		enemies = new Group<Enemy>();
		quizScene = new QuizScene();
		pauseContainer = new PauseCollection();
		setting = new Setting();
	}

	function setupEntities() {
		player.body.collideWorldBounds = true;
		player.assets = this.assets;
		add(player);

		app.onUpdate(this, quizScene.update);
		quizScene.depth = 99;
		add(quizScene);

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
		setting.pos(width * 0.015, height * 0.015);
		add(setting);

		if (levelData.level == QuestionPool.SUBJECTS[4]) {
			grid = new GridBackground(width, height);
			grid.depth = -10;
			add(grid);
		} else {
			var paperBackground = new Quad();
			paperBackground.texture = assets.texture('Notebook/${levelData.level}');
			paperBackground.depth = -10;
			paperBackground.alpha = 0.8;
			add(paperBackground);
			if (levelData.level == "UIT") {
				paperBackground.alpha = 0.95;
			}
		}
	}

	// Game UI
	var complete:Text;
	var scoreText:Text;
	var scoreBackground:Quad;
	var healthText:Text;

	function initGameUI() {
		complete = new Text();
		complete.content = "Complete this level";
		complete.pointSize = 30;
		complete.font = app.assets.font(Fonts.ROBOTO_MEDIUM);
		complete.color = 0x08E613;
		complete.anchor(1, 0);
		complete.pos(width * 0.95, height * 0.85);
		complete.onPointerDown(this, info -> {
			toGameOverScene();
		});
		complete.active = false;
		add(complete);

		scoreText = new Text();
		scoreText.pointSize = 28;
		scoreText.content = 'Score: 0';
		scoreText.font = app.assets.font(Fonts.ROBOTO_MEDIUM);
		scoreText.color = getColor(0, levelData);

		onScoreChange(this, (cur, pre) -> {
			cur = Std.int(cur * 100) / 100.0;
			scoreText.content = 'Score: $cur';
			scoreText.color = getColor(cur, levelData);

			if (getRank(score, levelData) == "Xuất sắc") {
				complete.active = true;
			}
		});
		score = 0;

		scoreBackground = new Quad();
		scoreBackground.color = 0x494B6D;
		scoreBackground.size(scoreText.width * 1.5, scoreText.height * 1.25);

		scoreBackground.pos(width * 0.08, height * 0.87);
		scoreText.anchor(0.5, 0.5);
		scoreText.pos(scoreBackground.width * 0.5, scoreBackground.height * 0.5);

		scoreBackground.anchor(0.5, 0.5);
		scoreBackground.alpha = 0.72;
		add(scoreBackground);
		scoreBackground.add(scoreText);

		healthText = new Text();
		healthText.pointSize = 28;
		healthText.content = 'Health: ${player.health}';
		healthText.font = app.assets.font(Fonts.ROBOTO_MEDIUM);
		healthText.color = 0x088A2F;
		healthText.anchor(1, 0);
		healthText.pos(width * 0.97, height * 0.05);
		add(healthText);
		player.onHealthChange(player, () -> {
			healthText.content = 'Health: ${player.health}';
			if (player.health <= 1) {
				healthText.color = 0xE62E0E;
			} else if (player.health <= 2) {
				healthText.color = 0xF3C21F;
			} else if (player.health <= 3) {
				healthText.color = 0x088A2F;
			} else {
				healthText.color = 0x0CD827;
			}
		});
	}

	// Game audio
	var backgroundMusic:SoundPlayer;
	var gunshotAudio:Sound;

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
		Im.begin("Volume mixer", 400);
		Im.slideFloat("Background music", Im.float(backgroundMusic.volume), 0, 1, 100);
		Im.slideFloat("Gun shot effect", Im.float(gunshotAudio.volume), 0, 1, 100);
		Im.end();
	}

	// Game progress
	var spawnDelay:Float = 7;
	var spawnMax:Float = 7;
	var spawnMin:Float = 1.5;
	var spawnRampTime:Float = 10 * 60;
	var spawnRate:Float;
	var spawnProgress:Visual;
	var spawnBar:Quad;
	var spawnEnemyTime:Float = 2;

	var difficulty:Float = 0.1;
	var difficultyMin:Float = 0.1;
	var difficultyMax:Float = 1.0;
	var difficultyRampTime:Float = 15 * 60;
	var difficultyRate:Float;
	var difficultyProgress:Visual;
	var difficultyBar:Quad;

	function initGameProgress() {
		if (levelData.level == QuestionPool.SUBJECTS[4]) {
			spawnDelay = 6;
			spawnMax = 6;
			spawnMin = 1;
			spawnRampTime = 13 * 60;

			difficulty = 0.0;
			difficultyMax = 1.0;
			difficultyMin = 0.0;
			difficultyRampTime = 20 * 60;
		}

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
		var pickSubject = Math.floor(Math.random() * levelData.subject.length);
		var enemy = new Enemy(x, y, enemySpeed, levelData.subject[pickSubject], isHard);

		if (enemy.destroyed) {
			return;
		}

		add(enemy);
		enemies.add(enemy);
		enemy.target = player;
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

	// Game result

	function save() {
		log.info("Entered save function");
		var result = getResult();

		var path = 'assets/saves/${levelData.level}.json';
		// Files.createDirectory(path);
		Files.saveContent(path, Json.stringify(result));
	}

	function getResult() {
		var result:Result = {
			score: this.score,
			rating: getRank(score, levelData)
		};

		return result;
	}

	static public function getRank(score:Float, levelData:LevelData = null) {
		if (levelData != null)
			if (levelData.level == QuestionPool.SUBJECTS[4]) {
				score /= levelData.subject.length;
			}

		if (score < 5) {
			return "Kém";
		} else if (score < 6) {
			return "Trung bình";
		} else if (score < 7) {
			return "Trung bình khá";
		} else if (score < 8) {
			return "Khá";
		} else if (score < 9) {
			return "Giỏi";
		} else if (score < 10) {
			return "Xuất sắc";
		} else {
			return "Xuất sắc!";
		}
	}

	static public function getColor(score:Float, levelData:LevelData = null) {
		if (levelData != null)
			if (levelData.level == QuestionPool.SUBJECTS[4]) {
				score /= levelData.subject.length;
			}

		if (score < 5.0) {
			return 0x3B5991;
		} else if (score < 6) {
			return 0x5C2F1A;
		} else if (score < 7) {
			return 0xCE752D;
		} else if (score < 8) {
			return 0xDBA2AE;
		} else if (score < 9) {
			return 0xE0BA10;
		} else if (score < 10) {
			return 0x3596F1;
		} else {
			return 0x312238;
		}
	}

	static public function getColorFromRating(rating:String) {
		if (rating == "Kém") {
			return getColor(0);
		} else if (rating == "Trung bình") {
			return getColor(5.1);
		} else if (rating == "Trung bình khá") {
			return getColor(6.1);
		} else if (rating == "Khá") {
			return getColor(7.1);
		} else if (rating == "Giỏi") {
			return getColor(8.1);
		} else if (rating == "Xuất sắc") {
			return getColor(9.1);
		} else {
			return getColor(10);
		}
	}

	// Switch between scene

	function toGameOverScene() {
		var result = getResult();
		app.scenes.main = new GameOverScene(result);
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
				if (bullet.animation == 'splash') {
					continue;
				}
				if (!world.overlap(enemy, bullet)) {
					continue;
				}

				enemy.takeDamage(bullet.damage);

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
					player.takeDamage(0.5);
				}
			case HARD:
				{
					player.takeDamage(1);
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
