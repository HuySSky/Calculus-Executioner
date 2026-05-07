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
		initEntities();
		setupEntities();
		prepareAudio();
		initGameUI();
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

		super.destroy();
	}

	// Init game entity

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
		add(setting);

		if (levelData.level == QuestionPool.SUBJECTS[4]) {
			var grid = new GridBackground(width, height);
			grid.depth = -10;
			add(grid);
		} else {
			var paperBackground = new Quad();
			paperBackground.texture = assets.texture('Notebook/${levelData.level}');
			paperBackground.depth = -10;
			paperBackground.alpha = 0.75;
			add(paperBackground);
		}
	}

	// Game UI
	var complete:Text;
	var scoreText:Text;
	var healthText:Text;

	function initGameUI() {
		complete = new Text();
		complete.content = "Complete this level";
		complete.pointSize = 30;
		complete.color = Color.LIME;
		complete.anchor(1, 0);
		complete.pos(width * 0.95, height * 0.85);
		complete.onPointerDown(this, info -> {
			toGameOverScene();
		});
		add(complete);

		scoreText = new Text();
		scoreText.pointSize = 24;
		scoreText.content = 'Score: 0';
		scoreText.color = Color.YELLOW;
		scoreText.pos(width * 0.02, height * 0.85);
		add(scoreText);
		onScoreChange(this, (cur, pre) -> {
			cur = Std.int(cur * 100) / 100.0;
			scoreText.content = 'Score: $cur';
			if (cur >= 10) {
				scoreText.color = Color.GOLD;
			}
		});
		score = 0;

		healthText = new Text();
		healthText.pointSize = 24;
		healthText.content = 'Health: ${player.health}';
		healthText.color = Color.GREEN;
		healthText.anchor(1, 0);
		healthText.pos(width * 0.97, height * 0.05);
		add(healthText);
		player.onHealthChange(player, () -> {
			healthText.content = 'Health: ${player.health}';
			if (player.health <= 1) {
				healthText.color = Color.RED;
			} else if (player.health <= 2) {
				healthText.color = Color.YELLOW;
			} else if (player.health <= 3) {
				healthText.color = Color.GREEN;
			} else {
				healthText.color = Color.LIME;
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
	var spawnDelay:Float = 6;
	final spawnMax:Float = 6;
	final spawnMin:Float = 1.2;
	final spawnRampTime:Float = 5 * 60;
	var spawnRate:Float;
	var spawnProgress:Visual;
	var spawnBar:Quad;
	var spawnEnemyTime:Float = 2;

	var difficulty:Float = 0.3;
	final difficultyMin:Float = 0.25;
	final difficultyMax:Float = 1.0;
	final difficultyRampTime:Float = 10 * 60;
	var difficultyRate:Float;
	var difficultyProgress:Visual;
	var difficultyBar:Quad;

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
		var pickSubject = Math.floor(Math.random() * levelData.subject.length);
		var enemy = new Enemy(x, y, enemySpeed, levelData.subject[pickSubject], isHard);
		add(enemy);
		enemies.add(enemy);

		if (enemy.destroyed) {
			return;
		}
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

	// Save result

	function save() {
		log.info("Entered save function");
		var result:Result = {
			score: this.score,
			rating: ""
		};

		var path = 'saves';
		Files.createDirectory(path);
		Files.saveContent(path + '/${levelData.level}.json', Json.stringify(result));
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
