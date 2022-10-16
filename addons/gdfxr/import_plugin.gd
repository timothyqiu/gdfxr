@tool
extends EditorImportPlugin

const SFXRConfig = preload("SFXRConfig.gd")
const SFXRGenerator = preload("SFXRGenerator.gd")


func _get_importer_name():
	return "com.timothyqiu.gdfxr.importer"


func _get_import_order():
	return ResourceImporter.IMPORT_ORDER_DEFAULT


func _get_visible_name():
	return "SFXR Audio"


func _get_recognized_extensions():
	return ["sfxr"]


func _get_save_extension():
	return "sample"


func _get_resource_type():
	return "AudioStreamWAV"


func _get_preset_count():
	return 1


func _get_preset_name(preset):
	return "Default"


func _get_import_options(path, preset):
	return [
		{
			name="loop",
			default_value=false,
		},
	]


func _get_option_visibility(path, option, options):
	return true


func _import(source_file, save_path, options, platform_variants, gen_files):
	var config := SFXRConfig.new()
	var err := config.load(source_file)
	if err != OK:
		printerr("Failed to open %s: %d" % [source_file, err])
		return err
	
	var stream := SFXRGenerator.new().generate_audio_stream(config)
	if options.loop:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = stream.data.size()
	
	var filename = save_path + "." + _get_save_extension()
	return ResourceSaver.save(stream, filename)
