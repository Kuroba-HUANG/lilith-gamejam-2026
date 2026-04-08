# scripts/forum/main.gd
extends Control

const POST_SCENE = preload("res://scenes/forum/post_scene.tscn")
const STORY_CONFIG_SCRIPT = preload("res://config/story_config.gd")

@onready var post_list: VBoxContainer = $ScrollContainer/VBoxContainer
@onready var scroll: ScrollContainer = $ScrollContainer
@onready var refresh_button: Button = $RefreshButton

var story_queue: Array = []
var published_ids: Array = []
var game_start_time: float = 0.0
var timer: Timer
var story_config

# 获取 button.gd 的引用（用于 AI 调用）
var post_button: Button = null

func _ready():
	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(0.94, 0.95, 0.96)
	add_theme_stylebox_override("panel", bg)
	
	# 隐藏底部发帖区域
	if $HBoxContainer:
		$HBoxContainer.visible = false
	
	# 创建配置实例
	story_config = STORY_CONFIG_SCRIPT.new()
	story_config.load_config()
	
	_init_story_queue()
	
	timer = Timer.new()
	timer.wait_time = 1.0
	timer.timeout.connect(_on_timer_tick)
	add_child(timer)
	timer.start()
	
	game_start_time = Time.get_ticks_msec() / 1000.0
	
	if refresh_button:
		refresh_button.pressed.connect(_on_refresh_pressed)
	
	print("论坛已启动，将自动发布剧情帖子...")
	_add_system_message("✨ 论坛已开启，剧情帖将自动发布 ✨")

# 玩家回复时的回调（由 post.gd 调用）
func on_player_replied(post_instance, user_reply: String, npc_name: String, post_content: String):
	print("玩家回复了帖子，NPC: %s, 回复内容: %s" % [npc_name, user_reply])
	
	# 调用 AI 生成 NPC 回复
	if post_button and post_button.has_method("call_ai_for_npc_reply"):
		post_button.call_ai_for_npc_reply(post_instance, user_reply, npc_name, post_content)

func _init_story_queue():
	var all_posts = story_config.get_story_posts()
	story_queue = all_posts.duplicate()
	story_queue.sort_custom(func(a, b): return a.delay_seconds < b.delay_seconds)

func _on_timer_tick():
	var current_time = (Time.get_ticks_msec() / 1000.0) - game_start_time
	
	while story_queue.size() > 0:
		var next_post = story_queue[0]
		if current_time >= next_post.delay_seconds:
			story_queue.pop_front()
			if next_post.id not in published_ids:
				_publish_story_post(next_post)
		else:
			break

func _publish_story_post(post):
	published_ids.append(post.id)
	
	var post_instance = POST_SCENE.instantiate()
	
	# === 关键修改：先加到场景树，让 @onready 生效 ===
	post_list.add_child(post_instance) 
	
	# 判断类型
	if post.post_type == "reply":
		var target_post = _find_post_by_id(post.reply_to)
		if target_post:
			target_post.add_reply(post.character, post.content, true)
			_add_system_message("%s 回复了帖子" % post.character)
		else:
			# 找不到目标，作为主帖显示
			post_instance.setup_as_main_post(post.title, post.content, post.character)
			_add_system_message("【%s】发布了内容" % post.character)
	else:
		# 主帖
		post_instance.setup_as_main_post(post.title, post.content, post.character)
		_add_system_message("【%s】发布了新帖《%s》" % [post.character, post.title])
	
	scroll_to_bottom()
	
	scroll_to_bottom()
	print("📢 发布: %s" % post.character)
	
func _find_post_by_id(post_id: int):
	for child in post_list.get_children():
		if child.has_method("get_post_id") and child.get_post_id() == post_id:
			return child
	return null

func _add_system_message(text: String):
	var msg_label = Label.new()
	msg_label.text = "🔔 " + text
	msg_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	msg_label.add_theme_font_size_override("font_size", 12)
	post_list.add_child(msg_label)
	scroll_to_bottom()

func scroll_to_bottom():
	await get_tree().process_frame
	if scroll and scroll.get_v_scroll_bar():
		scroll.scroll_vertical = scroll.get_v_scroll_bar().max_value

func _on_refresh_pressed():
	for child in post_list.get_children():
		child.queue_free()
	
	published_ids.clear()
	_init_story_queue()
	game_start_time = Time.get_ticks_msec() / 1000.0
	
	_add_system_message("🔄 论坛已刷新，剧情将重新开始")
	print("论坛已重置")
