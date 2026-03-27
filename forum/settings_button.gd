extends Button

func _ready():
	pressed.connect(_on_pressed)

func _on_pressed():
	print("设置功能待开发")
	# 可以添加设置界面
