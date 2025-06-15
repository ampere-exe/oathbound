extends CharacterBody2D

@export var speed := 100
@export var attack_range := 50
@export var detection_range := 300

# Health management
@export var max_health := 200
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
@onready var area := $Area2D
@onready var attack1_hitbox := $Area2D/Attack1_Hitbox
@onready var attack2_hitbox := $Area2D/Attack2_Hitbox
@onready var attack3_hitbox := $Area2D/Attack3_Hitbox
@onready var hurtbox := $Area2D/Hurtbox

func _ready():
	player = get_tree().get_first_node_in_group("player")
	randomize()
	sprite.connect("animation_finished", Callable(self, "_on_AnimatedSprite2D_animation_finished"))
	sprite.connect("frame_changed", Callable(self, "_on_frame_changed"))
	reset_attack_burst()
	
	# Emit initial health state for healthbar setup
	emit_signal("health_changed", health, max_health)

func _physics_process(delta):
	if is_dead or player == null:
		return

	var facing_left = global_position.x > player.global_position.x
	sprite.flip_h = facing_left
	area.scale.x = -1 if facing_left else 1

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
	elif sprite.animation == "death":
		# Disable boss or trigger cleanup after death animation
		queue_free()  # Optional: remove boss from scene

func reset_attack_burst():
	attacks_left = randi() % 3 + 1

func _on_frame_changed():
	var anim = sprite.animation
	var frame = sprite.frame
	var total = sprite.sprite_frames.get_frame_count(anim)

	attack1_hitbox.disabled = true
	attack2_hitbox.disabled = true
	attack3_hitbox.disabled = true

	if anim == "attack_1" and frame >= total - 2:
		attack1_hitbox.disabled = false
		take_damage(10)  # Boss takes 10 damage while swinging attack 1
	elif anim == "attack_2" and frame >= total - 2:
		attack2_hitbox.disabled = false
	elif anim == "attack_3" and frame >= total - 2:
		attack3_hitbox.disabled = false

# Health management
func take_damage(amount: int):
	if is_dead:
		return
	
	health = max(0, health - amount)
	print("Boss took ", amount, " damage. Current health: ", health)
	emit_signal("health_changed", health, max_health)
	
	if health <= 0:
		is_dead = true
		print("Boss defeated!")
		sprite.play("death", true)
