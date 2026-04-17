extends Node

var current_stage := 0
var is_waiting_ai := false

var player_state = {
	"fear": 0,
	"anger": 0,
	"curious": 0,
	"guilt": 0
}

@onready var story_config = get_node("/root/StoryConfig")
@onready var main = get_tree().root.find_child("Main", true, false)

func start_story():
	current_stage = 0
	play_stage()

func play_stage():
	var stage_data = story_config.get_stage_data("stage_" + str(current_stage + 1))
	
	if stage_data.is_empty():
		print("剧情结束")
		return
	
	# 👉 推送主楼剧情
	var post = stage_data["main_event"]
	main.display_message(post["author"], post["content"], post["id"])
	
	# 👉 进入AI阶段
	await get_tree().create_timer(2).timeout
	trigger_ai(stage_data)

func trigger_ai(stage_data):
	is_waiting_ai = true
	
	var npcs = stage_data.get("npcs", [])
	for npc in npcs:
		main.call_ai_for_npc(npc)

func on_player_input(text):
	# 👉 情绪记录（简单版）
	if text.find("报警") != -1:
		player_state["anger"] += 1
	elif text.find("怕") != -1:
		player_state["fear"] += 1
	elif text.find("为什么") != -1:
		player_state["curious"] += 1
	else:
		player_state["guilt"] += 1

func on_ai_finished():
	is_waiting_ai = false
	
	current_stage += 1
	
	if current_stage >= 5:
		trigger_ending()
	else:
		play_stage()

func trigger_ending():
	# 禁用玩家输入
	var current_scene = main.get_tree().root.find_node("PostScene", true, false)
	if current_scene:
		current_scene.send_button.disabled = true
		current_scene.reply_input.editable = false

	var ending_stage: Dictionary

	# 根据玩家状态选择分支
	if player_state["curious"] >= 5:
		ending_stage = story_config.get_stage_data("ending_crazy")
	elif player_state["anger"] >= 5:
		ending_stage = story_config.get_stage_data("ending_physical")
	else:
		ending_stage = story_config.get_stage_data("ending_sober")

	# 发帖到论坛
	main._post_to_forum(ending_stage["main_event"], false)

	# 可选：触发视觉或音效效果（你可以在 main.gd 添加对应方法）
	match ending_stage["main_event"]["id"]:
		"ending_crazy":
			main.apply_ui_glitch_effect()
			main.blackout_screen_fade()
		"ending_physical":
			main.play_sound("water_pipe_break")
			main.screen_splatter_blood()
			main.blackout_screen_fade()
		"ending_sober":
			main.play_sound("creepy_laughter")
			main.lock_game_forever()
			main.blackout_screen_fade()

	print("结局触发:", ending_stage["stage_hint"])
