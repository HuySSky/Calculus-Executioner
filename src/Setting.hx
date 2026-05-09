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
		background.color = 0x0C7A7A;
		background.onPointerDown(this, _openSetting);
		background.depth = 10;
		add(background);
	}

	override public function destroy() {
		super.destroy();
		settingScreen.destroy();
	}

	public function update(delta:Float) {
		if (app.input.keyJustReleased(ESCAPE)) {
			if (settingScreen.active != true) {
				openSetting();
			} else {
				quitSetting();
			}
		}
	}

	function createSetting() {
		settingScreen = new Quad();
		settingScreen.size(screen.width, screen.height);
		settingScreen.color = 0x1E2236;
		settingScreen.alpha = 0.75;
		settingScreen.active = false;
		settingScreen.depth = 99;

		var resume = new Text();
		resume.content = "Resume";
		resume.color = 0xD1BCBF;
		resume.onPointerOver(settingScreen, info -> {
			resume.color = 0xE2D411;
		});
		resume.onPointerOut(settingScreen, info -> {
			resume.color = 0xD1BCBF;
		});
		resume.onPointerDown(settingScreen, _quitSetting);
		resume.pointSize = 24;
		resume.x = (settingScreen.width - resume.width) / 2;
		resume.y = (settingScreen.height - resume.height) / 2 + settingScreen.height * 0.1;
		settingScreen.add(resume);

		var quit = new Text();
		quit.content = "Quit";
		quit.color = 0xD8B6BB;
		quit.onPointerOver(settingScreen, info -> {
			quit.color = 0xD8C40D;
		});
		quit.onPointerOut(settingScreen, info -> {
			quit.color = 0xD8B6BB;
		});
		quit.onPointerDown(settingScreen, toMenu);
		quit.pointSize = 24;
		quit.x = (settingScreen.width - quit.width) / 2;
		quit.y = (settingScreen.height - quit.height) / 2 + settingScreen.height * 0.3;
		settingScreen.add(quit);
	}

	function _openSetting(info:TouchInfo) {
		openSetting();
	}

	public function openSetting() {
		settingScreen.active = true;
		emitPaused();
	}

	function _quitSetting(info:ceramic.TouchInfo) {
		quitSetting();
	}

	function quitSetting() {
		settingScreen.active = false;
		emitUnpaused();
	}

	function toMenu(info:TouchInfo) {
		app.scenes.main = new MenuScene();
	}
}
