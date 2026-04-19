package;

import ceramic.Color;
import ceramic.Scene;
import ceramic.Text;
import ceramic.Quad;

class GameOverScene extends Scene {
	// menu game button
	var menu:Text;
	var menuBackground:Quad;

	public function new() {
		super();
	}

	override function preload() {}

	override function create() {
		super.create();

		menuBackground = new Quad();
		menuBackground.color = Color.RED;
		menuBackground.size(100, 50);
		menuBackground.anchor(0.5, 0.5);
		menuBackground.pos(width / 2, height / 2);
		add(menuBackground);

		menu = new Text();
		menu.content = "Menu";
		menu.pointSize = 24;
		menu.color = Color.WHITE;
		menu.anchor(0.5, 0.5);
		menu.pos(menuBackground.width / 2, menuBackground.height / 2);
		menu.onPointerDown(this, (info) -> {
			app.scenes.main = new MenuScene();
		});
		menuBackground.add(menu);
	}

	override function update(delta:Float) {}

	override function destroy() {
		super.destroy();
	}
}
