extends CharacterBody2D

# Health Management
@export var max_health := 100 # Maximum health for the player
var health := max_health      # Current health for the player

# Signal emitted when health changes.
# Other nodes can connect to this to update their display (e.g., health bar).
signal health_changed(current_health: int, max_health: int)

@export var speed := 200
@export var jump_force := -400
@export var gravity := 900
@export var max_fall_speed := 700

var is_attacking := false
var is_blocking := false

@onready var sprite := $AnimatedSprite2D
@onready var sword_hitbox := $Area2D/Sword_Hitbox

# Store the original position to flip later
var sword_hitbox_offset := Vector2.ZERO

func _ready():
	sprite.connect("animation_finished", Callable(self, "_on_animation_finished"))
	sprite.connect("frame_changed", Callable(self, "_on_frame_changed"))
	sword_hitbox_offset = sword_hitbox.position
	
	# Emit the initial health state when the player is ready
	# This ensures the health bar is correctly set up from the start
	emit_signal("health_changed", health, max_health)

func _unhandled_input(event):
	if Input.is_action_just_pressed("attack"):
		is_attacking = true
		is_blocking = false
		sprite.play("attack_1", true)
		# For demonstration: Player takes damage on attack (you can remove this)
		# You'd typically call take_damage from an enemy or hazard script
		take_damage(10) 

	elif Input.is_action_just_pressed("block"):
		is_blocking = true
		is_attacking = false
		sprite.play("block", true)  # true forces restart even if already playing

func _physics_process(delta):
	if not is_attacking and not is_blocking:
		handle_input()
	else:
		velocity.x = 0  # stop movement during attack or block

	apply_gravity(delta)
	move_character(delta)
	update_animation()

func handle_input():
	velocity.x = 0
	if Input.is_action_pressed("move_right"):
		velocity.x += 1
	if Input.is_action_pressed("move_left"):
		velocity.x -= 1
	velocity.x *= speed

	if is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity.y = jump_force

func apply_gravity(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
		velocity.y = min(velocity.y, max_fall_speed)
	elif velocity.y > 0:
		velocity.y = 0

func move_character(delta):
	move_and_slide()

func update_animation():
	if is_attacking or is_blocking:
		return  # Don't override active attack or block animation

	if not is_on_floor():
		if velocity.y < 0:
			sprite.play("jump")
		else:
			sprite.play("fall")
	elif velocity.x != 0:
		sprite.flip_h = velocity.x < 0
		update_sword_hitbox_flip()
		sprite.play("run")
	else:
		sprite.play("idle")

func update_sword_hitbox_flip():
	if sprite.flip_h:
		sword_hitbox.position.x = -abs(sword_hitbox_offset.x)
	else:
		sword_hitbox.position.x = abs(sword_hitbox_offset.x)

func _on_animation_finished():
	if sprite.animation == "attack_1":
		is_attacking = false
		sword_hitbox.disabled = true
	elif sprite.animation == "block":
		is_blocking = false

func _on_frame_changed():
	if sprite.animation == "attack_1":
		var frame = sprite.frame
		if frame >= 2 and frame <= 3:
			sword_hitbox.disabled = false
		else:
			sword_hitbox.disabled = true
	else:
		sword_hitbox.disabled = true

# Function to handle taking damage
func take_damage(amount: int):
	health = max(0, health - amount) # Ensure health doesn't go below 0
	print("Player took ", amount, " damage. Current health: ", health)
	emit_signal("health_changed", health, max_health)
	
	if health <= 0:
		print("Player has been defeated!")
		# queue_free() # remove player on death
		# get_tree().reload_current_scene() # restart scene on death
