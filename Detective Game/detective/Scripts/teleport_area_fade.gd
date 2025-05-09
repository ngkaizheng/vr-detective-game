@tool
class_name XRToolsTeleportAreaFade
extends Area3D


## Target node
@export var target: Node3D

## Fade duration for fade-in and fade-out (in seconds)
@export var fade_duration: float = 0.5

## Prevent multiple simultaneous teleports
var _is_teleporting: bool = false

## Reference to FadeController (set via autoload or node path)
var _fade_controller: FadeController


# Add support for is_xr_class on XRTools classes
func is_xr_class(name: String) -> bool:
	return name == "XRToolsTeleportAreaFade"


# Called when the node enters the scene tree
func _ready() -> void:
	# Connect body entered signal
	body_entered.connect(_on_body_entered)
	
	# Find FadeController (assuming autoload)
	_fade_controller = get_node_or_null("/root/fadeController")
	if not _fade_controller:
		push_warning("XRToolsTeleportArea: No FadeController found. Add as autoload or node.")
	
	# Debug: Check XR setup
	var origins: Array[Node] = get_tree().get_nodes_in_group("xr_origin")
	if origins.is_empty():
		push_warning("XRToolsTeleportArea: No XROrigin3D found in scene")
	else:
		var camera_found: bool = false
		for origin in origins:
			var cameras: Array[Node] = origin.find_children("*", "XRCamera3D")
			if not cameras.is_empty():
				camera_found = true
				break
		if not camera_found:
			push_warning("XRToolsTeleportArea: No XRCamera3D found in scene")


# Handle body entering area
func _on_body_entered(body: Node3D) -> void:
	# Skip if already teleporting
	if _is_teleporting:
		return
	
	# Test if the body is the player
	var player_body := body as XRToolsPlayerBody
	if not player_body:
		print("XRToolsTeleportArea: Body entered is not XRToolsPlayerBody")
		return

	# Ensure the target exists
	if not target:
		push_warning("XRToolsTeleportArea: Target node not set")
		return

	# Start teleport process
	_is_teleporting = true
	print("XRToolsTeleportArea: Starting teleport to ", target.global_transform.origin)

	# Fade to black using FadeController
	if _fade_controller:
		await _fade_controller.fade_to_black(fade_duration)
	else:
		push_warning("XRToolsTeleportArea: No FadeController, skipping fade")

	# Teleport the player
	player_body.teleport(target.global_transform)
	print("XRToolsTeleportArea: Teleport completed")

	# Fade back in
	if _fade_controller:
		await _fade_controller.fade_to_clear(fade_duration)
	else:
		push_warning("XRToolsTeleportArea: No FadeController, skipping fade")
	
	_is_teleporting = false
