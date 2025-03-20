extends AudioStreamPlayer

onready var playback:AudioStreamPlayback = get_stream_playback()
var freq = 220
var phase = 0.0
enum {SAW, SINE, TRI, PULSE}
var osc = 0.0
var crush = 5
var duty = 0.5

var skew = 0.5
var formant = 0.5
var y_span = 1.0

var filter = false

func _ready():
	fill_buffer()
	play()
	
func _process(delta):
	fill_buffer()

func fill_buffer():
	if not owner.get_node("CenterContainer/V"):  return
	var inc = freq / stream.mix_rate
	
	var to_fill = playback.get_frames_available()

	if filter:
		while to_fill > 0:
			var osc2 = oscillator(phase + 0.25)
			var phase = distort(fmod(self.phase , 1.0)) #Distort phase
			self.osc = oscillator(phase) * osc2
			#Push carrier and filter
#			playback.push_frame(Vector2(osc, osc2))
			playback.push_frame(Vector2.ONE * osc)

			#Increment phase accumulator
			self.phase = self.phase + inc/2.0
			to_fill -= 1
	else:
		while to_fill > 0:
			var phase = distort(fmod(self.phase , 1.0)) #Distort phase
			osc = oscillator(phase)
			#Push carrier and filter
			playback.push_frame(Vector2.ONE * osc)

			#Increment phase accumulator
			self.phase = self.phase + inc
			to_fill -= 1

func oscillator(phase):
	var osc
	match(get_parent().get_node("OptionButton").selected):
		SAW:
			osc = fmod(phase, 1.0)*2.0-1.0
		SINE:
			osc = sin(phase * TAU)
		TRI:
			osc = fmod(phase, 1.0)
			if osc > 0.5:  osc = 1.0 - osc
			osc = osc*4 - 1.0
			osc = stepify(osc, 1.0/float( 1 << crush ))  #Crush to n-bits
		PULSE: 
			osc = fmod(phase, 1.0)
			if osc > duty:  osc = 0.9 
			else: osc = -0.9
	return osc

#Distorts a phase 0-1 to the VPD value
func distort(phase):
	
	var y = (1.0-formant)
	y = (y-0.5) * y_span + 0.5
	
	if phase < skew:
		phase = range_lerp(phase, 0, skew, 0, y)
#		phase = lerp(0, skew, formant*phase)
	else:  
#		phase = lerp(formant*y_span, 1, lerp(skew, 1.0, (phase-0.5)*2.0))
		phase = range_lerp(phase, skew, 1.0, y, 1.0)
		
	return fposmod(phase, 1.0)

func _on_Freq_value_changed(value):
	freq = value


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


func _on_chkFilter_toggled(button_pressed):
	owner.get_node("CenterContainer").redraw()
	filter = button_pressed
