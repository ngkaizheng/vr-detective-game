class_name FadeController
extends Node


## Path to Fade.tscn
const FADE_SCENE_PATH: String = "res://addons/godot-xr-tools/effects/fade.tscn"

## Reference to the XRToolsFade node
var _fade_node: XRToolsFade

## Reference to the current Tween
var _tween: Tween


# Called when the node enters the scene tree
func _ready() -> void:
	# Find or create the XRCamera3D
	var camera: XRCamera3D = _find_xr_camera()
	if not camera:
		push_error("FadeController: No XRCamera3D found in scene")
		return
	else:
		print("FadeController: Camera Found")
	
	# Check for existing XRToolsFade node
	for child in camera.get_children():
		if child is XRToolsFade:
			_fade_node = child
			break
		else:
			print("FadeController: Fade node found")
	
	# If no XRToolsFade node, instance Fade.tscn
	if not _fade_node:
		var fade_scene: PackedScene = load(FADE_SCENE_PATH)
		if not fade_scene:
			push_error("FadeController: Failed to load Fade.tscn from ", FADE_SCENE_PATH)
			return
		_fade_node = fade_scene.instantiate() as XRToolsFade
		if not _fade_node:
			push_error("FadeController: Failed to instantiate Fade.tscn")
			return
		camera.add_child(_fade_node)
		_fade_node.owner = camera.get_tree().edited_scene_root if Engine.is_editor_hint() else camera
	
	print("FadeController: Initialized with XRToolsFade node under XRCamera3D")


# Find the XRCamera3D in the scene
#func _find_xr_camera() -> XRCamera3D:
	#var cameras: Array[Node] = get_tree().get_nodes_in_group("xr_origin")
	#if not cameras.is_empty():
		#return cameras[0] as XRCamera3D
	#for origin in get_tree().get_nodes_in_group("xr_origin"):
		#var cams: Array[Node] = origin.find_children("*", "XRCamera3D")
		#if not cams.is_empty():
			#return cams[0] as XRCamera3D
	#return null
func _find_xr_camera() -> XRCamera3D:
	var origins = get_tree().get_nodes_in_group("xr_origin")
	if origins.is_empty():
		return null
	# Get the first XROrigin3D and find its XRCamera3D child
	var camera = origins[0].get_node("XRCamera3D")  # Assumes exact name
	return camera as XRCamera3D  # Ensures type safety

# Fade to black with specified duration
func fade_to_black(duration: float) -> void:
	#if not _fade_node:
		#push_error("FadeController: No XRToolsFade node available")
		#return
	
	# Kill any existing tween
	if _tween:
		_tween.kill()
	
	# Create new tween for fade
	_tween = create_tween()
	_tween.tween_method(
		func(alpha: float):
			print("FadeController: Fade alpha = ", alpha)
			XRToolsFade.set_fade(self, Color(0, 0, 0, alpha)),
		0.0, 1.0, duration
	)
	await _tween.finished


# Fade to clear with specified duration
func fade_to_clear(duration: float) -> void:
	#if not _fade_node:
		#push_error("FadeController: No XRToolsFade node available")
		#return
	
	# Kill any existing tween
	if _tween:
		_tween.kill()
	
	# Create new tween for fade
	_tween = create_tween()
	_tween.tween_method(
		func(alpha: float):
			print("FadeController: Fade alpha = ", alpha)
			XRToolsFade.set_fade(self, Color(0, 0, 0, alpha)),
		1.0, 0.0, duration
	)
	await _tween.finished
