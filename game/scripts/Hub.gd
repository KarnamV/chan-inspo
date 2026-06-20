## Hub.gd — Post-death hub screen.
##
## Reads RunStats (AutoLoad) and displays the run summary.
## Two buttons: "New Run" (resets stats, reloads TestRoom) and "Quit".

extends Control

@onready var title_label:          Label  = $VBox/TitleLabel
@onready var rooms_label:          Label  = $VBox/Stats/RoomsLabel
@onready var enemies_label:        Label  = $VBox/Stats/EnemiesLabel
@onready var spirit_label:         Label  = $VBox/Stats/SpiritLabel
@onready var shards_label:         Label  = $VBox/Stats/ShardsLabel
@onready var new_run_button:       Button = $VBox/Buttons/NewRunButton
@onready var quit_button:          Button = $VBox/Buttons/QuitButton


func _ready() -> void:
	# Populate run summary from the RunStats singleton.
	rooms_label.text   = "Rooms visited:    %d"   % RunStats.rooms_visited
	enemies_label.text = "Enemies defeated: %d"   % RunStats.enemies_killed
	spirit_label.text  = "Spirit collected: %d"   % int(RunStats.spirit_collected)
	shards_label.text  = "Spirit Shards earned: %d" % RunStats.spirit_shards_earned()

	new_run_button.pressed.connect(_on_new_run_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	# Grab focus on the primary button so keyboard navigation works immediately.
	new_run_button.grab_focus()


func _on_new_run_pressed() -> void:
	# Reset all run stats before the scene loads so TestRoom starts clean.
	RunStats.reset()
	get_tree().change_scene_to_file("res://scenes/TestRoom.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()
