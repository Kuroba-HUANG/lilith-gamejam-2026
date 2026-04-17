# api.gd
extends HTTPRequest

@onready var auth_header = "Authorization: Bearer " + ApiKey.DEEPSEEK_API_KEY

signal ai_reply_generated(data: Dictionary, post_id: String)

func _ready():
	# ❗ 不再使用自身 HTTPRequest 发请求
	# 所以这里不需要连接 request_completed
	pass


func request_ai_reply(player_text: String, npc_name: String, custom_system_prompt: String, post_id: String):

	# ✅ 每个NPC独立请求实例
	var http = HTTPRequest.new()
	get_tree().current_scene.add_child(http)

	# ✅ 绑定回调（闭包带 post_id）
	http.request_completed.connect(
		func(result, response_code, headers, body):
			_on_request_completed(http, result, response_code, headers, body, post_id)
	)

	var url = "https://api.deepseek.com/chat/completions"
	var headers = [
		"Content-Type: application/json",
		auth_header
	]

	# ✅ 强制JSON输出
	var final_system_message = custom_system_prompt \
		+ "\n必须以JSON格式返回：{\"npc_name\": \"" + npc_name + "\", \"reply_text\": \"内容\"}"

	var body_data = {
		"model": "deepseek-chat",
		"messages": [
			{"role": "system", "content": final_system_message},
			{"role": "user", "content": player_text}
		],
		"response_format": { "type": "json_object" }
	}

	var err = http.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body_data))

	if err != OK:
		ai_reply_generated.emit(
			{"npc_name": "系统", "reply_text": "网络异常"},
			post_id
		)
		http.queue_free()


func _on_request_completed(http, result, response_code, _headers, body, post_id):

	# ❗ 防止请求失败但 response_code 还没进200分支
	if result != HTTPRequest.RESULT_SUCCESS:
		ai_reply_generated.emit(
			{"npc_name": "系统", "reply_text": "请求失败"},
			post_id
		)
		http.queue_free()
		return

	if response_code == 200:
		var raw_text = body.get_string_from_utf8()
		
		var raw_json = JSON.parse_string(raw_text)
		if typeof(raw_json) != TYPE_DICTIONARY:
			ai_reply_generated.emit(
				{"npc_name": "系统", "reply_text": "返回格式错误"},
				post_id
			)
			http.queue_free()
			return
		
		var content = raw_json["choices"][0]["message"]["content"]
		
		var content_json = JSON.parse_string(content)
		if typeof(content_json) != TYPE_DICTIONARY:
			ai_reply_generated.emit(
				{"npc_name": "系统", "reply_text": "AI输出解析失败"},
				post_id
			)
			http.queue_free()
			return
		
		# ✅ 正常返回
		ai_reply_generated.emit(content_json, post_id)

	else:
		ai_reply_generated.emit(
			{"npc_name": "系统", "reply_text": "错误代码:%d" % response_code},
			post_id
		)

	# ✅ 必须释放（否则内存爆）
	http.queue_free()
