class_name RobotWaterer
extends RobotUmum

func water() -> void:
	play_anim("interact")
	pakai_alat_ke_level(Enum.Tool.WATER)
	await get_tree().create_timer(0.5).timeout
	play_anim("idle")
