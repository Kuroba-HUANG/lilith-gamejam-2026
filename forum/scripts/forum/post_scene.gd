# scripts/forum/post_scene.gd
extends Control

@onready var api_manager = %APIManager
@onready var post_title: Label = %PostTitle
@onready var post_content: RichTextLabel = %PostMainContent
@onready var reply_input: TextEdit = %InputText
@onready var send_button: Button = %SendButton
@onready var comment_list: VBoxContainer = %CommentList
@onready var comment_scroll: ScrollContainer = %CommentScroll
@onready var post_item_container: VBoxContainer = %PostItemContainer

const COMMENT_ITEM = preload("res://scenes/forum/comment_item.tscn")
const LIST_ITEM = preload("res://scenes/forum/post_list_item.tscn")

# 核心变量：必须确保它是唯一的
var current_post_id: String = ""

func _ready():
	# 关键修复 1：连接信号前，确保先断开旧连接（防止重复触发）
	if api_manager:
		if api_manager.ai_reply_generated.is_connected(_on_ai_reply_received):
			api_manager.ai_reply_generated.disconnect(_on_ai_reply_received)
		api_manager.ai_reply_generated.connect(_on_ai_reply_received)
	
	if send_button:
		# 同样处理按钮连接
		if send_button.pressed.is_connected(_on_send_pressed):
			send_button.pressed.disconnect(_on_send_pressed)
		send_button.pressed.connect(_on_send_pressed)
	
	_refresh_left_post_list()

## 核心接口：由列表点击调用
func setup_post(data: Dictionary) -> void:
	print("【UI】尝试切换到帖子: ", data.get("title"))
	# 1. 立即锁定 ID（将 ID 转换为字符串，防止对比失败）
	var new_id = str(data.get("id", "001"))
	
	# 如果点击的是当前已经在看的帖子，不做重复加载
	if new_id == current_post_id and comment_list.get_child_count() > 0:
		return
		
	current_post_id = new_id
	
	# 2. UI 文本更新
	post_title.text = data.get("title", "论坛主页")
	post_content.text = data.get("content", "")
	
	# 3. 彻底清空（使用循环确保干净）
	_clear_comments()
	
	# 4. 从历史记录管理器中仅抓取属于 current_post_id 的内容
	var history = HistoryManager.get_history(current_post_id)
	for record in history:
		_add_comment_ui(record.author, record.content, record.time, record.is_npc)

## 玩家点击发送
func _on_send_pressed():
	var user_input = reply_input.text.strip_edges()
	if user_input.is_empty(): return
	
	# 1. 只有当前帖子 ID 存在时才处理
	if current_post_id == "": return
	
	# 2. 本地渲染并存入该 ID 的历史
	_add_comment_ui("我", user_input, "最新", false)
	HistoryManager.add_reply(current_post_id, "我", user_input, "最新", false)
	reply_input.clear()
	
	# 3. UI 状态调整
	send_button.disabled = true
	send_button.text = "正在回帖..."
	
	# 4. 传给 Main（带上 ID）
	var main_node = get_tree().root.find_child("Main", true, false)
	if main_node and main_node.has_method("notify_interaction"):
		main_node.notify_interaction("player_post", {"text": user_input, "post_id": current_post_id})

## 处理 AI 回复
func _on_ai_reply_received(response: Dictionary, original_post_id: String):
	# 无论是否是当前帖子，都要存入历史（保证切换回来能看到）
	HistoryManager.add_reply(original_post_id, response.npc_name, response.reply_text, "邻居", true)
	
	# 解锁 UI
	send_button.disabled = false
	send_button.text = "发布"
	var main_node = get_tree().root.find_child("Main", true, false)
	if main_node and main_node.has_method("on_ai_finished"):
		main_node.on_ai_finished()
	# 关键修复 2：严格校验 original_post_id
	# 只有当 AI 回复的帖子 ID 确实是玩家眼睛盯着的这个 ID，才渲染
	if str(original_post_id) == current_post_id:
		_add_comment_ui(response.npc_name, response.reply_text, "邻居", true)	


## 供 Main 调用接口（主线剧情回复）
func display_new_message(author: String, content: String, post_id: String):
	# 关键修复 3：这里的逻辑必须也带 ID 校验
	if str(post_id) == current_post_id:
		_add_comment_ui(author, content, "邻居", true)

func _add_comment_ui(author: String, content: String, time_text: String, is_npc: bool):
	if not comment_list: return
	var comment = COMMENT_ITEM.instantiate()
	comment_list.add_child(comment)
	if comment.has_method("setup"):
		comment.setup(author, content, time_text, is_npc)
	
	# 自动滚动
	await get_tree().process_frame
	if comment_scroll:
		comment_scroll.scroll_vertical = comment_scroll.get_v_scroll_bar().max_value

func _clear_comments():
	if not comment_list: return
	for child in comment_list.get_children():
		child.queue_free()

func _refresh_left_post_list():
	if not post_item_container: return
	
	# 清理旧列表
	for child in post_item_container.get_children():
		child.queue_free()
	
	var all_posts = StoryConfig.get_all_posts()
	
	for p in all_posts:
		var item = LIST_ITEM.instantiate()
		post_item_container.add_child(item)
		
		# 初始化数据
		if item.has_method("setup"):
			item.setup(p)
		
		# 关键修复：直接连接信号。因为旧 item 已经被 queue_free 了，
		# 新实例化的 item 信号必然是空的，直接连即可。
		if item.has_signal("post_selected"):
			item.post_selected.connect(setup_post)
		else:
			# 如果没信号，尝试连按钮原生的 pressed 信号（备选方案）
			item.pressed.connect(func(): setup_post(p))
