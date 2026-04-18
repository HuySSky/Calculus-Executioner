package;

import ceramic.Color;
import ceramic.Text;
import ceramic.Scene;
import ceramic.Quad;

class MenuScene extends Scene {
	// Play game button
	var play:Text;
	var playBackground:Quad;

	public function new() {
		super();
	}

	override function preload() {}

	override function create() {
		super.create();

		playBackground = new Quad();
		playBackground.color = Color.RED;
		playBackground.size(100, 50);
		playBackground.anchor(0.5, 0.5);
		playBackground.pos(width / 2, height / 2);
		add(playBackground);

		play = new Text();
		play.content = "PLAY";
		play.pointSize = 24;
		play.color = Color.WHITE;
		play.anchor(0.5, 0.5);
		play.pos(playBackground.width / 2, playBackground.height / 2);
		play.onPointerDown(this, (info) -> {
			app.scenes.main = new MainScene();
		});
		playBackground.add(play);
	}

	override function update(delta:Float) {}

	override function destroy() {
		super.destroy();
	}
}
