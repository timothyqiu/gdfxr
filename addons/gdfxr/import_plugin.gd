@tool
extends EditorImportPlugin

const SFXRConfig = preload("SFXRConfig.gd")
const SFXRGenerator = preload("SFXRGenerator.gd")


func _get_importer_name():
	return "com.timothyqiu.gdfxr.importer"


func _get_import_order():
	return ResourceImporter.IMPORT_ORDER_DEFAULT


func _get_priority():
	return 1.0


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
		{
			name="bit_depth",
			property_hint=PROPERTY_HINT_ENUM,
			hint_string="8 Bits,16 Bits",
			default_value=SFXRGenerator.WavBits.WAV_BITS_8,
		},
		{
			name="sample_rate",
			property_hint=PROPERTY_HINT_ENUM,
			hint_string="44100 Hz,22050 Hz",
			default_value=SFXRGenerator.WavFreq.WAV_FREQ_44100,
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
	
	var stream := SFXRGenerator.new().generate_audio_stream(
		config, options.bit_depth, options.sample_rate
	)
	if options.loop:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = stream.data.size()
	
	var filename = save_path + "." + _get_save_extension()
	return ResourceSaver.save(stream, filename)
