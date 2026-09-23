class_name ClueData
extends Resource
## A single piece of knowledge the player has learned, defined as data so
## writers add clues without code. Mirrors ItemData: discovered clues live in
## the Clues autoload and surface in the Journal screen.

@export var id: StringName = &""
@export var title: String = ""
@export_multiline var description: String = ""
## Free-text grouping shown in the journal (e.g. "People", "The Court", "Signs").
@export var category: String = ""
## Optional explicit texture (final art). If null, icon_index slices the sheet.
@export var icon: Texture2D
## Placeholder icon: index into the Kenney sheet (see Art.gd).
@export var icon_index: int = 0
## Whether this clue can be fed into a deduction (clue + clue -> new clue).
@export var combinable: bool = false


func get_icon() -> Texture2D:
	return icon if icon != null else Art.tile(icon_index)
