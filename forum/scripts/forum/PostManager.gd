extends Node

# 帖子数组
var posts = []

signal post_added(post)
signal posts_cleared()

func _ready():
	# 尝试加载之前的帖子
	load_posts()

# 添加帖子
func add_post(author, content, is_npc = false, post_type = "normal"):
	var post = {
		"author": author,
		"content": content,
		"time": Time.get_time_string_from_system(),
		"is_npc": is_npc,
		"type": post_type,
		"timestamp": Time.get_unix_time_from_system()  # 用于排序
	}
	posts.append(post)
	post_added.emit(post)
	
	# 自动保存
	save_posts()
	
	return post

# 获取最近 N 条帖子
func get_recent_posts(count = 20):
	var start = max(0, posts.size() - count)
	return posts.slice(start)

# 获取所有帖子
func get_all_posts():
	return posts

# 获取帖子数量
func get_post_count():
	return posts.size()

# 清空所有帖子
func clear_posts():
	posts.clear()
	posts_cleared.emit()
	save_posts()

# 检查是否包含关键词
func has_keyword(keyword):
	for post in posts:
		if keyword in post["content"]:
			return true
	return false

# 获取特定作者的帖子
func get_posts_by_author(author):
	var result = []
	for post in posts:
		if post["author"] == author:
			result.append(post)
	return result

# 保存到本地
func save_posts():
	var file = FileAccess.open("user://posts.save", FileAccess.WRITE)
	if file:
		file.store_var(posts)
		file.close()
		print("已保存 ", posts.size(), " 条帖子")

# 从本地加载
func load_posts():
	if FileAccess.file_exists("user://posts.save"):
		var file = FileAccess.open("user://posts.save", FileAccess.READ)
		if file:
			posts = file.get_var()
			file.close()
			print("已加载 ", posts.size(), " 条帖子")
			return true
	return false
