extends Label

func _ready() -> void:
	Engine.max_fps = 120

var sum: float = 0
var cnt: int = 0
@export var threshold: float = 1
func _process(delta: float) -> void:
	cnt += 1
	sum += delta
	if sum > threshold:
		var fps: float = cnt / sum
		fps = snapped(fps, 0.1)
		text = "FPS: " + str(fps)
		sum = 0
		cnt = 0
