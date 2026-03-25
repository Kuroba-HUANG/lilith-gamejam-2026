extends Button

@onready var input = get_node("../LineEdit")
@onready var post_list = get_node("../../ScrollContainer/VBoxContainer")
@onready var api = get_node("/root/Main/API")

func _ready():
	pressed.connect(_on_pressed)

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
	var url = "https://api.deepseek.com/v1/chat/completions"
	var headers = ["Content-Type: application/json"]
	var api_key = "sk-83cd209f144d4c3d89156ab0ffb55496"  # ⚠️ 替换成你充值后的密钥
	
	var body = {
		"model": "deepseek-chat",
		"messages": [
			{"role": "system", "content": "你是一个论坛网友，昵称'代码侠'，回答简短友好，每次回复不超过50字。"},
			{"role": "user", "content": user_message}
		]
	}
	
	var json_body = JSON.stringify(body)
	api.request(url, headers + ["Authorization: Bearer " + api_key], HTTPClient.METHOD_POST, json_body)
