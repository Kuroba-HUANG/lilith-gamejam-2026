# post_list_item.gd
extends Button
signal post_selected(post_data)

var _data = {}

func setup(post_data: Dictionary):
	_data = post_data
	# 修改：将 title 改为 content 的前几个字，或者在 JSON 中手动补全 title
	# 因为新版 JSON 楼主发的是 main_event，里面包含的是 content
	var preview_text = post_data.get("content", "无内容").left(15) + "..."
	$VBoxContainer/TitleLabel.text = preview_text
	
	# 修改：将 character 改为 author，id 增加安全检查
	var author_name = post_data.get("author", "未知用户")
	var post_id = str(post_data.get("id", "001"))
	$VBoxContainer/AuthorLabel.text = author_name + " · " + post_id

func _pressed():
	post_selected.emit(_data)
