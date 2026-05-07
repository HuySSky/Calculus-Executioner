package;

import ceramic.Json;
import ceramic.SoundPlayer;
import ceramic.Filter;
import ceramic.Line;
import ceramic.Group;
import ceramic.Color;
import ceramic.Text;
import MainScene.LevelData;
import ceramic.Visual;
import ceramic.Scene;
import ceramic.Quad;

class MenuScene extends Scene {
	var stageHolder:Visual;
	var graduationButton:Text;

	var menuSong:SoundPlayer;
	var grid:GridBackground;

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
		graduationButton.content = "Xet tot nghiep";
		graduationButton.pointSize = 36;
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
	}

	override function update(delta:Float) {
		grid.update(delta);
	}

	override function destroy() {
		super.destroy();
	}

	function createStage() {
		var posX:Array<Float> = [width * 0.2, width * 0.5, width * 0.8];
		var posY:Array<Float> = [height * 0.2, height * 0.6];

		var stageHolder = new Visual();
		add(stageHolder);

		for (i in 0...QuestionPool.SUBJECTS.length) {
			var subject = QuestionPool.SUBJECTS[i];
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
			background.color = 0x5F6B7A;
			background.anchor(0.5, 0.5);
			background.pos(quad.x, quad.y);
			background.depthRange = -1;

			var resultJson:String = assets.text('saves/$subject');
			if (resultJson != null) {
				var result = Json.parse(resultJson);
				var score = result.score;

				if (score < 5.0) {
					background.color = 0x5F6B7A;
				} else if (score < 6) {
					background.color = 0x5C3A1A;
				} else if (score < 7) {
					background.color = 0xC46A2D;
				} else if (score < 8) {
					background.color = 0xCFCFCF;
				} else if (score < 9) {
					background.color = 0xE6C200;
				} else if (score < 10) {
					background.color = 0x2DE2E6;
				} else {
					background.color = 0x3A3F47;
				}
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

	function handleCombination() {
		log.info("Temporary state");
	}
}
