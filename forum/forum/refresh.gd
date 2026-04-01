extends Button

func _ready():
	pressed.connect(_on_refresh_button_pressed)

func _on_refresh_button_pressed():
	print("已经刷新")
	
	# 路径：上一级到 Main，再找 ScrollContainer
	var post_list = get_node("../ScrollContainer/VBoxContainer")
	var scroll = get_node("../ScrollContainer")
	
	# 检查路径
	if post_list == null:
		print("路径错误！找不到帖子列表")
		return
	
	# 清空帖子
	for child in post_list.get_children():
		child.queue_free()
	
	# 加载中提示
	var loading_label = Label.new()
	loading_label.text = "加载中..."
	post_list.add_child(loading_label)
	
	await get_tree().create_timer(0.5).timeout
	loading_label.queue_free()
	
	# 示例帖子
	var demo_posts = [
		"欢迎来到论坛！",
		"AI NPC 会回复你的帖子",
		"试试发一条消息吧"
	]
	
	for content in demo_posts:
		var demo_post = Label.new()
		demo_post.text = "【系统】" + content
		demo_post.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		post_list.add_child(demo_post)
	
	# 滚动到底部
	await get_tree().process_frame
	scroll.scroll_vertical = scroll.get_v_scroll_bar().max_value
