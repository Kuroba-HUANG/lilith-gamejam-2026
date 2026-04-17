extends Node

# 存储格式：{ "post_id": [ {author, content, time, is_npc}, ... ] }
var chat_history: Dictionary = {}

func add_reply(post_id: String, author: String, content: String, time: String, is_npc: bool):
	if not chat_history.has(post_id):
		chat_history[post_id] = []
	chat_history[post_id].append({
		"author": author,
		"content": content,
		"time": time,
		"is_npc": is_npc
	})

func get_history(post_id: String) -> Array:
	return chat_history.get(post_id, [])
