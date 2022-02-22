# GDScript port of the original SFXR
# https://www.drpetter.se/project_sfxr.html

enum WaveType {
	SQUARE_WAVE,
	SAWTOOTH,
	SINE_WAVE,
	NOISE,
}

enum Category {
	PICKUP_COIN,
	LASER_SHOOT,
	EXPLOSION,
	POWERUP,
	HIT_HURT,
	JUMP,
	BLIP_SELECT,
}

var wave_type: int = WaveType.SQUARE_WAVE

var p_env_attack := 0.0 # Attack Time
var p_env_sustain := 0.3 # Sustain Time
var p_env_punch := 0.0 # Sustain Punch
var p_env_decay := 0.4 # Decay Time

var p_base_freq := 0.3 # Start Frequency
var p_freq_limit := 0.0 # Min Frequency
var p_freq_ramp := 0.0 # Slide
var p_freq_dramp := 0.0 # Delta Slide
var p_vib_strength := 0.0 # Vibrato Depth
var p_vib_speed := 0.0 # Vibrato Speed

var p_duty := 0.0 # Square Duty
var p_duty_ramp := 0.0 # Duty Sweep

var p_arp_mod := 0.0 # Change Amount
var p_arp_speed := 0.0 # Change Speed

var p_repeat_speed := 0.0 # Repeat Speed

var p_pha_offset := 0.0 # Phaser Offset
var p_pha_ramp := 0.0 # Phaser Weep

var p_lpf_freq := 1.0 # Lp Filter Cutoff
var p_lpf_ramp := 0.0 # Lp Filter Cutoff Sweep
var p_lpf_resonance := 0.0 # Lp Filter Resonance
var p_hpf_freq := 0.0 # Hp Filter Cutoff
var p_hpf_ramp := 0.0 # Hp Filter Cutoff Sweep

var sound_vol := 0.5


func load(path: String) -> int: # Error
	var f := File.new()
	var err := f.open(path, File.READ)
	if err != OK:
		return err
	
	var version := f.get_32()
	if not [100, 101, 102].has(version):
		return ERR_FILE_UNRECOGNIZED
	
	wave_type = f.get_32()
	sound_vol = 0.5
	if version == 102:
		sound_vol = f.get_float()
	
	p_base_freq = f.get_float()
	p_freq_limit = f.get_float()
	p_freq_ramp = f.get_float()
	if version >= 101:
		p_freq_dramp = f.get_float()
	p_duty = f.get_float()
	p_duty_ramp = f.get_float()
	
	p_vib_strength = f.get_float()
	p_vib_speed = f.get_float()
	f.get_float() # p_vib_delay
	
	p_env_attack = f.get_float()
	p_env_sustain = f.get_float()
	p_env_decay = f.get_float()
	p_env_punch = f.get_float()
	
	f.get_8() # filter_on
	p_lpf_resonance = f.get_float()
	p_lpf_freq = f.get_float()
	p_lpf_ramp = f.get_float()
	p_hpf_freq = f.get_float()
	p_hpf_ramp = f.get_float()
	
	p_pha_offset = f.get_float()
	p_pha_ramp = f.get_float()
	
	p_repeat_speed = f.get_float()
	
	if version >= 101:
		p_arp_speed = f.get_float()
		p_arp_mod = f.get_float()
	
	return OK


func save(path: String) -> int: # Error
	var f := File.new()
	var err := f.open(path, File.WRITE)
	if err != OK:
		return err
	
	f.store_32(102)
	f.store_32(wave_type)
	f.store_float(sound_vol)
	
	f.store_float(p_base_freq)
	f.store_float(p_freq_limit)
	f.store_float(p_freq_ramp)
	f.store_float(p_freq_dramp)
	f.store_float(p_duty)
	f.store_float(p_duty_ramp)
	
	f.store_float(p_vib_strength)
	f.store_float(p_vib_speed)
	f.store_float(0) # p_vib_delay
	
	f.store_float(p_env_attack)
	f.store_float(p_env_sustain)
	f.store_float(p_env_decay)
	f.store_float(p_env_punch)
	
	f.store_8(true) # filter_on
	f.store_float(p_lpf_resonance)
	f.store_float(p_lpf_freq)
	f.store_float(p_lpf_ramp)
	f.store_float(p_hpf_freq)
	f.store_float(p_hpf_ramp)
	
	f.store_float(p_pha_offset)
	f.store_float(p_pha_ramp)
	
	f.store_float(p_repeat_speed)
	
	f.store_float(p_arp_speed)
	f.store_float(p_arp_mod)
	
	return OK


func randomize_in_category(category: int) -> void:
	reset()
	
	match category:
		Category.PICKUP_COIN:
			p_base_freq = rand_range(0.4, 0.9)
			p_env_attack = 0.0
			p_env_sustain = rand_range(0.0, 0.1)
			p_env_decay = rand_range(0.1, 0.5)
			p_env_punch = rand_range(0.3, 0.6)
			if randi() % 2:
				p_arp_speed = rand_range(0.5, 0.7)
				p_arp_mod = rand_range(0.2, 0.6)
		
		Category.LASER_SHOOT:
			wave_type = randi() % 3
			if wave_type == 2 and randi() % 2:
				wave_type = randi() % 2
			p_base_freq = rand_range(0.5, 1.0)
			p_freq_limit = max(0.2, p_base_freq - rand_range(0.2, 0.8))
			p_freq_ramp = rand_range(-0.35, -0.15)
			if randi() % 3 == 0:
				p_base_freq = rand_range(0.3, 0.9)
				p_freq_limit = rand_range(0, 0.1)
				p_freq_ramp = rand_range(-0.65, -0.35)
			if randi() % 2:
				p_duty = rand_range(0, 0.5)
				p_duty_ramp = rand_range(0, 0.2)
			else:
				p_duty = rand_range(0.4, 0.9)
				p_duty_ramp = rand_range(-0.7, 0)
			p_env_attack = 0.0
			p_env_sustain = rand_range(0.1, 0.3)
			p_env_decay = rand_range(0.0, 0.4)
			if randi() % 2:
				p_env_punch = rand_range(0, 0.3)
			if randi() % 3 == 0:
				p_pha_offset = rand_range(0, 0.2)
				p_pha_ramp = rand_range(0, 0.2)
			if randi() % 2:
				p_hpf_freq = rand_range(0, 0.3)
		
		Category.EXPLOSION:
			wave_type = WaveType.NOISE
			if randi() % 2:
				p_base_freq = rand_range(0.1, 0.4)
				p_freq_ramp = rand_range(-0.1, 0.3)
			else:
				p_base_freq = rand_range(0.2, 0.9)
				p_freq_ramp = rand_range(-0.4, -0.2)
			p_base_freq *= p_base_freq
			if randi() % 5 == 0:
				p_freq_ramp = 0.0
			if randi() % 3 == 0:
				p_repeat_speed = rand_range(0.3, 0.8)
			p_env_attack = 0.0
			p_env_sustain = rand_range(0.1, 0.4)
			p_env_decay = rand_range(0, 0.5)
			if randi() % 2:
				p_pha_offset = rand_range(-0.3, 0.6)
				p_pha_ramp = rand_range(-0.3, 0)
			p_env_punch = rand_range(0.2, 0.8)
			if randi() % 2:
				p_vib_strength = rand_range(0, 0.7)
				p_vib_speed = rand_range(0, 0.6)
			if randi() % 3:
				p_arp_speed = rand_range(0.6, 0.9)
				p_arp_mod = rand_range(-0.8, 0.8)
		
		Category.POWERUP:
			if randi() % 2:
				wave_type = WaveType.SAWTOOTH
			else:
				p_duty = rand_range(0, 0.6)
			if randi() % 2:
				p_base_freq = rand_range(0.2, 0.5)
				p_freq_ramp = rand_range(0.1, 0.5)
				p_repeat_speed = rand_range(0.4, 0.8)
			else:
				p_base_freq = rand_range(0.2, 0.5)
				p_freq_ramp = rand_range(0.05, 0.25)
				if randi() % 2:
					p_vib_strength = rand_range(0, 0.7)
					p_vib_speed = rand_range(0, 0.6)
			p_env_attack = 0.0
			p_env_sustain = rand_range(0, 0.4)
			p_env_decay = rand_range(0.1, 0.5)
		
		Category.HIT_HURT:
			wave_type = randi() % 3
			match wave_type:
				WaveType.SINE_WAVE:
					wave_type = WaveType.NOISE
				WaveType.SQUARE_WAVE:
					p_duty = rand_range(0, 0.6)
			p_base_freq = rand_range(0.2, 0.8)
			p_freq_ramp = rand_range(-0.7, -0.3)
			p_env_attack = 0.0
			p_env_sustain = rand_range(0, 0.1)
			p_env_decay = rand_range(0.1, 0.3)
			if randi() % 2:
				p_hpf_freq = rand_range(0, 0.3)
		
		Category.JUMP:
			wave_type = WaveType.SQUARE_WAVE
			p_duty = rand_range(0, 0.6)
			p_base_freq = rand_range(0.3, 0.6)
			p_freq_ramp = rand_range(0.1, 0.3)
			p_env_attack = 0.0
			p_env_sustain = rand_range(0.1, 0.4)
			p_env_decay = rand_range(0.1, 0.3)
			if randi() % 2:
				p_hpf_freq = rand_range(0, 0.3)
			if randi() % 2:
				p_lpf_freq = rand_range(0.4, 1.0)
		
		Category.BLIP_SELECT:
			wave_type = randi() % 2
			if wave_type == WaveType.SQUARE_WAVE:
				p_duty = rand_range(0, 0.6)
			p_base_freq = rand_range(0.2, 0.6)
			p_env_attack = 0.0
			p_env_sustain = rand_range(0.1, 0.2)
			p_env_decay = rand_range(0, 0.2)
			p_hpf_freq = 0.1


func randomize() -> void:
	p_base_freq = pow(rand_range(-1.0, +1.0), 2.0)
	if randi() % 2:
		p_base_freq = pow(rand_range(-1.0, +1.0), 3.0) + 0.5
	p_freq_limit = 0.0
	p_freq_ramp = pow(rand_range(-1.0, +1.0), 5.0)
	if p_base_freq > 0.7 and p_freq_ramp > 0.2:
		p_freq_ramp = -p_freq_ramp
	if p_base_freq < 0.2 and p_freq_ramp < -0.05:
		p_freq_ramp = -p_freq_ramp
	p_freq_dramp = pow(rand_range(-1.0, +1.0), 3.0)
	p_duty = rand_range(-1.0, +1.0)
	p_duty_ramp = pow(rand_range(-1.0, +1.0), 3.0)
	p_vib_strength = pow(rand_range(-1.0, +1.0), 3.0)
	p_vib_speed = rand_range(-1.0, +1.0)
	# p_vib_delay = rand_range(-1.0, +1.0)
	p_env_attack = pow(rand_range(-1.0, +1.0), 3.0)
	p_env_sustain = pow(rand_range(-1.0, +1.0), 2.0)
	p_env_decay = rand_range(-1.0, +1.0)
	p_env_punch = pow(rand_range(0, 0.8), 2.0)
	if p_env_attack + p_env_sustain + p_env_decay < 0.2:
		p_env_sustain += rand_range(0.2, 0.5)
		p_env_decay += rand_range(0.2, 0.5)
	p_lpf_resonance = rand_range(-1.0, +1.0)
	p_lpf_freq = 1.0 - pow(randf(), 3.0)
	p_lpf_ramp = pow(rand_range(-1.0, +1.0), 3.0)
	if p_lpf_freq < 0.1 and p_lpf_ramp < -0.05:
		p_lpf_ramp = -p_lpf_ramp
	p_hpf_freq = pow(randf(), 5.0)
	p_hpf_ramp = pow(rand_range(-1.0, +1.0), 5.0)
	p_pha_offset = pow(rand_range(-1.0, +1.0), 3.0)
	p_pha_ramp = pow(rand_range(-1.0, +1.0), 3.0)
	p_repeat_speed = rand_range(-1.0, +1.0)
	p_arp_speed = rand_range(-1.0, +1.0)
	p_arp_mod = rand_range(-1.0, +1.0)


func mutate() -> void:
	if randi() % 2:
		p_base_freq += rand_range(-0.05, +0.05)
	if randi() % 2:
		p_freq_limit += rand_range(-0.05, +0.05)
	if randi() % 2:
		p_freq_ramp += rand_range(-0.05, +0.05)
	if randi() % 2:
		p_freq_dramp += rand_range(-0.05, +0.05)
	if randi() % 2:
		p_duty += rand_range(-0.05, +0.05)
	if randi() % 2:
		p_duty_ramp += rand_range(-0.05, +0.05)
	if randi() % 2:
		p_vib_strength += rand_range(-0.05, +0.05)
	if randi() % 2:
		p_vib_speed += rand_range(-0.05, +0.05)
#	if randi() % 2:
#		p_vib_delay += rand_range(-0.05, +0.05)
	if randi() % 2:
		p_env_attack += rand_range(-0.05, +0.05)
	if randi() % 2:
		p_env_sustain += rand_range(-0.05, +0.05)
	if randi() % 2:
		p_env_decay += rand_range(-0.05, +0.05)
	if randi() % 2:
		p_env_punch += rand_range(-0.05, +0.05)
	if randi() % 2:
		p_lpf_resonance += rand_range(-0.05, +0.05)
	if randi() % 2:
		p_lpf_freq += rand_range(-0.05, +0.05)
	if randi() % 2:
		p_lpf_ramp += rand_range(-0.05, +0.05)
	if randi() % 2:
		p_hpf_freq += rand_range(-0.05, +0.05)
	if randi() % 2:
		p_hpf_ramp += rand_range(-0.05, +0.05)
	if randi() % 2:
		p_pha_offset += rand_range(-0.05, +0.05)
	if randi() % 2:
		p_pha_ramp += rand_range(-0.05, +0.05)
	if randi() % 2:
		p_repeat_speed += rand_range(-0.05, +0.05)
	if randi() % 2:
		p_arp_speed += rand_range(-0.05, +0.05)
	if randi() % 2:
		p_arp_mod += rand_range(-0.05, +0.05)


func reset():
	wave_type = WaveType.SQUARE_WAVE

	p_base_freq = 0.3
	p_freq_limit = 0.0
	p_freq_ramp = 0.0
	p_freq_dramp = 0.0
	p_duty = 0.0
	p_duty_ramp = 0.0

	p_vib_strength = 0.0
	p_vib_speed = 0.0
	# p_vib_delay = 0.0

	p_env_attack = 0.0
	p_env_sustain = 0.3
	p_env_decay = 0.4
	p_env_punch = 0.0

	# filter_on = false
	p_lpf_resonance = 0.0
	p_lpf_freq = 1.0
	p_lpf_ramp = 0.0
	p_hpf_freq = 0.0
	p_hpf_ramp = 0.0

	p_pha_offset = 0.0
	p_pha_ramp = 0.0

	p_repeat_speed = 0.0

	p_arp_speed = 0.0
	p_arp_mod = 0.0


func copy_from(other: Reference) -> void: # SFXRConfig
	wave_type = other.wave_type

	p_env_attack = other.p_env_attack
	p_env_sustain = other.p_env_sustain
	p_env_punch = other.p_env_punch
	p_env_decay = other.p_env_decay

	p_base_freq = other.p_base_freq
	p_freq_limit = other.p_freq_limit
	p_freq_ramp = other.p_freq_ramp
	p_freq_dramp = other.p_freq_dramp
	p_vib_strength = other.p_vib_strength
	p_vib_speed = other.p_vib_speed

	p_duty = other.p_duty
	p_duty_ramp = other.p_duty_ramp

	p_arp_mod = other.p_arp_mod
	p_arp_speed = other.p_arp_speed

	p_repeat_speed = other.p_repeat_speed

	p_pha_offset = other.p_pha_offset
	p_pha_ramp = other.p_pha_ramp

	p_lpf_freq = other.p_lpf_freq
	p_lpf_ramp = other.p_lpf_ramp
	p_lpf_resonance = other.p_lpf_resonance
	p_hpf_freq = other.p_hpf_freq
	p_hpf_ramp = other.p_hpf_ramp

	sound_vol = other.sound_vol


func is_equal(other: Reference) -> bool: # SFXRConfig
	return (
		wave_type == other.wave_type

		and p_env_attack == other.p_env_attack
		and p_env_sustain == other.p_env_sustain
		and p_env_punch == other.p_env_punch
		and p_env_decay == other.p_env_decay

		and p_base_freq == other.p_base_freq
		and p_freq_limit == other.p_freq_limit
		and p_freq_ramp == other.p_freq_ramp
		and p_freq_dramp == other.p_freq_dramp
		and p_vib_strength == other.p_vib_strength
		and p_vib_speed == other.p_vib_speed

		and p_duty == other.p_duty
		and p_duty_ramp == other.p_duty_ramp

		and p_arp_mod == other.p_arp_mod
		and p_arp_speed == other.p_arp_speed

		and p_repeat_speed == other.p_repeat_speed

		and p_pha_offset == other.p_pha_offset
		and p_pha_ramp == other.p_pha_ramp

		and p_lpf_freq == other.p_lpf_freq
		and p_lpf_ramp == other.p_lpf_ramp
		and p_lpf_resonance == other.p_lpf_resonance
		and p_hpf_freq == other.p_hpf_freq
		and p_hpf_ramp == other.p_hpf_ramp

		and sound_vol == other.sound_vol
	)
