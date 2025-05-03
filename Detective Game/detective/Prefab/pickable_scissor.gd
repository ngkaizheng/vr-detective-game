@tool
class_name ScissorsPickable
extends XRToolsPickable

## Custom pickable script for scissors, extending XRToolsPickable.
## Handles animation playback for the Scissors node and blood splatter effects.

## Reference to the AnimationPlayer for the Scissors
@onready var scissors_animation_player : AnimationPlayer = $Scissors/AnimationPlayer

## Reference to the blood splatter Sprite3D
@onready var blood_splatter : Sprite3D = $Sprite3D

func _ready():
	# Call the parent class's _ready() to maintain XRToolsPickable functionality
	super._ready()
	
	## Start the scissors animation and loop it (optional)
	#if scissors_animation_player:
		#var anim = scissors_animation_player.get_animation("Scene")
		#if anim:
			#anim.loop_mode = Animation.LOOP_LINEAR  # Enable looping
			#scissors_animation_player.play("Scene")  # Play on start

func action():
	# Play the scissors animation and show blood splatter when action is pressed
	if scissors_animation_player and not scissors_animation_player.is_playing():
		scissors_animation_player.play("Scene")
	if blood_splatter:
		blood_splatter.visible = true
		var tween = create_tween()
		tween.tween_property(blood_splatter, "modulate:a", 0.0, 1.0).from(1.0)
		tween.tween_callback(blood_splatter.set_visible.bind(false))
	
	# Call the parent class's action() to maintain XRToolsPickable functionality
	super.action()
