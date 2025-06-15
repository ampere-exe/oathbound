extends TextureProgressBar

@export var boss_node_path: NodePath

func _ready():
	if boss_node_path.is_empty():
		print("Error: boss_node_path not set for HealthBar.")
		return

	var boss = get_node_or_null(boss_node_path)
	if boss:
		boss.health_changed.connect(_on_boss_health_changed)
		min_value = 0
		max_value = boss.max_health
		value = boss.health
	else:
		print("Error: Boss node not found at path ", boss_node_path)

func _on_boss_health_changed(current_health: int, max_health: int):
	min_value = 0
	max_value = max_health
	value = current_health
	print("HealthBar updated: ", current_health, "/", max_health)
