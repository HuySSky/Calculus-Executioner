package;

import Enemy.EnemyDifficulty;
import ceramic.Color;
import ceramic.Visual;
import ceramic.Quad;
import ceramic.Text;
import ceramic.EditText;
import ceramic.Click;

class QuizScene extends Visual {
	// UI Components
	var background:Quad;
	var questionText:Text;
	var answerInput:Text;
	var inputBox:Quad;
	var submitButton:Quad;
	var submitText:Text;
	var timerText:Text;

	// Quiz data
	var questionData:QuestionData = null;

	// Timer
	var timeRemaining:Float = 120.0;
	var timerRunning:Bool = false;

	var onComplete:(Bool, EnemyDifficulty) -> Void;

	public function new() {
		super();

		// Position at screen center
		this.x = 0;
		this.y = 0;
		this.width = app.screen.width;
		this.height = app.screen.height;

		// Start inactive
		active = false;

		createUI();
	}

	function createUI() {
		// Semi-transparent background overlay
		background = new Quad();
		background.width = app.screen.width;
		background.height = app.screen.height;
		background.color = 0x4D4949;
		background.alpha = 0.8;
		background.depth = -1;
		add(background);

		// Question display
		questionText = new Text();
		questionText.pointSize = 28;
		questionText.color = 0xEED0D8;
		questionText.font = app.assets.font(Fonts.ROBOTO_MEDIUM);
		questionText.x = app.screen.width * 0.07;
		questionText.y = app.screen.height * 0.16;
		questionText.depth = 1;
		questionText.fitWidth = 850;
		add(questionText);

		// Input box background
		inputBox = new Quad();
		inputBox.width = 277;
		inputBox.height = 55;
		inputBox.color = 0xC4E4BC;
		inputBox.x = app.screen.width * 0.499;
		inputBox.y = app.screen.height * 0.62;
		inputBox.depth = 1;
		inputBox.anchor(0.5, 0.5);
		add(inputBox);

		// Answer input text
		answerInput = new Text();
		answerInput.pointSize = 24;
		answerInput.content = "";
		answerInput.color = 0x14C1EC;
		answerInput.font = app.assets.font(Fonts.ROBOTO_MEDIUM);
		answerInput.x = inputBox.width * 0.01;
		answerInput.y = inputBox.height * 0.5;
		answerInput.depth = 2;
		answerInput.anchor(0, 0.5);
		inputBox.add(answerInput);

		// Enable text editing on answerInput
		var editText = new EditText(Color.BLUE, Color.RED);
		answerInput.component("EditText", editText);
		editText.container = inputBox;

		// Submit button
		submitButton = new Quad();
		submitButton.width = 135;
		submitButton.height = 55;
		submitButton.color = 0x1BE214;
		submitButton.x = app.screen.width * 0.5;
		submitButton.y = app.screen.height * 0.78;
		submitButton.anchor(0.5, 0.5);
		add(submitButton);

		// Submit button text
		submitText = new Text();
		submitText.pointSize = 22;
		submitText.color = 0xEEC9CE;
		submitText.content = "SUBMIT";
		submitText.font = app.assets.font(Fonts.ROBOTO_MEDIUM);
		submitText.x = submitButton.width * 0.5;
		submitText.y = submitButton.height * 0.5;
		submitText.anchor(0.5, 0.5);
		submitButton.add(submitText);

		// Add click component to submit button
		var click = new Click();
		click.onClick(submitButton, function() {
			onSubmitPressed();
		});
		submitButton.component("click", click);

		// Timer display
		timerText = new Text();
		timerText.pointSize = 32;
		timerText.color = 0xECC7C0;
		timerText.font = app.assets.font(Fonts.ROBOTO_MEDIUM);
		timerText.x = app.screen.width * 0.73;
		timerText.y = app.screen.height * 0.06;
		add(timerText);
	}

	public function setup(enemy:Enemy, onComplete:(Bool, EnemyDifficulty) -> Void) {
		questionData = enemy.questionData;
		answerInput.content = "";

		questionText.content = questionData.question;
		active = true;

		// Reset timer
		timeRemaining = 120.0;
		timerRunning = true;
		updateTimerDisplay();

		this.onComplete = onComplete;
	}

	public function update(delta:Float) {
		if (!active)
			return;

		if (timerRunning) {
			timeRemaining -= delta;

			if (timeRemaining <= 0) {
				timeRemaining = 0;
				timerRunning = false;
				// Auto-submit on time out (wrong answer)
				onSubmitPressed();
			}

			updateTimerDisplay();
		}

		if (app.input.keyJustReleased(ENTER)) {
			onSubmitPressed();
		}
	}

	function updateTimerDisplay() {
		var seconds = Math.ceil(timeRemaining);
		timerText.content = 'Time: ${seconds}s';
	}

	function onSubmitPressed() {
		timerRunning = false;
		var currentUserAnswer = answerInput.content;
		var isCorrect = currentUserAnswer == questionData.answer;

		// Deactivate quiz
		active = false;

		// Callback to PlayScene with result
		if (onComplete != null) {
			onComplete(isCorrect, questionData.difficulty);
		}
	}
}
