tool
extends HBoxContainer

signal param_changed(name, value)
signal param_reset(name)

export var label: String setget set_label
export var parameter: String
export var bipolar := false setget set_bipolar

var is_dragging_slider := false


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_ENTER_TREE, NOTIFICATION_THEME_CHANGED:
			var display: Label = $HSlider/Anchor/ValueDisplay
			var bg := StyleBoxFlat.new()
			bg.bg_color = get_color("dark_color_3", "Editor")
			bg.content_margin_bottom = 2
			bg.content_margin_top = 2
			bg.content_margin_left = 4
			bg.content_margin_right = 4
			display.add_stylebox_override("normal", bg)


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


func _update_slider_step():
	$HSlider.step = 0.01 if is_dragging_slider and Input.is_key_pressed(KEY_CONTROL) else 0


func _update_value_display():
	var anchor: Control = $HSlider/Anchor
	var display: Label = $HSlider/Anchor/ValueDisplay
	var slider: Slider = $HSlider
	var grabber_size := slider.get_icon("Grabber").get_size()
	
	display.text = str(slider.value)
	anchor.rect_position.x = slider.ratio * (slider.rect_size.x - grabber_size.x) + grabber_size.x * 0.5


func _on_HSlider_value_changed(value: float):
	_update_value_display()
	emit_signal("param_changed", parameter, value)


func _on_HSlider_mouse_entered():
	$HSlider/Anchor.show()
	_update_value_display()


func _on_HSlider_mouse_exited():
	$HSlider/Anchor.hide()


func _on_HSlider_gui_input(event: InputEvent):
	var mb := event as InputEventMouseButton
	if mb and mb.button_index == BUTTON_LEFT:
		is_dragging_slider = mb.pressed
		_update_slider_step()
	
	var ek := event as InputEventKey
	if ek and is_dragging_slider and ek.scancode == KEY_CONTROL:
		_update_slider_step()


func _on_Reset_pressed():
	emit_signal("param_reset", parameter)

