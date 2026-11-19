class_name RobotHarvester
extends RobotUmum

@export var max_cargo: int = 10
var cargo: int = 0

# --- SENSOR KHUSUS HARVESTER ---
func is_full() -> bool:
	return cargo >= max_cargo

func get_cargo() -> int:
	return cargo

func can_harvest() -> bool:
	var plant = get_front_plant()
	if plant and "death" in plant:
		# Cek apakah tanaman sudah siap panen (frame terakhir)
		var sprite = plant.get_node_or_null("Sprite2D")
		if sprite:
			return sprite.frame >= sprite.hframes - 1
	return false

# --- AKSI KHUSUS HARVESTER ---
func harvest() -> void:
	if is_night() and not is_sleeping:
		await pulang_dan_tidur()
		return

	if is_full():
		print("Harvester: Bak panen penuh! Balik ke garasi/toko dan panggil sell()")
		return

	play_anim("interact")
	var plant = get_front_plant()
	if plant and plant.has_method("_on_collision_area_body_entered"):
		plant._on_collision_area_body_entered(self)
		cargo += 1
		print("Harvester: Panen masuk bak (", cargo, "/", max_cargo, ")")

	await get_tree().create_timer(0.5).timeout
	play_anim("idle")

func sell() -> void:
	if not is_near_sell_point():
		print("Harvester: Harus di dekat Garasi atau SellBin buat jual hasil panen!")
		return

	if cargo <= 0:
		return

	play_anim("interact")
	await get_tree().create_timer(0.5).timeout
	print("Harvester: Berhasil menjual ", cargo, " hasil panen!")
	cargo = 0
	play_anim("idle")

func get_front_plant() -> Node2D:
	var level = get_tree().current_scene
	var target_grid: Vector2i = get_front_pos()
	var objects_node = level.get_node_or_null("Objects") if level else null
	if objects_node:
		for child in objects_node.get_children():
			if "coord" in child and child.coord == target_grid:
				return child
	return null

func is_near_sell_point() -> bool:
	if position.distance_to(garage_pos) <= grid_size * 1.5:
		return true
	for node in get_tree().get_nodes_in_group("SellBin"):
		if global_position.distance_to(node.global_position) <= grid_size * 2.0:
			return true
	return false
