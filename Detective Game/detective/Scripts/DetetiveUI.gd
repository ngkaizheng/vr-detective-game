extends CanvasLayer

## Signal emitted when the Next button is pressed
signal next_button_pressed()

## Signal emitted when the Previous button is pressed
signal previous_button_pressed()

func _ready():
	# Connect the Next button's pressed signal
	var next_button = $Control/ColorRect/CenterContainer/GridContainer_Button/Next
	if next_button:
		next_button.pressed.connect(_on_next_button_pressed)
	else:
		print("DetectiveUI: ERROR - Next button not found")

	# Connect the Previous button's pressed signal
	var previous_button = $Control/ColorRect/CenterContainer/GridContainer_Button/Previous
	if previous_button:
		previous_button.pressed.connect(_on_previous_button_pressed)
	else:
		print("DetectiveUI: ERROR - Previous button not found")

func _on_next_button_pressed():
	# Emit the next_button_pressed signal
	print("DetectiveUI: Next button pressed")
	emit_signal("next_button_pressed")

func _on_previous_button_pressed():
	# Emit the previous_button_pressed signal
	print("DetectiveUI: Previous button pressed")
	emit_signal("previous_button_pressed")
