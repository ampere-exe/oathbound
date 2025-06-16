extends Button

@export var instructions_canvas_layer_path: NodePath # Export a NodePath to easily select the CanvasLayer in the editor.

# Call when the node enters the scene tree for the first time.
func _ready():
	# Make sure that the NodePath is set in the editor before connecting signal.
	if instructions_canvas_layer_path.is_empty():
		print("WARNING: 'instructions_canvas_layer_path' not set for 'How_To_Play' Button.")
		return

	# Get the CanvasLayer node using the exported NodePath.
	var instructions_layer: CanvasLayer = get_node(instructions_canvas_layer_path)
	if instructions_layer == null:
		print("ERROR: Instructions CanvasLayer not found at path: ", instructions_canvas_layer_path)
		return

	# Connect the 'pressed' signal of this button to the '_on_pressed' function.
	self.pressed.connect(_on_pressed)

# Function called when the button is pressed.
func _on_pressed():
	# Get the CanvasLayer node again (temporary bug fix).
	var instructions_layer: CanvasLayer = get_node(instructions_canvas_layer_path)

	# Check if the CanvasLayer exists before trying to access its properties.
	if instructions_layer != null:
		# Set the 'visible' property of the CanvasLayer to true, making it appear.
		instructions_layer.visible = true
	else:
		print("ERROR: Could not make Instructions CanvasLayer visible")
