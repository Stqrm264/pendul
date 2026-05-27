extends VBoxContainer
class_name SliderInput

@onready var name_label: Label = %Name
@onready var text_input: LineEdit = %TextInput
@onready var units_label: Label = %Units
@onready var slider: HSlider = %Slider

signal value_changed(new_value: float)

func set_new_name(new_name: StringName) -> void:
	name_label.text = new_name

func set_units(units: StringName) -> void:
	units_label.text = units

func set_min(new_min: float) -> void:
	slider.min_value = new_min

func set_max(new_max: float) -> void:
	slider.max_value = new_max

func set_step(step: float) -> void:
	slider.step = step

func set_value(value: float) -> void:
	text_input.text = str(value)
	slider.value = value
	value_changed.emit(value)

func _on_slider_value_changed(value: float) -> void:
	set_value(value)

func _on_text_input_text_submitted(new_text: String) -> void:
	if new_text.is_valid_float():
		var value: float = new_text.to_float()
		value = clamp(value, slider.min_value, slider.max_value)
		set_value(value)
	else:
		text_input.text = str(slider.value)
