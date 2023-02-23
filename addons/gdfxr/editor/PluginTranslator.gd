@tool
extends Node

var plugin: EditorPlugin :
	set = set_plugin

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
	var path := script.resource_path.get_base_dir().path_join("translations/%s.po" % locale)
	if ResourceLoader.exists(path):
		_translation = ResourceLoader.load(path)
	
	if _translation:
		_translate_node.call_deferred(get_parent())


func t(message: StringName) -> String:
	if _translation:
		var translated := _translation.get_message(message)
		if translated:
			return String(translated)
	return String(message)


func _translate_node(node: Node):
	if node is Control:
		node.tooltip_text = t(node.tooltip_text)
		
		if node is HBoxContainer and node.has_method("set_options"):
			var options = []
			for item in node.options:
				options.append(t(item))
			node.options = options
		
		if node is Button and not node is OptionButton:
			node.text = t(node.text)
		
		if node is Label:
			node.text = t(node.text)
		
		if node is Slider:
			node.tooltip_text = t(node.tooltip_text)
	
	for child in node.get_children():
		_translate_node(child)
