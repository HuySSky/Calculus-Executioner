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

		var escape = new Text();
		escape.content = "Press Esc to return to menu screen";
		escape.pointSize = 20;
		escape.color = 0x5E5368;
		escape.pos(width * 0.03, height * 0.93);
		add(escape);
	}

	override function update(delta:Float) {
		if (app.input.keyJustReleased(ESCAPE)) {
			accessUIT();
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
		add(scoreOfSubject);

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
			text.pointSize = 28;
			text.y = y;
			text.color = 0xECD1D3;
			text.font = app.assets.font(Fonts.ROBOTO_MEDIUM);
			scoreOfSubject.add(text);

			if (i <= 3 && result.rating == "Kém") {
				isGraduated = false;
			}

			y += height * 0.09;
		}

		scoreOfSubject.pos(width * 0.12, height * 0.07);
	}

	var judge:Text;

	function initJudge() {
		judge = new Text();
		judge.pointSize = 40;
		judge.font = app.assets.font(Fonts.ROBOTO_MEDIUM);
		judge.anchor(0.5, 0.5);
		judge.pos(width * 0.49, height * 0.64);
		add(judge);

		if (isGraduated) {
			judge.content = "Bạn đủ điều kiện tốt nghiệp";
			judge.color = 0x13d62d;
		} else {
			judge.content = "Bạn chưa đủ điều kiện tốt nghiệp";
			judge.color = 0xe9d415;
		}

		showAllowAccess();
	}

	function accessUIT() {
		var access = {allow: isGraduated};
		var path = 'assets/access UIT.json';
		log.info(Json.stringify(access));
		Files.saveContent(path, Json.stringify(access));
	}

	function showAllowAccess() {
		if (!isGraduated)
			return;

		var allow = new Text();
		allow.content = "Bạn đủ điều kiện vào màn chơi 'tìm hiểu về UIT'";
		allow.pointSize = 36;
		allow.color = 0x62f31e;
		allow.font = app.assets.font(Fonts.ROBOTO_MEDIUM);
		allow.anchor(0.5, 0.5);
		allow.pos(width * 0.51, height * 0.78);
		add(allow);
	}
}
