extends CharacterBody2D

# Attack and physics var exports
@export var speed := 150
@export var jump_force := -300
@export var gravity := 900
@export var attack_range := 50
@export var detection_range := 300
@export var jump_chance := 0.05
@export var jump_cooldown_time := 2.0

# Health management variables
@export var max_health := 200
var health := max_health
var is_dead := false
signal health_changed(current_health: int, max_health: int)

# Local physics and attack vars
var player: Node2D = null
var is_attacking := false
var is_jumping_away := false

var attack_timer := 0.0
var attacks_left := 0
var jump_cooldown := 0.0

# Sprite and collision variables
@onready var sprite := $AnimatedSprite2D
@onready var area := $Vhaldir_Hurtbox
@onready var attack1_area := $Attack1_Hitbox
@onready var attack2_area := $Attack2_Hitbox
@onready var attack3_area := $Attack3_Hitbox
@onready var attack1_shape := $Attack1_Hitbox/CollisionShape2D
@onready var attack2_shape := $Attack2_Hitbox/CollisionShape2D
@onready var attack3_shape := $Attack3_Hitbox/CollisionShape2D
@onready var hurtbox := $Vhaldir_Hurtbox/CollisionShape2D
@onready var win_screen := $Winscreen

# Initialization and connections
func _ready():
	player = get_tree().get_first_node_in_group("player")
	randomize()
	sprite.connect("animation_finished", Callable(self, "_on_animation_finished"))
	sprite.connect("frame_changed", Callable(self, "_on_frame_changed"))
	
	# Connect Area2D signals for detecting hits
	attack1_area.connect("area_entered", Callable(self, "_on_attack1_hitbox_area_entered"))
	attack2_area.connect("area_entered", Callable(self, "_on_attack2_hitbox_area_entered"))
	attack3_area.connect("area_entered", Callable(self, "_on_attack3_hitbox_area_entered"))
	
	reset_attack_burst()
	emit_signal("health_changed", health, max_health)

# Handle boss physics
func _physics_process(delta):
	if is_dead or player == null:
		return

	# Face player and flip sprite + hitboxes
	var facing_left = global_position.x > player.global_position.x
	sprite.flip_h = facing_left
	hurtbox.scale.x = -1 if facing_left else 1
	attack1_shape.scale.x = -1 if facing_left else 1
	attack2_shape.scale.x = -1 if facing_left else 1
	attack3_shape.scale.x = -1 if facing_left else 1
	
	attack1_shape.position.x = abs(attack1_shape.position.x) * (-1 if facing_left else 1)
	attack2_shape.position.x = abs(attack2_shape.position.x) * (-1 if facing_left else 1)
	attack3_shape.position.x = abs(attack3_shape.position.x) * (-1 if facing_left else 1)

	var distance = global_position.distance_to(player.global_position)

	# Cooldowns
	attack_timer = max(attack_timer - delta, 0)
	jump_cooldown = max(jump_cooldown - delta, 0)

	# Apply gravity always when not on floor
	if not is_on_floor():
		velocity.y += gravity * delta
		velocity.y = min(velocity.y, 1000)  # clamp fall speed to avoid excessive speed

	if is_attacking:
		velocity.x = 0
	elif is_jumping_away:
		# If landed, stop jumping away
		if is_on_floor():
			is_jumping_away = false
			velocity.x = 0
			sprite.play("idle")
		else:
			# Keep velocity set during jump away
			if velocity.y < 0:
				sprite.play("jump")
			else:
				sprite.play("fall")
	elif distance <= attack_range:
		if attack_timer == 0 and attacks_left > 0:
			start_attack()
		else:
			velocity.x = sign(player.global_position.x - global_position.x) * 0  # Stop horizontal when close
			sprite.play("idle")
			try_jump_away()
	elif distance <= detection_range:
		var direction = (player.global_position - global_position).normalized()
		velocity.x = direction.x * speed
		sprite.play("run")
	else:
		velocity.x = 0
		sprite.play("idle")

	move_and_slide()

func start_attack():
	is_attacking = true
	attacks_left -= 1
	sprite.play("attack_%d" % (randi() % 3 + 1))

func _on_animation_finished():
	if is_attacking and sprite.animation.begins_with("attack"):
		is_attacking = false
		if attacks_left == 0:
			attack_timer = randf_range(1.0, 2.0)
			reset_attack_burst()

func reset_attack_burst():
	attacks_left = randi() % 3 + 1

func try_jump_away():
	if jump_cooldown <= 0 and is_on_floor() and randf() < jump_chance:
		var away_dir = (global_position - player.global_position).normalized()
		var jump_dir_x = sign(away_dir.x)
		if jump_dir_x == 0:
			jump_dir_x = -1
		velocity.x = jump_dir_x * speed * 1.5
		velocity.y = jump_force
		jump_cooldown = jump_cooldown_time
		is_jumping_away = true
		sprite.play("jump")

func _on_frame_changed():
	var anim = sprite.animation
	var frame = sprite.frame
	var total = sprite.sprite_frames.get_frame_count(anim)

	# Disable all attack hitboxes by default
	attack1_shape.disabled = true
	attack2_shape.disabled = true
	attack3_shape.disabled = true

	# Enable appropriate hitbox on correct attack animation frame
	if anim == "attack_1" and frame == total - 3:
		attack1_shape.disabled = false
		$Slash.play()
	elif anim == "attack_2" and frame == total - 5:
		attack2_shape.disabled = false
		$Slash.play()
	elif anim == "attack_3" and frame == total - 4:
		attack3_shape.disabled = false
		$Slash.play()

# Give player damage
func _on_attack1_hitbox_area_entered(area: Area2D) -> void:
	if area.name == "Player_Hurtbox":
		var p = area.get_parent()
		if p.has_method("take_damage"):
			p.take_damage(25)
			print("Boss dealt 24 damage with Attack 1")

func _on_attack2_hitbox_area_entered(area: Area2D) -> void:
	if area.name == "Player_Hurtbox":
		var p = area.get_parent()
		if p.has_method("take_damage"):
			p.take_damage(21)
			print("Boss dealt 21 damage with Attack 2")

func _on_attack3_hitbox_area_entered(area: Area2D) -> void:
	if area.name == "Player_Hurtbox":
		var p = area.get_parent()
		if p.has_method("take_damage"):
			p.take_damage(36)
			print("Boss dealt 36 damage with Attack 3")

# Handle taking damage from player
func take_damage(amount: int):
	if is_dead:
		return
	health = max(0, health - amount)
	$Flesh.play()
	print("Boss took ", amount, " damage. Current health: ", health)
	emit_signal("health_changed", health, max_health)
	if health <= 0:
		is_dead = true
		sprite.play("death")
		show_win_screen()

# Show win screen upon death to player
func show_win_screen() -> void:
	if win_screen:
		win_screen.visible = true
