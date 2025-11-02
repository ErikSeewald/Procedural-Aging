extends Node
class_name Profiler

@export var warmup_seconds := 3
@export var measure_interval := 0.1
@export var export_path := "user://"

var _warmup_started := false
var _warmup := 0.0

var _profiling := false
var _frame_data := []
var _measure_timer := 0.0

var _cur_profiling_id: String

signal saved_data

func _process(delta):
	if _profiling:
		_measure_timer += delta
		if _measure_timer > measure_interval:
			_measure_timer = 0
			
			_frame_data.append({
				"frametime": delta, 
				"fps": Performance.get_monitor(Performance.TIME_FPS), 
				"vmem": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED), 
				"bufmem": Performance.get_monitor(Performance.RENDER_BUFFER_MEM_USED), 
				"texmem": Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED),
				"drawcalls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
				"primitives": Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
			})
			if len(_frame_data) > 20:
				save_and_reset()
				
	elif _warmup_started:
		_warmup += delta
		if _warmup > warmup_seconds:
			print("Profiler started!")
			_profiling = true

## Starts the warmup process and subsequently starts profiling in the process loop.
## The given profiling id is used for naming the output file.
func warmup_and_run(profiling_id: String) -> void:
	_cur_profiling_id = profiling_id
	_warmup_started = true

## Saves the profiling data and resets the profiler to be ready for the next run.
func save_and_reset() -> void:
	_profiling = false
	_measure_timer = 0.0	
	_warmup_started = false
	_warmup = 0.0

	save_profile_data()
	_frame_data.clear()

## Saves the profile data in a basic csv at the specified path
func save_profile_data() -> void:
	var path = export_path + _cur_profiling_id + ".csv"
	var file = FileAccess.open(path, FileAccess.WRITE)
	if not file or len(_frame_data) < 1:
		push_error("Failed to save profiling data")
		return
	
	var header = ""
	for n in _frame_data[0].keys():
		header += n + ","
	file.store_line(header)
	
	# AVERAGES
	var line = ""
	for key in _frame_data[0].keys():
		line += "Avg: " + str(_get_average(key)) + ","
	file.store_line(line)
	
	# MEDIAN
	line = ""
	for key in _frame_data[0].keys():
		line += "Med: " + str(_get_median(key)) + ","
	file.store_line(line)
	
	# DATA
	for d in _frame_data:
		line = ""
		for v in d.values():
			line += "%f," % v
		file.store_line(line)
		
	file.close()
	print("Profile data saved to " + path)
	saved_data.emit()

# Returns the average value for the given key in the current frame data
func _get_average(key: String) -> float:
	var v = 0.0
	for entry in _frame_data:
		v += entry[key]
	return v / len(_frame_data)

# Returns the median value for the given key in the current frame data
func _get_median(key: String) -> float:
	var s = []
	for entry in _frame_data:
		s.append(entry[key])
	s.sort()

	return s[int(len(s) / 2.0)]
