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
	var file = FileAccess.open("res://api_key.gd", FileAccess.READ)
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

func _on_pressed():
	print("_on_pressed 被调用了")
	
	var user_text = input.text.strip_edges()
	print("输入内容: ", user_text)
	
	if user_text == "":
		print("内容为空，返回")
		return
	
	# 先清空输入框
	input.clear()
	
	# 显示用户帖子
	show_user_post(user_text)
	
	# 显示"正在输入"动画
	show_loading_indicator()
	
	# 调用AI
	call_ai(user_text)

func show_user_post(content):
	var user_post = load("res://post.tscn").instantiate()
	
	var nickname = user_post.get_node("HBoxContainer/VBoxContainer/HBoxContainer/Nickname")
	if nickname:
		nickname.text = "我"
	
	var message = user_post.get_node("HBoxContainer/VBoxContainer/Message")
	if message:
		message.text = content
	
	post_list.add_child(user_post)
	input.clear()
	scroll_to_bottom()

func show_loading_indicator():
	# 用帖子模板显示加载中
	var loading_post = load("res://post.tscn").instantiate()
	
	# 设置加载内容
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
	
	# 标记为加载中
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
	var npc_post = load("res://post.tscn").instantiate()
	
	# 设置昵称
	var nickname = npc_post.get_node("HBoxContainer/VBoxContainer/HBoxContainer/Nickname")
	if nickname:
		nickname.text = "代码侠"
	
	# 设置内容（AI回复用绿色）
	var message = npc_post.get_node("HBoxContainer/VBoxContainer/Message")
	if message:
		message.text = content
		message.add_theme_color_override("font_color", Color(0.3, 0.8, 0.3))
	
	# 设置时间
	var time = npc_post.get_node("HBoxContainer/VBoxContainer/HBoxContainer/Time")
	if time:
		time.text = Time.get_time_string_from_system()
	
	post_list.add_child(npc_post)
	scroll_to_bottom()

func scroll_to_bottom():
	await get_tree().process_frame
	scroll.scroll_vertical = scroll.get_v_scroll_bar().max_value

func call_ai(user_message):
	if api_key == "":
		print("没有API密钥，无法调用AI")
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
