package;

import Enemy.EnemyDifficulty;

class QuestionData {
	public var question:String; // LaTeX format
	public var answer:String;
	public var difficulty:EnemyDifficulty;

	public function new(question:String, answer:String, difficulty:EnemyDifficulty) {
		this.question = question;
		this.answer = answer;
		this.difficulty = difficulty;
	}
}
