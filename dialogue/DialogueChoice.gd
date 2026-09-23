class_name DialogueChoice
extends Resource
## One selectable option on a dialogue node. Hidden entirely when its condition
## fails (e.g. a clue-gated question the player can't yet ask). Picking it runs
## its effect, then jumps to `goto` (empty = continue after the choice node).

@export var text: String = ""
## Only offered when this passes (null = always available).
@export var condition: DialogueCondition
## Applied when this choice is picked.
@export var effect: DialogueEffect
## Node id to jump to after picking. Empty = fall through; &"end" = end talk.
@export var goto: StringName = &""
