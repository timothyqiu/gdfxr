@tool
extends HBoxContainer

signal param_changed(name, value)
signal param_submitted(name)
signal param_reset(name)

@export var options: Array :
	set = set_options
@export var parameter: String # Could be PackedStringArray, but pybabel won't catch that

@onready var option_button := $OptionButton as OptionButton


func _ready():
	set_options(options)


func set_options(v: Array) -> void:
	options = v
	
	if is_inside_tree():
		option_button.clear()
		for item in options:
			option_button.add_item(item)


func set_value(v: int) -> void:
	option_button.select(v)


func get_value() -> int:
	return option_button.selected


func set_resetable(v: bool) -> void:
	$Reset.disabled = not v


func _on_OptionButton_item_selected(index: int):
	param_changed.emit(parameter, index)
	param_submitted.emit(parameter)


func _on_Reset_pressed():
	param_reset.emit(parameter)
