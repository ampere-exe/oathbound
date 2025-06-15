extends CanvasLayer

@onready var progressbar = $ProgressBar

# Call this to initialize the max health
func set_max_health(max_health):
	progressbar.max_value = max_health

# Call this whenever the health changes
func update_health(current_health):
	progressbar.value = current_health
