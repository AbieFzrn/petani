class_name RobotPlanter
extends RobotUmum

@export var max_seeds: int = 10
var seeds: int = 10
var current_seed: Enum.Seed = Enum.Seed.TOMATO

# --- SENSOR KHUSUS PLANTER ---
func is_empty() -> bool:
	return seeds <= 0

func get_seeds() -> int:
	return seeds

func set_seed(seed_type: Enum.Seed) -> void:
	current_seed = seed_type

# --- AKSI KHUSUS PLANTER ---
func till() -> void:
	if is_night() and not is_sleeping:
		await pulang_dan_tidur()
		return

	play_anim("interact")
	pakai_alat_ke_level(Enum.Tool.HOE)
	await get_tree().create_timer(0.5).timeout
	play_anim("idle")

func plant(seed_type: int = -1) -> void:
	if is_night() and not is_sleeping:
		await pulang_dan_tidur()
		return

	if is_empty():
		print("Planter: Bibit habis! Balik ke garasi/silo dan panggil restock()")
		return

	var chosen_seed: Enum.Seed = current_seed if seed_type == -1 else seed_type
	var level = get_tree().current_scene
	if level and level.has_method("is_tool_valid"):
		if not level.is_tool_valid(Enum.Tool.SEED, get_front_pos()):
			return

	seeds -= 1
	play_anim("interact")
	pakai_alat_ke_level(Enum.Tool.SEED, chosen_seed)
	await get_tree().create_timer(0.5).timeout
	play_anim("idle")

func restock() -> void:
	if not is_near_supply("Silo"):
		print("Planter: Harus di dekat Garasi atau Silo buat restock!")
		return

	play_anim("interact")
	await get_tree().create_timer(0.5).timeout
	seeds = max_seeds
	play_anim("idle")
	print("Planter: Restock penuh (", seeds, "/", max_seeds, ")")

func is_near_supply(group_name: String) -> bool:
	# Bisa restock di garasi awal ATAU di dekat node grup "Silo" kalau map temen lu udah jadi
	if position.distance_to(garage_pos) <= grid_size * 1.5:
		return true
	for node in get_tree().get_nodes_in_group(group_name):
		if global_position.distance_to(node.global_position) <= grid_size * 2.0:
			return true
	return false
