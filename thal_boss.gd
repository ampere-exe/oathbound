extends CharacterBody2D

@export var speed := 100
@export var attack_range := 50
@export var detection_range := 300

# Health management
@export var max_health := 150
var health := max_health
var is_dead := false

# Signal for health changes
signal health_changed(current_health: int, max_health: int)

var player: Node2D = null
var is_attacking := false

var attack_timer := 0.0
var attacks_left := 0  # How many attacks left in this burst

var roll_timer := 0.0
var roll_duration := 0.7
var roll_chance := 0.05

var is_rolling := false

@onready var sprite := $AnimatedSprite2D
@onready var area := $Thal_Hurtbox
@onready var attack1_hitbox := $Attack1_Hitbox/CollisionShape2D
@onready var attack2_hitbox := $Attack2_Hitbox/CollisionShape2D
@onready var attack3_hitbox := $Attack3_Hitbox/CollisionShape2D
@onready var hurtbox := $Thal_Hurtbox/CollisionShape2D
@onready var win_screen := $Winscreen

func _ready():
	player = get_tree().get_first_node_in_group("player")
	randomize()
	sprite.connect("animation_finished", Callable(self, "_on_AnimatedSprite2D_animation_finished"))
	sprite.connect("frame_changed", Callable(self, "_on_frame_changed"))
	attack1_hitbox.connect("area_entered", Callable(self, "_on_attack1_hitbox_area_entered"))
	attack2_hitbox.connect("area_entered", Callable(self, "_on_attack2_hitbox_area_entered"))
	attack3_hitbox.connect("area_entered", Callable(self, "_on_attack3_hitbox_area_entered"))

	reset_attack_burst()
	
	# Emit initial health state for healthbar setup
	emit_signal("health_changed", health, max_health)

func _physics_process(delta):
	if is_dead or player == null:
		return

	var facing_left = global_position.x > player.global_position.x
	sprite.flip_h = facing_left
	area.scale.x = -1 if facing_left else 1
	$Attack1_Hitbox.scale.x = -1 if facing_left else 1
	$Attack2_Hitbox.scale.x = -1 if facing_left else 1
	$Attack3_Hitbox.scale.x = -1 if facing_left else 1
	
	var distance = global_position.distance_to(player.global_position)

	if attack_timer > 0:
		attack_timer = max(attack_timer - delta, 0)
	if roll_timer > 0:
		roll_timer = max(roll_timer - delta, 0)
		if roll_timer == 0:
			is_rolling = false

	if is_attacking:
		velocity = Vector2.ZERO
	elif is_rolling:
		var away_dir = (global_position - player.global_position).normalized()
		velocity.x = away_dir.x * speed * 2
		sprite.play("roll")
	elif distance <= attack_range:
		if attack_timer == 0 and attacks_left > 0:
			start_attack()
		else:
			velocity = Vector2.ZERO
			sprite.play("idle")
			if roll_timer == 0 and randf() < roll_chance:
				start_roll()
	elif distance <= detection_range:
		var direction = (player.global_position - global_position).normalized()
		velocity.x = direction.x * speed
		sprite.play("run")
	else:
		velocity = Vector2.ZERO
		sprite.play("idle")

	move_and_slide()

func start_attack():
	is_attacking = true
	attacks_left -= 1
	sprite.play("attack_%d" % (randi() % 3 + 1))

func start_roll():
	is_rolling = true
	roll_timer = roll_duration
	sprite.play("roll")
	hurtbox.disabled = true

func _on_AnimatedSprite2D_animation_finished():
	if is_attacking and sprite.animation.begins_with("attack"):
		is_attacking = false
		if attacks_left == 0:
			attack_timer = randf_range(1.0, 2.0)
			reset_attack_burst()
	elif is_rolling and sprite.animation == "roll":
		is_rolling = false
		roll_timer = 0
		hurtbox.disabled = false

func reset_attack_burst():
	attacks_left = randi() % 3 + 1

func _on_frame_changed():
	var anim = sprite.animation
	var frame = sprite.frame
	var total = sprite.sprite_frames.get_frame_count(anim)

	attack1_hitbox.disabled = true
	attack2_hitbox.disabled = true
	attack3_hitbox.disabled = true

	if anim == "attack_1" and frame == total - 2:
		$Slash.play()
		attack1_hitbox.disabled = false
	elif anim == "attack_2" and frame == total - 2:
		$Slash.play()
		attack2_hitbox.disabled = false
	elif anim == "attack_3" and frame == total - 2:
		$Slash.play()
		attack3_hitbox.disabled = false

func _on_attack1_hitbox_area_entered(area: Area2D) -> void:
	if area.name == "Player_Hurtbox":
		var p = area.get_parent()
		if p.has_method("take_damage"):
			p.take_damage(34)
			print("Dealt 32 damage to player")

func _on_attack2_hitbox_area_entered(area: Area2D) -> void:
	if area.name == "Player_Hurtbox":
		var p = area.get_parent()
		if p.has_method("take_damage"):
			p.take_damage(21)
			print("Dealt 21 damage to player")

func _on_attack3_hitbox_area_entered(area: Area2D) -> void:
	if area.name == "Player_Hurtbox":
		var p = area.get_parent()
		if p.has_method("take_damage"):
			p.take_damage(27)
			print("Dealt 27 damage to player")
			
# Health management
func take_damage(amount: int):
	if is_dead:
		return

	health = max(0, health - amount)
	$Flesh.play()
	print("Boss took ", amount, " damage. Current health: ", health)
	emit_signal("health_changed", health, max_health)

	if health <= 0:
		is_dead = true
		print("Boss defeated!")
		sprite.play("death", true)
		await show_win_screen()  # await to ensure sequential execution

func show_win_screen() -> void:
	if win_screen:
		win_screen.visible = true
	await get_tree().create_timer(5).timeout
	get_tree().reload_current_scene()



func _on_attack_1_hitbox_area_entered(area: Area2D) -> void:
	if area.name == "Player_Hurtbox":
		var p = area.get_parent()
		if p.has_method("take_damage"):
			p.take_damage(34)
			print("Attack 1 hit! Dealt 32 damage to player.")


func _on_attack_2_hitbox_area_entered(area: Area2D) -> void:
	if area.name == "Player_Hurtbox":
		var p = area.get_parent()
		if p.has_method("take_damage"):
			p.take_damage(21)
			print("Attack 2 hit! Dealt 21 damage to player.")


func _on_attack_3_hitbox_area_entered(area: Area2D) -> void:
	if area.name == "Player_Hurtbox":
		var p = area.get_parent()
		if p.has_method("take_damage"):
			p.take_damage(25)
			print("Attack 3 hit! Dealt 27 damage to player.")
