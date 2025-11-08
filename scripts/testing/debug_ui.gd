extends CanvasLayer

@onready var _list := $Panel/MarginContainer/VBoxContainer

const TOGGLE_ACTION := "ui_toggle"

@warning_ignore("unused_signal")
signal reset_ages

@warning_ignore("unused_signal")
signal test_multiple

@warning_ignore("unused_signal")
signal show_probes

var buttons: Array[Dictionary] = [
	{
		"label": "Reset ages",
		"event": "reset_ages",
		"args": {}
	},
]

var checkboxes: Array[Dictionary] = [
	{
		"label": "Test multiple",
		"event": "test_multiple",
		"default": false,
		"args": {"amount": 100}
	},
	
	{
		"label": "Show Probes",
		"event": "show_probes",
		"default": false,
		"args": {}
	},
]

func _ready() -> void:
	self.visible = false
	_build_buttons()
	_build_checkboxes()
	
func _build_buttons() -> void:	
	for entry in  buttons:
		var button := Button.new()
		_build_entry(entry, button)	
		
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(func(): emit_signal(entry["event"], entry["args"]))
		
func _build_checkboxes() -> void:
	for entry in checkboxes:
		var checkbox = CheckBox.new()
		_build_entry(entry, checkbox)
		
		var args := entry["args"] as Dictionary
		checkbox.toggled.connect(func(toggled):	
			args["toggled"] = toggled
			emit_signal(entry["event"], entry["args"])
		)
		checkbox.button_pressed = entry["default"]
		
## Builds up the given base object (Button or Checkbox) with the attributes
## from the given entry dict and adds it to _list.
func _build_entry(entry: Dictionary, obj_base) -> void:
	var label := str(entry["label"])
	obj_base.text = label
	_list.add_child(obj_base)
