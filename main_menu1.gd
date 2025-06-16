extends Button

# Menu scene path
@export var menu_scene_path: String = "res://menu.tscn" 

# Function called when the node enters the scene tree for the first time.
func _ready():
	# Connect the 'pressed' signal of this button to the '_on_pressed' function.
	self.pressed.connect(_on_pressed)

# function called when the button is pressed.
func _on_pressed():
	# Change to the menu scene when the button is pressed.
	get_tree().change_scene_to_file(menu_scene_path)
