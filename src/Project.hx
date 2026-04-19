package;

import ceramic.Entity;
import ceramic.Color;
import ceramic.InitSettings;

class Project extends Entity {
	function new(settings:InitSettings) {
		super();

		settings.antialiasing = 2;
		settings.background = Color.BLACK;
		settings.targetWidth = 1024;
		settings.targetHeight = 720;
		settings.scaling = FIT;
		settings.resizable = true;

		app.onceReady(this, ready);

		app.assets.addAll();

		app.assets.onceComplete(app.assets, (success) -> {});
	}

	function ready() {
		app.assets.load();
		// Load all questions at startup BEFORE creating MainScene
		QuestionPool.loadAllSubjects();

		// Set MainScene as the current scene (see MainScene.hx)
		app.scenes.main = new MenuScene();
	}
}
