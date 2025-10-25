extends Node

@export var warmup_seconds := 30000
@export var measure_interval := 0.1
@export var export_path := "user://profile_data.csv"

var frame_data := []
var profiling := false
var warmup := 0.0
var measure_timer := 0.0

func _exit_tree():
	save_profile_data()

func _process(delta):
	if profiling:
		measure_timer += delta
		if measure_timer > measure_interval:
			measure_timer = 0
			
			frame_data.append({
				"frametime": delta, 
				"fps": Performance.get_monitor(Performance.TIME_FPS), 
				"vmem": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED), 
				"bufmem": Performance.get_monitor(Performance.RENDER_BUFFER_MEM_USED), 
				"texmem": Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED),
				"drawcalls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
				"primitives": Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
			})
	else:
		warmup += delta
		if warmup > warmup_seconds:
			print("Profiler started!")
			profiling = true
	
	if Input.is_action_pressed("save_and_export"):
		queue_free()

## Saves the profile data in a basic csv at the specified path
func save_profile_data():
	var file = FileAccess.open(export_path, FileAccess.WRITE)
	if file and len(frame_data) > 0:
		var header = ""
		for n in frame_data[0].keys():
			header += n + ","
		file.store_line(header)
		
		for d in frame_data:
			var line = ""
			for v in d.values():
				line += "%f," % v
			file.store_line(line)
			
		file.close()
		print("Profile data saved to " + export_path)
