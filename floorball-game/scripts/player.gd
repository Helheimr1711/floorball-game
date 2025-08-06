extends CharacterBody3D

# === Speed settings ===
var WALK_SPEED := 5.0
var RUN_SPEED := 8.0
var SPRINT_SPEED := 13.0

var acceleration := 10.0
var deceleration := 12.0

var target_velocity := Vector3.ZERO
var is_sprinting: bool = false

# === Ball control ===
var is_on_ball: bool = true
var is_ball_on_ground: bool = true

# === Input powers ===
var slapshot_input: float = 0.0
var slapshot_power: float = 0.0
var pass_input: float = 0.0
var pass_power: float = 0.0
var through_pass_input: float = 0.0
var through_pass_power: float = 0.0

# === Right stick positions and skill system ===
enum right_stick_positions {MIDDLE, UP, DOWN, LEFT, RIGHT}
var current_right_stick_position := right_stick_positions.MIDDLE

var right_stick_positions_values: Dictionary = {
	right_stick_positions.MIDDLE: {"Values": {"Min": Vector2(-0.2, -0.2), "Max": Vector2(0.2, 0.2)}},
	right_stick_positions.UP:     {"Values": {"Min": Vector2(-0.5, -1.0), "Max": Vector2(0.5, -0.7)}},
	right_stick_positions.DOWN:   {"Values": {"Min": Vector2(-0.5, 0.7),  "Max": Vector2(0.5, 1.0)}},
	right_stick_positions.LEFT:   {"Values": {"Min": Vector2(-1.0, -0.5), "Max": Vector2(-0.7, 0.5)}},
	right_stick_positions.RIGHT:  {"Values": {"Min": Vector2(0.7, -0.5),  "Max": Vector2(1.0, 0.5)}}
}

var stick_positions = [
	right_stick_positions.MIDDLE,
	right_stick_positions.UP,
	right_stick_positions.DOWN,
	right_stick_positions.LEFT,
	right_stick_positions.RIGHT
]

var stick_sequence: Array = []
var sequence_timer: float = 0.0
var sequence_max_length: int = 10

var skill_tricks: Dictionary = {
	"hockey_dribnling": {
		"sequence": [right_stick_positions.RIGHT, right_stick_positions.MIDDLE, right_stick_positions.LEFT],
		"tolerance": 0.3,
		"action": "perform_hockey_dribbling"
	},
	"spin_move": {
		"sequence": [right_stick_positions.UP, right_stick_positions.RIGHT, right_stick_positions.DOWN, right_stick_positions.LEFT],
		"tolerance": 1.5,
		"action": "perform_spin_move"
	},
	"wrist_shot": {
		"sequence": [right_stick_positions.DOWN, right_stick_positions.RIGHT],
		"tolerance": 0.5,
		"action": "perform_wrist_shot"
	},
	"drag_shot": {
		"sequence": [right_stick_positions.DOWN, right_stick_positions.LEFT],
		"tolerance": 0.8,
		"action": "perform_drag_shot"
	},
	"eight": {
		"sequence": [right_stick_positions.LEFT, right_stick_positions.UP, right_stick_positions.MIDDLE, right_stick_positions.RIGHT, right_stick_positions.DOWN, right_stick_positions.MIDDLE],
		"tolerance": 1.2,
		"action": "perform_eight"
	},
	"floorball_dribbling": {
		"sequence": [right_stick_positions.LEFT, right_stick_positions.UP, right_stick_positions.LEFT],
		"tolerance": 0.5,
		"action": "perform_floorball_dribbling"
	},
	"puller": {
		"sequence": [right_stick_positions.LEFT, right_stick_positions.UP, right_stick_positions.RIGHT, right_stick_positions.UP, right_stick_positions.LEFT],
		"tolerance": 1.0,
		"action": "perform_puller"
	},
	"zorro": {
		"sequence": [right_stick_positions.LEFT, right_stick_positions.UP, right_stick_positions.RIGHT, right_stick_positions.DOWN, right_stick_positions.MIDDLE],
		"tolerance": 1.0,
		"action": "perform_zorro"
	},
	"basic_ball_lift": {
		"sequence": [right_stick_positions.UP, right_stick_positions.MIDDLE, right_stick_positions.DOWN, right_stick_positions.MIDDLE],
		"tolerance": 1.0,
		"action": "perform_basic_ball_lift"
	}
}

# === MAIN PROCESS ===
func _process(delta: float) -> void:
	var left_stick_input = snapped(Input.get_vector("left_stick_left", "left_stick_right", "left_stick_up", "left_stick_down"), Vector2(0.01, 0.01))
	var right_stick_input = snapped(Input.get_vector("right_stick_left", "right_stick_right", "right_stick_up", "right_stick_down"), Vector2(0.01, 0.01))
	var sprinting_input = snapped(Input.get_action_strength("sprinting"), 0.01)

	is_sprinting = sprinting_input > 0.0

	var input_strength = left_stick_input.length()
	var direction = (transform.basis * Vector3(left_stick_input.x, 0.0, left_stick_input.y)).normalized()

	# Výpočet rychlosti podle vstupu
	var speed := 0.0
	if is_sprinting:
		speed = SPRINT_SPEED
	elif input_strength > 0.5:
		speed = RUN_SPEED
	elif input_strength > 0.0:
		speed = WALK_SPEED


	# Výpočet cílové rychlosti
	var target_velocity = direction * speed



	# ✅ Oprava ternárního výrazu:
	var accel: float
	if speed > velocity.length():
		accel = acceleration
	else:
		accel = deceleration

	# Interpolace směrem k cílové rychlosti
	velocity.x = move_toward(velocity.x, target_velocity.x, accel * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, accel * delta)

	move_and_slide()


	# Power input
	slapshot_power = power_release("slapshot", slapshot_input, slapshot_power)
	slapshot_input = power_input_getter("slapshot", slapshot_input)

	pass_power = power_release("pass", pass_input, pass_power)
	pass_input = power_input_getter("pass", pass_input)

	through_pass_power = power_release("through_pass", through_pass_input, through_pass_power)
	through_pass_input = power_input_getter("through_pass", through_pass_input)

	# Right stick detection
	if is_on_ball:
		for position in stick_positions:
			var min = right_stick_positions_values[position]["Values"]["Min"]
			var max = right_stick_positions_values[position]["Values"]["Max"]
			if is_inside_range(right_stick_input, min, max):
				current_right_stick_position = position
				break

	# Sledování změn
	if stick_sequence.size() == 0 or current_right_stick_position != stick_sequence[-1]:
		stick_sequence.append(current_right_stick_position)
		sequence_timer = 0.0

	if stick_sequence.size() > sequence_max_length:
		stick_sequence.pop_front()

	sequence_timer += delta
	if sequence_timer > 2.0:
		stick_sequence.clear()

	# Vyhodnocení triku
	for trick_name in skill_tricks.keys():
		var trick = skill_tricks[trick_name]
		var required_sequence = trick["sequence"]
		var tolerance = trick["tolerance"]
		if stick_sequence.size() >= required_sequence.size():
			var recent = stick_sequence.slice(-required_sequence.size(), stick_sequence.size())
			if recent == required_sequence and sequence_timer <= tolerance:
				call(trick["action"])
				stick_sequence.clear()
				break

# === POWER FUNCTIONS ===
func power_input_getter(InputAction: String, input_variable: float) -> float:
	if Input.is_action_pressed(InputAction) and input_variable < 1.0:
		return input_variable + 0.01
	elif Input.is_action_pressed(InputAction):
		return 1.0
	else:
		return 0.0

func power_release(InputAction: String, input_variable: float, power_variable: float) -> float:
	if Input.is_action_just_released(InputAction):
		return input_variable
	else:
		return power_variable

# === STICK RANGE FUNCTIONS ===
func is_inside_range(value: Vector2, min: Vector2, max: Vector2) -> bool:
	return value.x >= min.x and value.x <= max.x and value.y >= min.y and value.y <= max.y

func get_stick_position_name(position: int) -> String:
	for name in right_stick_positions.keys():
		if right_stick_positions[name] == position:
			return name
	return "UNKNOWN"

# === SKILL ACTIONS ===
func perform_hockey_dribbling(): if is_ball_on_ground: print("Hockey Dribbling!")
func perform_spin_move(): if is_ball_on_ground: print("Spin Move!")
func perform_wrist_shot(): if is_ball_on_ground: print("Wrist Shot!")
func perform_drag_shot(): if is_ball_on_ground: print("Drag Shot!")
func perform_eight(): if is_ball_on_ground: print("Eight!")
func perform_floorball_dribbling(): if is_ball_on_ground: print("Floorball Dribbling!")
func perform_puller(): if is_ball_on_ground: print("Puller!")
func perform_zorro(): if is_ball_on_ground: print("Zorro!")
func perform_basic_ball_lift():
	if is_ball_on_ground:
		is_ball_on_ground = false
		print("Basic Ball Lift!")
