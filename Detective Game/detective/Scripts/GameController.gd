extends Node

## GameController script to handle game logic, including catching the suspect_selected signal,
## updating the Detective's Interactable3D messages, and showing ending UI based on suspect_id.

## Exported properties for customization in the editor
@export var detective: Node3D = null ## Reference to the Detective Node3D
@export var teleport: Node3D = null ## Reference to the Teleport Node3D
@export var ending_ui_sprite: Node3D = null ## Reference to the Sprite3D with EndingUI.tscn
@export var modified_messages: Array[String] = ["Suspect confirmed!"] ## Messages to append to Detective's Interactable3D
@export var enable_logging: bool = true ## Enable/disable debug logging

## Node references
var interactable: Node = null ## Reference to the Detective's Interactable3D script
var dialog_ui: Node = null ## Reference to the DialogUI node (CanvasLayer)
var teleport_area: Area3D = null ## Reference to the XRToolsTeleportArea (Area3D)
var ending_ui: Node = null ## Reference to the EndingUI.tscn instance

## Stored suspect ID
var selected_suspect_id: int = -1 ## Stores the selected suspect_id (-1 means none selected)

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
			# Defer DialogUI initialization to ensure scene instance is loaded
			_initialize_dialog_ui_deferred(viewport)
		else:
			_log("ERROR: Viewport2DIn3D not found under Detective", true)
	else:
		_log("ERROR: Detective node not assigned for DialogUI lookup", true)
	
	# Initialize Teleport visibility and monitoring
	if teleport:
		# Find the XRToolsTeleportArea child
		teleport_area = teleport.get_node_or_null("XRToolsTeleportArea")
		if teleport_area and teleport_area is Area3D:
			teleport.visible = false
			teleport_area.monitoring = false
			_log("Teleport node initialized, hidden, and monitoring disabled")
		else:
			_log("ERROR: XRToolsTeleportArea not found or not an Area3D under Teleport", true)
	else:
		_log("ERROR: Teleport node not assigned", true)
	
	# Initialize EndingUI
	if ending_ui_sprite:
		var viewport = ending_ui_sprite.get_node_or_null("Viewport2DIn3D")
		if viewport:
			# Defer EndingUI initialization to ensure scene instance is loaded
			_initialize_ending_ui_deferred(viewport)
		else:
			_log("ERROR: Viewport2DIn3D not found under Sprite3D", true)
	else:
		_log("ERROR: Ending UI Sprite3D node not assigned", true)

func _initialize_dialog_ui_deferred(viewport: XRToolsViewport2DIn3D) -> void:
	# Wait for the DialogUI scene instance to be ready
	var dialog_instance = await _wait_for_scene_instance(viewport)
	if dialog_instance:
		dialog_ui = dialog_instance
		if dialog_ui and dialog_ui.has_signal("suspect_selected"):
			dialog_ui.suspect_selected.connect(_on_suspect_selected)
			_log("Connected to suspect_selected signal from DialogUI")
		else:
			_log("ERROR: DialogUI instance does not have suspect_selected signal", true)
	else:
		_log("ERROR: No scene instance found in Detective/Sprite3D/Viewport2DIn3D", true)

func _initialize_ending_ui_deferred(viewport: XRToolsViewport2DIn3D) -> void:
	# Wait for the EndingUI scene instance to be ready
	var ending_instance = await _wait_for_scene_instance(viewport)
	if ending_instance:
		ending_ui = ending_instance
		_log("EndingUI.tscn instance found under Sprite3D/Viewport2DIn3D")
		# Ensure all ending controls are hidden initially
		_set_ending_visibility(0) # 0 means hide all
	else:
		_log("ERROR: No scene instance found in Sprite3D/Viewport2DIn3D", true)

func _wait_for_scene_instance(viewport: XRToolsViewport2DIn3D) -> Node:
	# Wait for the Viewport2DIn3D scene instance to be ready (up to 5 seconds)
	var start_time = Time.get_ticks_msec()
	var timeout_ms = 5000 # 5 seconds
	while Time.get_ticks_msec() - start_time < timeout_ms:
		var instance = viewport.get_scene_instance()
		if instance:
			return instance
		await get_tree().create_timer(0.1).timeout
	return null

func _on_suspect_selected(suspect_id: int) -> void:
	# Handle the suspect_selected signal by storing the suspect_id, updating messages,
	# showing the Teleport, and displaying the appropriate ending UI
	_log("Received suspect_selected signal with suspect_id=%s" % suspect_id)
	
	# Store the suspect_id
	selected_suspect_id = suspect_id
	_log("Stored suspect_id: %s" % selected_suspect_id)

	# Update Detective's messages
	if interactable and interactable.has_method("update_messages"):
		original_messages = interactable.messages.duplicate() # Backup current messages
		interactable.update_messages(modified_messages, true) # Append without updating display
		_log("Updated Detective's Interactable3D messages: %s" % modified_messages)
	else:
		_log("ERROR: Cannot update messages; invalid interactable on Detective", true)

	# Show and enable the Teleport node
	if teleport and teleport_area:
		teleport.visible = true
		teleport_area.monitoring = true
		_log("Teleport node shown and monitoring enabled after suspect selection")
	else:
		_log("ERROR: Teleport or XRToolsTeleportArea not valid, cannot enable", true)
	
	# Show the appropriate ending based on suspect_id
	if ending_ui:
		_set_ending_visibility(suspect_id)
	else:
		_log("ERROR: EndingUI not initialized, cannot show ending", true)

func _set_ending_visibility(suspect_id: int) -> void:
	# Show the appropriate ending control based on suspect_id and hide others
	if not ending_ui:
		_log("ERROR: EndingUI not available for setting visibility", true)
		return
	
	var ending_1 = ending_ui.get_node_or_null("Control_Dialog/ColorRect/Control_Ending1")
	var ending_2 = ending_ui.get_node_or_null("Control_Dialog/ColorRect/Control_Ending2")
	var ending_3 = ending_ui.get_node_or_null("Control_Dialog/ColorRect/Control_Ending3")
	
	# Validate ending nodes
	if not ending_1 or not ending_2 or not ending_3:
		_log("ERROR: One or more ending controls (Control_Ending1, Control_Ending2, Control_Ending3) not found", true)
		return
	
	# Hide all endings by default
	ending_1.visible = false
	ending_2.visible = false
	ending_3.visible = false
	
	# Show the appropriate ending based on suspect_id
	match suspect_id:
		1:
			ending_1.visible = true
			_log("Showing Control_Ending1 for suspect_id=%s" % suspect_id)
		2:
			ending_2.visible = true
			_log("Showing Control_Ending2 for suspect_id=%s" % suspect_id)
		3:
			ending_3.visible = true
			_log("Showing Control_Ending3 for suspect_id=%s" % suspect_id)
		_:
			_log("No ending shown for suspect_id=%s (hiding all)" % suspect_id)

func _log(message: String, is_error: bool = false) -> void:
	# Log messages if logging is enabled
	if enable_logging:
		if is_error:
			push_warning("GameController: %s" % message)
		else:
			print("GameController: %s" % message)
