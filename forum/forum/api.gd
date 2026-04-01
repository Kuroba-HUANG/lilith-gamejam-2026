extends HTTPRequest

@onready var post_list = get_node("/root/Main/ScrollContainer/VBoxContainer")
@onready var button = get_node("/root/Main/HBoxContainer/Button")

func _ready():
	request_completed.connect(_on_request_completed)

func _on_request_completed(_result, response_code, _headers, body):
	# 删除"正在输入"动画
	button.remove_loading_indicator()
	
	var response_body = body.get_string_from_utf8()
	
	print("状态码: ", response_code)
	
	if response_code != 200:
		print("AI请求失败: ", response_body)
		var error_post = Label.new()
		error_post.text = "【系统】AI请求失败，请检查网络"
		error_post.add_theme_color_override("font_color", Color(1, 0.5, 0.5))
		post_list.add_child(error_post)
		return
	
	var json = JSON.parse_string(response_body)
	if json == null:
		print("解析JSON失败")
		return
	
	if json.has("choices") and json["choices"].size() > 0:
		var reply = json["choices"][0]["message"]["content"]
		button.show_ai_reply(reply)
	else:
		print("返回数据中没有choices字段")
