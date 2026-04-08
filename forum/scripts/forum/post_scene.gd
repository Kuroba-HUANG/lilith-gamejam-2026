extends Control

# ========== 全新的节点引用（基于三栏结构） ==========
@onready var post_title: Label = $MainLayout/CenterColumn/PostDetailArea/PostTitle
@onready var post_content: RichTextLabel = $MainLayout/CenterColumn/PostDetailArea/PostMainContent
@onready var reply_input: TextEdit = $MainLayout/CenterColumn/PostDetailArea/ReplyInputBox/VBoxContainer/InputText
@onready var send_button: Button = $MainLayout/CenterColumn/PostDetailArea/ReplyInputBox/VBoxContainer/SendButton
@onready var comment_list: VBoxContainer = $MainLayout/CenterColumn/CommentScroll/CommentList
@onready var comment_scroll: ScrollContainer = $MainLayout/CenterColumn/CommentScroll
@onready var post_item_container: VBoxContainer = $MainLayout/LeftColumn/PostListScroll/PostItemContainer

var my_post_id: int = 0
var current_post_data: Dictionary = {}

func _ready():
	# 重新连接发送按钮信号
	if send_button:
		send_button.pressed.connect(_on_send_pressed)
	#测试左侧缩略图效果
	_test_load_left_list()
	var test_posts = [
		{"id": 1, "title": "【寻人】我的妹妹失踪了", "character": "佐藤", "content": "她下午三点左右出门后一直没回来..."},
		{"id": 2, "title": "有人看到奇怪的光吗？", "character": "灵异爱好者", "content": "就在刚才，山顶方向..."}
	]	

		
func _create_left_list_item(data: Dictionary):
	var item_scene = preload("res://scenes/forum/post_list_item.tscn")
	var item = item_scene.instantiate()
	# 假设你的 LeftColumn 下面有一个 VBoxContainer 叫 PostItemContainer
	$MainLayout/LeftColumn/PostListScroll/PostItemContainer.add_child(item)
	# 让小按钮显示自己的标题和作者
	item.setup(data)
	# 重要：把按钮的点击信号，连到 post_scene 的处理函数上
	item.post_selected.connect(_on_post_item_selected)


func setup_as_main_post(title: String, content: String, character: String) -> void:
	"""设置主帖内容（由 main.gd 调用）"""
	# 如果节点还没ready，手动强制获取一下
	if post_title == null:
		_manual_grab_nodes()
	
	my_post_id = Time.get_ticks_msec()
	post_title.text = title
	post_content.text = content
	print("✅ 帖子加载成功: %s" % title)

func add_reply(author: String, content: String, is_npc: bool = false) -> void:
	"""添加一条评论"""
	var CommentItemScene = preload("res://scenes/forum/comment_item.tscn")
	var comment = CommentItemScene.instantiate()
	
	# 这里先加进列表，再 setup，防止 Nil 报错
	comment_list.add_child(comment)
	comment.setup(author, content, "刚刚", is_npc)
	
	# 自动滚动到底部
	await get_tree().process_frame
	comment_scroll.scroll_vertical = comment_scroll.get_v_scroll_bar().max_value

func _on_send_pressed():
	var user_input = reply_input.text.strip_edges()
	if user_input.is_empty():
		return
	
	add_reply("玩家用户", user_input, false)
	reply_input.clear()

func _manual_grab_nodes():
	# 防错用的手动获取路径
	post_title = $MainLayout/CenterColumn/PostDetailArea/PostTitle
	post_content = $MainLayout/CenterColumn/PostDetailArea/PostMainContent
	# ... 其他节点同理
	
func _test_load_left_list():
	# 这里假设你有一些剧情帖子数据
	var mock_data = [
		{"id": 1, "title": "有人看到我的猫吗？", "content": "它是一只橘猫...", "character": "隔壁老王"},
		{"id": 2, "title": "【惊爆】深夜学校旧楼的灯光", "content": "昨天晚上我路过...", "character": "灵异爱好者"}
	]
	
	for data in mock_data:
		var item_scene = preload("res://scenes/forum/post_list_item.tscn")
		var item = item_scene.instantiate()
		post_item_container.add_child(item)
		item.setup(data)
		
		# 核心联动逻辑：连接信号
		item.post_selected.connect(_on_post_item_selected)

func _on_post_item_selected(data: Dictionary):
	current_post_data = data
	post_title.text = data.title
	post_content.text = data.content
	
	# 清空旧评论
	for child in comment_list.get_children():
		child.queue_free()
	
	# 加载该帖子的固定主线剧情楼层
	if data.has("fixed_stairs"):
		for comment_data in data.fixed_stairs:
			_render_comment(comment_data)

func _render_comment(c_data: Dictionary):
	var CommentItemScene = preload("res://scenes/forum/comment_item.tscn")
	var comment = CommentItemScene.instantiate()
	comment_list.add_child(comment)
	
	# 假设你的 comment_item 有一个 setup 函数
	# 这里增加 floor 参数来匹配论坛观感
	comment.setup(c_data.author, c_data.content, str(c_data.floor) + "F", c_data.is_npc)
