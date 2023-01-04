# GDScript port of the original SFXR
# https://www.drpetter.se/project_sfxr.html

const SFXRConfig := preload("SFXRConfig.gd")

const master_vol := 0.05

enum WavBits {
	WAV_BITS_8,
	WAV_BITS_16,
}
enum WavFreq {
	WAV_FREQ_44100,
	WAV_FREQ_22050,
}

var _config: SFXRConfig

var rep_time: int
var rep_limit: int
var arp_time: int
var arp_limit: int
var arp_mod: float
var period: int
var fperiod: float
var fmaxperiod: float
var fslide: float
var fdslide: float
var vib_amp: float
var vib_phase: float
var vib_speed: float
var square_duty: float
var square_slide: float
var env_vol: float
var env_length := PackedInt32Array([0, 0, 0])
var phase: int
var fphase: float
var fdphase: float
var iphase: int
var flthp: float
var flthp_d: float
var noise_buffer := PackedFloat32Array([])
var phaser_buffer := PackedFloat32Array([])
var ipp: int
var fltp: float
var fltdp: float
var fltw: float
var fltw_d: float
var fltdmp: float
var fltphp: float


func generate_audio_stream(
	config: SFXRConfig,
	wav_bits: int = WavBits.WAV_BITS_8,
	wav_freq: int = WavFreq.WAV_FREQ_44100
) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS if wav_bits == WavBits.WAV_BITS_8 else AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 44100 if wav_freq == WavFreq.WAV_FREQ_44100 else 22050
	
	_config = config
	stream.data = _generate_samples(wav_bits, wav_freq).data_array
	_config = null
	
	return stream


func generate_samples(
	config: SFXRConfig,
	wav_bits: int = WavBits.WAV_BITS_8,
	wav_freq: int = WavFreq.WAV_FREQ_44100
) -> PackedByteArray:
	_config = config
	var data := _generate_samples(wav_bits, wav_freq).data_array
	_config = null
	return data


func _generate_samples(wav_bits: int, wav_freq: int) -> StreamPeerBuffer:
	_reset_sample(true)
	
	var playing_sample := true
	var env_stage := 0
	var env_time := 0
	var filesample: float = 0
	var fileacc := 0
	var buffer := StreamPeerBuffer.new()
	
	# SynthSample
	while playing_sample:
		rep_time += 1
		if rep_limit != 0 and rep_time >= rep_limit:
			rep_time = 0
			_reset_sample(false)
		
		# frequency envelopes/arpeggios
		arp_time += 1
		if arp_limit != 0 and arp_time >= arp_limit:
			arp_limit = 0
			fperiod *= arp_mod
		fslide += fdslide
		fperiod *= fslide
		if fperiod > fmaxperiod:
			fperiod = fmaxperiod
			if _config.p_freq_limit > 0:
				playing_sample = false
		var rfperiod := fperiod
		if vib_amp > 0.0:
			vib_phase += vib_speed
			rfperiod = fperiod * (1.0 + sin(vib_phase) * vib_amp)
		period = int(max(8, rfperiod))
		square_duty = clamp(square_duty + square_slide, 0.0, 0.5)
		
		# volume envelope
		env_time += 1 # Note: this skips 0 of env_stage 0. Seems problematic.
		if env_time > env_length[env_stage]:
			env_time = 0
			
			while true:
				env_stage += 1
				if env_stage == 3:
					playing_sample = false
					break
				if env_length[env_stage] != 0:
					break
		
		match env_stage:
			0:
				env_vol = float(env_time) / env_length[0]
			1:
				env_vol = 1.0 + pow(1.0 - float(env_time) / env_length[1], 1.0) * 2.0 * _config.p_env_punch
			2:
				env_vol = 1.0 - float(env_time) / env_length[2]
		
		# phaser step
		fphase += fdphase
		iphase = int(min(abs(fphase), 1023))
		
		if flthp_d != 0.0:
			flthp = clamp(flthp * flthp_d, 0.00001, 0.1)
		
		var ssample := 0.0
		for si in 8: # 8x supersampling
			var sample := 0.0
			phase += 1
			if phase >= period:
				phase %= period
				if _config.wave_type == SFXRConfig.WaveType.NOISE:
					for j in 32:
						noise_buffer[j] = randf_range(-1.0, +1.0)
			
			# base waveform
			var fp := float(phase) / period
			match _config.wave_type:
				SFXRConfig.WaveType.SQUARE_WAVE:
					sample = 0.5 if fp < square_duty else -0.5
				SFXRConfig.WaveType.SAWTOOTH:
					sample = 1.0 - fp * 2
				SFXRConfig.WaveType.SINE_WAVE:
					sample = sin(fp * 2 * PI)
				SFXRConfig.WaveType.NOISE:
					sample = noise_buffer[phase * 32 / period]
			
			# lp filter
			var pp := fltp
			fltw = clamp(fltw * fltw_d, 0.0, 0.1)
			if _config.p_lpf_freq == 1.0:
				fltp = sample
				fltdp = 0.0
			else:
				fltdp += (sample - fltp) * fltw
				fltdp -= fltdp * fltdmp
			fltp += fltdp
			
			# hp filter
			fltphp += fltp - pp
			fltphp -= fltphp * flthp
			sample = fltphp
			
			# phaser
			phaser_buffer[ipp & 1023] = sample
			sample += phaser_buffer[(ipp - iphase + 1024) & 1023]
			ipp = (ipp + 1) & 1023
			
			# final accumulation and envelope application
			ssample += sample * env_vol
		
		ssample = ssample / 8 * master_vol
		
		ssample *= 2.0 * _config.sound_vol
		
		ssample *= 4.0 # arbitrary gain to get reasonable output volume...
		ssample = clamp(ssample, -1.0, +1.0)
		
		filesample += ssample
		fileacc += 1
		
		if wav_freq == WavFreq.WAV_FREQ_44100 or fileacc == 2:
			filesample /= fileacc
			fileacc = 0
			
			if wav_bits == WavBits.WAV_BITS_8:
				buffer.put_8(filesample * 255)
			else:
				buffer.put_16(filesample * 32000)
			
			filesample = 0
	
	return buffer


func _reset_sample(restart: bool) -> void:
	fperiod = 100.0 / (_config.p_base_freq * _config.p_base_freq + 0.001)
	period = int(fperiod)
	fmaxperiod = 100.0 / (_config.p_freq_limit * _config.p_freq_limit + 0.001)
	fslide = 1.0 - pow(_config.p_freq_ramp, 3.0) * 0.01
	fdslide = -pow(_config.p_freq_dramp, 3.0) * 0.000001
	square_duty = 0.5 - _config.p_duty * 0.5
	square_slide = -_config.p_duty_ramp * 0.00005
	if _config.p_arp_mod >= 0.0:
		arp_mod = 1.0 - pow(_config.p_arp_mod, 2.0) * 0.9
	else:
		arp_mod = 1.0 + pow(_config.p_arp_mod, 2.0) * 10.0
	arp_time = 0
	arp_limit = int(pow(1.0 - _config.p_arp_speed, 2.0) * 20000 + 32)
	if _config.p_arp_speed == 1.0:
		arp_limit = 0
	
	if restart:
		phase = 0
		
		# Reset filter.
		fltp = 0.0
		fltdp = 0.0
		fltw = pow(_config.p_lpf_freq, 3.0) * 0.1
		fltw_d = 1.0 + _config.p_lpf_ramp * 0.0001
		fltdmp = min(5.0 / (1.0 + pow(_config.p_lpf_resonance, 2.0) * 20.0) * (0.01 + fltw), 0.8)
		fltphp = 0.0
		flthp = pow(_config.p_hpf_freq, 2.0) * 0.1
		flthp_d = 1.0 + _config.p_hpf_ramp * 0.0003
		
		# Reset vibrato
		vib_phase = 0.0
		vib_speed = pow(_config.p_vib_speed, 2.0) * 0.01
		vib_amp = _config.p_vib_strength * 0.5
		
		# Reset envelope
		env_vol = 0.0
		env_length[0] = int(_config.p_env_attack * _config.p_env_attack * 100000.0)
		env_length[1] = int(_config.p_env_sustain * _config.p_env_sustain * 100000.0)
		env_length[2] = int(_config.p_env_decay * _config.p_env_decay * 100000.0)
		
		fphase = pow(_config.p_pha_offset, 2.0) * 1020.0
		if _config.p_pha_offset < 0.0:
			fphase = -fphase
		fdphase = pow(_config.p_pha_ramp, 2.0) * 1.0
		if _config.p_pha_ramp < 0.0:
			fdphase = -fdphase
		iphase = int(abs(fphase))
		ipp = 0
		
		phaser_buffer.resize(1024)
		for i in phaser_buffer.size():
			phaser_buffer[i] = 0.0
		
		noise_buffer.resize(32)
		for i in noise_buffer.size():
			noise_buffer[i] = randf_range(-1.0, +1.0)
		
		rep_time = 0
		rep_limit = int(pow(1.0 - _config.p_repeat_speed, 2.0) * 20000 + 32)
		if _config.p_repeat_speed == 0.0:
			rep_limit = 0
