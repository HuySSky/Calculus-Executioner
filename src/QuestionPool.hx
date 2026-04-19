package;

import haxe.Json;
import Enemy.EnemyDifficulty;

class QuestionPool {
	// Cached questions: Map<subject, Map<difficulty, Array<QuestionData>>>
	// Pre-organized by difficulty to avoid expensive filtering at query time
	static var cachedQuestions:Map<String, Map<EnemyDifficulty, Array<QuestionData>>> = new Map();

	// List of available subjects
	public static final SUBJECTS = [
		"Calculus",
		"Linear Algebra",
		"Discrete Structures",
		"Probability and Statistics"
	];

	// List of question types per subject
	public static final QUESTION_TYPES:Map<String, Array<String>> = [
		SUBJECTS[0] => ["limits", "derivatives", "integrals"],
		SUBJECTS[1] => ["matrices", "vectors"],
		SUBJECTS[2] => ["graphs", "logic"],
		SUBJECTS[3] => ["probability", "statistics"]
	];

	/**
		Load all subjects synchronously at app startup.
		Must be called in Project.hx before any gameplay.
	**/
	public static function loadAllSubjects() {
		log.info("Loading all question subjects...");

		for (subject in SUBJECTS) {
			loadSubject(subject);
		}

		var totalLoaded = 0;
		for (difficultyMap in cachedQuestions) {
			for (questions in difficultyMap) {
				totalLoaded += questions.length;
			}
		}

		log.success("All subjects loaded successfully! Total: " + totalLoaded + " questions");
	}

	/**
		Load all question types for a specific subject.
		Synchronous - blocking operation.
	**/
	static function loadSubject(subject:String) {
		var types = QUESTION_TYPES.get(subject);

		if (types == null) {
			log.error("Subject not found in QUESTION_TYPES: " + subject);
			return;
		}

		var subjectQuestion = cachedQuestions.get(subject);
		if (subjectQuestion == null) {
			subjectQuestion = new Map();
			cachedQuestions.set(subject, subjectQuestion);
		}

		for (type in types) {
			var loadedQuestions = loadQuestionType(subject, type);

			for (q in loadedQuestions) {
				var arr = subjectQuestion.get(q.difficulty);
				if (arr == null) {
					arr = [];
					subjectQuestion.set(q.difficulty, arr);
				}
				arr.push(q);
			}
		}

		// log.info("Has data: " + cachedQuestions.get(subject).get(EASY).length);
	}

	/**
		Load a specific question type file (e.g., Calculus/limits.json).
		Synchronous loading - returns array or null on failure.
	**/
	static function loadQuestionType(subject:String, type:String):Array<QuestionData> {
		var path = 'Questions/${subject}/${type}';

		#if js
		// Browser environment - synchronous fetch
		return loadJsonFromUrlSync(path);
		#else
		// C++ / Desktop environment - read from file system
		return loadJsonFromFileSync(path);
		#end
	}

	/**
		Load JSON from file synchronously (for C++ builds).
	**/
	#if !js
	static function loadJsonFromFileSync(path:String):Array<QuestionData> {
		try {
			var content = sys.io.File.getContent(path);
			var json:Array<Dynamic> = Json.parse(content);
			return parseQuestionsFromJson(json);
		} catch (e:Dynamic) {
			log.error("Error loading file " + path + ": " + e);
			return [];
		}
	}
	#end

	/**
		Load JSON from URL synchronously (for web builds).
		Note: Synchronous XHR is deprecated but works for file loading at startup.
	**/
	#if js
	static function loadJsonFromUrlSync(path:String):Array<QuestionData> {
		try {
			var data = app.assets.text(path);
			var json:Array<Dynamic> = Json.parse(data);
			var result = parseQuestionsFromJson(json);

			return result;
		} catch (e:Dynamic) {
			log.error("Error parsing JSON from " + path + ": " + e);
			return [];
		}
	}
	#end

	/**
		Parse raw JSON array into QuestionData objects.
	**/
	static function parseQuestionsFromJson(jsonArray:Array<Dynamic>):Array<QuestionData> {
		var questions:Array<QuestionData> = [];

		for (item in jsonArray) {
			try {
				var q = new QuestionData(item.question, item.answer, EnemyDifficulty.fromString(item.difficulty));
				questions.push(q);
			} catch (e:Dynamic) {
				log.error("Error parsing question item: " + e);
				continue;
			}
		}

		return questions;
	}

	/**
		Get random question by subject and optional difficulty.
		If difficulty is null, returns any difficulty.
		Returns null if subject not found or no questions available.
	**/
	public static function getRandomQuestion(subject:String, ?difficulty:EnemyDifficulty):QuestionData {
		if (!cachedQuestions.exists(subject)) {
			log.error("Subject not loaded: " + subject);
			return null;
		}

		var difficultyMap = cachedQuestions.get(subject);

		var questions:Array<QuestionData> = [];

		// If difficulty specified, get that array; otherwise combine both
		if (difficulty != null) {
			questions = difficultyMap.get(difficulty);
		} else {
			// Combine both difficulties
			for (combine in difficultyMap) {
				for (item in combine) {
					questions.push(item);
				}
			}
		}

		if (questions == null || questions.length == 0) {
			var logDifficulty = "";
			if (difficulty != null) {
				logDifficulty = ", difficulty= " + difficulty;
			}

			log.error("No questions found for subject= " + subject + logDifficulty);
			return null;
		}

		var randomIndex = Math.floor(Math.random() * questions.length);
		log.info('Get #$randomIndex question');
		return questions[randomIndex];
	}

	/**
		Get total question count for a subject.
		If difficulty specified, returns count for that difficulty only.
	**/
	public static function getQuestionCount(subject:String, ?difficulty:EnemyDifficulty):Int {
		if (!cachedQuestions.exists(subject)) {
			return 0;
		}

		var difficultyMap = cachedQuestions.get(subject);

		if (difficulty != null) {
			var questions = difficultyMap.get(difficulty);
			return questions != null ? questions.length : 0;
		}

		var total = 0;
		for (questions in difficultyMap) {
			total += questions.length;
		}
		return total;
	}

	/**
		Clear cache (for testing or resetting).
	**/
	public static function clearCache() {
		cachedQuestions.clear();
	}
}
