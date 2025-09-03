## Autoload for managing compute shader memory.

extends Node

var _pending_rids: Array[RID] = []

## Allows nodes that are being deleted to schedule the freeing of the
## given RIDs for the next _process() iteration. 
## This ensures that all async compute calls by the now deleted nodes are finished
## before the memory is freed.
func defer_free(rids: Array[RID]) -> void:
	_pending_rids.append_array(rids)
	
func _rid_cleanup() -> void:
	var rd := RenderingServer.get_rendering_device()
	for rid in _pending_rids:
		rd.free_rid(rid)
	_pending_rids.clear()	
	
func _process(_delta: float) -> void:
	if !_pending_rids.is_empty():
		_rid_cleanup()
