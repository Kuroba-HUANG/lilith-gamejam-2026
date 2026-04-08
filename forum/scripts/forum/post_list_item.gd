extends Button
signal post_selected(post_data) # 定义一个信号，把数据传出去

var _data = {}

func setup(post_data: Dictionary):
	_data = post_data
	$VBoxContainer/TitleLabel.text = post_data.title
	$VBoxContainer/AuthorLabel.text = post_data.character + " · " + str(post_data.id)

func _pressed():
	# 当按钮被点击，发出信号
	post_selected.emit(_data)
