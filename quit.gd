extends Button

# Initialization and connections
func _ready():
	# Connect the 'pressed' signal of this button to the '_on_pressed' function.
	self.pressed.connect(_on_pressed)

# Dunction called when the button is pressed.
func _on_pressed():
	# Quit the application when the button is pressed.
	get_tree().quit()
