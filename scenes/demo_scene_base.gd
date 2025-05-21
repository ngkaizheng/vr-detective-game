class_name DemoSceneBase
extends XRToolsSceneBase

#var target_script = preload("res://Detective Game/detective/Scripts/DetectCollisionWithItem.gd")
#var out_list = []
var npcs = ["Detective", "Boy", "Chef_CGD", "Tailor_CGD"]
var killer = npcs[randi() % npcs.size()]
var alibi = []
var ClueBoard = ""
var Detective = ""
var suspect = ""
var evidence = []


func _ready():
	super()
	
	match(killer.split("_")[0]):
		"Boy":
			suspect = "Jay"
		"Chef":
			suspect = "Rita"
		"Tailor":
			suspect = "Lina"
		_:
			suspect = "Detective"
	
	#var stack = [get_tree().get_root()]
	#while stack.size() > 0:
		#var node = stack.pop_back()
		#if node.get_script() == target_script:
			#out_list.append(node)
		#for child in node.get_children():
			#stack.append(child)
#
	#for node in out_list:
		#print("Found node:", node.name, " at ", node.get_path())

	var webxr_interface = XRServer.find_interface("WebXR")
	if webxr_interface:
		XRToolsUserSettings.webxr_primary_changed.connect(self._on_webxr_primary_changed)
		_on_webxr_primary_changed(XRToolsUserSettings.get_real_webxr_primary())

func _update_alibi():
	ClueBoard = $/root/DemoStaging/Scene/Node3D/InterrogationRoom/ClueBoard/Sprite3D/Viewport2DIn3D
	if(alibi.size() >= 4):
		ClueBoard.get_scene_instance().get_node('Control_Dialog/ColorRect/Control_Ending1/VBoxContainer2/Progress2').text = "Done"
		ClueBoard.get_scene_instance().get_node('Control_Dialog/ColorRect/Control_Ending1/VBoxContainer2/Progress2').add_theme_color_override("font_color", Color(0, 1, 0)) 
		ClueBoard.get_scene_instance().get_node('Control_Dialog/ColorRect/Control_Ending1/VBoxContainer3/Note2').text = suspect + " is nervous"
		ClueBoard.get_scene_instance().get_node('Control_Dialog/ColorRect/Control_Ending1/VBoxContainer3/Note2').add_theme_color_override("font_color", Color(0, 1, 0)) 
		if not evidence.has("Alibi"):
			evidence.append("Alibi")
			_update_evidence()
		
func _update_document():
	ClueBoard = $/root/DemoStaging/Scene/Node3D/InterrogationRoom/ClueBoard/Sprite3D/Viewport2DIn3D
	ClueBoard.get_scene_instance().get_node('Control_Dialog/ColorRect/Control_Ending1/VBoxContainer2/Progress3').text = "Done"
	ClueBoard.get_scene_instance().get_node('Control_Dialog/ColorRect/Control_Ending1/VBoxContainer2/Progress3').add_theme_color_override("font_color", Color(0, 1, 0))
	ClueBoard.get_scene_instance().get_node('Control_Dialog/ColorRect/Control_Ending1/VBoxContainer3/Note3').text = suspect + " has motive"
	ClueBoard.get_scene_instance().get_node('Control_Dialog/ColorRect/Control_Ending1/VBoxContainer3/Note3').add_theme_color_override("font_color", Color(0, 1, 0))
	if not evidence.has("Document"):
		evidence.append("Document")
		_update_evidence()

func _update_evidence():
	if evidence.size() >= 3:
		Detective = $/root/DemoStaging/Scene/Node3D/InterrogationRoom/Detective/Sprite3D/Viewport2DIn3D
		Detective.get_scene_instance().get_node('Control_Dialog/ColorRect/CenterContainer/GridContainer_Button/IdentifyMurderer').visible = true
	
func _on_webxr_primary_changed(webxr_primary: int) -> void:
	# Default to thumbstick.
	if webxr_primary == 0:
		webxr_primary = XRToolsUserSettings.WebXRPrimary.THUMBSTICK

	# Re-assign the action name on all the applicable functions.
	var action_name = XRToolsUserSettings.get_webxr_primary_action(webxr_primary)
	for controller in [$XROrigin3D/LeftHand, $XROrigin3D/RightHand]:
		for n in ["MovementDirect", "MovementTurn", "FunctionTeleport"]:
			var f = controller.get_node_or_null(n)
			if f:
				if "input_action" in f:
					f.input_action = action_name
				if "rotation_action" in f:
					f.rotation_action = action_name
