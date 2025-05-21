extends Node3D

## Script for a reusable 3D interactable object (NPCs, doors, etc.) with proximity-based prompts and optional dialog.
## Supports VR (via XRToolsViewport2DIn3D) interactions only, with animation playback and default animation fallback for dialog messages.

## Enum to define the type of interaction
enum InteractionType {
	DIALOG,      ## Displays a cycling dialog (e.g., for NPCs), controlled by Next/Previous buttons with optional animations and default fallback
	PROMPT,      ## Displays a single prompt (e.g., "Press to open" for doors)
	CUSTOM       ## Emits a signal for custom interaction handling
}

## Exported properties for customization in the editor
@export var is_killer: bool = false
@export var interaction_type: InteractionType = InteractionType.DIALOG
@export var target_group: String = "player" ## Group name of the interacting entity (e.g., "player")
@export var messages: Array[String] = ["Interact to proceed!"] ## Messages or prompt text
@export var original_message_size: int = 0 ## Initial size of messages array
@export var animation_clips: Array[String] = [] ## Animation clip names corresponding to messages
@export var default_animation: String = "" ## Default animation clip to play when dialog animations finish
@export var use_default_animation: bool = false ## If true, play default animation after dialog animations
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
@onready var message_label: Label = (dialog.get_scene_instance().get_node("Control_Dialog/ColorRect/Dialog") if dialog and dialog.get_scene_instance() else null)
@onready var animation_player: AnimationPlayer = $AnimationPlayer

#@onready var weapon_status: Label = (dialog.get_scene_instance().get_node("Control_Dialog/ColorRect/Control_Ending1/VBoxContainer2/Progress1") if dialog and dialog.get_scene_instance() else null)
#@onready var weapon_notes: Label = (dialog.get_scene_instance().get_node("Control_Dialog/ColorRect/Control_Ending1/VBoxContainer3/Note1") if dialog and dialog.get_scene_instance() else null)

## Store original scale of prompt for enabling/disabling
var original_prompt_scale: Vector3 = Vector3(1, 1, 1)

func _ready() -> void:
	
	
	# Set killer	
	if Initialization.killer == self.name:
		is_killer = true
		
	# Initialize node references and signals
	_log("Initializing interactable object, interaction_type=%s" % InteractionType.keys()[interaction_type])

	# Set original_message_size
	original_message_size = messages.size()
	_log("Original message size set to: %s" % original_message_size)
	
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

	# Check AnimationPlayer and connect animation_finished signal
	if animation_player:
		_log("AnimationPlayer found at $AnimationPlayer")
		if use_default_animation and default_animation != "":
			if animation_player.has_animation(default_animation):
				animation_player.animation_finished.connect(_on_animation_finished)
				_log("Connected animation_finished signal for default animation: %s" % default_animation)
			else:
				_log("WARNING: Default animation '%s' not found in AnimationPlayer" % default_animation, true)
	else:
		_log("WARNING: AnimationPlayer is null; animations will not play", true)

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
	# Handle interaction based on type (excluding DIALOG)
	match interaction_type:
		InteractionType.PROMPT, InteractionType.CUSTOM:
			_log("Emitting interacted signal")
			emit_signal("interacted", self)

func _update_display() -> void:
	# Update the displayed message or prompt
	if interaction_type == InteractionType.DIALOG and message_label:
		message_label.text = messages[current_message_index]
		_log("Dialog updated, message=%s" % message_label.text)
		
		# Play corresponding animation if available
		if animation_player and current_message_index < animation_clips.size() and animation_clips[current_message_index] != "":
			var anim_name = animation_clips[current_message_index]
			if animation_player.has_animation(anim_name):
				animation_player.play(anim_name)
				_log("Playing animation: %s" % anim_name)
			else:
				_log("WARNING: Animation '%s' not found in AnimationPlayer" % anim_name, true)
		# If no dialog animation, play default animation if enabled
		elif animation_player and use_default_animation and default_animation != "" and animation_player.has_animation(default_animation):
			animation_player.play(default_animation)
			_log("Playing default animation: %s (no dialog animation)" % default_animation)
		else:
			_log("No animation played: AnimationPlayer=%s, index=%s, clips=%s, use_default=%s, default_anim=%s" % [
				animation_player, current_message_index, animation_clips, use_default_animation, default_animation])

	elif interaction_type == InteractionType.PROMPT and message_label:
		message_label.text = messages[0] if messages.size() > 0 else ""
		_log("Prompt updated, message=%s" % message_label.text)
		
	else:
		match(messages[current_message_index]):
			"Weapon":
				dialog.get_scene_instance().get_node("Control_Dialog/ColorRect/Control_Ending1/VBoxContainer2/Progress1").text = "Done"
				dialog.get_scene_instance().get_node("Control_Dialog/ColorRect/Control_Ending1/VBoxContainer2/Progress1").add_theme_color_override("font_color", Color(0, 1, 0)) 
				dialog.get_scene_instance().get_node("Control_Dialog/ColorRect/Control_Ending1/VBoxContainer3/Note1").text =  Initialization.suspect + " 's fingerprint"
				dialog.get_scene_instance().get_node("Control_Dialog/ColorRect/Control_Ending1/VBoxContainer3/Note1").add_theme_color_override("font_color", Color(0, 1, 0)) 
				if not Initialization.evidence.has("Weapon"):
					Initialization.evidence.append("Weapon")
					Initialization._update_evidence()
				
		_log("WARNING: Cannot update display (invalid mode or null label)", true)

func _on_animation_finished(anim_name: String) -> void:
	# Play default animation when a dialog animation finishes, if enabled
	if use_default_animation and default_animation != "" and animation_player and animation_player.has_animation(default_animation):
		if anim_name != default_animation: # Avoid replaying if already playing default
			animation_player.play(default_animation)
			_log("Animation '%s' finished, playing default animation: %s" % [anim_name, default_animation])
	else:
		_log("No default animation played after '%s' finished: use_default=%s, default_anim=%s" % [
			anim_name, use_default_animation, default_animation])

func update_messages(new_messages: Array[String], update_display: bool = true) -> void:
	# Append new messages to the existing messages array
	if new_messages.size() > 0:
		var old_messages_size = messages.size();
		messages.append_array(new_messages.duplicate())
		_log("Appended messages: %s, total messages=%s" % [new_messages, messages])
		if update_display:
			# Only update display if current_message_index is invalid
			if current_message_index >= messages.size():
				current_message_index = clamp(current_message_index, 0, messages.size() - 1)
				_update_display()
			else:
				current_message_index = old_messages_size # Set to first appended message
				_update_display()
	else:
		_log("WARNING: Cannot append messages; new_messages is empty", true)

func revert_messages(original_messages: Array[String]) -> void:
	# Revert to original messages
	messages = original_messages.duplicate()
	# Adjust current_message_index if it exceeds new size
	current_message_index = clamp(current_message_index, 0, messages.size() - 1)
	_log("Reverted messages: %s, current_message_index=%s" % [messages, current_message_index])
	_update_display()

func _log(message: String, is_error: bool = false) -> void:
	# Log messages if logging is enabled
	if enable_logging:
		if is_error:
			push_warning("Interactable3D: %s" % message)
		else:
			print("Interactable3D: %s" % message)
