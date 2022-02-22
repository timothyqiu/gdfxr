tool
extends Container

const SFXRConfig := preload("../SFXRConfig.gd")
const SFXRGenerator := preload("../SFXRGenerator.gd")

var plugin: EditorPlugin

var _config := SFXRConfig.new()
var _config_defaults := SFXRConfig.new()
var _generator := SFXRGenerator.new()
var _path: String
var _modified := false
var _param_map := {}
var _syncing_ui := false # a hack since Range set_value emits value_changed

onready var audio_player := $AudioStreamPlayer as AudioStreamPlayer
onready var filename_label := find_node("Filename") as Label
onready var save_button := find_node("Save") as Button
onready var restore_button := find_node("Restore") as Button
onready var version_button := find_node("VersionButton")
onready var translator := $PluginTranslator


func _ready():
	if not plugin:
		return # Running in the edited scene instead of from Plugin
	
	for child in get_children():
		_hook_plugin(child)
	
	var params := find_node("Params") as Container
	for category in params.get_children():
		for control in category.get_children():
			_param_map[control.parameter] = control
			control.connect("param_changed", self, "_on_param_changed")
			control.connect("param_reset", self, "_on_param_reset")
	
	_set_editing_file("")


func _notification(what: int):
	if not plugin:
		return # Running in the edited scene instead of from Plugin
	
	match what:
		NOTIFICATION_ENTER_TREE, NOTIFICATION_THEME_CHANGED:
			find_node("ScrollContainer").add_stylebox_override("bg", get_stylebox("bg", "Tree"))


func edit(path: String) -> void:
	if _modified:
		_popup_confirm(
			translator.tr("There are unsaved changes.\nOpen '%s' anyway?") % path,
			"_set_editing_file", [path]
		)
	else:
		_set_editing_file(path)


func _hook_plugin(node: Node) -> void:
	if "plugin" in node:
		node.plugin = plugin
	for child in node.get_children():
		_hook_plugin(child)


func _popup_confirm(content: String, callback: String, binds := []) -> void:
	var dialog := ConfirmationDialog.new()
	add_child(dialog)
	dialog.dialog_text = content
	dialog.window_title = translator.tr("SFXR Editor")
	dialog.connect("confirmed", self, callback, binds)
	dialog.connect("popup_hide", dialog, "queue_free")
	dialog.popup_centered()


func _popup_message(content: String) -> void:
	var dialog := AcceptDialog.new()
	add_child(dialog)
	dialog.dialog_text = content
	dialog.window_title = translator.tr("SFXR Editor")
	dialog.connect("popup_hide", dialog, "queue_free")
	dialog.popup_centered()


func _popup_file_dialog(mode: int, callback: String) -> void:
	var dialog := EditorFileDialog.new()
	add_child(dialog)
	dialog.access = EditorFileDialog.ACCESS_RESOURCES
	dialog.mode = mode
	dialog.add_filter("*.sfxr; %s" % translator.tr("SFXR Audio"))
	dialog.connect("popup_hide", dialog, "queue_free")
	dialog.connect("file_selected", self, callback)
	dialog.popup_centered_ratio()


func _reset_defaults() -> void: # SFXRConfig
	_config_defaults.copy_from(_config)
	_set_modified(false)
	_sync_ui()


func _set_editing_file(path: String) -> int: # Error
	if path.empty():
		_config.reset()
		audio_player.stream = null
	else:
		var err := _config.load(path)
		if err != OK:
			_popup_message(translator.tr("'%s' is not a valid SFXR file.") % path)
			return err
		audio_player.stream = load(path)
	
	_path = path
	_reset_defaults()
	return OK


func _set_modified(value: bool) -> void:
	_modified = value
	
	var has_file := not _path.empty()
	var base = _path if has_file else translator.tr("Unsaved sound")
	if _modified:
		base += "(*)"
	filename_label.text = base
	restore_button.disabled = not _modified
	save_button.disabled = has_file and not _modified


func _sync_ui() -> void:
	_syncing_ui = true
	for name in _param_map:
		var control = _param_map[name]
		var value = _config.get(name)
		control.set_value(value)
		control.set_resetable(value != _config_defaults.get(name))
	_syncing_ui = false


func _on_param_changed(name, value):
	if _syncing_ui:
		return
	
	_config.set(name, value)
	
	_param_map[name].set_resetable(value != _config_defaults.get(name))
	
	_set_modified(not _config.is_equal(_config_defaults))
	audio_player.stream = null


func _on_param_reset(name):
	var value = _config_defaults.get(name)
	_config.set(name, value)
	
	_syncing_ui = true
	var control = _param_map[name]
	control.set_value(value)
	control.set_resetable(false)
	_syncing_ui = false
	
	_set_modified(not _config.is_equal(_config_defaults))
	audio_player.stream = null


func _on_Play_pressed(force_regenerate := false):
	if force_regenerate or audio_player.stream == null:
		audio_player.stream = _generator.generate_audio_stream(_config)
	audio_player.play()


func _on_Randomize_pressed(category: int):
	if category == -1:
		_config.randomize()
	else:
		_config.randomize_in_category(category)
	
	_set_modified(true)
	_sync_ui()
	_on_Play_pressed(true)


func _on_Mutate_pressed():
	_config.mutate()
	
	_set_modified(true)
	_sync_ui()
	_on_Play_pressed(true)


func _on_Restore_pressed():
	_set_editing_file(_path)


func _on_New_pressed():
	if _modified:
		_popup_confirm(
			translator.tr("There are unsaved changes.\nCreate a new one anyway?"),
			"_on_New_confirmed"
		)
	else:
		_on_New_confirmed()


func _on_New_confirmed() -> void:
	_set_editing_file("")


func _on_Save_pressed():
	if _path.empty():
		_popup_file_dialog(EditorFileDialog.MODE_SAVE_FILE, "_on_SaveAsDialog_confirmed")
	else:
		_config.save(_path)
		plugin.get_editor_interface().get_resource_filesystem().scan_sources()
		_reset_defaults()


func _on_SaveAsDialog_confirmed(path: String):
	_path = path
	_config.save(path)
	plugin.get_editor_interface().get_resource_filesystem().scan()
	_reset_defaults()


func _on_Load_pressed():
	if _modified:
		_popup_confirm(
			translator.tr("There are unsaved changes.\nLoad anyway?"),
			"_popup_file_dialog", [EditorFileDialog.MODE_OPEN_FILE, "_set_editing_file"]
		)
	else:
		_popup_file_dialog(EditorFileDialog.MODE_OPEN_FILE, "_set_editing_file")

