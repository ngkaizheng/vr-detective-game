extends Node3D

## Script to detect collisions with objects in a specified group and extend Interactable3D messages by appending new messages.

## Exported properties for customization in the editor
@export var collision_group: String = "Scissors" ## Group name of objects to detect (e.g., "Scissors")
@export var modified_messages: Array[String] = ["Scissors detected!"] ## Messages to append when collision occurs
@export var revert_on_exit: bool = false ## If true, remove appended messages when object exits
@export var enable_logging: bool = true ## Enable/disable debug logging

## Node references
@onready var detection_area: Area3D = $Area3D
@onready var interactable: Node = get_parent() ## Reference to NPC with Interactable3D script

## Store original messages for reverting
var original_messages: Array[String] = []
## Track appended messages to remove on exit
var appended_messages: Array[String] = []
## Track if messages have been updated
var has_updated_messages: bool = false

func _ready() -> void:
	
	has_updated_messages = false
	
	# Initialize node references and signals
	_log("Initializing detection script, collision_group=%s" % collision_group)

	# Connect detection area signals
	if detection_area:
		detection_area.body_entered.connect(_on_detection_area_body_entered)
		#detection_area.body_exited.connect(_on_detection_area_body_exited)
		_log("Detection area signals connected")
	else:
		_log("ERROR: Detection Area3D is null", true)

	# Validate interactable parent
	if interactable and interactable.has_method("update_messages") and interactable.has_method("revert_messages"):
		_log("Interactable3D found on parent")
		original_messages = interactable.messages.duplicate() # Store original messages
	else:
		_log("ERROR: Parent does not have Interactable3D script or required methods", true)

func _on_detection_area_body_entered(body: Node3D) -> void:
	_log("Body entered detection area, body=%s" % body)
	
	if body.get_parent().name == "Document":
		Initialization._update_document()
		
	if body.get_parent().name == "Scissor_Pickable":
		if not Initialization.alibi.has(interactable.name) and interactable.name != "ClueBoard":
			Initialization.alibi.append(interactable.name)
			Initialization._update_alibi()
	
	# Check if messages have already been updated
	if has_updated_messages:
		_log("Messages already updated for group '%s', skipping" % collision_group)
		return
	
	# Check if the body or its parent is in the collision group
	var current_node = body
	while current_node:
		if current_node.is_in_group(collision_group):
			_log("Detected object in group '%s'" % collision_group)
			if interactable and interactable.has_method("update_messages"):
				original_messages = interactable.messages.duplicate() # Backup current messages
				appended_messages = modified_messages.duplicate() # Track appended messages
				interactable.update_messages(modified_messages, true) # Append without updating display
				has_updated_messages = true # Mark as updated
				#_log("Appended messages to Interactable3D: %s" % modified_messages)
			else:
				_log("ERROR: Cannot update messages; invalid interactable", true)
			return
		current_node = current_node.get_parent()
	
	_log("No '%s' group found in hierarchy" % collision_group)

#func _on_detection_area_body_exited(body: Node3D) -> void:
	#_log("Body exited detection area, body=%s" % body)
	#
	## Check if the exiting body or its parent is in the collision group
	#var current_node = body
	#while current_node:
		#if current_node.is_in_group(collision_group):
			#_log("Object in group '%s' exited" % collision_group)
			#if revert_on_exit and interactable and interactable.has_method("revert_messages"):
				#interactable.revert_messages(original_messages)
				#_log("Reverted Interactable3D messages to: %s" % original_messages)
				#appended_messages.clear() # Clear tracked messages
			#else:
				#_log("Keeping appended messages: revert_on_exit=%s" % revert_on_exit)
			#return
		#current_node = current_node.get_parent()
	#
	#_log("No '%s' group found in hierarchy on exit" % collision_group)

func _log(message: String, is_error: bool = false) -> void:
	# Log messages if logging is enabled
	if enable_logging:
		if is_error:
			push_warning("DetectCollisionWithItem: %s" % message)
		else:
			print("DetectCollisionWithItem: %s" % message)
