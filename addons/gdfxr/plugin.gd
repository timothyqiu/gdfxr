@tool
extends EditorPlugin


var import_plugin: EditorImportPlugin
var sfxr_editor: Control


func _enter_tree():
	import_plugin = preload("import_plugin.gd").new()
	add_import_plugin(import_plugin)
	
	sfxr_editor = preload("editor/Editor.tscn").instantiate()
	sfxr_editor.plugin = self
	add_control_to_bottom_panel(sfxr_editor, "gdfxr")


func _exit_tree():
	remove_control_from_bottom_panel(sfxr_editor)
	sfxr_editor.queue_free()
	sfxr_editor = null
	
	remove_import_plugin(import_plugin)
	import_plugin = null


func _handles(object: Object) -> bool:
	return object is AudioStreamWAV and object.resource_path.ends_with(".sfxr")


func _edit(object: Object):
	sfxr_editor.edit(object)


func _make_visible(visible: bool):
	if visible:
		make_bottom_panel_item_visible(sfxr_editor)
	elif sfxr_editor.is_visible_in_tree():
		hide_bottom_panel()
