class_name RobotHarvester
extends RobotUmum

func harvest() -> void:
	play_anim("interact")
	var level = get_tree().current_scene
	if level and level.has_method("get_target_grid"):
		var target_grid: Vector2i = level.get_target_grid(global_position, facing_dir)
		var objects_node = level.get_node_or_null("Objects")
		if objects_node:
			for child in objects_node.get_children():
				if "coord" in child and child.coord == target_grid:
					if child.has_method("_on_collision_area_body_entered"):
						child._on_collision_area_body_entered(self)
						break
	await get_tree().create_timer(0.5).timeout
	play_anim("idle")
