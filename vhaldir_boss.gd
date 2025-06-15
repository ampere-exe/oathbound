extends CharacterBody2D

@export var speed := 150
@export var jump_force := -300
@export var gravity := 900
@export var attack_range := 50
@export var detection_range := 300
@export var jump_chance := 0.05
@export var jump_cooldown_time := 2.0
@export var max_health := 250
var health := max_health
var is_dead := false
signal health_changed(current_health: int, max_health: int)

var player: Node2D = null
var is_attacking := false
var is_jumping_away := false

var attack_timer := 0.0
var attacks_left := 0
var jump_cooldown := 0.0

@onready var sprite := $AnimatedSprite2D
@onready var attack1_hitbox := $Area2D/Attack1_Hitbox
@onready var attack2_hitbox := $Area2D/Attack2_Hitbox
@onready var attack3_hitbox := $Area2D/Attack3_Hitbox

func _ready():
	emit_signal("health_changed", health, max_health)
	player = get_tree().get_first_node_in_group("player")
	randomize()
	sprite.connect("animation_finished", Callable(self, "_on_animation_finished"))
	sprite.connect("frame_changed", Callable(self, "_on_frame_changed"))
	reset_attack_burst()

func _physics_process(delta):
	if is_dead or player == null:
		return

	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0
		# Only reset jump state after landing
		if is_jumping_away:
			is_jumping_away = false

	# Face the player and flip hitboxes
	var facing_left = global_position.x > player.global_position.x
	sprite.flip_h = facing_left
	var flip_sign = -1 if facing_left else 1

	# Flip hitbox positions
	attack1_hitbox.position.x = abs(attack1_hitbox.position.x) * flip_sign
	attack2_hitbox.position.x = abs(attack2_hitbox.position.x) * flip_sign
	attack3_hitbox.position.x = abs(attack3_hitbox.position.x) * flip_sign

	var distance = global_position.distance_to(player.global_position)

	# Cooldowns
	attack_timer = max(attack_timer - delta, 0)
	jump_cooldown = max(jump_cooldown - delta, 0)

	if is_attacking:
		velocity.x = 0
	elif is_jumping_away:
		# Maintain current velocity and jump/fall animation, skip other logic
		if velocity.y < 0:
			sprite.play("jump")
		else:
			sprite.play("fall")
		move_and_slide()
		return
	elif distance <= attack_range:
		if attack_timer == 0 and attacks_left > 0:
			start_attack()
		else:
			# If can't attack, maybe shuffle around a bit or at least not freeze completely
			velocity.x = sign(player.global_position.x - global_position.x)
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

	if not is_attacking and not is_on_floor():
		if velocity.y < 0:
			sprite.play("jump")
		else:
			sprite.play("fall")

func start_attack():
	is_attacking = true
	attacks_left -= 1
	var attack_index = randi() % 3 + 1
	sprite.play("attack_%d" % attack_index)

func _on_animation_finished():
	if sprite.animation.begins_with("attack") and is_attacking:
		is_attacking = false
		if attacks_left == 0:
			attack_timer = randf_range(1, 2.0)
			reset_attack_burst()
	# Removed jump animation end resetting is_jumping_away here

func reset_attack_burst():
	attacks_left = randi() % 3 + 1

func try_jump_away():
	if jump_cooldown <= 0.0 and is_on_floor() and randf() < jump_chance:
		var away_dir = (global_position - player.global_position).normalized()
		var jump_dir_x = sign(away_dir.x)
		if jump_dir_x == 0:
			jump_dir_x = -1
		velocity.x = jump_dir_x * speed * 1.5
		velocity.y = jump_force
		jump_cooldown = jump_cooldown_time
		is_jumping_away = true
		sprite.play("jump")

func take_damage(amount: int):
	if is_dead:
		return
	health = max(0, health - amount)
	print("Boss took ", amount, " damage. Current health: ", health)
	emit_signal("health_changed", health, max_health)
	if health <= 0:
		is_dead = true
		sprite.play("death")

func _on_frame_changed():
	var anim = sprite.animation
	var frame = sprite.frame

	# Disable all hitboxes by default
	attack1_hitbox.disabled = true
	attack2_hitbox.disabled = true
	attack3_hitbox.disabled = true

	# Enable based on specific frames
	# TEMPORARY DAMAGE DURING ATTACK SWING
	if anim == "attack_1" and frame == 3:
		take_damage(10)
	elif anim == "attack_2" and frame == 2:
		take_damage(12)
	elif anim == "attack_3" and frame == 3:
		take_damage(15)
