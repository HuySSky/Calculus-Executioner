package;

import ceramic.Assets;
import Enemy.EnemyDifficulty;

/**
	QuestionPool preloads questions from data assets, stores and retrives questions anytime. 
**/
class QuestionPool {
	static var cachedQuestions:Map<String, Map<EnemyDifficulty, Array<QuestionData>>> = new Map();

	static var assets:Assets;

	public static final SUBJECTS = [
		"Calculus",
		"Discrete Structures",
		"Linear Algebra",
		"Probability and Statistics"
	];

	public static final TYPES = [
		SUBJECTS[0] => ["limits", "integrals", "derivatives"],
		SUBJECTS[1] => ["graphs", "logic"],
		SUBJECTS[2] => ["matrices", "vectors"],
		SUBJECTS[3] => ["probability", "statistics"]
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

		for (type in TYPES[subject]) {
			var loadedQuestion:Array<QuestionData> = loadType(subject, type);

			// Seperate question base on difficulty
			for (q in loadedQuestion) {
				var difficulty:EnemyDifficulty = q.difficulty;

				var questions:Array<QuestionData> = subjectQuestions.get(difficulty);
				if (questions == null) {
					questions = [];
					subjectQuestions.set(difficulty, questions);
				}
				questions.push(q);
			}
		}

		return subjectQuestions;
	}

	/**
		Load and return a specific question type of subject
	**/
	static function loadType(subject:String, type:String):Array<QuestionData> {
		var path = 'Questions/$subject/$type';
		return loadFromPath(path);
	}

	/**
		Get data from built in preload and return questions
	**/
	static function loadFromPath(path:String):Array<QuestionData> {
		if (assets == null) {
			return [];
		}

		var json = assets.text(path); // Get json string from built-in preload
		if (json == null) {
			log.error('Get data fail, path = $path');
			return [];
		}

		var questions:Array<Dynamic> = haxe.Json.parse(json);

		var questionArray:Array<QuestionData> = [];
		for (q in questions) {
			var questionData = QuestionData.fromJson(q);
			questionArray.push(questionData);
		}

		return questionArray;
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
			if (questions == null)
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
