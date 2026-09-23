class_name DialogueCondition
extends Resource
## A small, data-described test over game state. All specified checks must pass
## (logical AND); leave a field empty to ignore it. For OR, author separate
## nodes/choices. Reused by dialogue nodes, choices, and (later) examine spots
## and interactable gating — one condition model, queried everywhere.

## Flags that must be truthy (GameState.has_flag).
@export var flags_set: Array[StringName] = []
## Flags that must be falsy/absent.
@export var flags_unset: Array[StringName] = []
## Exact flag values required, e.g. {"performance_tier": "great"}.
@export var flag_equals: Dictionary = {}
## Item ids the player must be carrying (Inventory.has_id).
@export var has_items: Array[StringName] = []
## Clue ids the player must have discovered (Clues.has).
@export var has_clues: Array[StringName] = []


func passes() -> bool:
	for f in flags_set:
		if not GameState.has_flag(String(f)):
			return false
	for f in flags_unset:
		if GameState.has_flag(String(f)):
			return false
	for key in flag_equals:
		if GameState.get_flag(String(key)) != flag_equals[key]:
			return false
	for id in has_items:
		if not Inventory.has_id(id):
			return false
	for id in has_clues:
		if not Clues.has(id):
			return false
	return true
