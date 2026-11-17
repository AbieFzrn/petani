@tool
extends EditorScript

# Sesuaikan path PNG kamu (kalau Waterer & Harvester belum ada, kasih tanda # di depannya dulu)
const ROBOTS = {
	"res://graphics/characters/tractor/planter_anim.tres": "res://graphics/characters/tractor/Planter • Animation Sheet • 64px • Idle4 Move4 Plant6 • Elevated Top-Down-64px.png",
	"res://graphics/characters/tractor/harvester_anim.tres": "res://graphics/characters/tractor/Harvester • Animation Sheet • 64px • Idle4 Move4 Harvest6 • Elevated Top-Down-64px.png",
	"res://graphics/characters/tractor/waterer_anim.tres": "res://graphics/characters/tractor/Waterer • Animation Sheet • 64px • Idle4 Move4 Water6 • Elevated Top-Down-64px.png",
}

const COLS = 14
const ROWS = 4
const DIRECTIONS = ["down", "right", "left", "up"]

func _run() -> void:
	for output_path in ROBOTS:
		var png_path: String = ROBOTS[output_path]
		var tex: Texture2D = load(png_path)
		if not tex:
			printerr("File PNG tidak ketemu di: ", png_path)
			continue

		var sf := SpriteFrames.new()
		sf.remove_animation("default")

		var frame_w := tex.get_width() / COLS
		var frame_h := tex.get_height() / ROWS

		for row in range(ROWS):
			var dir: String = DIRECTIONS[row]
			var base_idx := row * COLS

			# 4 frame idle, 4 frame walk, 6 frame interact
			_tambah_anim(sf, tex, frame_w, frame_h, "idle_" + dir, base_idx, 4, true, 8.0)
			_tambah_anim(sf, tex, frame_w, frame_h, "walk_" + dir, base_idx + 4, 4, true, 8.0)
			_tambah_anim(sf, tex, frame_w, frame_h, "interact_" + dir, base_idx + 8, 6, false, 10.0)

		ResourceSaver.save(sf, output_path)
		print("Sukses! Tersimpan di: ", output_path)

func _tambah_anim(sf: SpriteFrames, tex: Texture2D, fw: int, fh: int, anim_name: String, start_idx: int, count: int, is_loop: bool, fps: float) -> void:
	sf.add_animation(anim_name)
	sf.set_animation_loop(anim_name, is_loop)
	sf.set_animation_speed(anim_name, fps)

	for i in range(count):
		var idx := start_idx + i
		var col := idx % COLS
		var row := idx / COLS

		var atlas := AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(col * fw, row * fh, fw, fh)
		sf.add_frame(anim_name, atlas)
