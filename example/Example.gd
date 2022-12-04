extends Container

# These two classes are for runtime generation.
const SFXRConfig = preload("res://addons/gdfxr/SFXRConfig.gd")
const SFXRGenerator = preload("res://addons/gdfxr/SFXRGenerator.gd")

@onready var audio_player: AudioStreamPlayer = $AudioPlayer
@onready var adhoc_audio_player: AudioStreamPlayer = $AdhocAudioPlayer


func _on_Play_pressed() -> void:
	audio_player.play()


func _on_PlayFile_pressed() -> void:
	adhoc_audio_player.stream = preload("res://example/example.sfxr")
	adhoc_audio_player.play()


func _on_Generate_pressed() -> void:
	var config := SFXRConfig.new()
	
	# Fill the fields manually
	# config.p_base_freq = 0.5
	
	# Load from .sfxr file
	# config.load("res://example/example.sfxr")
	
	# Load from jsfxr base58 string
	config.load_from_base58("34T6PkmKkNTf3aUynCpV3oetaq6ecj9Grh9W7tiTbccVYK8FxNKBbfBFXJCLzk8QTy4d7fbiCfY2gXDaiengXbENjdLWt5jZBtcz8QmSCXjHCSuooDCWp4SrT")
	
	# generate_audio_stream() might freeze a bit when generating long sounds.
	# It's recommended to pre-generate the sound effects in editor.
	# If you do want to generate the sound effects on the fly, you might want
	# to generate and cache the sound effects at the start of your game.
	var generator := SFXRGenerator.new()
	adhoc_audio_player.stream = generator.generate_audio_stream(config)
	adhoc_audio_player.play()
