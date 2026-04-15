extends Node

# 存储解析后的剧情数据
var story_data: Dictionary = {}
const FILE_PATH = "res://data/story_data.json"

func _ready() -> void:
	load_story_data()

## 加载并解析 JSON 文件
func load_story_data():
	if not FileAccess.file_exists(FILE_PATH):
		push_error("错误：找不到剧情文件 " + FILE_PATH +"。已加载默认空数据")
		return {"posts": []} # 返回一个空结构防止报错

	var file = FileAccess.open(FILE_PATH, FileAccess.READ)
	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(json_string)
	
	if error == OK:
		var data = json.get_data()
		if typeof(data) == TYPE_DICTIONARY:
			story_data = data
			print("✅ 剧情数据加载成功，共有帖子：", story_data["posts"].size())
		else:
			push_error("错误：JSON 格式不符合预期的 Dictionary 结构")
	else:
		push_error("JSON 解析失败: ", json.get_error_message(), " 在第 ", json.get_error_line(), " 行")

## 提供给外部调用的接口：获取所有帖子列表
func get_all_posts() -> Array:
	if story_data.has("posts"):
		return story_data["posts"]
	return []

## 根据字符串 ID 获取特定帖子
func get_post_by_id(post_id: String) -> Dictionary:
	for post in get_all_posts():
		# 使用 str() 强制转换，防止 JSON 解析出来偶尔变成数字导致匹配失败
		if str(post.get("id", "")) == post_id:
			return post
	
	push_warning("【剧情警告】未找到 ID 为 " + post_id + " 的帖子")
	return {}
