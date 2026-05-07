package;

import ceramic.Color;
import ceramic.Line;
import ceramic.Filter;
import ceramic.Group;
import ceramic.Visual;

class GridBackground extends Visual {
	var linesVertical:Group<Line>;
	var linesHorizontal:Group<Line>;
	var lineFilter:Filter;

	var gapX:Float;
	var gapY:Float;

	public function new(width = 0.0, height = 0.0) {
		super();
		this.width = width == 0 ? app.screen.width : width;
		this.height = height == 0 ? app.screen.height : height;
		createLine();
	}

	override public function destroy() {
		super.destroy();
	}

	function createLine() {
		linesVertical = new Group<Line>();
		linesHorizontal = new Group<Line>();
		lineFilter = new Filter();
		lineFilter.size(width, height);

		add(lineFilter);

		gapX = width * 0.08;
		gapY = gapX;

		var x:Float = 0;
		var y:Float = 0;
		while (x <= width) {
			var line = new Line();
			line.points = [x, 0, x, height];
			line.color = Color.GREEN;
			line.thickness = 2;
			lineFilter.content.add(line);

			linesVertical.add(line);

			x += gapX;
		}

		while (y <= height) {
			var line = new Line();
			line.points = [0, y, width, y];
			line.color = Color.GREEN;
			line.thickness = 2;
			lineFilter.content.add(line);

			linesHorizontal.add(line);

			y += gapY;
		}

		lineFilter.alpha = 0.4;

		gapX = gapX - (width - (x - gapX));
		gapY = gapY - (height - (y - gapY));
	}

	public function update(delta:Float) {
		var jump = delta * 20;
		for (line in linesVertical.items) {
			var points = line.points;

			points[0] += jump;
			points[2] += jump;

			if (points[0] > width) {
				points[0] -= width + gapX;
				points[2] -= width + gapX;
			}

			line.points = points;
		}

		for (line in linesHorizontal.items) {
			var points = line.points;

			points[1] += jump;
			points[3] += jump;

			if (points[1] > height) {
				points[1] -= height + gapY;
				points[3] -= height + gapY;
			}

			line.points = points;
		}
	}
}
