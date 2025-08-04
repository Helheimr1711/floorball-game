extends CharacterBody3D

var slapshot_input: float = 0.0
var slapshot_power: float = 0.0
var pass_input: float = 0.0
var pass_power: float = 0.0
var through_pass_input: float = 0.0
var through_pass_power: float = 0.0

var power: float = 0.0
var power_input: float = 0.0

func _process(delta: float) -> void:
	var left_stick_input = snapped(Input.get_vector("left_stick_left", "left_stick_right", "left_stick_up", "left_stick_down"), Vector2(0.01, 0.01))
	var right_stick_input = snapped(Input.get_vector("right_stick_left", "right_stick_right", "right_stick_up", "right_stick_down"), Vector2(0.01, 0.01))
	var sprinting_input = snapped(Input.get_action_strength("sprinting"), 0.01)
	
	slapshot_power = power_release("slapshot", slapshot_input, slapshot_power)
	slapshot_input = power_input_getter("slapshot", slapshot_input)
	
	if Input.is_action_pressed("pass") or Input.is_action_pressed("through_pass") or Input.is_action_pressed("slapshot"):
		power = power_release(Input.)
		power_input = power_input_getter()
	
	print(power_input)
	print(power)



func power_input_getter(InputAction: String, input_variable: float) -> float:
	if Input.is_action_pressed(InputAction) and input_variable < 1.0:
		return input_variable + 0.01
	elif Input.is_action_pressed(InputAction) and input_variable >= 1.0: return 1.0
	else: return 0.0

func power_release(InputAction: String, input_variable: float, power_variable: float) -> float:
	if Input.is_action_just_released(InputAction): return input_variable
	else: return power_variable
