class_name CombineRecipe
extends Resource
## Data for "item A + item B -> result". Order-independent.

@export var input_a: ItemData
@export var input_b: ItemData
@export var result: ItemData


func matches(x: ItemData, y: ItemData) -> bool:
	return (x == input_a and y == input_b) or (x == input_b and y == input_a)
