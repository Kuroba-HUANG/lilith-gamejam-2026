# config/story_config.gd
# 剧情配置加载器

extends RefCounted

# 数据结构
class StoryPost:
	var id: int
	var post_type: String      # "thread" 或 "reply"
	var character: String
	var title: String
	var content: String
	var delay_seconds: float
	var reply_to: int           # 仅 reply 类型使用
	var stage: String
	var required_flags: Array
	var clear_flags: Array
	
	func _init(p_id, p_post_type, p_character, p_title, p_content, p_delay, p_reply_to = 0, p_stage = "", p_required_flags = [], p_clear_flags = []):
		id = p_id
		post_type = p_post_type
		character = p_character
		title = p_title
		content = p_content
		delay_seconds = p_delay
		reply_to = p_reply_to
		stage = p_stage
		required_flags = p_required_flags
		clear_flags = p_clear_flags

# 缓存数据
var _story_posts: Array = []
var _loaded: bool = false

# 加载配置文件（从 JSON 文件读取）
func load_config() -> bool:
	var file = FileAccess.open("res://config/story_config.json", FileAccess.READ)
	if not file:
		print("错误：找不到 res://config/story_config.json 文件")
		return false
	
	var content = file.get_as_text()
	file.close()
	
	var json = JSON.parse_string(content)
	if json == null:
		print("错误：解析 story_config.json 失败")
		return false
	
	# 加载剧情帖子
	if json.has("mainline_posts"):
		_story_posts.clear()
		for post_data in json["mainline_posts"]:
			var post = StoryPost.new(
				post_data.get("id", 0),
				post_data.get("post_type", "thread"),
				post_data.get("character", ""),
				post_data.get("title", ""),
				post_data.get("content", ""),
				post_data.get("delay_seconds", 0.0),
				post_data.get("reply_to", 0),
				post_data.get("stage", ""),
				post_data.get("required_flags", []),
				post_data.get("clear_flags", [])
			)
			_story_posts.append(post)
	
	_loaded = true
	print("✅ 成功加载 %d 个剧情帖子" % _story_posts.size())
	return true

# 获取所有剧情帖子
func get_story_posts() -> Array:
	if not _loaded:
		load_config()
	return _story_posts

# 根据 ID 获取帖子
func get_post_by_id(post_id: int):
	if not _loaded:
		load_config()
	for post in _story_posts:
		if post.id == post_id:
			return post
	return null
