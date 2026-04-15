# scripts/forum/post_scene.gd
extends Control

# ========== 节点引用 (请确保在场景中勾选了“取个唯一名称”) ==========
@onready var api_manager = %APIManager
@onready var post_title: Label = %PostTitle
@onready var post_content: RichTextLabel = %PostMainContent
@onready var reply_input: TextEdit = %InputText
@onready var send_button: Button = %SendButton
@onready var comment_list: VBoxContainer = %CommentList
@onready var comment_scroll: ScrollContainer = %CommentScroll
@onready var post_item_container: VBoxContainer = %PostItemContainer

# 预制体加载
const COMMENT_ITEM = preload("res://scenes/forum/comment_item.tscn")
const LIST_ITEM = preload("res://scenes/forum/post_list_item.tscn")

var current_post_data: Dictionary = {}

func _ready():
	# 连接 API 信号
	if api_manager:
		api_manager.ai_reply_generated.connect(_on_ai_reply_received)
	
	# 连接按钮信号
	if send_button:
		send_button.pressed.connect(_on_send_pressed)
	
	# 初始化加载左侧列表
	_refresh_left_post_list()

## 核心接口：由 main.gd 或列表点击调用
func setup_post(data: Dictionary) -> void:
	current_post_data = data
	post_title.text = data.get("title", "无标题")
	post_content.text = data.get("content", "")
	
	_clear_comments()
	# 渲染 JSON 中的固定楼层
	if data.has("fixed_stairs"):
		for c_data in data["fixed_stairs"]:
			_add_comment_ui(c_data.author, c_data.content, str(c_data.floor) + "F", true)
	
	_refresh_left_post_list()

## 渲染评论 UI
func _add_comment_ui(author: String, content: String, floor_text: String, is_npc: bool):
	if not comment_list: return
	
	var comment = COMMENT_ITEM.instantiate()
	comment_list.add_child(comment)
	
	if comment.has_method("setup"):
		comment.setup(author, content, floor_text, is_npc)
	
	# 确保 UI 更新后滚动到底部
	await get_tree().process_frame
	if comment_scroll:
		comment_scroll.scroll_vertical = comment_scroll.get_v_scroll_bar().max_value

## 玩家点击发送按钮
func _on_send_pressed():
	var user_input = reply_input.text.strip_edges()
	if user_input.is_empty(): return
	
	# 1. 立即渲染玩家的回帖
	_add_comment_ui("我", user_input, "最新", false)
	reply_input.clear()
	
	# 2. 视觉反馈：禁用按钮进入“正在回帖”状态
	send_button.disabled = true
	send_button.text = "正在回帖..."
	
	# 3. 发起 API 请求
	var stage = current_post_data.get("stage", "日常")
	if api_manager:
		api_manager.request_ai_reply(user_input, stage)
	else:
		_on_ai_reply_received({"npc_name": "系统", "reply_text": "错误：找不到APIManager"})

## 信号回调：处理 AI 回复
func _on_ai_reply_received(response: Dictionary):
	# --- 1. 原有的 UI 处理逻辑 ---
	if response.has("npc_name"):
		_add_comment_ui(response.npc_name, response.reply_text, "邻居", true)
	
	# 恢复按钮状态
	send_button.disabled = false
	send_button.text = "发布"
	
	# --- 2. 强力查找 Main 节点 (必须写在函数里面) ---
	var main_node = get_tree().root.find_child("Main", true, false)
	
	if main_node:
		print("【调试】找到 Main 节点了，准备调用方法...")
		if main_node.has_method("notify_interaction"):
			main_node.notify_interaction("player_post")
		else:
			print("【错误】找到了 Main 节点，但它没有 notify_interaction 函数！")
	else:
		# 这里的打印非常关键，能告诉我们现在到底是谁在当家
		print("【错误】全场景树搜索也找不到名为 Main 的节点。")
		var current_root = get_tree().current_scene
		if current_root:
			print("当前场景根节点是: ", current_root.name)


## ================= 左侧列表逻辑 =================
func _refresh_left_post_list():
	if not post_item_container: return
	for child in post_item_container.get_children():
		child.queue_free()
	
	var all_posts = StoryConfig.get_all_posts()
	for p in all_posts:
		var item = LIST_ITEM.instantiate()
		post_item_container.add_child(item)
		item.setup(p)
		# 假设 post_list_item 有个信号叫 post_selected
		if item.has_signal("post_selected"):
			item.post_selected.connect(_on_post_item_selected)

func _on_post_item_selected(data: Dictionary):
	setup_post(data)

func _clear_comments():
	if not comment_list: return
	for child in comment_list.get_children():
		child.queue_free()
