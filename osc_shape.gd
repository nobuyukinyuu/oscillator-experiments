tool
extends ColorRect


func _ready():
	set_uniforms()

func set_uniforms():
	material.set_shader_param("rect_size", rect_size)


func _on_ColorRect_resized():
	set_uniforms()
