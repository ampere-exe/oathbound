extends Button

@export var menu_scene_path: String = "res://menu.tscn" # Export a string for the menu scene path, with a default.

# Called when the node enters the scene tree for the first time.
func _ready():
	# Connect the 'pressed' signal of this button to the '_on_pressed' function.
	# This function will be called whenever the button is clicked or activated.
	self.pressed.connect(_on_pressed)

# This function is called when the button is pressed.
func _on_pressed():
	# Change to the menu scene when the button is pressed.
	get_tree().change_scene_to_file(menu_scene_path)
