class_name RobotUmum
extends Node2D

@export var grid_size: int = 16
@export var jeda_aksi: float = 0.25

var facing_dir: Vector2 = Vector2.DOWN
var garage_pos: Vector2
var is_sleeping: bool = false

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	garage_pos = position # Otomatis nyatet posisi awal sebagai garasi
	play_anim("idle")

# --- PENGATUR ANIMASI 4 ARAH ---
func get_dir_name() -> String:
	if facing_dir == Vector2.UP:
		return "up"
	elif facing_dir == Vector2.LEFT:
		return "left"
	elif facing_dir == Vector2.RIGHT:
		return "right"
	return "down"

func play_anim(state: String) -> void:
	if anim:
		anim.play(state + "_" + get_dir_name())

# --- SENSOR UMUM (Dipakai pas ngoding if / while) ---
func get_pos() -> Vector2i:
	return Vector2i(floor(global_position.x / grid_size), floor(global_position.y / grid_size))

func get_front_pos() -> Vector2i:
	return get_pos() + Vector2i(facing_dir.round())

func can_move() -> bool:
	var level = get_tree().current_scene
	if level and level.has_method("is_cell_walkable"):
		return level.is_cell_walkable(get_front_pos())
	return true

func is_night() -> bool:
	var level = get_tree().current_scene
	if level and level.has_method("is_night"):
		return level.is_night()
	return false

# --- GERAKAN UMUM ---
func move() -> void:
	if is_night() and not is_sleeping:
		await pulang_dan_tidur()
		return

	if not can_move():
		play_anim("idle")
		await get_tree().create_timer(jeda_aksi).timeout
		return

	play_anim("walk")
	var target_pos = position + (facing_dir * grid_size)
	var tween = create_tween()
	tween.tween_property(self, "position", target_pos, jeda_aksi)
	await tween.finished
	play_anim("idle")

func turn_right() -> void:
	if is_night() and not is_sleeping:
		await pulang_dan_tidur()
		return
	facing_dir = facing_dir.rotated(PI / 2).round()
	play_anim("idle")
	await get_tree().create_timer(jeda_aksi).timeout

func turn_left() -> void:
	if is_night() and not is_sleeping:
		await pulang_dan_tidur()
		return
	facing_dir = facing_dir.rotated(-PI / 2).round()
	play_anim("idle")
	await get_tree().create_timer(jeda_aksi).timeout

func turn_around() -> void:
	if is_night() and not is_sleeping:
		await pulang_dan_tidur()
		return
	facing_dir = (-facing_dir).round()
	play_anim("idle")
	await get_tree().create_timer(jeda_aksi).timeout

# --- SISTEM PULANG GARASI & TIDUR MALAM ---
func pulang_dan_tidur() -> void:
	is_sleeping = true
	
	# Jalan balik ke koordinat X garasi
	while abs(position.x - garage_pos.x) >= grid_size * 0.5:
		facing_dir = Vector2.RIGHT if garage_pos.x > position.x else Vector2.LEFT
		play_anim("walk")
		var next_x = position + Vector2(facing_dir.x * grid_size, 0)
		var tween = create_tween()
		tween.tween_property(self, "position", next_x, jeda_aksi)
		await tween.finished
	
	# Jalan balik ke koordinat Y garasi
	while abs(position.y - garage_pos.y) >= grid_size * 0.5:
		facing_dir = Vector2.DOWN if garage_pos.y > position.y else Vector2.UP
		play_anim("walk")
		var next_y = position + Vector2(0, facing_dir.y * grid_size)
		var tween = create_tween()
		tween.tween_property(self, "position", next_y, jeda_aksi)
		await tween.finished
	
	# Parkir rapi & masuk mode tidur
	position = garage_pos
	facing_dir = Vector2.DOWN
	play_anim("idle")
	modulate = Color(0.55, 0.55, 0.75) # Lampu robot redup pas tidur
	
	# Tunggu sampai pagi tiba
	while is_night():
		await get_tree().create_timer(0.5).timeout
	
	# Bangun pagi!
	modulate = Color.WHITE
	is_sleeping = false

# --- JEMBATAN KE SISTEM TANAH DI LEVEL ---
func pakai_alat_ke_level(tool: Enum.Tool, extra_data = null) -> void:
	var level = get_tree().current_scene
	if level and level.has_method("robot_use_tool"):
		level.robot_use_tool(tool, get_front_pos(), extra_data)
