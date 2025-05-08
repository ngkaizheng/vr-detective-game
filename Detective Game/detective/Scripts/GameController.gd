extends Node

## GameController script to handle game logic, including catching the suspect_selected signal
## and updating the Detective's Interactable3D messages.

## Exported properties for customization in the editor
@export var detective: Node3D = null ## Reference to the Detective Node3D
@export var modified_messages: Array[String] = ["Suspect confirmed!"] ## Messages to append to Detective's Interactable3D
@export var enable_logging: bool = true ## Enable/disable debug logging

## Node references
var interactable: Node = null ## Reference to the Detective's Interactable3D script
var dialog_ui: Node = null ## Reference to the DialogUI node (CanvasLayer)

## Store original messages for reverting
var original_messages: Array[String] = []

func _ready() -> void:
	# Initialize node references and signals
	_log("Initializing GameController")

	# Validate and get the Interactable3D script from the Detective
	if detective:
		if detective.has_method("update_messages") and detective.has_method("revert_messages"):
			interactable = detective
			_log("Interactable3D found on Detective")
			original_messages = interactable.messages.duplicate() # Store original messages
		else:
			_log("ERROR: Detective does not have Interactable3D script or required methods", true)
	else:
		_log("ERROR: Detective node not assigned", true)

	# Find the DialogUI node through the Detective's Viewport2DIn3D scene instance
	if detective:
		var viewport = detective.get_node_or_null("Sprite3D/Viewport2DIn3D")
		if viewport:
			var dialog_instance = viewport.get_scene_instance()
			if dialog_instance:
				dialog_ui = dialog_instance
				if dialog_ui and dialog_ui.has_signal("suspect_selected"):
					dialog_ui.suspect_selected.connect(_on_suspect_selected)
					_log("Connected to suspect_selected signal from DialogUI")
				else:
					_log("ERROR: DialogUI instance does not have suspect_selected signal", true)
			else:
				_log("ERROR: No scene instance found in Viewport2DIn3D", true)
		else:
			_log("ERROR: Viewport2DIn3D not found under Detective", true)
	else:
		_log("ERROR: Detective node not assigned for DialogUI lookup", true)

func _on_suspect_selected(suspect_id: int) -> void:
	# Handle the suspect_selected signal by updating the Detective's messages
	_log("Received suspect_selected signal with suspect_id=%s" % suspect_id)
	if interactable and interactable.has_method("update_messages"):
		original_messages = interactable.messages.duplicate() # Backup current messages
		interactable.update_messages(modified_messages, true) # Append without updating display
		_log("Updated Detective's Interactable3D messages: %s" % modified_messages)
	else:
		_log("ERROR: Cannot update messages; invalid interactable on Detective", true)

func _log(message: String, is_error: bool = false) -> void:
	# Log messages if logging is enabled
	if enable_logging:
		if is_error:
			push_warning("GameController: %s" % message)
		else:
			print("GameController: %s" % message)
