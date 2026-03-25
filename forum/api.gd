extends HTTPRequest

func _ready():
	request_completed.connect(_on_request_completed)

func _on_request_completed(result, response_code, headers, body):
	var response_body = body.get_string_from_utf8()
	
	print("状态码: ", response_code)
	
	if response_code != 200:
		print("AI请求失败: ", response_body)
		return
	
	var json = JSON.parse_string(response_body)
	if json == null:
		print("解析JSON失败")
		return
	
	if json.has("choices") and json["choices"].size() > 0:
		var reply = json["choices"][0]["message"]["content"]
		
		var post_list = get_node("/root/Main/ScrollContainer/VBoxContainer")
		var npc_post = Label.new()
		npc_post.text = "【代码侠】" + reply
		npc_post.add_theme_color_override("font_color", Color(0.3, 0.8, 0.3))
		post_list.add_child(npc_post)
		
		var scroll = get_node("/root/Main/ScrollContainer")
		scroll.scroll_vertical = scroll.get_v_scroll_bar().max_value
	else:
		print("返回数据中没有choices字段")
