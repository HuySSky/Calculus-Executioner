package;

import haxe.Json;
import ceramic.Assets;
import Enemy.EnemyDifficulty;

/**
	QuestionPool preloads questions from data assets, stores and retrives questions anytime. 
**/
class QuestionPool {
	static var cachedQuestions:Map<String, Map<EnemyDifficulty, Array<QuestionData>>> = new Map();

	static var assets:Assets;

	public static final SUBJECTS = [
		"Linear Algebra",
		"Calculus",
		"Discrete Structures",
		"Probability and Statistics",
		"Combination"
	];

	/**
		This function load all question into cache
	**/
	public static function loadAllSubjects(assets:Assets) {
		log.info('Loading question');

		QuestionPool.assets = assets;
		var count:Int = 0;
		for (subject in SUBJECTS) {
			var subjectQuestion = loadSubject(subject);
			cachedQuestions.set(subject, subjectQuestion);

			for (item in subjectQuestion) {
				count += item.length;
			}
		}

		log.success('Load success $count questions');
	}

	/**
		Load and return all question of the subject. 
	**/
	static function loadSubject(subject:String):Map<EnemyDifficulty, Array<QuestionData>> {
		var subjectQuestions:Map<EnemyDifficulty, Array<QuestionData>> = [];

		var loadedQuestion:Array<QuestionData> = loadFromPath('Questions/$subject');

		for (q in loadedQuestion) {
			var difficulty:EnemyDifficulty = q.difficulty;

			var questions:Array<QuestionData> = subjectQuestions.get(difficulty);
			if (questions == null) {
				questions = [];
				subjectQuestions.set(difficulty, questions);
			}
			questions.push(q);
		}

		return subjectQuestions;
	}

	/**
		Get data from built in preload and return questions
	**/
	static function loadFromPath(path:String):Array<QuestionData> {
		if (assets == null)
			return [];

		var json = assets.text(path);
		if (json == null) {
			return [];
		}

		var questionsString:Array<Dynamic> = Json.parse(assets.text(path));
		var questions = new Array<QuestionData>();
		for (q in questionsString) {
			var question = QuestionData.fromJson(q);
			questions.push(question);
		}

		return questions;
	}

	/**
		Get question randomly
	**/
	public static function getRandomQuestion(subject:String, difficulty:EnemyDifficulty = null):QuestionData {
		var questions:Array<QuestionData> = null;
		var subjectQuestions = cachedQuestions.get(subject);

		if (difficulty != null) {
			questions = subjectQuestions.get(difficulty);
		} else {
			questions = [];

			for (combine in subjectQuestions) {
				for (item in combine) {
					questions.push(item);
				}
			}
		}

		if (questions == null) {
			return null;
		}

		var length = questions.length;

		// Ensure position is an integer in range [0, length)
		var position = Math.floor(Math.random() * length);

		return questions[position];
	}
}
