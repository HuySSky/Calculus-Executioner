package;

import ceramic.Tween;
import elements.Im;
import ceramic.Json;
import ceramic.SoundPlayer;
import ceramic.Color;
import ceramic.Text;
import MainScene.LevelData;
import ceramic.Visual;
import ceramic.Scene;
import ceramic.Quad;
import ceramic.Sprite;

using ceramic.SpritePlugin;

class MenuScene extends Scene {
	var stageHolder:Visual;
	var graduationButton:Text;

	var menuSong:SoundPlayer;
	var grid:GridBackground;

	var SUBJECTS = QuestionPool.SUBJECTS;

	public function new() {
		super();
	}

	override function preload() {
		assets.addAll(~/^Subject\/.*$/);
		assets.addAll(~/^Questions\/.*$/);
		assets.addAll(~/^saves\/.*$/);
		assets.add(Sounds.MAIN_MENU, null, {stream: true});
	}

	override function create() {
		super.create();

		menuSong = assets.sound(Sounds.MAIN_MENU).play(0, true);

		clip = this;
		graduationButton = new Text();
		graduationButton.content = "Xét tốt nghiệp";
		graduationButton.pointSize = 36;
		graduationButton.font = app.assets.font(Fonts.ROBOTO_BLACK);
		graduationButton.anchor(0.5, 0.5);
		graduationButton.pos(width * 0.85, height * 0.94);
		graduationButton.color = Color.LIME;
		graduationButton.depth = 3;
		add(graduationButton);

		var bottomMargin = new Quad();
		bottomMargin.size(width, height * 0.12);
		bottomMargin.anchor(0, 1);
		bottomMargin.y = height;
		bottomMargin.color = 0x1B2C25;
		bottomMargin.alpha = 0.8;
		bottomMargin.depth = 2;
		add(bottomMargin);

		createStage();
		grid = new GridBackground();
		grid.depth = -1;
		add(grid);
		QuestionPool.loadAllSubjects(assets);

		choiceBox();
	}

	override function update(delta:Float) {
		grid.update(delta);
		if (combBackground.active) {
			combIM();
		}
	}

	override function destroy() {
		super.destroy();
		combBackground.destroy();
	}

	function createStage() {
		var posX:Array<Float> = [width * 0.2, width * 0.5, width * 0.8];
		var posY:Array<Float> = [height * 0.2, height * 0.6];

		var stageHolder = new Visual();
		add(stageHolder);

		for (i in 0...SUBJECTS.length) {
			var subject = SUBJECTS[i];
			var quad = new Quad();
			quad.texture = assets.texture('Subject/$subject');

			quad.anchor(0.5, 0.5);
			quad.x = posX[i % 3];
			quad.y = posY[Std.int(i / 3)];
			quad.onPointerDown(stageHolder, (info) -> {
				if (i <= 3) {
					handleNormalSubject(subject);
				} else if (i == 4) {
					handleCombination();
				}
			});

			var background = new Quad();
			background.size(quad.width * 1.053, quad.height * 1.045);
			background.anchor(0.5, 0.5);
			background.pos(quad.x, quad.y);
			background.depthRange = -1;

			var resultJson:String = assets.text('saves/$subject');
			if (resultJson != null) {
				var result = Json.parse(resultJson);
				var score = result.score;

				background.color = MainScene.getColor(score);
			} else {
				background.color = MainScene.getColor(0);
			}

			stageHolder.add(quad);
			stageHolder.add(background);
		}
	}

	function handleNormalSubject(name:String) {
		var levelData:LevelData = {
			subject: [],
			level: name
		};
		levelData.subject.push(name);

		app.scenes.main = new MainScene(levelData);
	}

	// Combination
	var combBackground:Quad;
	var choice:Array<Bool> = [false, false, false, false];
	var chooseOne:Text;

	function choiceBox() {
		combBackground = new Quad();
		combBackground.color = Color.BLACK;
		combBackground.alpha = 0.7;
		combBackground.depth = 10;
		combBackground.size(width, height);

		combBackground.active = false;
		var turnBack = new Text();
		turnBack.content = "Return";
		turnBack.color = Color.WHITE;
		turnBack.onPointerOver(combBackground, info -> {
			turnBack.color = 0xECCA09;
		});
		turnBack.onPointerOut(combBackground, info -> {
			turnBack.color = Color.WHITE;
		});
		turnBack.onPointerDown(combBackground, info -> {
			combBackground.active = false;
			this.touchable = true;
		});
		turnBack.pointSize = 24;
		turnBack.x = (combBackground.width - turnBack.width) / 2;
		turnBack.y = (combBackground.height - turnBack.height) / 2 + combBackground.height * 0.3;
		combBackground.add(turnBack);

		var play = new Text();
		play.content = "Play";
		play.color = Color.WHITE;
		play.onPointerOver(combBackground, info -> {
			play.color = 0xECCA09;
		});
		play.onPointerOut(combBackground, info -> {
			play.color = Color.WHITE;
		});
		play.onPointerDown(combBackground, playComb);
		play.pointSize = 24;
		play.x = (combBackground.width - play.width) / 2;
		play.y = (combBackground.height - play.height) / 2 + combBackground.height * 0.45;
		combBackground.add(play);

		chooseOne = new Text();
		chooseOne.content = "You have to choose at least one subject!";
		chooseOne.pointSize = 36;
		chooseOne.font = app.assets.font(Fonts.ROBOTO_BLACK);
		chooseOne.color = 0xD6240C;
		chooseOne.alpha = 0;
		chooseOne.anchor(0.5, 0.5);
		chooseOne.pos(width * 0.5, height * 0.2);
		chooseOne.depth = 12;
		combBackground.add(chooseOne);
	}

	function combIM() {
		Im.begin("Choose the subjects you want to tackle!", 275);

		Im.check(SUBJECTS[0], Im.bool(choice[0]));
		Im.check(SUBJECTS[1], Im.bool(choice[1]));
		Im.check(SUBJECTS[2], Im.bool(choice[2]));
		Im.check(SUBJECTS[3], Im.bool(choice[3]));

		Im.end();
	}

	function handleCombination() {
		combBackground.active = true;
		this.touchable = false;
	}

	function playComb(info:ceramic.TouchInfo) {
		var levelData:LevelData = {
			subject: [],
			level: SUBJECTS[4]
		};

		for (i in 0...4) {
			if (!choice[i])
				continue;

			levelData.subject.push(SUBJECTS[i]);
		}

		if (levelData.subject.length == 0) {
			log.error("You must choose something.");
			Tween.start(this, NONE, 1, 1, 0, (value, time) -> {
				chooseOne.alpha = value;
			});
			return;
		}

		app.scenes.main = new MainScene(levelData);
	}
}
