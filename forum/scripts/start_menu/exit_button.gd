extends Button

func _ready():
	pressed.connect(_on_pressed)

func _on_pressed():
	# 创建确认对话框
	var dialog = ConfirmationDialog.new()
	dialog.dialog_text = "确定要退出游戏吗？"
	dialog.ok_button_text = "退出"
	dialog.cancel_button_text = "取消"
	
	# 连接信号
	dialog.confirmed.connect(_quit_game)
	
	# 显示对话框
	add_child(dialog)
	dialog.popup_centered()

func _quit_game():
	get_tree().quit()
