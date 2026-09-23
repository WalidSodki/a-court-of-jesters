class_name DialogueNode
extends Resource
## One beat in a conversation graph: a spoken/narration line, a branch point, or
## a pure side-effect step. Nodes live in an ordered array on ConversationData;
## flow falls through in order unless a `goto` (or a chosen option) jumps away.

## Referenced by `goto` from other nodes/choices. Required for `once` nodes.
@export var id: StringName = &""
@export var speaker: String = ""
@export_multiline var text: String = ""
## Skipped when this fails (null = always shown), e.g. a return-visit greeting.
@export var condition: DialogueCondition
## Applied the moment this node is reached.
@export var effect: DialogueEffect
## Options presented on this node. Those whose condition fails are hidden.
@export var choices: Array[DialogueChoice] = []
## Play at most once ever (tracked in GameState via a "seen/…" flag).
@export var once: bool = false
## Where to go after this node. Empty = next in array; &"end" = end talk.
@export var goto: StringName = &""
