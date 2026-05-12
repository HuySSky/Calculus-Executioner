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

		color = 0x725486;
		createResult();
		createMenuButton();
	}

	override function update(delta:Float) {}

	override function destroy() {
		super.destroy();
	}

	function createResult() {
		var score = result.score;
		var rating = result.rating;

		scoreText = new Text();
		scoreText.content = 'Điểm môn học: ${score}';
		scoreText.font = app.assets.font(Fonts.ROBOTO_MEDIUM);
		scoreText.pointSize = 36;
		scoreText.color = MainScene.getColorFromRating(rating);
		scoreText.anchor(0.5, 0.5);
		scoreText.pos(width * 0.5, height * 0.2);
		add(scoreText);

		ratingText = new Text();
		ratingText.content = 'Đánh giá xếp loại: ${rating}';
		ratingText.font = app.assets.font(Fonts.ROBOTO_MEDIUM);
		ratingText.pointSize = 32;
		ratingText.color = MainScene.getColorFromRating(rating);
		ratingText.anchor(0.5, 0.5);
		ratingText.pos(width * 0.5, height * 0.35);
		add(ratingText);

		if (rating == "Kém") {
			var fail = new Text();
			fail.content = "Bạn rớt môn";
			fail.pointSize = 40;
			fail.font = app.assets.font(Fonts.ROBOTO_MEDIUM);
			fail.anchor(0.5, 0.5);
			fail.pos(width * 0.5, height * 0.5);
			fail.color = MainScene.getColorFromRating(rating);

			add(fail);
		}
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
