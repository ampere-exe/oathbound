extends Button

# @export var instructions_canvas_layer_path: NodePath # This export is not needed for exiting the game.

# Called when the node enters the scene tree for the first time.
func _ready():
	# Connect the 'pressed' signal of this button to the '_on_pressed' function.
	# This function will be called whenever the button is clicked or activated.
	self.pressed.connect(_on_pressed)

# This function is called when the button is pressed.
func _on_pressed():
	# Quit the application when the button is pressed.
	get_tree().quit()
