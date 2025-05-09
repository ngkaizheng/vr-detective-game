extends Node3D

## Simple Audio Controller for switching background music (BGM) when the player enters/exits an Area3D.
## Plays a specified music track on enter and reverts to default music on exit.

## Exported properties
@export var audio_player: AudioStreamPlayer ## AudioStreamPlayer node to play music
@export var area_music: AudioStream ## Music to play when player enters Area3D
@export var default_music: AudioStream ## Default music to play on start and exit
@export var enable_logging: bool = true ## Enable/disable debug logging

## Node references
@onready var trigger_area: Area3D = $Area3D

## Group name for the player
const PLAYER_GROUP: String = "player"

func _ready() -> void:
	# Validate nodes and properties
	if not audio_player:
		_log("ERROR: AudioStreamPlayer not assigned", true)
		return
	if not trigger_area:
		_log("ERROR: Area3D not found at $Area3D", true)
		return
	if not default_music:
		_log("WARNING: Default music is not assigned", true)
		return
	if not area_music:
		_log("WARNING: Area music is not assigned", true)
		return
	
	# Connect area signals
	trigger_area.body_entered.connect(_on_body_entered)
	trigger_area.body_exited.connect(_on_body_exited)
	_log("Connected Area3D signals")

	# Play default music
	_play_music(default_music)

func _on_body_entered(body: Node3D) -> void:
	_log("Body entered: %s" % body)
	
	# Check if body is in the player group
	if body.is_in_group(PLAYER_GROUP):
		_log("Player entered, switching to area music")
		_play_music(area_music)
	else:
		_log("Body not in group '%s'" % PLAYER_GROUP)

func _on_body_exited(body: Node3D) -> void:
	_log("Body exited: %s" % body)
	
	# Check if the exiting body is the player
	if body.is_in_group(PLAYER_GROUP):
		_log("Player exited, reverting to default music")
		_play_music(default_music)
	else:
		_log("Exiting body not in group '%s'" % PLAYER_GROUP)

func _play_music(music: AudioStream) -> void:
	# Validate music
	if not music:
		_log("WARNING: No music to play", true)
		return
	
	# Stop current music if playing
	if audio_player.playing:
		audio_player.stop()
	
	# Play new music
	audio_player.stream = music
	audio_player.play()
	_log("Playing music: %s" % music.resource_path)

func _log(message: String, is_error: bool = false) -> void:
	if enable_logging:
		if is_error:
			push_warning("AudioController: %s" % message)
		else:
			print("AudioController: %s" % message)
