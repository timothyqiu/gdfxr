tool
extends Container

enum ExtraOption { SAVE_AS, COPY, PASTE, PASTE_JSFXR, RECENT }
enum DefaultFilename { EMPTY, GUESS_FOR_SAVE }

const SFXRConfig := preload("../SFXRConfig.gd")
const SFXRGenerator := preload("../SFXRGenerator.gd")
const Base58 := preload("../Base58.gd")
const NUM_RECENTS := 4

class RecentEntry:
	var title: String
	var config := SFXRConfig.new()

var plugin: EditorPlugin

var _config := SFXRConfig.new()
var _config_defaults := SFXRConfig.new()
var _config_clipboard: SFXRConfig
var _config_recents: Array
var _recents_id := 0
var _generator := SFXRGenerator.new()
var _path: String
var _modified := false
var _param_map := {}
var _syncing_ui := false # a hack since Range set_value emits value_changed
var _category_names := {}

onready var audio_player := $AudioStreamPlayer as AudioStreamPlayer
onready var filename_label := find_node("Filename") as Label
onready var save_button := find_node("Save") as Button
onready var restore_button := find_node("Restore") as Button
onready var extra_button := find_node("Extra") as MenuButton
onready var version_button := find_node("VersionButton")
onready var translator := $PluginTranslator


func _ready():
	if not plugin:
		return # Running in the edited scene instead of from Plugin
	
	for child in get_children():
		_hook_plugin(child)
	
	var popup := extra_button.get_popup()
	popup.add_item(translator.tr("Save As..."), ExtraOption.SAVE_AS)
	popup.add_separator()
	popup.add_item(translator.tr("Copy"), ExtraOption.COPY)
	popup.add_item(translator.tr("Paste"), ExtraOption.PASTE)
	popup.add_item(translator.tr("Paste from jsfxr"), ExtraOption.PASTE_JSFXR)
	popup.add_separator(translator.tr("Recently Generated"))
	popup.connect("id_pressed", self, "_on_Extra_id_pressed")
	
	_category_names = {
		SFXRConfig.Category.PICKUP_COIN: translator.tr("Pickup/Coin"),
		SFXRConfig.Category.LASER_SHOOT: translator.tr("Laser/Shoot"),
		SFXRConfig.Category.EXPLOSION: translator.tr("Explosion"),
		SFXRConfig.Category.POWERUP: translator.tr("Powerup"),
		SFXRConfig.Category.HIT_HURT: translator.tr("Hit/Hurt"),
		SFXRConfig.Category.JUMP: translator.tr("Jump"),
		SFXRConfig.Category.BLIP_SELECT: translator.tr("Blip/Select"),
	}
	
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
			
			if extra_button:
				var popup = extra_button.get_popup()
				popup.set_item_icon(popup.get_item_index(ExtraOption.COPY), get_icon("ActionCopy", "EditorIcons"))
				popup.set_item_icon(popup.get_item_index(ExtraOption.PASTE), get_icon("ActionPaste", "EditorIcons"))


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


func _push_recent(title: String) -> void:
	var recent: RecentEntry
	if _config_recents.size() < NUM_RECENTS:
		recent = RecentEntry.new()
	else:
		recent = _config_recents.pop_back()
	
	_recents_id += 1
	recent.title = "#%d %s" % [_recents_id, title]
	recent.config.copy_from(_config)
	
	_config_recents.push_front(recent)


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


func _popup_file_dialog(mode: int, callback: String, default_filename: int = DefaultFilename.EMPTY) -> void:
	var dialog := EditorFileDialog.new()
	add_child(dialog)
	dialog.access = EditorFileDialog.ACCESS_RESOURCES
	dialog.mode = mode
	
	match default_filename:
		DefaultFilename.EMPTY:
			pass
		
		DefaultFilename.GUESS_FOR_SAVE:
			if _path:
				dialog.current_path = _generate_serial_path(_path)
	
	dialog.add_filter("*.sfxr; %s" % translator.tr("SFXR Audio"))
	dialog.connect("popup_hide", dialog, "queue_free")
	dialog.connect("file_selected", self, callback)
	dialog.popup_centered_ratio()


func _reset_defaults() -> void:
	_config_defaults.copy_from(_config)
	_set_modified(false)
	_sync_ui()


func _restore_from_config(config: SFXRConfig) -> void:
	_config.copy_from(config)
	_sync_ui()
	_set_modified(not config.is_equal(_config_defaults))
	audio_player.stream = null


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


func _generate_serial_path(path: String) -> String:
	var directory := Directory.new()
	if directory.open(path.get_base_dir()) != OK:
		return path
	
	if not directory.file_exists(path.get_file()):
		return path
	
	var basename := path.get_basename()
	var extension := path.get_extension()
	
	# Extract trailing number.
	var num_string: String
	for i in range(basename.length() - 1, -1, -1):
		var c: String = basename[i]
		if "0" <= c and c <= "9":
			num_string = c + num_string
		else:
			break
	var number := num_string.to_int() if num_string else 0
	var name_string: String = basename.substr(0, basename.length() - num_string.length())
	
	while true:
		number += 1
		var attemp := "%s%d.%s" % [name_string, number, extension]
		if not directory.file_exists(attemp):
			return attemp
	
	return path  # Unreachable


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
		_push_recent(translator.tr("Randomize"))
	else:
		_config.randomize_in_category(category)
		_push_recent(_category_names.get(category, "Unknown"))
	
	_set_modified(true)
	_sync_ui()
	_on_Play_pressed(true)


func _on_Mutate_pressed():
	_config.mutate()
	
	_push_recent(translator.tr("Mutate"))
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


func _on_Extra_about_to_show():
	var popup := extra_button.get_popup()
	popup.set_item_disabled(popup.get_item_index(ExtraOption.PASTE), _config_clipboard == null)
	popup.set_item_disabled(popup.get_item_index(ExtraOption.PASTE_JSFXR), not OS.has_clipboard())
	
	# Rebuild recents menu everytime :)
	var first_recent_index := popup.get_item_index(ExtraOption.RECENT)
	if first_recent_index != -1:
		var count := popup.get_item_count()
		for i in count - first_recent_index:
			popup.remove_item(count - 1 - i)
	
	if _config_recents.empty():
		popup.add_item(translator.tr("None"), ExtraOption.RECENT)
		popup.set_item_disabled(popup.get_item_index(ExtraOption.RECENT), true)
	else:
		for i in _config_recents.size():
			popup.add_item(_config_recents[i].title, ExtraOption.RECENT + i)


func _on_Extra_id_pressed(id: int) -> void:
	match id:
		ExtraOption.SAVE_AS:
			_popup_file_dialog(EditorFileDialog.MODE_SAVE_FILE, "_on_SaveAsDialog_confirmed", DefaultFilename.GUESS_FOR_SAVE)
		
		ExtraOption.COPY:
			if not _config_clipboard:
				_config_clipboard = SFXRConfig.new()
			_config_clipboard.copy_from(_config)
		
		ExtraOption.PASTE:
			_restore_from_config(_config_clipboard)
		
		ExtraOption.PASTE_JSFXR:
			var pasted := SFXRConfig.new()
			if pasted.load_from_base58(OS.clipboard) == OK:
				_restore_from_config(pasted)
			else:
				_popup_message(translator.tr("Clipboard does not contain code copied from jsfxr."))
		
		_:
			var i := id - ExtraOption.RECENT as int
			if i < 0 or _config_recents.size() <= i:
				printerr("Bad index %d (%d in total)" % [i, _config_recents.size()])
				return
			var recent: RecentEntry = _config_recents[i]
			_restore_from_config(recent.config)
			_on_Play_pressed()

