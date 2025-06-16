extends Button

@export var instructions_canvas_layer_path: NodePath # Export a NodePath to easily select the CanvasLayer in the editor.

# Called when the node enters the scene tree for the first time.
func _ready():
	# Ensure the NodePath is set in the editor before connecting the signal.
	if instructions_canvas_layer_path.is_empty():
		print("WARNING: 'instructions_canvas_layer_path' not set for 'How_To_Play' Button.")
		return

	# Get the CanvasLayer node using the exported NodePath.
	# We expect it to be a CanvasLayer, so we cast it for type safety.
	var instructions_layer: CanvasLayer = get_node(instructions_canvas_layer_path)
	if instructions_layer == null:
		print("ERROR: Instructions CanvasLayer not found at path: ", instructions_canvas_layer_path)
		return

	# Connect the 'pressed' signal of this button to the '_on_pressed' function.
	# This function will be called whenever the button is clicked or activated.
	self.pressed.connect(_on_pressed)

# This function is called when the button is pressed.
func _on_pressed():
	# Get the CanvasLayer node.
	var instructions_layer: CanvasLayer = get_node(instructions_canvas_layer_path)

	# Check if the CanvasLayer exists before trying to access its properties.
	if instructions_layer != null:
		# Toggle the 'visible' property of the CanvasLayer.
		# If it's visible, make it invisible. If it's invisible, make it visible.
		instructions_layer.visible = not instructions_layer.visible
	else:
		print("ERROR: Could not toggle Instructions CanvasLayer visibility. Node not found.")
