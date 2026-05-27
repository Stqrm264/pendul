extends VBoxContainer

@onready var shader_material: ShaderMaterial = (%FractalDisplay as ColorRect).material

var step_size: float = 0.0025
var time: float = 3

func _ready() -> void:
	var step_input: SliderInput = $StepInput
	step_input.set_new_name("Step: ")
	step_input.set_units("s")
	step_input.set_min(0.001)
	step_input.set_max(0.01)
	step_input.set_step(0.0001)
	step_input.value_changed.connect(set_step_size)
	step_input.set_value(step_size)

	var time_input: SliderInput = $TimeInput
	time_input.set_new_name("Time: ")
	time_input.set_units("s")
	time_input.set_min(2)
	time_input.set_max(20)
	time_input.set_step(0.1)
	time_input.value_changed.connect(set_time)
	time_input.set_value(time)

func set_step_size(value: float) -> void:
	step_size = value
	shader_material.set_shader_parameter("dt", value)
	shader_material.set_shader_parameter("steps", time / value)

func set_time(value: float) -> void:
	time = value
	shader_material.set_shader_parameter("steps", time / step_size)

func _on_menu_button_item_selected(index: int) -> void:
	print(index);
	shader_material.set_shader_parameter("function", index)
