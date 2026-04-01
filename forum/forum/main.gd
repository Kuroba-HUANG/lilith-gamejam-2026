extends Control

func _ready():
	# 设置论坛背景色（浅灰色）
	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(0.94, 0.95, 0.96)  # #f0f2f5
	add_theme_stylebox_override("panel", bg)
