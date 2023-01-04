tool
extends EditorImportPlugin

const SFXRConfig = preload("SFXRConfig.gd")
const SFXRGenerator = preload("SFXRGenerator.gd")


func get_importer_name():
	return "com.timothyqiu.gdfxr.importer"


func get_visible_name():
	return "SFXR Audio"


func get_recognized_extensions():
	return ["sfxr"]


func get_save_extension():
	return "sample"


func get_resource_type():
	return "AudioStreamSample"


func get_preset_count():
	return 1


func get_preset_name(preset):
	return "Default"


func get_import_options(preset):
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


func get_option_visibility(option, options):
	return true


func import(source_file, save_path, options, platform_variants, gen_files):
	var config := SFXRConfig.new()
	var err := config.load(source_file)
	if err != OK:
		printerr("Failed to open %s: %d" % [source_file, err])
		return err
	
	var stream := SFXRGenerator.new().generate_audio_stream(
		config, options.bit_depth, options.sample_rate
	)
	if options.loop:
		stream.loop_mode = AudioStreamSample.LOOP_FORWARD
		stream.loop_end = stream.data.size()
	
	var filename = save_path + "." + get_save_extension()
	return ResourceSaver.save(filename, stream)
