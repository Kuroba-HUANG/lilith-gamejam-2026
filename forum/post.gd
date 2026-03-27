extends Control

func _ready():
	# 设置背景
	var style = StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1)  # 白色
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	add_theme_stylebox_override("panel", style)
	
	# 设置文字
	var nickname = get_node("HBoxContainer/VBoxContainer/HBoxContainer/Nickname")
	if nickname:
		nickname.add_theme_color_override("font_color", Color(0, 0, 0))
	
	var message = get_node("HBoxContainer/VBoxContainer/Message")
	if message:
		message.add_theme_color_override("font_color", Color(0, 0, 0))
