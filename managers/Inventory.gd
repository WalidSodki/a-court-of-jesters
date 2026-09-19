extends Node
## The player's items. Autoloaded so it persists across scenes and can be
## folded into the save system later (it ties into GameState).

signal changed
signal item_added(item: ItemData)
signal combined(result: ItemData)

# Recipes are data. Add a .tres and list it here (or scan a folder later).
const RECIPE_PATHS := [
	"res://items/recipe_baton.tres",
]

var items: Array[ItemData] = []
## The item currently selected to "use" on a world object (null = none).
var held_item: ItemData

var _recipes: Array[CombineRecipe] = []


func _ready() -> void:
	for path in RECIPE_PATHS:
		var r := load(path) as CombineRecipe
		if r != null:
			_recipes.append(r)


func add(item: ItemData) -> void:
	if item == null or has(item):
		return
	items.append(item)
	item_added.emit(item)
	changed.emit()


func remove(item: ItemData) -> void:
	items.erase(item)
	if held_item == item:
		held_item = null
	changed.emit()


func has(item: ItemData) -> bool:
	return items.has(item)


func has_id(id: StringName) -> bool:
	for it in items:
		if it.id == id:
			return true
	return false


func set_held(item: ItemData) -> void:
	held_item = item
	changed.emit()


## Attempts to combine two items. Returns the result item, or null if no recipe.
func combine(a: ItemData, b: ItemData) -> ItemData:
	if a == null or b == null or a == b:
		return null
	for r in _recipes:
		if r.matches(a, b):
			remove(a)
			remove(b)
			add(r.result)
			combined.emit(r.result)
			return r.result
	return null
