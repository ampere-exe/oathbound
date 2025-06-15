extends TextureProgressBar

# Export a NodePath to allow you to easily select the player node
# in the Godot editor. Drag your Player node from the scene tree
# into this property in the Inspector.
@export var player_node_path: NodePath 

func _ready():
	# Check if a player node path has been set in the editor
	if player_node_path.is_empty():
		print("Error: player_node_path not set for HealthBar.")
		return

	# Get a reference to the player node using the provided path
	var player = get_node_or_null(player_node_path)
	
	if player:
		# Connect the player's 'health_changed' signal to a function in this script
		# This means whenever the player's health changes, our _on_player_health_changed
		# function will be called.
		player.health_changed.connect(_on_player_health_changed)
		
		# Initialize the health bar with the player's current health and max health
		min_value = 0
		max_value = player.max_health
		value = player.health
		
		print("HealthBar connected to player: ", player.name)
	else:
		print("Error: Player node not found at path ", player_node_path)

# This function is called whenever the player's health_changed signal is emitted
func _on_player_health_changed(current_health: int, max_health: int):
	# Update the ProgressBar's values to reflect the player's health
	min_value = 0 # ProgressBar's minimum value is always 0 for health
	max_value = max_health
	value = current_health
	print("HealthBar updated: ", current_health, "/", max_health)
