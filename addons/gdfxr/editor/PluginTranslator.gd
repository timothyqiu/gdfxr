tool
extends Node

var plugin: EditorPlugin setget set_plugin

var _translation: Translation


func set_plugin(v: EditorPlugin) -> void:
	if plugin == v:
		return
	if not v:
		plugin = null
		_translation = null
		return
	
	plugin = v
	var locale: String = plugin.get_editor_interface().get_editor_settings().get('interface/editor/editor_language')
	var script := get_script() as Script
	var path := script.resource_path.get_base_dir().plus_file("translations/%s.po" % locale)
	if ResourceLoader.exists(path):
		_translation = ResourceLoader.load(path)
	
	if _translation:
		_translate_node(get_parent())


func tr(message: String) -> String:
	if _translation:
		var translated := _translation.get_message(message)
		if not translated.empty():
			return translated
	return message


func _translate_node(node: Node):
	if node is Control:
		node.hint_tooltip = tr(node.hint_tooltip)
		
		if node is HBoxContainer and node.has_method("set_options"):
			var options = []
			for item in node.options:
				options.append(tr(item))
			node.options = options
		
		if node is Button and not node is OptionButton:
			node.text = tr(node.text)
		
		if node is Label:
			node.text = tr(node.text)
	
	for child in node.get_children():
		_translate_node(child)
