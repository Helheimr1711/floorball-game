extends CharacterBody3D

func _process(delta: float) -> void:
	var left_stick_input = snapped(Input.get_vector("left_stick_left", "left_stick_right", "left_stick_up", "left_stick_down"), Vector2(0.01, 0.01))
	var right_stick_input = snapped(Input.get_vector("right_stick_left", "right_stick_right", "right_stick_up", "right_stick_down"), Vector2(0.01, 0.01))
	
	print(left_stick_input)
