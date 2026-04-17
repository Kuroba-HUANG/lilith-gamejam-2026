extends Node

# 存储解析后的剧情数据
var story_data: Dictionary = {}
const FILE_PATH = "res://config/story_config.json"

func _ready() -> void:
	load_story_data()

## 加载并解析 JSON 文件
func load_story_data():
	if not FileAccess.file_exists(FILE_PATH):
		push_error("错误：找不到剧情文件 " + FILE_PATH)
		return

	var file = FileAccess.open(FILE_PATH, FileAccess.READ)
	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(json_string)
	
	if error == OK:
		var data = json.get_data()
		if typeof(data) == TYPE_DICTIONARY:
			story_data = data
			_confirm_data_structure()
		else:
			push_error("错误：JSON 格式不符合预期的 Dictionary 结构")
	else:
		push_error("JSON 解析失败: " + json.get_error_message() + " 在第 " + str(json.get_error_line()) + " 行")

## 内部调试：确认数据加载状态
func _confirm_data_structure():
	if story_data.has("story_stages"):
		print("✅ 剧情阶段加载成功，共有阶段：", story_data["story_stages"].size())
	if story_data.has("npc_database"):
		print("✅ NPC 数据库加载成功，包含角色：", story_data["npc_database"].keys())

## ================= 外部调用接口 =================

## 获取特定阶段的完整数据 (用于 main.gd 切换阶段) [cite: 3, 94]
func get_stage_data(stage_key: String) -> Dictionary:
	# 兼容 "stage_1" 或索引查找
	if story_data.has("story_stages"):
		# 如果传入的是 "stage_1" 这种格式，尝试解析数字索引
		var index = int(stage_key.replace("stage_", "")) - 1
		if index >= 0 and index < story_data["story_stages"].size():
			return story_data["story_stages"][index]
	
	push_warning("【剧情警告】未找到阶段数据: " + stage_key)
	return {}

## 获取 NPC 的人设信息 (用于 AI 互动) [cite: 8, 16, 30]
func get_npc_info(npc_id: String) -> Dictionary:
	if story_data.has("npc_database") and story_data["npc_database"].has(npc_id):
		return story_data["npc_database"][npc_id]
	
	push_warning("【剧情警告】未找到 NPC 人设信息: " + npc_id)
	return {}

## 动态更新 NPC 状态 (例如进入污染态) [cite: 6, 35]
func set_npc_status(npc_id: String, status: String):
	if story_data.has("npc_database") and story_data["npc_database"].has(npc_id):
		story_data["npc_database"][npc_id]["current_status"] = status
		print("【系统】NPC ", npc_id, " 状态已更新为：", status)

## 获取当前阶段的 AI 上下文提示 [cite: 17, 24]
func get_stage_hint(stage_index: int) -> String:
	var stage_data = get_stage_data("stage_" + str(stage_index + 1))
	return stage_data.get("stage_hint", "")


	## [兼容层]：供论坛左侧列表获取所有已发生的帖子
func get_all_posts() -> Array:
	var all_posts = []
	
	if not story_data.has("story_stages"):
		return []
	
	# 👉 只取第一阶段作为主帖
	var first_stage = story_data["story_stages"][0]
	
	if first_stage.has("main_event"):
		var p = first_stage["main_event"].duplicate()
		
		if not p.has("title"):
			p["title"] = "关于妹妹走失..."
		
		all_posts.append(p)
	
	return all_posts
