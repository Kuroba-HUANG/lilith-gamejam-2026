# scripts/forum/button.gd
extends Button

@onready var input = get_node("../LineEdit")
@onready var post_list = get_node("../../ScrollContainer/VBoxContainer")
@onready var api = get_node("/root/Main/API")
@onready var scroll = get_node("../../ScrollContainer")

var api_key = ""

func _ready():
	pressed.connect(_on_pressed)
	load_api_key()

func load_api_key():
	var file = FileAccess.open("res://scripts/api/api_key.gd", FileAccess.READ)
	if file:
		var content = file.get_as_text()
		var lines = content.split("\n")
		for line in lines:
			if "DEEPSEEK_API_KEY" in line and "\"" in line:
				var start = line.find("\"")
				var end = line.find("\"", start + 1)
				if start != -1 and end != -1:
					api_key = line.substr(start + 1, end - start - 1)
					print("API密钥加载成功")
					break
		file.close()
	else:
		print("警告：找不到 api_key.gd 文件")

# 原有的发帖功能（可选保留）
func _on_pressed():
	var user_text = input.text.strip_edges()
	if user_text == "":
		return
	
	input.clear()
	show_user_post(user_text)
	show_loading_indicator()
	call_ai(user_text)

# 新增：供 post.gd 调用的 AI 回复方法
func call_ai_for_npc_reply(post_instance, user_reply: String, npc_name: String, post_content: String):
	if api_key == "":
		print("没有API密钥")
		post_instance.add_reply(npc_name, "（AI未配置）", true)
		return
	
	# 显示"正在输入..."
	var loading_label = Label.new()
	loading_label.text = "✍️ %s 正在输入..." % npc_name
	loading_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	post_instance.reply_container.add_child(loading_label)
	
	# 构建请求 - 最简化的 Prompt
	var url = "https://api.deepseek.com/v1/chat/completions"
	var headers = ["Content-Type: application/json"]
	
	var prompt = """你是论坛NPC调度器。根据玩家的回复，生成1个NPC的回复。

当前剧情：%s

NPC列表：%s

规则：
1. 回复要符合社区氛围
2. 不超过60字
3. 只返回JSON：{"npc_name": "名字", "reply_text": "台词"}

玩家说：%s""" % [post_content, npc_name, user_reply]
	
	var body = {
		"model": "deepseek-chat",
		"messages": [
			{"role": "system", "content": prompt},
			{"role": "user", "content": "请生成回复"}
		]
	}
	
	var json_body = JSON.stringify(body)
	
	# 使用独立的 HTTPRequest
	var http = HTTPRequest.new()
	post_instance.add_child(http)
	http.request_completed.connect(func(result, code, headers, body):
		_on_ai_reply_completed(result, code, headers, body, loading_label, post_instance, npc_name, http)
	)
	http.request(url, headers + ["Authorization: Bearer " + api_key], HTTPClient.METHOD_POST, json_body)

func _on_ai_reply_completed(_result, response_code, _headers, body, loading_label, post_instance, npc_name, http):
	loading_label.queue_free()
	
	if response_code != 200:
		post_instance.add_reply(npc_name, "（AI回复失败）", true)
		http.queue_free()
		return
	
	var json = JSON.parse_string(body.get_string_from_utf8())
	if json and json.has("npc_name") and json.has("reply_text"):
		post_instance.add_reply(json["npc_name"], json["reply_text"], true)
	else:
		# 尝试解析其他格式
		var text = body.get_string_from_utf8()
		var alt_json = JSON.parse_string(text)
		if alt_json and alt_json.has("choices"):
			var reply = alt_json["choices"][0]["message"]["content"]
			# 尝试从回复中提取 JSON
			var json_match = reply.find("{")
			if json_match != -1:
				var json_str = reply.substr(json_match)
				var parsed = JSON.parse_string(json_str)
				if parsed and parsed.has("npc_name"):
					post_instance.add_reply(parsed["npc_name"], parsed["reply_text"], true)
				else:
					post_instance.add_reply(npc_name, reply.substr(0, 60), true)
			else:
				post_instance.add_reply(npc_name, reply.substr(0, 60), true)
		else:
			post_instance.add_reply(npc_name, "（AI回复解析失败）", true)
	
	http.queue_free()

# 以下是原有函数（保留兼容）
func show_user_post(content):
	var user_post = load("res://scenes/forum/post.tscn").instantiate()
	var nickname = user_post.get_node("HBoxContainer/VBoxContainer/HBoxContainer/Nickname")
	if nickname:
		nickname.text = "我"
	var message = user_post.get_node("HBoxContainer/VBoxContainer/Message")
	if message:
		message.text = content
	post_list.add_child(user_post)
	scroll_to_bottom()

func show_loading_indicator():
	var loading_post = load("res://scenes/forum/post.tscn").instantiate()
	var nickname = loading_post.get_node("HBoxContainer/VBoxContainer/HBoxContainer/Nickname")
	if nickname:
		nickname.text = "代码侠"
	var message = loading_post.get_node("HBoxContainer/VBoxContainer/Message")
	if message:
		message.text = "正在输入..."
		message.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	var time = loading_post.get_node("HBoxContainer/VBoxContainer/HBoxContainer/Time")
	if time:
		time.text = Time.get_time_string_from_system()
	loading_post.set_meta("is_loading", true)
	post_list.add_child(loading_post)
	scroll_to_bottom()

func remove_loading_indicator():
	for i in range(post_list.get_child_count() - 1, -1, -1):
		var child = post_list.get_child(i)
		if child.has_meta("is_loading") and child.get_meta("is_loading"):
			child.queue_free()
			break

func show_ai_reply(content):
	var npc_post = load("res://scenes/forum/post.tscn").instantiate()
	var nickname = npc_post.get_node("HBoxContainer/VBoxContainer/HBoxContainer/Nickname")
	if nickname:
		nickname.text = "代码侠"
	var message = npc_post.get_node("HBoxContainer/VBoxContainer/Message")
	if message:
		message.text = content
		message.add_theme_color_override("font_color", Color(0.3, 0.8, 0.3))
	var time = npc_post.get_node("HBoxContainer/VBoxContainer/HBoxContainer/Time")
	if time:
		time.text = Time.get_time_string_from_system()
	post_list.add_child(npc_post)
	scroll_to_bottom()

func scroll_to_bottom():
	await get_tree().process_frame
	scroll.scroll_vertical = scroll.get_v_scroll_bar().max_value

func call_ai(user_message):
	# 保留原有逻辑
	if api_key == "":
		print("没有API密钥")
		remove_loading_indicator()
		var error_post = Label.new()
		error_post.text = "【系统】AI未配置，请创建 api_key.gd 文件"
		error_post.add_theme_color_override("font_color", Color(1, 0.5, 0.5))
		post_list.add_child(error_post)
		return
	
	var url = "https://api.deepseek.com/v1/chat/completions"
	var headers = ["Content-Type: application/json"]
	
	var body = {
		"model": "deepseek-chat",
		"messages": [
			{"role": "system", "content": "你是一个论坛网友，昵称'代码侠'，回答简短友好，每次回复不超过50字。"},
			{"role": "user", "content": user_message}
		]
	}
	
	var json_body = JSON.stringify(body)
	api.request(url, headers + ["Authorization: Bearer " + api_key], HTTPClient.METHOD_POST, json_body)
