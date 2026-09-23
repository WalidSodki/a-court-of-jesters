class_name ConversationData
extends Resource
## A data-authored conversation: an ordered graph of DialogueNodes walked by the
## Dialogue manager. Conditions gate nodes/choices, effects write game state, and
## `goto` links branches — so writers author branching, reactive dialogue in the
## inspector without touching code.

## Namespaces the "seen/<id>/<node>" flags used by `once` nodes; keep it unique.
@export var id: StringName = &""
@export var nodes: Array[DialogueNode] = []


func find_index(node_id: StringName) -> int:
	for i in nodes.size():
		if nodes[i].id == node_id:
			return i
	return -1
