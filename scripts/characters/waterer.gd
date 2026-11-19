class_name RobotWaterer
extends RobotUmum

@export var max_water: int = 10
var water_tank: int = 10

# --- SENSOR KHUSUS WATERER ---
func is_empty() -> bool:
	return water_tank <= 0

func get_water() -> int:
	return water_tank

func is_wet() -> bool:
	var level = get_tree().current_scene
	if level and level.has_method("is_soil_wet"):
		return level.is_soil_wet(get_front_pos())
	return false

# --- AKSI KHUSUS WATERER ---
func water() -> void:
	if is_night() and not is_sleeping:
		await pulang_dan_tidur()
		return

	if is_empty():
		print("Waterer: Air habis! Hadap ke air/sumur dan panggil refill()")
		return

	var level = get_tree().current_scene
	if level and level.has_method("is_tool_valid"):
		if not level.is_tool_valid(Enum.Tool.WATER, get_front_pos()):
			return

	water_tank -= 1
	play_anim("interact")
	pakai_alat_ke_level(Enum.Tool.WATER)
	await get_tree().create_timer(0.5).timeout
	play_anim("idle")

func refill() -> void:
	var level = get_tree().current_scene
	var can_refill := false
	
	# Bisa refill kalau menghadap petak air ATAU di dekat garasi
	if level and level.has_method("is_water_tile") and level.is_water_tile(get_front_pos()):
		can_refill = true
	elif position.distance_to(garage_pos) <= grid_size * 1.5:
		can_refill = true

	if not can_refill:
		print("Waterer: Hadap ke kolam/sungai atau ke Garasi buat refill air!")
		return

	play_anim("interact")
	await get_tree().create_timer(0.5).timeout
	water_tank = max_water
	play_anim("idle")
	print("Waterer: Tangki air penuh (", water_tank, "/", max_water, ")")
