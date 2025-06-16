extends OptionButton

func _ready():
	self.item_selected.connect(_on_item_selected)

	if get_item_count() == 0:
		add_item("Select Level", -1)
		add_item("Level 1", 0)
		add_item("Level 2", 1)

	select(-1)

func _on_item_selected(index: int) -> void:
	match index:
		# Visual index 1 corresponds to "Level 1"
		1:
			get_tree().change_scene_to_file("res://level_1.tscn")
		# Visual index 2 corresponds to "Level 2"
		2:
			get_tree().change_scene_to_file("res://level_2.tscn")
		_:
			pass
