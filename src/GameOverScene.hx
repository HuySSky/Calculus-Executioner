package;

import MainScene.Result;
import ceramic.Color;
import ceramic.Scene;
import ceramic.Text;
import ceramic.Quad;

class GameOverScene extends Scene {
	// menu game button
	var menu:Text;
	var menuBackground:Quad;

	// Result of previous game
	var result:Result;
	var scoreText:Text;
	var ratingText:Text;

	public function new(result:Result = null) {
		super();
		if (result == null) {
			result = {
				score: 0,
				rating: "Kém"
			};
		}

		this.result = result;
	}

	override function preload() {}

	override function create() {
		super.create();

		createResult();
		createMenuButton();
	}

	override function update(delta:Float) {}

	override function destroy() {
		super.destroy();
	}

	function createResult() {
		var score = result.score;

		scoreText = new Text();
		scoreText.content = 'Điểm môn học: ${score}';
		scoreText.pointSize = 40;
		scoreText.color = MainScene.getColor(score);
		scoreText.anchor(0.5, 0.5);
		scoreText.pos(width * 0.5, height * 0.25);
		add(scoreText);

		ratingText = new Text();
		ratingText.content = 'Đánh giá xếp loại: ${result.rating}';
		ratingText.pointSize = 36;
		ratingText.color = MainScene.getColor(score);
		ratingText.anchor(0.5, 0.5);
		ratingText.pos(width * 0.5, height * 0.4);
		add(ratingText);
	}

	function createMenuButton() {
		menuBackground = new Quad();
		menuBackground.color = Color.RED;
		menuBackground.size(100, 50);
		menuBackground.anchor(0.5, 0.5);
		menuBackground.pos(width * 0.5, height * 0.6);
		add(menuBackground);

		menu = new Text();
		menu.content = "Menu";
		menu.pointSize = 24;
		menu.color = Color.WHITE;
		menu.anchor(0.5, 0.5);
		menu.pos(menuBackground.width * 0.5, menuBackground.height * 0.5);
		menu.onPointerDown(this, (info) -> {
			app.scenes.main = new MenuScene();
		});
		menuBackground.add(menu);
	}
}
