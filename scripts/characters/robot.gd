class_name RobotUmum
extends Node2D

@export var grid_size: int = 16
@export var jeda_aksi: float = 0.25

var facing_dir: Vector2 = Vector2.DOWN
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
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

# --- GERAKAN UMUM ---
func move() -> void:
	play_anim("walk")
	var target_pos = position + (facing_dir * grid_size)
	var tween = create_tween()
	tween.tween_property(self, "position", target_pos, jeda_aksi)
	await tween.finished
	play_anim("idle")

func turn_right() -> void:
	facing_dir = facing_dir.rotated(PI / 2).round()
	play_anim("idle")
	await get_tree().create_timer(jeda_aksi).timeout

func turn_left() -> void:
	facing_dir = facing_dir.rotated(-PI / 2).round()
	play_anim("idle")
	await get_tree().create_timer(jeda_aksi).timeout

# --- JEMBATAN KE SISTEM TANAH DI LEVEL ---
func pakai_alat_ke_level(tool: Enum.Tool) -> void:
	var level = get_tree().current_scene
	if level and level.has_method("_on_player_tool_use"):
		level._on_player_tool_use(tool, global_position, facing_dir)
