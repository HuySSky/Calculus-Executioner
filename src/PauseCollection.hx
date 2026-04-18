package;

import ceramic.Velocity;
import ceramic.Entity;
import haxe.ds.Map;
import ceramic.Visual;

typedef CopyPosition = {
	var x:Float;
	var y:Float;
	var velocityX:Float;
	var velocityY:Float;
};

class PauseCollection {
	var datas:Map<Visual, CopyPosition>;

	public function new() {
		datas = new Map<Visual, CopyPosition>();
	}

	public function update(delta:Float) {
		/*for (key in datas.keys()) {
			var value = datas[key];
			key.pos(value.x, value.y);
		}*/
	}

	public function unpause() {
		for (key in datas.keys()) {
			var value = datas[key];
			key.velocity(value.velocityX, value.velocityY);
		}
	}

	public function add(obj:Visual) {
		if (datas.exists(obj))
			return;

		var copy:CopyPosition = {
			x: obj.x,
			y: obj.y,
			velocityX: obj.velocityX,
			velocityY: obj.velocityY
		};

		obj.velocity(0, 0);
		datas.set(obj, copy);
		obj.onDestroy(obj, itemDestroyed);
	}

	public function remove(obj:Visual) {
		if (!datas.exists(obj))
			return;

		obj.offDestroy(itemDestroyed);
		datas.remove(obj);
	}

	public function clear() {
		unpause();
		for (obj in datas.keys()) {
			remove(obj);
		}
	}

	function itemDestroyed(item:Entity) {
		datas.remove(cast item);
	}
}
