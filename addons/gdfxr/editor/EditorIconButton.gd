@tool
extends Button

@export var icon_name: String

var plugin: EditorPlugin # a hack to know if this is executing as plugin


func _notification(what: int):
	if not plugin:
		return
	
	match what:
		NOTIFICATION_ENTER_TREE, NOTIFICATION_THEME_CHANGED:
			if icon_name:
				icon = get_theme_icon(icon_name, "EditorIcons")
