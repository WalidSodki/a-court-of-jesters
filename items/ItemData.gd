class_name ItemData
extends Resource
## A single inventory item, defined as data so designers add items without code.

@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
## Optional explicit texture (final art). If null, icon_index slices the sheet.
@export var icon: Texture2D
## Placeholder icon: index into the Kenney sheet (see Art.gd).
@export var icon_index: int = 0
## Whether this item can be used as an input to a combine recipe.
@export var combinable: bool = false


func get_icon() -> Texture2D:
	return icon if icon != null else Art.tile(icon_index)
