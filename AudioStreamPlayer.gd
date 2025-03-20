extends AudioStreamPlayer

onready var playback:AudioStreamPlayback = get_stream_playback()
var freq = 0.2
#var freq = 440
var phase = 0.0
enum {SAW, SINE, TRI, PULSE}
var osc = 0.0

func _ready():
	fill_buffer()
	play()
	
func _process(delta):
	fill_buffer()

func fill_buffer():
	if not owner.get_node("CenterContainer/V"):  return
	var inc = freq / stream.mix_rate
	
	var to_fill = playback.get_frames_available()
	while to_fill > 0:
		var phase = fmod(self.phase + inc, 1.0)
		match(get_parent().get_node("OptionButton").selected):
			SAW:
				osc = fmod(phase, 1.0)*2.0-1.0
			SINE:
				osc = sin(phase * TAU)
			TRI:
				osc = fmod(phase, 1.0)
				if osc > 0.5:  osc = 1.0 - osc
				osc = osc*2 - 1.0
				osc = stepify(osc, 1.0/float( 1 << int(owner.get_node("Duty").value) ))  #Crush to n-bits
			PULSE: 
				osc = fmod(phase, 1.0)
				if osc <= owner.get_node("Duty").value/16.0:  
					osc = 0.75
				else: osc = -0.75

		#Push modulator
#		playback.push_frame(Vector2.ONE * osc)

		#Push op
		var frame = get_length().y * Vector2.ONE
		playback.push_frame(frame * Vector2.ONE*0.5 + Vector2.ONE*0.5)
		if frame.x > 1.0 or frame.x < -1.0:  printerr("bad frame: " + frame)
		
		self.phase = phase + inc
		to_fill -= 1

func get_length():
	var v = owner.get_node("CenterContainer/V")
	var theta = (osc + 1) * PI #Rotational value of osc
	var angle = (osc + 1) / 2.0 #Percentage value of osc
	var length = lerp(get_side(theta), get_side(theta + 1/v.get_node("Sides").value*TAU), 
			fposmod((angle - v.get_node("Angle").value/360.0)*v.get_node("Sides").value, 1.0))
	return length
func get_side(theta):
	var v = owner.get_node("CenterContainer/V")
	var ratio = Vector2(min(v.get_node("Ratio").value, 0.5), min(1.0 - v.get_node("Ratio").value, 0.5))
	var angle = deg2rad(v.get_node("Angle").value)
	var phase = floor((theta-angle) * v.get_node("Sides").value/TAU) / v.get_node("Sides").value * TAU 
	var step = Vector2(cos(phase), sin(phase)) * ratio * 2

	var output = step #Output needs to be rotated by angle.
	output.x = cos(angle) * step.x - sin(angle) *  step.y
	output.y = sin(angle) * step.x + cos(angle) *  step.y

	return(output)


func _on_Freq_value_changed(value):
	freq = value
