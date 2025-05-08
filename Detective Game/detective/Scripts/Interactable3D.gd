extends Node3D

## Script for a reusable 3D interactable object (NPCs, doors, etc.) with proximity-based prompts and optional dialog.
## Supports VR (via XRToolsViewport2DIn3D) and non-VR interactions.

## Enum to define the type of interaction
enum InteractionType {
	DIALOG,      ## Displays a cycling dialog (e.g., for NPCs)
	PROMPT,      ## Displays a single prompt (e.g., "Press A to open" for doors)
	CUSTOM       ## Emits a signal for custom interaction handling
}

## Exported properties for customization in the editor
@export var interaction_type: InteractionType = InteractionType.DIALOG
@export var target_group: String = "player" ## Group name of the interacting entity (e.g., "player")
@export var messages: Array[String] = ["Interact to proceed!"] ## Messages or prompt text
@export var prompt_texture: Texture2D = null ## Optional texture for the prompt
@export var enable_logging: bool = true ## Enable/disable debug logging

## Custom signal for interaction events (e.g., door opening)
signal interacted(interactable: Node3D)

## Current message index for dialog mode
var current_message_index: int = 0

## Reference to the interacting entity (e.g., player)
var interacting_entity: Node = null

## Node references
@onready var proximity_area: Area3D = $ProximityArea
@onready var prompt: Sprite3D = $Sprite3D
@onready var dialog: XRToolsViewport2DIn3D = $Sprite3D/Viewport2DIn3D
@onready var message_label: Label = (dialog.get_scene_instance().get_node("Control/ColorRect/Dialog") if dialog and dialog.get_scene_instance() else null)

## Store original scale of prompt for enabling/disabling
var original_prompt_scale: Vector3 = Vector3(1, 1, 1)

func _ready() -> void:
	# Initialize node references and signals
	_log("Initializing interactable object, interaction_type=%s" % InteractionType.keys()[interaction_type])

	# Store original prompt scale
	if prompt:
		original_prompt_scale = prompt.scale
		prompt.scale = Vector3(0, 0, 0)
		prompt.visible = false
		if prompt_texture:
			prompt.texture = prompt_texture
		_log("Prompt initialized, original_scale=%s, texture=%s" % [original_prompt_scale, prompt_texture])
	else:
		_log("WARNING: Prompt (Sprite3D) is null", true)

	# Connect dialog signals if in DIALOG mode
	if interaction_type == InteractionType.DIALOG and dialog:
		var dialog_instance = dialog.get_scene_instance()
		if dialog_instance:
			if dialog_instance.has_signal("next_button_pressed"):
				dialog_instance.next_button_pressed.connect(_on_next_button_pressed)
			if dialog_instance.has_signal("previous_button_pressed"):
				dialog_instance.previous_button_pressed.connect(_on_previous_button_pressed)
			_log("Connected to dialog instance signals")
		else:
			_log("ERROR: Dialog instance is null", true)
		dialog.enabled = true
		_log("Dialog enabled")
	else:
		_log("Dialog skipped (interaction_type=%s or dialog null)" % InteractionType.keys()[interaction_type])

	# Connect proximity area signals
	if proximity_area:
		proximity_area.body_entered.connect(_on_proximity_area_body_entered)
		proximity_area.body_exited.connect(_on_proximity_area_body_exited)
		_log("Proximity area signals connected")
	else:
		_log("ERROR: ProximityArea is null", true)

	# Connect pointer event for VR interaction
	if dialog:
		dialog.pointer_event.connect(_on_pointer_event)
		_log("Connected to pointer_event signal")

	# Set initial message or prompt
	_update_display()

func _on_proximity_area_body_entered(body: Node3D) -> void:
	_log("Body entered proximity area, body=%s" % body)
	
	# Check if the body or its parent is in the target group
	var current_node = body
	while current_node:
		if current_node.is_in_group(target_group):
			interacting_entity = current_node
			if prompt:
				prompt.set_deferred("visible", true)
				prompt.set_deferred("scale", original_prompt_scale)
				_log("Target detected (%s), prompt enabled, scale=%s" % [target_group, original_prompt_scale])
			else:
				_log("WARNING: Prompt is null, cannot enable", true)
			return
		current_node = current_node.get_parent()
	
	_log("No '%s' group found in hierarchy" % target_group)

func _on_proximity_area_body_exited(body: Node3D) -> void:
	_log("Body exited proximity area, body=%s" % body)
	
	# Check if the exiting body or its parent is in the target group
	var current_node = body
	while current_node:
		if current_node.is_in_group(target_group):
			interacting_entity = null
			if prompt:
				prompt.set_deferred("visible", false)
				prompt.set_deferred("scale", Vector3(0, 0, 0))
				_log("Target exited (%s), prompt disabled, scale=%s" % [target_group, Vector3(0, 0, 0)])
			else:
				_log("WARNING: Prompt is null, cannot disable", true)
			return
		current_node = current_node.get_parent()
	
	_log("No '%s' group found in hierarchy on exit" % target_group)

func _on_pointer_event(event: XRToolsPointerEvent) -> void:
	# Handle VR pointer interaction
	if event.event_type == XRToolsPointerEvent.Type.PRESSED:
		_log("Pointer pressed, target=%s, position=%s" % [event.target, event.position])
		if interaction_type != InteractionType.DIALOG:
			_handle_interaction()
		else:
			_log("Dialog interaction ignored; use Next/Previous buttons")
	else:
		_log("Ignored pointer event, type=%s" % event.event_type)

func _input(event: InputEvent) -> void:
	# Handle non-VR input (e.g., "interact" action for doors)
	if interacting_entity and interaction_type != InteractionType.DIALOG:
		if event.is_action_pressed("interact"):
			_log("Interact action pressed")
			_handle_interaction()

func _on_next_button_pressed() -> void:
	# Cycle to the next message in DIALOG mode
	if interaction_type == InteractionType.DIALOG:
		current_message_index = (current_message_index + 1) % messages.size()
		_log("Next button pressed, current_message_index=%s" % current_message_index)
		_update_display()

func _on_previous_button_pressed() -> void:
	# Cycle to the previous message in DIALOG mode
	if interaction_type == InteractionType.DIALOG:
		current_message_index = (current_message_index - 1 + messages.size()) % messages.size()
		_log("Previous button pressed, current_message_index=%s" % current_message_index)
		_update_display()

func _handle_interaction() -> void:
	# Handle interaction based on type
	match interaction_type:
		#InteractionType.DIALOG:
			#current_message_index = (current_message_index + 1) % messages.size()
			#_log("Dialog interaction, current_message_index=%s" % current_message_index)
			#_update_display()
		InteractionType.PROMPT, InteractionType.CUSTOM:
			_log("Emitting interacted signal")
			emit_signal("interacted", self)

func _update_display() -> void:
	# Update the displayed message or prompt
	if interaction_type == InteractionType.DIALOG and message_label:
		message_label.text = messages[current_message_index]
		_log("Dialog updated, message=%s" % message_label.text)
	elif interaction_type == InteractionType.PROMPT and message_label:
		message_label.text = messages[0] if messages.size() > 0 else ""
		_log("Prompt updated, message=%s" % message_label.text)
	else:
		_log("WARNING: Cannot update display (invalid mode or null label)", true)

func _log(message: String, is_error: bool = false) -> void:
	# Log messages if logging is enabled
	if enable_logging:
		if is_error:
			push_warning("Interactable3D: %s" % message)
		else:
			print("Interactable3D: %s" % message)
