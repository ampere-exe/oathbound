extends Button

# Initialization and connections
func _ready():
	# Connect the 'pressed' signal
	self.pressed.connect(_on_pressed)

# Function called when the button is pressed.
func _on_pressed():
	# Reload the current scene when the button is pressed.
	get_tree().reload_current_scene()
