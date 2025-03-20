extends Panel

var pts = []
var pts2 = []
const SQ2 = sqrt(2)
var font = get_font("")

func _ready():
	for o in $V.get_children():
		if !o is HSlider:  continue
		o.connect("value_changed", self, "refresh")

	refresh(0)

func _process(delta):
	update()

var tweak = [6.0, 4.0, 2.0] #used to make the display pretty
func refresh(val):
	var ratio = Vector2(min($V/Ratio.value, 0.5), min(1.0 - $V/Ratio.value, 0.5))
	var r = rect_size / 1.0 #* ratio 
#	r *= deg2rad($V/Angle.value)
	pts.clear()
	pts2.clear()
	
	for i in $V/Sides.value:
		var theta = TAU * i/float($V/Sides.value)
#		theta -= PI * 1/float(tweak[fmod($V/Sides.value,3)])
		var angle = deg2rad($V/Angle.value)
		var pt = Vector2(r.x * cos(theta) * ratio.x, r.y * sin(theta) * ratio.y)
		pts.append(pt)
		pts[i].x = cos(angle) * pt.x - sin(angle) *  pt.y
		pts[i].y = sin(angle) * pt.x + cos(angle) *  pt.y
		pts2.append(pts[i] + rect_size/2.0)

	pts.append(pts[0])
	pts2.append(pts[0] + rect_size/2.0)
	
	$Poly.points = pts2

func get_side(theta):
	var ratio = Vector2(min($V/Ratio.value, 0.5), min(1.0 - $V/Ratio.value, 0.5))
	var angle = deg2rad($V/Angle.value)
	var phase = floor((theta-angle) * $V/Sides.value/TAU) / $V/Sides.value * TAU 
	var step = Vector2(cos(phase), sin(phase)) * ratio * 2

	var output = step #Output needs to be rotated by angle.
	output.x = cos(angle) * step.x - sin(angle) *  step.y
	output.y = sin(angle) * step.x + cos(angle) *  step.y


#	var step2 = stepify(cos(phase), ($V/Sides.value+1))
	return(output)


func _draw():
	var c = rect_size/2.0
	draw_circle(c, 1, ColorN("white"))

	var theta = (owner.get_node("AudioStreamPlayer").osc + 1) * PI #Rotational value of osc
	var angle = (owner.get_node("AudioStreamPlayer").osc + 1) / 2.0 #Percentage value of osc
#	angle += fmod($V/Angle.value / 180.0, 1.0)

	var dest = Vector2(cos(theta), sin(theta))  #Destination point from center
#	var a = fmod(floor(angle * (pts.size()-1)), pts.size())
#	var b = fmod(ceil(angle * (pts.size()-1)), pts.size())

	var length = lerp(get_side(theta), get_side(theta + 1/$V/Sides.value*TAU), 
			fposmod((angle - $V/Angle.value/360.0)*$V/Sides.value, 1.0))
	
	draw_line(c, dest * c + c, ColorN("white", 0.5))
#	draw_line(pts[a] + c, pts[b] + c, ColorN("red"), 4.0)
	
	draw_string(font, Vector2.ZERO, str(length))
	draw_circle(get_side(theta)*c + c, 3, ColorN("cyan")) #end of previous segment
	draw_circle(get_side(theta + 1/$V/Sides.value*TAU)*c + c, 3, ColorN("orange")) #start of next segment

	draw_circle(length * c +c, 4, ColorN("green"))
	
