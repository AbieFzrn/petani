extends Node2D

@onready var waterGrassLayer := $Layers/WaterGrassLayer

# Plant
var plant_scene = preload("res://scenes/objects/plant.tscn")
var planted_cells: Array[Vector2i]
var plant_info_scene = preload("res://scenes/ui/plant_info.tscn")

# Day and Weather
@onready var day_transition_material = $Overlay/CanvasLayer/DayTransitionLayer.material
@export var daytimer_color: Gradient
@export var rain_color: Color
@export var volume_curve: Curve
var raining: bool = false:
	set(value):
		raining = value
		$Layers/RainFloorsParticles.emitting = value
		$Overlay/RainParticles2D.emitting = value
		$Sounds/Rain.playing = value

signal update_hint_ui_keys



@export var camera_speed: float = 300.0

func _process(delta):
	# 1. Geser kamera pakai tombol panah (Up, Down, Left, Right)
	var cam_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if cam_dir != Vector2.ZERO:
		$Camera2D.position += cam_dir * camera_speed * delta

	# 2. Siklus Siang-Malam & Cuaca
	var daytime_point = 1 - ($Timers/DayTimer.time_left / $Timers/DayTimer.wait_time)
	var color = daytimer_color.sample(daytime_point)
	var volume = volume_curve.sample(daytime_point)
	$Sounds/BG.volume_db = volume
	
	if raining:
		color = color.lerp(rain_color, 1 - daytime_point)
	$Overlay/CanvasModulate.color = color


# =========================================================
# Day Night Cycle
# =========================================================
func day_restart():
	var tween = create_tween()
	
	tween.tween_property(day_transition_material, "shader_parameter/progress", 1.0, 1.0)
	tween.tween_interval(0.5)
	tween.tween_callback(level_reset)
	tween.tween_property(day_transition_material, "shader_parameter/progress", 0.0, 1.0)


func level_reset():
	for plant: StaticBody2D in get_tree().get_nodes_in_group("Plants"):
		plant.grow(plant.coord in $Layers/WetSoilLayer.get_used_cells())
			
	$Timers/DayTimer.start()
	$Layers/WetSoilLayer.clear()
	
	for object in get_tree().get_nodes_in_group("Objects"):
		if not object.is_in_group("Tree") or [false, true].pick_random():
			continue
		object.create_apple()

	raining = Data.FORECAST_RAIN
	Data.FORECAST_RAIN = [true, false].pick_random()
	print("Tomorrow will rain" if Data.FORECAST_RAIN else "Tomorrow is sunny")
	
	if raining:
		waterSoils()


func waterSoils():
	for cell in $Layers/SoilLayer.get_used_cells():
		$Layers/WetSoilLayer.set_cell(
			cell,
			0,
			Vector2i(randi_range(0, 2), 0)
		)


func _ready() -> void:
	Data.FORECAST_RAIN = [true, false].pick_random()
	if raining:
		waterSoils()
		
	var canvas_modulate = CanvasModulate.new()
	canvas_modulate.color = Color(0.1, 0.1, 0.15)
	add_child(canvas_modulate)
		
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	if Input.get_connected_joypads().size() > 0:
		Data.ControllerConnected = true
		
	tes_robot()


# =========================================================
# VALIDATION (Dipakai Robot buat cek validitas petak)
# =========================================================
func is_tool_valid(tool: Enum.Tool, grid_coord: Vector2i) -> bool:
	var cell = $Layers/WaterGrassLayer.get_cell_tile_data(grid_coord)

	if not cell:
		return false

	var is_water = cell.get_custom_data("water")
	var is_farmable = cell.get_custom_data("farmable")
	var has_soil = $Layers/SoilLayer.get_cell_source_id(grid_coord) != -1

	match tool:
		Enum.Tool.HOE:
			if is_water or not is_farmable:
				return false
			if is_object_near_cell(grid_coord):
				return false
			return true

		Enum.Tool.WATER:
			return has_soil

		Enum.Tool.FISH:
			return is_water
			
		Enum.Tool.SEED:
			return has_soil and grid_coord not in planted_cells
			
		Enum.Tool.AXE, Enum.Tool.SWORD:
			return true

	return false


func is_object_near_cell(grid_coord: Vector2i) -> bool:
	for object in get_tree().get_nodes_in_group("Objects"):
		var object_pos := Vector2i(
			floor(object.position.x / Data.TILE_SIZE),
			floor(object.position.y / Data.TILE_SIZE)
		)
		
		if object.is_in_group("Tree"):
			if grid_coord.x >= object_pos.x - 1 \
			and grid_coord.x <= object_pos.x + 1 \
			and grid_coord.y >= object_pos.y - 2 \
			and grid_coord.y <= object_pos.y:
				return true
		else:
			if grid_coord.x >= object_pos.x \
			and grid_coord.x <= object_pos.x + 1 \
			and grid_coord.y >= object_pos.y \
			and grid_coord.y <= object_pos.y + 1:
				return true
	
	return false


# =========================================================
# Signal Func for Plant Death and Harvest
# =========================================================
func plant_death(coord: Vector2i):
	planted_cells.erase(coord)


func plant_harvest(coord: Vector2i):
	planted_cells.erase(coord)


func open_shop(shop_type: Enum.Shop):
	$Overlay/CanvasLayer/ShopUI.reveal(shop_type)


func close_shop() -> void:
	$Overlay/CanvasLayer/ShopUI.hide()
	$Overlay/CanvasLayer/ShopUI.remove_items()


func _on_joy_connection_changed(device_id: int, connected: bool):
	update_hint_ui_keys.emit()
	Data.ControllerConnected = connected


# --- TES SEMENTARA ROBOT (HAPUS NANTI KALAU UI KODING UDAH JADI) ---
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		tes_robot()


func tes_robot() -> void:
	await get_tree().create_timer(1.0).timeout
	
	tugas_planter()
	tugas_waterer()
	tugas_harvester()


func tugas_planter() -> void:
	var planter = $Objects/Planter
	await planter.till()
	await planter.plant()
	await planter.turn_left()
	await planter.move()
	await planter.till()
	await planter.plant()


func tugas_waterer() -> void:
	var waterer = $Objects/Waterer
	await waterer.water()
	await waterer.turn_left()
	await waterer.move()
	await waterer.water()


func tugas_harvester() -> void:
	var harvester = $Objects/Harvester
	await harvester.move()
	await harvester.turn_right()
	await harvester.harvest()

# =========================================================
# ROBOT API & SENSOR BRIDGE
# =========================================================
func is_night() -> bool:
	var daytime_point = 1.0 - ($Timers/DayTimer.time_left / $Timers/DayTimer.wait_time)
	return daytime_point >= 0.75

func is_cell_walkable(grid_coord: Vector2i) -> bool:
	var cell = $Layers/WaterGrassLayer.get_cell_tile_data(grid_coord)
	if not cell:
		return false
	if cell.get_custom_data("water"):
		return false
	if is_object_near_cell(grid_coord):
		return false
	return true

func is_water_tile(grid_coord: Vector2i) -> bool:
	var cell = $Layers/WaterGrassLayer.get_cell_tile_data(grid_coord)
	return cell != null and cell.get_custom_data("water")

func is_soil_wet(grid_coord: Vector2i) -> bool:
	return $Layers/WetSoilLayer.get_cell_source_id(grid_coord) != -1

func robot_use_tool(tool: Enum.Tool, grid_coord: Vector2i, extra_data = null) -> void:
	if not is_tool_valid(tool, grid_coord):
		return

	match tool:
		Enum.Tool.HOE:
			$Layers/SoilLayer.set_cells_terrain_connect([grid_coord], 0, 1)
			if raining:
				$Layers/WetSoilLayer.set_cell(grid_coord, 0, Vector2i(randi_range(0, 2), 0))

		Enum.Tool.WATER:
			$Layers/WetSoilLayer.set_cell(grid_coord, 0, Vector2i(randi_range(0, 2), 0))

		Enum.Tool.SEED:
			var seed_type: Enum.Seed = extra_data if extra_data != null else Enum.Seed.TOMATO
			if Data.ITEMS_AMOUNT[Data.SEED_TO_ITEM[seed_type]] <= 0:
				return
			Data.ITEMS_AMOUNT[Data.SEED_TO_ITEM[seed_type]] -= 1

			var plant_res = PlantResource.new()
			plant_res.setup(seed_type)
			var plant := plant_scene.instantiate()

			var plant_info = plant_info_scene.instantiate()
			plant_info.setup(plant_res)
			$Overlay/CanvasLayer/PlantInfoControl.add(plant_info)

			plant.setup(grid_coord, $Objects, plant_res, plant_info, plant_death, plant_harvest)
			planted_cells.append(grid_coord)
