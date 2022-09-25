tool
extends Control

signal value_changed(value)

export var value: float = 0.0 setget set_value
export var min_value: float = 0.0
export var max_value: float = 1.0

var _line_edit: LineEdit

var _stylebox_normal: StyleBox
var _stylebox_hover: StyleBox
var _stylebox_editing: StyleBox
var _stylebox_value: StyleBox

var _line_edit_just_closed := false
var _mouse_hovering := false
var _is_editing := false

var _drag_start_position: Vector2
var _drag_cancelled := true
var _drag_dist := 0.0
var _drag_start_factor: float


func _init() -> void:
	mouse_default_cursor_shape = Control.CURSOR_HSIZE
	rect_clip_content = true
	focus_mode = Control.FOCUS_ALL
	
	var style := StyleBoxEmpty.new()
	style.content_margin_left = 8
	style.content_margin_right = 8
	
	_line_edit = LineEdit.new()
	_line_edit.set_as_toplevel(true)
	_line_edit.visible = false
	_line_edit.add_stylebox_override("normal", style)
	_line_edit.add_stylebox_override("focus", StyleBoxEmpty.new())
	
	var _ret: int
	_ret = _line_edit.connect("focus_exited", self, "_on_line_edit_focus_exited")
	_ret = _line_edit.connect("text_entered", self, "_on_line_edit_text_entered")
	_ret = _line_edit.connect("visibility_changed", self, "_on_line_edit_visibility_changed")
	
	add_child(_line_edit)


func _draw() -> void:
	var font := get_font("font", "LineEdit")
	var color := get_color("highlighted_font_color" if _mouse_hovering else "font_color", "Editor")
	var number_string := "%.3f" % value
	var number_size := font.get_string_size(number_string)
	var pos := Vector2(
		(rect_size.x - number_size.x) / 2,
		(rect_size.y - number_size.y) / 2 + font.get_ascent()
	)
	
	var stylebox := _stylebox_editing if _is_editing else _stylebox_hover if _mouse_hovering else _stylebox_normal
	
	if _line_edit.visible:
		draw_style_box(stylebox, Rect2(Vector2.ZERO, rect_size))
	else:
		var value_width := rect_size.x * ((value - min_value) / (max_value - min_value))
		draw_style_box(stylebox, Rect2(value_width, 0, rect_size.x - value_width, rect_size.y))
		draw_style_box(_stylebox_value, Rect2(0, 0, value_width, rect_size.y))
		draw_string(font, pos, number_string, color)


func _get_minimum_size() -> Vector2:
	var ms := _stylebox_normal.get_minimum_size()
	ms.y += get_font("font", "LineEdit").get_height()
	return ms


func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb and mb.button_index == BUTTON_LEFT:
		if mb.pressed:
			_drag_prepare(mb)
		else:
			_drag_done()
			if _drag_cancelled:
				_show_text_edit()
			_drag_cancelled = true
		_is_editing = mb.pressed
		update()
	
	var mm := event as InputEventMouseMotion
	if mm and mm.button_mask & BUTTON_MASK_LEFT:
		_drag_motion(mm)
		_drag_cancelled = false


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_ENTER_TREE, NOTIFICATION_THEME_CHANGED:
			_update_stylebox()
		
		NOTIFICATION_MOUSE_ENTER:
			_mouse_hovering = true
			update()
		
		NOTIFICATION_MOUSE_EXIT:
			_mouse_hovering = false
			update()
		
		NOTIFICATION_FOCUS_ENTER:
			if (Input.is_action_pressed("ui_focus_next") or Input.is_action_pressed("ui_focus_prev")) and not _line_edit_just_closed:
				_show_text_edit()
			_line_edit_just_closed = false


func set_value(v: float) -> void:
	if is_equal_approx(v, value):
		return
	value = v
	emit_signal("value_changed", value)
	update()


func _update_stylebox() -> void:
	_stylebox_normal = get_stylebox("normal", "LineEdit")
	_stylebox_hover = StyleBoxFlat.new()
	_stylebox_hover.bg_color = get_color("highlight_color", "Editor")
	_stylebox_editing = StyleBoxFlat.new()
	_stylebox_editing.bg_color = get_color("dark_color_2", "Editor")
	_stylebox_value = StyleBoxFlat.new()
	_stylebox_value.bg_color = get_color("accent_color", "Editor") * Color(1, 1, 1, 0.4)


func _drag_prepare(mouse: InputEventMouse) -> void:
	_drag_dist = 0.0
	_drag_start_factor = (value - min_value) / (max_value - min_value)
	_drag_start_position = mouse.global_position
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _drag_done() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	if _drag_cancelled:
		Input.warp_mouse_position(_drag_start_position)
	else:
		Input.warp_mouse_position(rect_global_position + rect_size * Vector2(
			(value - min_value) / (max_value - min_value),
			0.5
		))


func _drag_motion(motion: InputEventMouseMotion) -> void:
	_drag_dist += motion.relative.x
	
	var factor := _drag_start_factor + _drag_dist / rect_size.x
	if factor < 0 or 1 < factor:
		factor = clamp(factor, 0, 1)
		_drag_dist = (factor - _drag_start_factor) * rect_size.x
	
	var v := factor * (max_value - min_value) + min_value
	var snap := motion.command or motion.shift
	if snap and not (is_equal_approx(v, min_value) or is_equal_approx(v, max_value)):
		if motion.shift and motion.command:
			v = round(v * 1000.0) * 0.001
		elif motion.shift:
			v = round(v * 100.0) * 0.01
		else:
			v = round(v * 10.0) * 0.1
	
	set_value(clamp(v, min_value, max_value))
	
	update()


func _show_text_edit() -> void:
	var gr := get_global_rect()
	_line_edit.text = str(value)
	_line_edit.set_position(gr.position)
	_line_edit.set_size(gr.size)
	_line_edit.show_modal()
	_line_edit.select_all()
	_line_edit.grab_focus()
	_line_edit.focus_next = find_next_valid_focus().get_path()
	_line_edit.focus_previous = find_prev_valid_focus().get_path()


func _on_line_edit_focus_exited():
	if _line_edit.get_menu().visible:
		return
	if _line_edit.text.is_valid_float():
		set_value(clamp(_line_edit.text.to_float(), min_value, max_value))
	if not _line_edit_just_closed:
		_line_edit.hide()
	update()


func _on_line_edit_text_entered(_text: String):
	_line_edit.hide()


func _on_line_edit_visibility_changed():
	if not _line_edit.visible:
		_line_edit_just_closed = true
