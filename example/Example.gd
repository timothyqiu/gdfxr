extends CenterContainer

func _ready() -> void:
	var audio := load("res://example/example.sfxr") as AudioStreamSample
	print(audio)
	audio.save_to_wav("/home/timothy/Desktop/foo.wav")
	$AudioStreamPlayer.stream = audio
