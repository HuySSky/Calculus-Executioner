package;

import ceramic.Files;
import haxe.Json;
import MainScene.Result;
import ceramic.Visual;
import ceramic.Scene;
import ceramic.Text;

class GraduateScene extends Scene {
	public function new() {
		super();
	}

	override function preload() {
		assets.addAll(~/^saves\/.*$/);
	}

	override function create() {
		initScoreboard();
		initJudge();
		accessUIT();
		showAllowAccess();
	}

	override function update(delta:Float) {
		if (app.input.keyJustReleased(ESCAPE)) {
			app.scenes.main = new MenuScene();
		}
	}

	var isGraduated:Bool = true;

	var defaultResult:Result = {
		score: 0,
		rating: "Kém"
	};
	var scoreOfSubject:Visual;

	function initScoreboard() {
		scoreOfSubject = new Visual();

		var SUBJECTS = QuestionPool.SUBJECTS;
		var y = 0.0;
		for (i in 0...SUBJECTS.length) {
			var subject = SUBJECTS[i];
			var json = assets.text('saves/$subject');
			var result = defaultResult;

			if (json != null) {
				result = Json.parse(json);
			}

			var text = new Text();
			text.content = 'Điểm $subject: ${result.score}';
			text.pointSize = 26;
			text.y = y;
			text.color = 0xECD1D3;
			text.font = app.assets.font(Fonts.ROBOTO_MEDIUM);
			scoreOfSubject.add(text);

			if (i <= 3 && result.rating == "Kém") {
				isGraduated = false;
			}

			y += height * 0.08;
		}

		scoreOfSubject.pos(width * 0.13, height * 0.07);
	}

	var judge:Text;

	function initJudge() {
		judge = new Text();
		judge.pointSize = 32;
		judge.font = app.assets.font(Fonts.ROBOTO_MEDIUM);
		judge.anchor(0.5, 0.5);
		judge.pos(width * 0.49, height * 0.58);
		add(judge);

		if (isGraduated) {
			judge.content = "Bạn đủ điều kiện tốt nghiệp";
			judge.color = 0x13d62d;
		} else {
			judge.content = "Bạn chưa đủ điều kiện tốt nghiệp";
			judge.color = 0xe9d415;
		}
	}

	function accessUIT() {
		var access = {allow: true};
		var path = 'assets/accessUIT.json';
		Files.createDirectory(path);
		Files.saveContent(path, Json.stringify(access));
	}

	function showAllowAccess() {
		if (!isGraduated)
			return;

		var allow = new Text();
		allow.content = "Bạn đủ điều kiện vào màn chơi 'tìm hiểu về UIT'";
		allow.pointSize = 28;
		allow.color = 0x62f31e;
		allow.font = app.assets.font(Fonts.ROBOTO_MEDIUM);
		allow.anchor(0.5, 0.5);
		allow.pos(width * 0.51, height * 0.67);
		add(allow);
	}
}
