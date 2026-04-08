extends HBoxContainer

# 获取节点引用
@onready var avatar: TextureRect = $CommentAvatar
@onready var comment_author: Label = $CommentContent/CommentMeta/CommentAuthor
@onready var comment_time: Label = $CommentContent/CommentMeta/CommentTime
@onready var comment_text: Label = $CommentContent/CommentText

# 临时存储数据的变量，防止节点还没 ready 时报错
var _temp_author = ""
var _temp_content = ""
var _temp_time = ""
var _temp_is_npc = false

func setup(author: String, content: String, time_str: String, is_npc: bool = false) -> void:
	"""设置评论内容（供外部调用）"""
	_temp_author = author
	_temp_content = content
	_temp_time = time_str
	_temp_is_npc = is_npc
	
	# 如果节点已经准备好了（比如手动调用时），直接更新 UI
	if is_inside_tree():
		_update_ui()

func _ready():
	# 当节点进入场景树后，自动更新一次 UI
	_update_ui()

func _update_ui():
	if comment_author:
		comment_author.text = _temp_author
		comment_text.text = _temp_content
		comment_time.text = _temp_time
		
		if _temp_is_npc:
			# NPC/AI 回复用不同颜色
			comment_author.add_theme_color_override("font_color", Color(0.2, 0.7, 0.3))
