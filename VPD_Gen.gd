extends AudioStreamPlayer

onready var playback:AudioStreamPlayback = get_stream_playback()
var freq = 220
var phase = 0.0  #Oscillator phase
enum {SAW, SINE, TRI, PULSE}
var osc = 0.0
var crush = 5
var duty = 0.5

var skew = 0.5
var formant = 0.5
var y_span = 1.0

var filter = false

var reso_freq = 220  #Resonance frequency, for "filtered" mode
var reso_phase = 0.0  #This is incremented by reso_freq, but hard synced to reset when osc phase crosses over


var inc = 0.0  #Base phase Increment.  Filled by frequency changers
var reso_inc = 0.0  #Increment for resonance frequency

func _ready():
	fill_buffer()
	play()
	
	yield(owner.get_node("Freq"), "ready")  #Wait a second before we chunk in the increment
	_on_Freq_value_changed(owner.get_node("Freq").value)  #Sets our increment to default freq value.
#	_on_YSpan_value_changed(owner.get_node("CenterContainer/V/YSpan").value)
	reso_inc = inc
	
func _process(_delta):
	fill_buffer()

func fill_buffer():
	if not owner.get_node("CenterContainer/V"):  return
	var to_fill = playback.get_frames_available()

	if filter:
		while to_fill > 0:
			#Process the phase of the fundamental frequency.
#			var phase = distort(fmod(self.phase , 1.0), true) #Distort phase but limit formant mult to 1
			var phase = fmod(self.phase , 1.0) #Distort phase but limit formant mult to 1
			
			#The resonance frequency counter determines the initial oscillator value, which will be
			#windowed by the base frequency. First, compare state of phase accumulator to previous.
			#if hard sync is needed (base oscillation cycled over last frame), then reset accordingly.
			var phase_differential = floor(self.phase) - floor(self.phase - inc)
			if phase_differential >= 1.0:  #We need to hard sync as next increment will cross the cycle boundary.
				reso_phase = self.phase
	
			#Now retrieve the value of the resonance frequency and window it based on fundamental.
#			osc = oscillator(reso_phase) * window(phase)
			osc = oscillator(distort(fmod(reso_phase, 1.0), true)) * window(phase, SINC)
	

			playback.push_frame(Vector2.ONE * osc)

			#Increment phase accumulators
			self.phase = self.phase + inc
			reso_phase += reso_inc
			to_fill -= 1




	else:
		while to_fill > 0:
			var phase = distort(fmod(self.phase , 1.0)) #Distort phase
			osc = oscillator(phase)
			
			playback.push_frame(Vector2.ONE * osc)

			#Increment phase accumulator
			self.phase = self.phase + inc
			to_fill -= 1

func oscillator(phase, osc_type=-1):
	if osc_type == -1:  osc_type = get_parent().get_node("OptionButton").selected
	var osc
	match(osc_type):
		SAW:
			osc = fmod(phase+0.5, 1.0)*2.0-1.0
		SINE:
			osc = sin(phase * TAU)
		TRI:
			osc = fmod(phase+0.25, 1.0)
			if osc > 0.5:  osc = 1.0 - osc
			osc = osc*4 - 1.0
			osc = stepify(osc, 1.0/float( 1 << crush ))  #Crush to n-bits
		PULSE: 
			osc = fmod(phase, 1.0)
			if osc > duty:  osc = 0.9 
			else: osc = -0.9
	return osc

#Distorts a phase 0-1 to the VPD value
func distort(phase, filtered=false):
	#The resonance frequency counter is used instead of the y_span multiplier as a hard sync if we're filtering
	var y_span = 1.0 if filtered else self.y_span
	
	var y = (1.0-formant)
	y = (y-0.5) * y_span + 0.5
	
	if phase < skew:
		phase = range_lerp(phase, 0.0, skew, 0.0, y)
#		phase = lerp(0, skew, formant*phase)
	else:  
#		phase = lerp(formant*y_span, 1, lerp(skew, 1.0, (phase-0.5)*2.0))
		phase = range_lerp(phase, skew, 1.0, y, 1.0)
		
	return fposmod(phase, 1.0)

enum {AUTO=-1, DEFAULT, SINC}
func window(phase, func_type=DEFAULT):
	#angle is the phase angle 0-1. For our typical symmetrical windowing funcs we wanna offset phase 50%?
	var angle = fmod(phase, 1.0)
	
	#TODO:  Add more windowing functions
	
	match func_type:
		DEFAULT:
			return 1.0-distort(angle, true)
		SINC:
			#normalized sinc
		#	return sin((PI*angle)/PI*angle)
			return sin((TAU*(angle-0.5))/TAU*(angle-0.5)) * 4

func _on_Freq_value_changed(value):
	freq = value
	inc = freq / stream.mix_rate
	owner.get_node("Reso").value = freq * y_span

func _on_Reso_value_changed(value):
	reso_freq = value
	reso_inc = reso_freq / stream.mix_rate


func _on_Duty_value_changed(value):
	crush = int(value)
	duty = value / 16.0
	owner.get_node("CenterContainer").redraw()
	pass # Replace with function body.


func _on_Skew_value_changed(value):
	skew = value
func _on_Formant_value_changed(value):
	formant = value
func _on_YSpan_value_changed(value):
	y_span = value
	owner.get_node("Reso").value = freq * y_span


func _on_chkFilter_toggled(button_pressed):
	owner.get_node("CenterContainer").redraw()
	filter = button_pressed
	
	#Reset the phrase accumulators so that hard sync works properly
	phase = 0
	reso_phase = 0
