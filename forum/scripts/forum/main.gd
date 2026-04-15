# main.gd
extends Node

@onready var scene_container = $SceneContainer
@onready var anim_player = $TransitionLayer/AnimationPlayer

# 记录当前剧情进度的变量（策划条件预留）
var interaction_count = 0

func _ready():
	# 初始场景：进入桌面
	change_sub_scene("res://scenes/desktop/desktop.tscn")

## 通用的场景切换函数
func change_sub_scene(scene_path: String):
	# 1. 播放淡出动画（可选）
	#if anim_player:
		#anim_player.play("fade_out")
		#await anim_player.animation_finished

	# 2. 清理容器
	for child in scene_container.get_children():
		child.queue_free()

	# 3. 实例新场景
	var new_scene = load(scene_path).instantiate()
	scene_container.add_child(new_scene)

	
	# 4. 播放淡入动画（暂无）
	#if anim_player:
		#anim_player.play("fade_in")

## ================= 剧情控制接口 (交互驱动核心) =================

## 供 post_scene 或 desktop 调用：汇报发生了什么
func notify_interaction(type: String, extra_data: Dictionary = {}):
	print("【导演层】接收到交互：", type)
	
	match type:
		"player_post":
			interaction_count += 1
			_check_story_logic()
		"open_file":
			print("玩家查看了文件：", extra_data.get("file_name"))

## 检查是否满足策划的“神秘条件”
func _check_story_logic():
	# 示例测试逻辑：回帖 2 次后触发佐藤新帖
	if interaction_count == 2:
		trigger_sato_event("sato_post_002")

## 强制触发佐藤事件
func trigger_sato_event(event_id: String):
	print("【剧情】触发主线：", event_id)
	var next_data = StoryConfig.get_post_by_id(event_id) # 假设 StoryConfig 有这个方法
	
	# 获取当前正在运行的场景
	var current_scene = scene_container.get_child(0)
	
	# 如果当前就在论坛，直接刷新内容
	if current_scene.has_method("setup_post"):
		current_scene.setup_post(next_data)
	else:
		# 如果玩家在桌面，可以弹出一个“通知”
		print("玩家不在论坛，应弹出桌面通知")
		
