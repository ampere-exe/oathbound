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
var can_block_damage := false
var is_staggered := false

@onready var sprite := $AnimatedSprite2D
@onready var sword_hitbox := $Sword_Hitbox
@onready var sword_collision_shape := $Sword_Hitbox/CollisionShape2D
@onready var spark := $SparkEffect
@onready var hurtbox := $Player_Hurtbox/CollisionShape2D   # Adjust this path to your hurtbox node
@onready var death_screen := $Deathscreen

var sword_collision_shape_offset := Vector2.ZERO

func _ready():
	sprite.connect("animation_finished", Callable(self, "_on_animation_finished"))
	sprite.connect("frame_changed", Callable(self, "_on_frame_changed"))
	spark.connect("animation_finished", Callable(self, "_on_spark_animation_finished"))
	sword_collision_shape_offset = sword_collision_shape.position
	emit_signal("health_changed", health, max_health)
	
	# Start disabled so it doesn't hit outside attack frames
	sword_collision_shape.disabled = true

func _on_sword_hitbox_area_entered(area: Area2D) -> void:
	if area.name == "Thal_Hurtbox" or area.name == "Vhaldir_Hurtbox":
		var boss = area.get_parent()
		if boss.has_method("take_damage"):
			boss.take_damage(6)
			print("Hit ", area.name, "- dealt 6 damage")

func _on_spark_animation_finished():
	spark.visible = false
	
func _unhandled_input(event):
	if is_dead:
		return  # Ignore input if dead

	if Input.is_action_just_pressed("attack"):
		is_attacking = true
		is_blocking = false
		sprite.play("attack_1", true)

	elif Input.is_action_just_pressed("block"):
		is_blocking = true
		is_attacking = false
		sprite.play("block", true)

func _physics_process(delta):
	if is_dead:
		velocity.x = 0
		apply_gravity(delta)
		move_character(delta)
		update_animation()
		return
	
	if is_staggered:
		velocity.x = 0
		apply_gravity(delta)
		move_character(delta)
		update_animation()
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
	if is_dead:
		if sprite.animation != "death":
			sprite.play("death")
		return
	
	if is_staggered:
		if sprite.animation != "stagger":
			sprite.play("stagger")
		return
	
	if is_attacking:
		if sprite.animation != "attack_1":
			sprite.play("attack_1")
		return
	
	if is_blocking:
		if sprite.animation != "block":
			sprite.play("block")
		return
	
	# If none of the above states, do normal movement animations
	if not is_on_floor():
		if velocity.y < 0:
			if sprite.animation != "jump":
				sprite.play("jump")
		else:
			if sprite.animation != "fall":
				sprite.play("fall")
	elif velocity.x != 0:
		sprite.flip_h = velocity.x < 0
		update_sword_hitbox_flip()
		if sprite.animation != "run":
			sprite.play("run")
	else:
		if sprite.animation != "idle":
			sprite.play("idle")

func update_sword_hitbox_flip():
	if sprite.flip_h:
		sword_collision_shape.position.x = -abs(sword_collision_shape_offset.x)
	else:
		sword_collision_shape.position.x = abs(sword_collision_shape_offset.x)

func _on_animation_finished():
	if sprite.animation == "attack_1":
		is_attacking = false
		sword_collision_shape.disabled = true
	elif sprite.animation == "block":
		is_blocking = false
	elif sprite.animation == "stagger":
		is_staggered = false
	elif sprite.animation == "death":
		# handle death animation finished
		pass

func _on_frame_changed():
	var frame = sprite.frame

	if sprite.animation == "attack_1":
		if frame >= 2 and frame <= 3:
			sword_collision_shape.disabled = false
		else:
			sword_collision_shape.disabled = true
		if frame == 2:
			$Slash.play()
	else:
		sword_collision_shape.disabled = true

	# Block damage only in the last 2 frames of block animation
	if sprite.animation == "block":
		var total_frames = sprite.sprite_frames.get_frame_count("block")
		can_block_damage = frame >= total_frames - 3
	else:
		can_block_damage = false

func play_spark():
	spark.visible = true
	spark.frame = 0
	spark.play("spark")  

func take_damage(amount: int):
	if can_block_damage:
		print("Blocked damage!")
		play_spark()
		var choice = randi() % 2  # 0 or 1 randomly
		if choice == 0:
			$Deflect1.play()
		else:
			$Deflect2.play()
		return  # No damage if blocking in the last 2 frames

	health = max(0, health - amount)
	print("Player took ", amount, " damage. Current health: ", health)
	emit_signal("health_changed", health, max_health)

	if health <= 0 and not is_dead:
		is_dead = true
		print("Player has been defeated!")
		sprite.play("death", true)
		hurtbox.disabled = true
		$Flesh.play()
		show_death_screen()  
	elif not is_dead:
		is_staggered = true
		$Flesh.play()
		sprite.play("stagger", true)
		
func show_death_screen():
	if death_screen:
		death_screen.visible = true
