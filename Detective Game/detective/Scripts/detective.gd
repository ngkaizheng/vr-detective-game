extends Node3D

## Script for the Detective NPC to handle proximity-based 3D dialog interaction in VR.
## Uses Sprite3D for prompt and Viewport2DIn3D for dialog, ensuring no occlusion.

## List of dialog messages
var messages : Array[String] = [
	"Detective: I found a clue about the case!",
	"Detective: The scissors are key evidence!",
	"Detective: We need to solve this mystery!"
]

## Current message index
var current_message_index : int = 0

## Reference to the player (set when player enters proximity)
var player : Node = null

## Reference to the proximity area
@onready var proximity_area : Area3D = $ProximityArea

## Reference to the interaction prompt
@onready var prompt : Sprite3D = $Sprite3D

## Reference to the dialog (Viewport2DIn3D)
@onready var dialog : XRToolsViewport2DIn3D = $Sprite3D/Viewport2DIn3D

## Reference to the dialog message label within the instanced scene
@onready var message_label : Label = dialog.get_scene_instance().get_node("Control/ColorRect/Dialog")

## Store the original scale of prompt and dialog to restore when enabling
var original_prompt_scale : Vector3 = Vector3(1, 1, 1)

func _ready():
	# Connect to the pointer_event signal from Viewport2DIn3D
	#if dialog:
		#dialog.pointer_event.connect(_on_pointer_event)
		#print("DetectiveNPC: Connected to pointer_event signal")
	#else:
		#print("DetectiveNPC: ERROR - dialog is null")

	# Connect to the next_button_pressed and previous_button_pressed signals from the instanced DetectiveUI
	var dialog_instance = dialog.get_scene_instance()
	if dialog_instance:
		dialog_instance.next_button_pressed.connect(_on_next_button_pressed)
		dialog_instance.previous_button_pressed.connect(_on_previous_button_pressed)
		print("DetectiveNPC: Connected to next_button_pressed and previous_button_pressed signals from DetectiveUI")
	else:
		print("DetectiveNPC: ERROR - dialog instance is null")

	# Ensure dialog is enabled initially
	if dialog:
		dialog.enabled = true
		print("DetectiveNPC: Dialog set to enabled")
	else:
		print("DetectiveNPC: ERROR - dialog is null")
		
	# Ensure prompt and dialog are disabled initially
	if prompt:
		original_prompt_scale = prompt.scale
		prompt.scale = Vector3(0, 0, 0)
		print("DetectiveNPC: Prompt disabled with scale =", prompt.scale)
	else:
		print("DetectiveNPC: ERROR - prompt is null")
		
		# Connect area signals to detect player entering/exiting
	if proximity_area:
		proximity_area.body_entered.connect(_on_proximity_area_body_entered)
		proximity_area.body_exited.connect(_on_proximity_area_body_exited)
		print("DetectiveNPC: Proximity area signals connected")
	else:
		print("DetectiveNPC: ERROR - proximity_area is null")

	# Set initial message
	_update_dialog_message()

func _on_proximity_area_body_entered(body: Node3D):
	# Log the body that entered
	print("DetectiveNPC: Body entered proximity area, body =", body)
	
	# Traverse up the hierarchy to find the node in the "player" group
	var current_node = body
	while current_node:
		print("DetectiveNPC: Checking node for 'player' group:", current_node, "Groups:", current_node.get_groups())
		if current_node.is_in_group("player"):
			player = current_node
			if prompt:
				prompt.visible = true
				prompt.scale = original_prompt_scale
				print("DetectiveNPC: Player detected, prompt enabled with scale =", prompt.scale, ", player =", player)
				print("DetectiveNPC: Player detected, prompt set to visible, player =", player)
			else:
				print("DetectiveNPC: ERROR - prompt is null, cannot set visible")
			return
		current_node = current_node.get_parent()
	
	print("DetectiveNPC: No 'player' group found in hierarchy")

func _on_proximity_area_body_exited(body: Node3D):
	# Log the body that exited
	print("DetectiveNPC: Body exited proximity area, body =", body)
	
	# Traverse up to find the node in the "player" group
	var current_node = body
	while current_node:
		print("DetectiveNPC: Checking node for 'player' group:", current_node, "Groups:", current_node.get_groups())
		if current_node.is_in_group("player"):
			player = null
			if prompt:
				prompt.visible = false
				prompt.scale = Vector3(0, 0, 0)
				print("DetectiveNPC: Player exited, prompt disabled with scale =", prompt.scale)
				print("DetectiveNPC: Player exited, prompt set to invisible")
			else:
				print("DetectiveNPC: ERROR - prompt is null, cannot set invisible")
			return
		current_node = current_node.get_parent()
	
	print("DetectiveNPC: No 'player' group found in hierarchy on exit")


func _on_pointer_event(event: XRToolsPointerEvent) -> void:
	# Handle pointer events for cycling through messages
	if event.event_type == XRToolsPointerEvent.Type.PRESSED:
		print("DetectiveNPC: Pointer pressed on dialog, target =", event.target, "position =", event.position)
		_cycle_message()

func _cycle_message():
	# Cycle to the next message
	current_message_index = (current_message_index + 1) % messages.size()
	print("DetectiveNPC: Cycling message, current_message_index =", current_message_index)
	_update_dialog_message()
	
func _on_next_button_pressed():
	# Cycle to the next message
	current_message_index = (current_message_index + 1) % messages.size()
	print("DetectiveNPC: Next button pressed, current_message_index =", current_message_index)
	_update_dialog_message()

func _on_previous_button_pressed():
	# Cycle to the previous message
	current_message_index = (current_message_index - 1 + messages.size()) % messages.size()
	print("DetectiveNPC: Previous button pressed, current_message_index =", current_message_index)
	_update_dialog_message()

func _update_dialog_message():
	# Update dialog message
	if message_label:
		message_label.text = messages[current_message_index]
		print("DetectiveNPC: Dialog message updated, message_label.text =", message_label.text)
	else:
		print("DetectiveNPC: ERROR - message_label is null, cannot update message")
