extends CanvasLayer

@onready var progressbar = $ProgressBar

# Initialize the max health
func set_max_health(max_health):
	progressbar.max_value = max_health

#  Update any health changes to the healthbar
func update_health(current_health):
	progressbar.value = current_health
