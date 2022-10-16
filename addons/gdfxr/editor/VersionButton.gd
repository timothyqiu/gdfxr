@tool
extends LinkButton

@export var website: String

var plugin: EditorPlugin :
	set = set_plugin


func set_plugin(v: EditorPlugin) -> void:
	plugin = v
	
	var script := get_script() as Script
	var path := script.resource_path.get_base_dir().path_join("../plugin.cfg")
	
	var cfg := ConfigFile.new()
	var err := cfg.load(path)
	text = "%s v%s" % [
		cfg.get_value("plugin", "name", "plugin"),
		cfg.get_value("plugin", "version", "1.0"),
	]


func _on_VersionButton_pressed():
	if website:
		OS.shell_open(website)
