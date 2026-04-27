package;

import ceramic.TouchInfo;
import ceramic.Text;
import ceramic.Color;
import ceramic.Quad;
import ceramic.Visual;

class Setting extends Visual {
	@event function paused();

	@event function unpaused();

	var background:Quad;

	// HUD
	public var settingScreen:Quad;

	public function new() {
		super();

		createSetting();

		background = new Quad();
		background.size(32, 32);
		background.color = Color.TEAL;
		background.onPointerDown(this, openSetting);
		background.depth = 10;
		add(background);
	}

	override public function destroy() {
		super.destroy();
		settingScreen.destroy();
	}

	function createSetting() {
		settingScreen = new Quad();
		settingScreen.size(screen.width, screen.height);
		settingScreen.alpha = 0.3;
		settingScreen.active = false;
		settingScreen.depth = 99;

		var resume = new Text();
		resume.content = "Resume";
		resume.color = Color.WHITE;
		resume.onPointerOver(settingScreen, info -> {
			resume.color = Color.GOLD;
		});
		resume.onPointerOut(settingScreen, info -> {
			resume.color = Color.WHITE;
		});
		resume.onPointerDown(settingScreen, quitSetting);
		resume.pointSize = 24;
		resume.x = (settingScreen.width - resume.width) / 2;
		resume.y = (settingScreen.height - resume.height) / 2 + settingScreen.height * 0.1;
		settingScreen.add(resume);

		var quit = new Text();
		quit.content = "Quit";
		quit.color = Color.WHITE;
		quit.onPointerOver(settingScreen, info -> {
			quit.color = Color.GOLD;
		});
		quit.onPointerOut(settingScreen, info -> {
			quit.color = Color.WHITE;
		});
		quit.onPointerDown(settingScreen, toMenu);
		quit.pointSize = 24;
		quit.x = (settingScreen.width - quit.width) / 2;
		quit.y = (settingScreen.height - quit.height) / 2 + settingScreen.height * 0.3;
		settingScreen.add(quit);
	}

	public function openSetting(info:ceramic.TouchInfo) {
		settingScreen.active = true;
		emitPaused();
	}

	function quitSetting(info:ceramic.TouchInfo) {
		settingScreen.active = false;
		emitUnpaused();
	}

	function toMenu(info:TouchInfo) {
		app.scenes.main = new MenuScene();
	}
}
