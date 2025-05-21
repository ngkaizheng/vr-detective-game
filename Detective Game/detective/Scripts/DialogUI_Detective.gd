extends CanvasLayer

## UI script for dialog and suspect identification in a VR-compatible dialog system.
## Manages dialog cycling, suspect selection, and confirmation dialog, emitting signals for interactions.

## Signal emitted when the Next button is pressed
signal next_button_pressed()

## Signal emitted when the Previous button is pressed
signal previous_button_pressed()

## Signal emitted when a suspect is selected (1, 2, or 3)
signal suspect_selected(suspect_id: int)

## Store the current suspect ID for confirmation
var current_suspect_id: int = 0

## Class-level node references for controls
var dialog_control: Control = null
var identify_control: Control = null
var confirmation_control: Control = null

## Class-level node references for buttons
var next_button: Button = null
var previous_button: Button = null
var identify_murderer_button: Button = null
var suspect1_button: Button = null
var suspect2_button: Button = null
var suspect3_button: Button = null
var suspect4_button: Button = null
var back_button: Button = null
var no_button: Button = null
var yes_button: Button = null

func _ready():
	# Defer initialization to ensure nodes are ready
	call_deferred("_initialize_ui")

func _initialize_ui():
	# Initialize class-level control references
	dialog_control = $Control_Dialog
	identify_control = $Control_Identify
	confirmation_control = $Control_Confirmation

	# Initialize class-level button references
	next_button = $Control_Dialog/ColorRect/CenterContainer/GridContainer_Button/Next
	previous_button = $Control_Dialog/ColorRect/CenterContainer/GridContainer_Button/Previous
	identify_murderer_button = $Control_Dialog/ColorRect/CenterContainer/GridContainer_Button/IdentifyMurderer
	suspect1_button = $Control_Identify/ColorRect/MarginContainer/VBoxContainer/Button_Suspect1
	suspect2_button = $Control_Identify/ColorRect/MarginContainer/VBoxContainer/Button_Suspect2
	suspect3_button = $Control_Identify/ColorRect/MarginContainer/VBoxContainer/Button_Suspect3
	suspect4_button = $Control_Identify/ColorRect/MarginContainer/VBoxContainer/Button_Suspect4
	back_button = $Control_Identify/ColorRect/CenterContainer/GridContainer_Button/Back
	no_button = $Control_Confirmation/MarginContainer/ColorRectBg/ColorRect/GridContainer_Button/No
	yes_button = $Control_Confirmation/MarginContainer/ColorRectBg/ColorRect/GridContainer_Button/Yes
	
	var endingText = ""
	match Initialization.suspect:
		"Lina":
			endingText = "Lina the tailor was arrested. Her prized scissors matched the wounds perfectly. The victim's last words? 'Your hemming is crooked.' Some insults cut deeper than blades."
		"Rita":
			endingText = "Overworked chef, Rita was caught murdering a man at his house over unpaid catering services. Beloved friend's scissor was chosen as murder weapon."
		"Jay":
			endingText = "Uprising Internet star and streamer, Jay ultimately destroys own career over argument over filming credit rights. From friends to foe in a quick glimpse, shattering long-term friendship."
		"Detective":
			endingText = "The upbringer of law and justice turns corrupt over blackmail and exposure by responsible civillian leads to his unrightfully demise. The former detective has been arrested by fellow co-worker."
	
	var EndingViewPort = $/root/DemoStaging/Scene/Node3D/Environment_Home/Sprite3D/Viewport2DIn3D
	EndingViewPort.get_scene_instance().get_node('Control_Dialog/ColorRect/Control_Ending1/Label_Ending').text = endingText

	# Initialize UI visibility
	if dialog_control:
		dialog_control.visible = true
	else:
		push_warning("DialogUI: ERROR - Control_Dialog not found at $Control_Dialog")

	if identify_control:
		identify_control.visible = false
	else:
		push_warning("DialogUI: ERROR - Control_Identify not found at $Control_Identify")

	if confirmation_control:
		confirmation_control.visible = false
	else:
		push_warning("DialogUI: ERROR - Control_Confirmation not found at $Control_Confirmation")

	# Connect Control_Dialog button signals
	if next_button:
		next_button.pressed.connect(_on_next_button_pressed)
	else:
		push_warning("DialogUI: ERROR - Next button not found at $Control_Dialog/ColorRect/CenterContainer/GridContainer_Button/Next")

	if previous_button:
		previous_button.pressed.connect(_on_previous_button_pressed)
	else:
		push_warning("DialogUI: ERROR - Previous button not found at $Control_Dialog/ColorRect/CenterContainer/GridContainer_Button/Previous")

	if identify_murderer_button:
		identify_murderer_button.pressed.connect(_on_identify_murderer_button_pressed)
	else:
		push_warning("DialogUI: ERROR - IdentifyMurderer button not found at $Control_Dialog/ColorRect/CenterContainer/GridContainer_Button/IdentifyMurderer")

	# Connect Control_Identify button signals
	if suspect1_button:
		if Initialization.suspect == "Lina":
			suspect1_button.pressed.connect(_on_suspect_button_pressed.bind(1))
		else:
			suspect1_button.pressed.connect(_on_suspect_button_pressed.bind(2))
			
	else:
		push_warning("DialogUI: ERROR - Button_Suspect1 not found at $Control_Identify/ColorRect/MarginContainer/VBoxContainer/Button_Suspect1")

	if suspect2_button:
		if Initialization.suspect == "Rita":
			suspect2_button.pressed.connect(_on_suspect_button_pressed.bind(1))
		else:
			suspect2_button.pressed.connect(_on_suspect_button_pressed.bind(2))
	else:
		push_warning("DialogUI: ERROR - Button_Suspect2 not found at $Control_Identify/ColorRect/MarginContainer/VBoxContainer/Button_Suspect2")

	if suspect3_button:
		if Initialization.suspect == "Jay":
			suspect3_button.pressed.connect(_on_suspect_button_pressed.bind(1))
		else:
			suspect3_button.pressed.connect(_on_suspect_button_pressed.bind(2))
	else:
		push_warning("DialogUI: ERROR - Button_Suspect3 not found at $Control_Identify/ColorRect/MarginContainer/VBoxContainer/Button_Suspect3")

	if suspect4_button:
		if Initialization.suspect == "Detective":
			suspect4_button.pressed.connect(_on_suspect_button_pressed.bind(1))
		else:
			suspect4_button.pressed.connect(_on_suspect_button_pressed.bind(2))
	else:
		push_warning("DialogUI: ERROR - Button_Suspect3 not found at $Control_Identify/ColorRect/MarginContainer/VBoxContainer/Button_Suspect4")

	if back_button:
		back_button.pressed.connect(_on_back_button_pressed)
	else:
		push_warning("DialogUI: ERROR - Back button not found at $Control_Identify/ColorRect/CenterContainer/GridContainer_Button/Back")

	# Connect Control_Confirmation button signals
	if no_button:
		no_button.pressed.connect(_on_no_button_pressed)
	else:
		push_warning("DialogUI: ERROR - No button not found at $Control_Confirmation/MarginContainer/ColorRectBg/ColorRect/GridContainer_Button/No")

	if yes_button:
		yes_button.pressed.connect(_on_yes_button_pressed)
	else:
		push_warning("DialogUI: ERROR - Yes button not found at $Control_Confirmation/MarginContainer/ColorRectBg/ColorRect/GridContainer_Button/Yes")

func _on_next_button_pressed():
	# Emit the next_button_pressed signal
	print("DialogUI: Next button pressed")
	emit_signal("next_button_pressed")

func _on_previous_button_pressed():
	# Emit the previous_button_pressed signal
	print("DialogUI: Previous button pressed")
	emit_signal("previous_button_pressed")

func _on_identify_murderer_button_pressed():
	# Switch to Control_Identify
	if dialog_control and identify_control:
		dialog_control.visible = false
		identify_control.visible = true
		print("DialogUI: Switched to Control_Identify")
	else:
		push_warning("DialogUI: ERROR - Cannot switch to Control_Identify; controls not assigned")

func _on_suspect_button_pressed(suspect_id: int):
	# Show confirmation dialog
	if identify_control and confirmation_control:
		current_suspect_id = suspect_id
		identify_control.visible = true
		confirmation_control.visible = true
		confirmation_control.move_to_front()
		print("DialogUI: Showing confirmation for Suspect %s" % suspect_id)
	else:
		push_warning("DialogUI: ERROR - Cannot show confirmation; controls not assigned")

func _on_no_button_pressed():
	# Hide confirmation and stay on Control_Identify
	if confirmation_control and identify_control:
		confirmation_control.visible = false
		print("DialogUI: Confirmation cancelled")
	else:
		push_warning("DialogUI: ERROR - Cannot hide confirmation; controls not assigned")

func _on_yes_button_pressed():
	Initialization.alibi.clear()
	Initialization.evidence.clear()
	
	var killer = Initialization.npcs[randi() % Initialization.npcs.size()]
	match(killer.split("_")[0]):
		"Boy":
			Initialization.suspect = "Jay"
		"Chef":
			Initialization.suspect = "Rita"
		"Tailor":
			Initialization.suspect = "Lina"
		_:
			Initialization.suspect = "Detective"
			
	# Confirm selection, hide confirmation and Control_Identify, show Control_Dialog, hide IdentifyMurderer button
	if confirmation_control and identify_control and dialog_control:
		confirmation_control.visible = false
		identify_control.visible = false
		dialog_control.visible = true
		if identify_murderer_button:
			identify_murderer_button.visible = false
			print("DialogUI: IdentifyMurderer button hidden")
		else:
			push_warning("DialogUI: ERROR - IdentifyMurderer button not assigned")
		print("DialogUI: Suspect %s confirmed, switched to Control_Dialog" % current_suspect_id)
		emit_signal("suspect_selected", current_suspect_id)
	else:
		push_warning("DialogUI: ERROR - Cannot process confirmation; controls not assigned")

func _on_back_button_pressed():
	# Switch back to Control_Dialog
	if dialog_control and identify_control:
		identify_control.visible = false
		dialog_control.visible = true
		print("DialogUI: Switched back to Control_Dialog")
	else:
		push_warning("DialogUI: ERROR - Cannot switch to Control_Dialog; controls not assigned")
