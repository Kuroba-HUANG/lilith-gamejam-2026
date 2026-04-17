# main.gd
extends Node

@onready var scene_container = $SceneContainer
@onready var anim_player = $TransitionLayer/AnimationPlayer
@onready var story_manager = $StoryManager

var current_stage_index = 1
var stage_timer = 0.0
var force_next_stage_time = 60.0

var pending_ai_count = 0
var is_game_running = false
var is_waiting_ai = false

var has_triggered_glitch = false

# =========================
# 游戏启动
# =========================
func _ready():
	change_sub_scene("res://scenes/desktop/desktop.tscn")

func _process(delta):
	if !is_game_running:
		return
	
	stage_timer += delta
	if stage_timer >= force_next_stage_time:
		trigger_next_stage()

# =========================
# 🎬 剧情阶段控制
# =========================
func start_stage(stage_num: int):
	# 污染爆发（第5阶段）
	if stage_num == 5:
		StoryConfig.set_npc_status("@平安是福", "polluted")
		print("⚠️ 王姨进入污染态")
	
	current_stage_index = stage_num
	stage_timer = 0.0
	
	var stage_data = StoryConfig.get_stage_data("stage_" + str(stage_num))
	if stage_data.is_empty():
		return
	
	# 第一阶段：发新帖
	if stage_num == 1:
		_post_to_forum(stage_data.main_event, true)
	else:
		if stage_data.has("main_event"):
			_post_to_forum(stage_data.main_event, false)
	
	# 自动NPC互动
	if stage_data.has("auto_interactions"):
		for npc_post in stage_data.auto_interactions:
			var delay_time = npc_post.get("delay", 1.0)
			var timer = get_tree().create_timer(delay_time)
			timer.timeout.connect(func():
				_post_to_forum(npc_post, false)
			)

func trigger_next_stage():
	if current_stage_index < 6:
		start_stage(current_stage_index + 1)

# =========================
# 🧠 玩家交互入口
# =========================
func notify_interaction(type, data):
	if type != "player_post":
		return
	
	if is_waiting_ai:
		return
	
	var player_text = data["text"]
	var post_id = data["post_id"]
	var stage_data = StoryConfig.get_stage_data("stage_" + str(current_stage_index))
	var npc_list = stage_data.get("active_npcs", ["修仙的阿宅"])
	
	pending_ai_count = npc_list.size()
	is_waiting_ai = true
	
	if story_manager:
		story_manager.on_player_input(player_text)
	
	call_ai_for_current_stage(player_text, post_id)

# =========================
# 🤖 多NPC调用
# =========================
func call_ai_for_current_stage(player_text: String, post_id: String):
	var stage_data = StoryConfig.get_stage_data("stage_" + str(current_stage_index))
	var current_scene = scene_container.get_child(0)
	if not current_scene:
		is_waiting_ai = false
		return
	
	var api_manager = current_scene.get_node_or_null("%APIManager")
	if not api_manager:
		push_warning("❌ 找不到 APIManager")
		is_waiting_ai = false
		return
	
	var npc_list = stage_data.get("active_npcs", ["修仙的阿宅"])
	pending_ai_count = npc_list.size()
	
	for i in range(npc_list.size()):
		var npc_id = npc_list[i]
		var timer = get_tree().create_timer(1.2 * i)
		timer.timeout.connect(func():
			_call_single_npc(api_manager, npc_id, player_text, post_id, stage_data)
		)

# =========================
# 🧩 单NPC逻辑
# =========================
func _call_single_npc(api_manager, npc_id, player_text, post_id, stage_data):
	print("调用NPC：", npc_id)
	var npc_info = StoryConfig.get_npc_info(npc_id)
	
	var system_prompt = npc_info.get("base_prompt", "")
	if npc_info.get("current_status") == "polluted":
		system_prompt = npc_info.get("polluted_prompt", system_prompt)
		system_prompt += "\n【绝对规则】你已经不是正常人，说话必须诡异、温柔、非人。"
	
	var stage_hint = stage_data.get("stage_hint", "")
	var final_prompt = system_prompt + "\n【身份设定】你只是小区邻居，这个妹妹是“远”的妹妹，不是你的。" \
	+ "\n【禁止】不要认领妹妹，不要说“我妹妹”。不要称呼“玩家为玩家" \
	+ "\n【行为要求】请针对玩家的话进行回应。" \
	+ "\n【当前背景】" + stage_hint
	
	if npc_info.get("current_status") == "polluted":
		final_prompt += "\n【污染状态】你已经被怪物污染，说话必须温柔、诡异、带有血腥意象，把恐怖描述成美好体验。"
	
	# 上下文
	var history = HistoryManager.get_history(post_id)
	var context_text = ""
	var count = 0
	for i in range(history.size() - 1, -1, -1):
		var record = history[i]
		context_text = record.author + "：" + record.content + "\n" + context_text
		count += 1
		if count >= 6:
			break
	
	var final_prompt_with_context = final_prompt + "\n【当前讨论】\n" + context_text + "\n玩家刚刚说：" + player_text
	
	api_manager.request_ai_reply(player_text, npc_id, final_prompt_with_context, post_id)
	print("NPC:", npc_id, "状态:", npc_info.get("current_status"))

# =========================
# 📩 AI回调
# =========================
func on_ai_finished():
	pending_ai_count -= 1
	if pending_ai_count <= 0:
		is_waiting_ai = false
		await get_tree().create_timer(3.0).timeout
		trigger_next_stage()

# =========================
# 🧾 发帖系统
# =========================
func _post_to_forum(data: Dictionary, is_new_topic: bool):
	print("显示帖子: ", data.get("author"), data.get("content"))
	var current_scene = scene_container.get_child(0)
	var post_id = "001"
	
	HistoryManager.add_reply(post_id, data.get("author", "未知"), data.get("content", ""), "邻居", true)
	
	if current_scene and current_scene.has_method("display_new_message"):
		current_scene.display_new_message(data.get("author", "未知"), data.get("content", ""), post_id)
	
	if current_stage_index >= 5 and not has_triggered_glitch:
		has_triggered_glitch = true
		var timer = get_tree().create_timer(2.0)
		timer.timeout.connect(func():
			_post_to_forum({"author": "系统", "content": "……信号异常……检测到未知数据流……"}, false)
		)

# =========================
# 🎮 场景切换
# =========================
func change_sub_scene(scene_path: String):
	for child in scene_container.get_children():
		child.queue_free()
	
	var new_scene = load(scene_path).instantiate()
	scene_container.add_child(new_scene)
	
	if "post_scene.tscn" in scene_path:
		is_game_running = true
		if stage_timer == 0:
			start_stage(1)

# =========================
# 🧟‍♂️ 结局测试
# =========================

func apply_ui_glitch_effect():
	var current_scene = scene_container.get_child(0)
	if not current_scene:
		return
	
	for label in current_scene.get_tree().get_nodes_in_group("post_labels"):
		label.add_color_override("font_color", Color(randf(), randf(), randf()))
		label.rect_position += Vector2(randf() * 4 - 2, randf() * 4 - 2)
	
	var timer = Timer.new()
	timer.wait_time = 0.1
	timer.one_shot = false
	timer.timeout.connect(apply_ui_glitch_effect)
	current_scene.add_child(timer)
	timer.start()

func blackout_screen_fade(duration: float = 1.0):
	var rect = $EfffectOverlay
	rect.visible = true
	rect.modulate.a = 0

	var tween = Tween.new()
	add_child(tween)
	tween.tween_property(rect, "modulate:a", 1.0, duration)
	tween.start()

func screen_splatter_blood():
	print("⚠️ 屏幕溅血效果触发")

func lock_game_forever():
	print("⚠️ 游戏锁死，无法退出")
