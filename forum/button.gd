extends Button

@onready var input = get_node("../LineEdit")
@onready var post_list = get_node("../../ScrollContainer/VBoxContainer")
@onready var api = get_node("/root/Main/API")

var api_key = ""

func _ready():
	pressed.connect(_on_pressed)
	load_api_key()

# 从 api_key.gd 文件读取密钥
func load_api_key():
	var file = FileAccess.open("res://api_key.gd", FileAccess.READ)
	if file:
		var content = file.get_as_text()
		# 解析文件内容，提取密钥
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
		print("请在项目根目录创建 api_key.gd，内容为：")
		print('const DEEPSEEK_API_KEY = "你的密钥"')

func _on_pressed():
	var text = input.text.strip_edges()
	if text == "":
		return
	
	# 显示用户帖子
	var user_post = Label.new()
	user_post.text = "【我】" + text
	post_list.add_child(user_post)
	input.clear()
	
	# 调用AI
	call_ai(text)

func call_ai(user_message):
	# 检查是否有密钥
	if api_key == "":
		print("没有API密钥，无法调用AI")
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
