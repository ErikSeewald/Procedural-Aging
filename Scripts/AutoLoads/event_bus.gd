extends Node

signal reset_ages
signal test_multiple

func _ready():
	# Reference the declared signals to silence "unused" warning
	var _ref = reset_ages
	_ref = test_multiple

## Meant to be used as a replacement for 'emit_signal' in case 'args'
## has to be passed into the function even if no args are expected.
## If 'args' is empty, the helper will and call 'emit_signal' without args.
func emit_signal_helper(signal_name: String, args: Dictionary) -> void:
	if len(args) > 0:
		emit_signal(signal_name, args)
	else:
		emit_signal(signal_name)
