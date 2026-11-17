class_name RobotPlanter
extends RobotUmum

func till() -> void:
	play_anim("interact")
	pakai_alat_ke_level(Enum.Tool.HOE)
	await get_tree().create_timer(0.5).timeout
	play_anim("idle")

func plant() -> void:
	play_anim("interact")
	var level = get_tree().current_scene
	if level and level.has_node("%Player"):
		var seed_type = level.get_node("%Player").current_seed
		Data.ITEMS_AMOUNT[Data.SEED_TO_ITEM[seed_type]] = 99
		
	pakai_alat_ke_level(Enum.Tool.SEED)
	await get_tree().create_timer(0.5).timeout
	play_anim("idle")
