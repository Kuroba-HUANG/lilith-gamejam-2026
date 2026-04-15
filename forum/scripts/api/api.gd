# scripts/api/api.gd
extends HTTPRequest

# 引用单例中的密钥
@onready var auth_header = "Authorization: Bearer " + ApiKey.DEEPSEEK_API_KEY

signal ai_reply_generated(data: Dictionary)

func _ready():
	# 核心修复：必须连接内置信号才能触发 _on_request_completed
	self.request_completed.connect(_on_request_completed)

func request_ai_reply(player_text: String, game_stage: String):
	var url = "https://api.deepseek.com/chat/completions"
	var headers = ["Content-Type: application/json", auth_header]
	
	# 根据你的《简易说明》文档构建 Prompt
	var system_prompt = "你是一个文字冒险游戏中的NPC调度器。游戏背景：██是一个被不可名状怪物控制的社区。这里的居民认知已经完全扭曲，认为怪物吃人是温馨正常的日常。当前阶段：%s。任务：根据玩家输入生成回复。必须以JSON格式返回：{\"npc_name\": \"名字\", \"reply_text\": \"台词\"}" % game_stage
	
	var body_data = {
		"model": "deepseek-chat",
		"messages": [
			{"role": "system", "content": system_prompt},
			{"role": "user", "content": player_text}
		],
		"response_format": { "type": "json_object" }
	}
	
	var json_string = JSON.stringify(body_data)
	var error = request(url, headers, HTTPClient.METHOD_POST, json_string)
	
	if error != OK:
		push_error("API请求发起失败")
		ai_reply_generated.emit({"npc_name": "系统", "reply_text": "网络请求初始化失败"})

func _on_request_completed(result, response_code, headers, body):
	print("收到回复，状态码:", response_code)
	
	if response_code == 200:
		var response_raw = body.get_string_from_utf8()
		var json_res = JSON.parse_string(response_raw)
		
		if json_res and json_res.has("choices"):
			var content_str = json_res["choices"][0]["message"]["content"]
			var content_json = JSON.parse_string(content_str)
			ai_reply_generated.emit(content_json)
		else:
			ai_reply_generated.emit({"npc_name": "系统", "reply_text": "解析回复失败"})
	else:
		var err_body = body.get_string_from_utf8()
		print("API详细错误:", err_body)
		ai_reply_generated.emit({"npc_name": "系统", "reply_text": "邻居们暂时不想说话 (Code: %d)" % response_code})
