extends CharacterBody2D

# Health Management
@export var max_health := 100 # Maximum health for the player
var health := max_health      # Current health for the player

# Signal emitted when health changes.
signal health_changed(current_health: int, max_health: int)

@export var speed := 200
@export var jump_force := -400
@export var gravity := 900
@export var max_fall_speed := 700

var is_attacking := false
var is_blocking := false
var is_dead := false   # New flag to track if player is dead

@onready var sprite := $AnimatedSprite2D
@onready var sword_hitbox := $Area2D/Sword_Hitbox

var sword_hitbox_offset := Vector2.ZERO

func _ready():
	sprite.connect("animation_finished", Callable(self, "_on_animation_finished"))
	sprite.connect("frame_changed", Callable(self, "_on_frame_changed"))
	sword_hitbox_offset = sword_hitbox.position
	
	emit_signal("health_changed", health, max_health)

func _unhandled_input(event):
	if is_dead:
		return  # Ignore input if dead

	if Input.is_action_just_pressed("attack"):
		is_attacking = true
		is_blocking = false
		sprite.play("attack_1", true)
		take_damage(10)  # demo damage on attack

	elif Input.is_action_just_pressed("block"):
		is_blocking = true
		is_attacking = false
		sprite.play("block", true)

func _physics_process(delta):
	if is_dead:
		velocity.x = 0  # stop movement if dead
		apply_gravity(delta)
		move_character(delta)
		# Don't update animations after death animation is playing
		return

	if not is_attacking and not is_blocking:
		handle_input()
	else:
		velocity.x = 0

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
	if is_attacking or is_blocking or is_dead:
		return  # Don't override active animations or death animation

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
	elif sprite.animation == "death":
		# You could do something here when death animation finishes (e.g., disable player)
		pass

func _on_frame_changed():
	if sprite.animation == "attack_1":
		var frame = sprite.frame
		if frame >= 2 and frame <= 3:
			sword_hitbox.disabled = false
		else:
			sword_hitbox.disabled = true
	else:
		sword_hitbox.disabled = true

func take_damage(amount: int):
	if is_dead:
		return  # No effect if already dead

	health = max(0, health - amount)
	print("Player took ", amount, " damage. Current health: ", health)
	emit_signal("health_changed", health, max_health)
	
	if health <= 0:
		is_dead = true
		print("Player has been defeated!")
		sprite.play("death", true)
