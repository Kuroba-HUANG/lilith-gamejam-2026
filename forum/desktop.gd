extends Control

# ============================================
# 节点引用（区分大小写）
# ============================================
@onready var time_label: Label = $Taskbar/Tray/TimeLabel
@onready var volume_button: Button = $Taskbar/Tray/VolumeButton
@onready var shutdown_button: Button = $Taskbar/ShutdownButton
@onready var start_button: Button = $Taskbar/StartButton

# 图标按钮
@onready var browser_icon: Button = $IconsContainer/IconBrowser
@onready var icon_docs: Button = $IconsContainer/IconDocs
@onready var icon_media: Button = $IconsContainer/IconMedia
@onready var icon_files: Button = $IconsContainer/IconFiles

# 弹窗容器
@onready var popup_container: Control = $PopupContainer

# 背景
@onready var background: ColorRect = $Background

# ============================================
# 常量 - 场景路径
# ============================================
const FORUM_SCENE = "res://main.tscn"        # 论坛主场景
const POST_SCENE = "res://post.tscn"         # 帖子场景（如果需要）

# ============================================
# 全局变量
# ============================================
# 在变量定义区域添加（放在 current_volume 变量附近）
var current_popup: Panel = null  # 当前打开的弹窗

var current_volume: int = 50:
	set(value):
		current_volume = clamp(value, 0, 100)
		_update_volume_display()

# ============================================
# 初始化
# ============================================
func _ready():
	
	# 初始化音量
	current_volume = 50
	
	# 更新时间显示
	_update_time()
	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.timeout.connect(_update_time)
	add_child(timer)
	timer.start()
	
	# 连接按钮信号
	shutdown_button.pressed.connect(_on_shutdown_pressed)
	volume_button.pressed.connect(_on_volume_pressed)
	start_button.pressed.connect(_on_start_pressed)
	
	# 连接图标信号
	browser_icon.pressed.connect(_on_browser_pressed)
	icon_docs.pressed.connect(_on_icon_pressed.bind("我的文档"))
	icon_media.pressed.connect(_on_icon_pressed.bind("媒体播放器"))
	icon_files.pressed.connect(_on_icon_pressed.bind("文件管理器"))
	
	# 可选：设置图标悬停效果
	_setup_hover_effects()

# ============================================
# 悬停效果设置
# ============================================
func _setup_hover_effects():
	var icons = [browser_icon, icon_docs, icon_media, icon_files]
	for icon in icons:
		icon.mouse_entered.connect(_on_icon_mouse_entered.bind(icon))
		icon.mouse_exited.connect(_on_icon_mouse_exited.bind(icon))

func _on_icon_mouse_entered(icon: Button):
	var tween = create_tween()
	tween.tween_property(icon, "scale", Vector2(1.05, 1.05), 0.1)

func _on_icon_mouse_exited(icon: Button):
	var tween = create_tween()
	tween.tween_property(icon, "scale", Vector2(1.0, 1.0), 0.1)

# ============================================
# 更新时间显示
# ============================================
func _update_time():
	var time = Time.get_time_dict_from_system()
	time_label.text = "%02d:%02d" % [time.hour, time.minute]

# ============================================
# 音量显示更新
# ============================================
func _update_volume_display():
	var icon = ""
	if current_volume == 0:
		icon = "🔇"
	elif current_volume < 30:
		icon = "🔈"
	elif current_volume < 70:
		icon = "🔉"
	else:
		icon = "🔊"
	volume_button.text = "%s %d%%" % [icon, current_volume]

# ============================================
# 音量按钮 - 弹出横向滑块弹窗
# ============================================
func _on_volume_pressed():
	_show_volume_popup()

func _show_volume_popup():
	# 如果已经有弹窗，先关闭它
	if current_popup != null and is_instance_valid(current_popup):
		current_popup.queue_free()
		current_popup = null
	
	# 获取音量按钮的位置
	var btn_pos = volume_button.global_position
	var btn_size = volume_button.size
	
	# 创建弹窗
	var popup = Panel.new()
	popup.size = Vector2(70, 200)
	popup.name = "VolumePopup"
	popup.z_index = 100
	
	# 计算位置：在音量按钮正上方居中
	popup.position = Vector2(
		btn_pos.x + (btn_size.x / 2) - (popup.size.x / 2),
		btn_pos.y - popup.size.y - 5
	)
	
	# 如果超出顶部，就放到下方
	if popup.position.y < 0:
		popup.position.y = btn_pos.y + btn_size.y + 5
	
	# 样式
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.925, 0.91, 0.847)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.039, 0.184, 0.353)
	popup.add_theme_stylebox_override("panel", style)
	
	# 内容布局
	var vbox = VBoxContainer.new()
	vbox.anchor_right = 1.0
	vbox.anchor_bottom = 1.0
	vbox.add_theme_constant_override("margin_left", 10)
	vbox.add_theme_constant_override("margin_right", 10)
	vbox.add_theme_constant_override("margin_top", 10)
	vbox.add_theme_constant_override("margin_bottom", 10)
	vbox.add_theme_constant_override("separation", 8)
	popup.add_child(vbox)
	
	# 图标
	var icon = Label.new()
	icon.text = "🔊"
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(icon)
	
	# 竖向滑块
	var slider = VSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.value = current_volume
	slider.custom_minimum_size = Vector2(30, 100)
	slider.size_flags_vertical = Control.SIZE_EXPAND
	vbox.add_child(slider)
	
	# 数值
	var value_label = Label.new()
	value_label.text = "%d%%" % current_volume
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(value_label)
	
	# 确定按钮
	var ok_btn = Button.new()
	ok_btn.text = "确定"
	ok_btn.custom_minimum_size = Vector2(50, 24)
	vbox.add_child(ok_btn)
	
	# 滑块变化
	slider.value_changed.connect(func(val):
		value_label.text = "%d%%" % val
		if val == 0:
			icon.text = "🔇"
		elif val < 30:
			icon.text = "🔈"
		elif val < 70:
			icon.text = "🔉"
		else:
			icon.text = "🔊"
	)
	
	# 确定按钮
	ok_btn.pressed.connect(func():
		current_volume = slider.value
		popup.queue_free()
		current_popup = null
	)
	
	# 弹窗关闭时清空引用
	popup.tree_exited.connect(func():
		if current_popup == popup:
			current_popup = null
	)
	
	popup_container.add_child(popup)
	current_popup = popup

# ============================================
# 未开放图标点击
# ============================================
func _on_icon_pressed(soft_name: String):
	_show_message_popup("提示", "“%s”\n该功能暂未开放" % soft_name)

func _show_message_popup(title: String, message: String, show_cancel: bool = false, on_confirm: Callable = func(): pass):
	# 如果已经有弹窗，先关闭它
	if current_popup != null and is_instance_valid(current_popup):
		current_popup.queue_free()
		current_popup = null
	
	# 根据消息长度动态调整弹窗高度
	var message_lines = message.count("\n") + 1
	var dynamic_height = 140 + (message_lines * 20)
	dynamic_height = clamp(dynamic_height, 160, 280)
	
	var popup = Panel.new()
	popup.size = Vector2(340, dynamic_height)
	popup.position = (get_viewport_rect().size - popup.size) / 2
	popup.name = "MessagePopup"
	popup.z_index = 100
	
	# 设置弹窗样式
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.925, 0.91, 0.847)
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.border_color = Color(0.039, 0.184, 0.353)
	popup.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.anchor_right = 1.0
	vbox.anchor_bottom = 1.0
	vbox.add_theme_constant_override("separation", 12)
	vbox.add_theme_constant_override("margin_left", 16)
	vbox.add_theme_constant_override("margin_right", 16)
	vbox.add_theme_constant_override("margin_top", 16)
	vbox.add_theme_constant_override("margin_bottom", 16)
	popup.add_child(vbox)
	
	# 标题
	var title_label = Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 16)
	title_label.add_theme_color_override("font_color", Color(0.1, 0.23, 0.36))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_label)
	
	# 分隔线
	var separator = HSeparator.new()
	vbox.add_child(separator)
	
	# 内容
	var msg_label = Label.new()
	msg_label.text = message
	msg_label.add_theme_font_size_override("font_size", 14)
	msg_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	msg_label.size_flags_horizontal = Control.SIZE_EXPAND
	msg_label.size_flags_vertical = Control.SIZE_EXPAND
	msg_label.custom_minimum_size = Vector2(280, 0)
	vbox.add_child(msg_label)
	
	# 按钮区域
	var btn_hbox = HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 15)
	vbox.add_child(btn_hbox)
	
	var confirm_btn = Button.new()
	confirm_btn.text = "确定"
	confirm_btn.custom_minimum_size = Vector2(80, 30)
	btn_hbox.add_child(confirm_btn)
	
	if show_cancel:
		var cancel_btn = Button.new()
		cancel_btn.text = "取消"
		cancel_btn.custom_minimum_size = Vector2(80, 30)
		btn_hbox.add_child(cancel_btn)
		cancel_btn.pressed.connect(func(): 
			popup.queue_free()
			current_popup = null
		)
	
	confirm_btn.pressed.connect(func():
		on_confirm.call()
		popup.queue_free()
		current_popup = null
	)
	
	# 弹窗关闭时清空引用
	popup.tree_exited.connect(func():
		if current_popup == popup:
			current_popup = null
	)
	
	popup_container.add_child(popup)
	current_popup = popup
# ============================================
# 开始按钮（彩蛋）
# ============================================
func _on_start_pressed():
	_show_message_popup("提示", "开始菜单(演示版)")

# ============================================
# 关机按钮
# ============================================
func _on_shutdown_pressed():
	_show_message_popup("⚠️ 关机", "确定要关闭电脑并退出游戏吗？\n数据不会保存", true, func():
		get_tree().quit()
	)

# ============================================
# 浏览器按钮 - 弹出网址输入窗口
# ============================================
const CORRECT_URL = "论坛网址"

func _on_browser_pressed():
	_show_url_input_popup()

func _show_url_input_popup():
	# 如果已经有弹窗，先关闭它
	if current_popup != null and is_instance_valid(current_popup):
		current_popup.queue_free()
		current_popup = null
	
	var popup = Panel.new()
	popup.size = Vector2(400, 240)
	popup.position = (get_viewport_rect().size - popup.size) / 2
	popup.name = "UrlInputPopup"
	popup.z_index = 100
	
	# 设置弹窗样式
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.925, 0.91, 0.847)
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.border_color = Color(0.039, 0.184, 0.353)
	popup.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.anchor_right = 1.0
	vbox.anchor_bottom = 1.0
	vbox.add_theme_constant_override("separation", 12)
	vbox.add_theme_constant_override("margin_left", 16)
	vbox.add_theme_constant_override("margin_right", 16)
	vbox.add_theme_constant_override("margin_top", 16)
	vbox.add_theme_constant_override("margin_bottom", 16)
	popup.add_child(vbox)
	
	# 标题
	var title = Label.new()
	title.text = "🌐 请输入网址"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.1, 0.23, 0.36))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	# 分隔线
	var separator = HSeparator.new()
	vbox.add_child(separator)
	
	# 输入框
	var line_edit = LineEdit.new()
	line_edit.placeholder_text = "请输入设定字符..."
	line_edit.size_flags_horizontal = Control.SIZE_EXPAND
	vbox.add_child(line_edit)
	
	# 提示文字
	var hint = Label.new()
	hint.text = "💡 提示：请输入 \"%s\" 来打开论坛" % CORRECT_URL
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(hint)
	
	# 按钮区域
	var btn_hbox = HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_END
	btn_hbox.add_theme_constant_override("separation", 10)
	vbox.add_child(btn_hbox)
	
	var cancel_btn = Button.new()
	cancel_btn.text = "取消"
	cancel_btn.custom_minimum_size = Vector2(80, 30)
	btn_hbox.add_child(cancel_btn)
	
	var confirm_btn = Button.new()
	confirm_btn.text = "前往"
	confirm_btn.custom_minimum_size = Vector2(80, 30)
	btn_hbox.add_child(confirm_btn)
	
	# 取消按钮
	cancel_btn.pressed.connect(func(): 
		popup.queue_free()
		current_popup = null
	)
	
	# 确认按钮
	confirm_btn.pressed.connect(func():
		var input = line_edit.text.strip_edges()
		if input == CORRECT_URL:
			popup.queue_free()
			current_popup = null
			get_tree().change_scene_to_file(FORUM_SCENE)
		else:
			_show_message_popup("❌ 网址错误", "请输入正确的设定字符：\"%s\"\n\n当前输入：\"%s\"" % [CORRECT_URL, input])
			line_edit.clear()
			line_edit.grab_focus()
	)
	
	# 回车键提交
	line_edit.text_submitted.connect(func(_text): confirm_btn.emit_signal("pressed"))
	
	# 弹窗关闭时清空引用
	popup.tree_exited.connect(func():
		if current_popup == popup:
			current_popup = null
	)
	
	popup_container.add_child(popup)
	current_popup = popup
