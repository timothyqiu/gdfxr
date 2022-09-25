tool
extends HBoxContainer

signal param_changed(name, value)
signal param_reset(name)

export var label: String setget set_label
export var parameter: String
export var bipolar := false setget set_bipolar


func set_label(v: String) -> void:
	label = v
	$Label.text = v


func set_bipolar(v: bool) -> void:
	bipolar = v
	if bipolar:
		$HSlider.min_value = -1.0
	else:
		$HSlider.min_value = 0.0


func set_value(v: float) -> void:
	$HSlider.value = v


func get_value() -> float:
	return $HSlider.value


func set_resetable(v: bool) -> void:
	$Reset.disabled = not v


func _on_HSlider_value_changed(value: float):
	emit_signal("param_changed", parameter, value)


func _on_Reset_pressed():
	emit_signal("param_reset", parameter)

