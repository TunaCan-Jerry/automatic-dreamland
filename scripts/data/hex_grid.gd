class_name HexGrid
extends RefCounted

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

const HEX_SIZE := 32.0
const SQRT3 := 1.7320508

# Axial direction vectors for pointy-top hexes (E, NE, NW, W, SW, SE)
const DIRECTIONS: Array[Vector2i] = [
	Vector2i(1, 0),
	Vector2i(1, -1),
	Vector2i(0, -1),
	Vector2i(-1, 0),
	Vector2i(-1, 1),
	Vector2i(0, 1),
]

# ---------------------------------------------------------------------------
# Enums
# ---------------------------------------------------------------------------

enum Zone { ALLY, NEUTRAL, ENEMY }

# ---------------------------------------------------------------------------
# Properties
# ---------------------------------------------------------------------------

## Maps Vector2i axial coord -> { "occupied": bool, "occupant": Variant }
var tiles: Dictionary = {}

## Maps Vector2i axial coord -> Zone enum value
var tile_zones: Dictionary = {}

# ---------------------------------------------------------------------------
# Hex Math
# ---------------------------------------------------------------------------

## Convert axial coordinates to pixel position (pointy-top orientation).
func axial_to_pixel(hex: Vector2i) -> Vector2:
	var q := float(hex.x)
	var r := float(hex.y)
	var x := HEX_SIZE * (SQRT3 * q + SQRT3 / 2.0 * r)
	var y := HEX_SIZE * (3.0 / 2.0 * r)
	return Vector2(x, y)


## Convert a pixel position back to axial coordinates (rounded to nearest hex).
func pixel_to_axial(pixel: Vector2) -> Vector2i:
	var q := (SQRT3 / 3.0 * pixel.x - 1.0 / 3.0 * pixel.y) / HEX_SIZE
	var r := (2.0 / 3.0 * pixel.y) / HEX_SIZE
	return axial_round(Vector2(q, r))


## Round fractional axial coordinates to the nearest integer hex using
## cube-coordinate rounding to avoid drift artifacts.
func axial_round(frac: Vector2) -> Vector2i:
	var s_frac := -frac.x - frac.y

	var q := roundi(frac.x)
	var r := roundi(frac.y)
	var s := roundi(s_frac)

	var q_diff := absf(float(q) - frac.x)
	var r_diff := absf(float(r) - frac.y)
	var s_diff := absf(float(s) - s_frac)

	if q_diff > r_diff and q_diff > s_diff:
		q = -r - s
	elif r_diff > s_diff:
		r = -q - s

	return Vector2i(q, r)


## Hex Manhattan (cube) distance between two axial coordinates.
func hex_distance(a: Vector2i, b: Vector2i) -> int:
	var dq := b.x - a.x
	var dr := b.y - a.y
	return (abs(dq) + abs(dq + dr) + abs(dr)) / 2


## Return all 6 neighbors of hex that actually exist in the grid.
func get_neighbors(hex: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for dir in DIRECTIONS:
		var neighbor := hex + dir
		if tiles.has(neighbor):
			result.append(neighbor)
	return result

# ---------------------------------------------------------------------------
# Grid Creation
# ---------------------------------------------------------------------------

## Build the MVP battlefield with ally, neutral, and enemy zones.
func create_battle_grid() -> void:
	tiles.clear()
	tile_zones.clear()

	# Ally cluster: radius-2 around (-3, 0)
	_create_hex_cluster(Vector2i(-3, 0), 2, Zone.ALLY)

	# Enemy cluster: radius-2 around (3, 0)
	_create_hex_cluster(Vector2i(3, 0), 2, Zone.ENEMY)

	# Neutral zone: columns q = -1, 0, 1 for r in [-2, 2]
	for q in [-1, 0, 1]:
		for r in range(-2, 3):
			var hex := Vector2i(q, r)
			if not tiles.has(hex):
				tiles[hex] = {&"occupied": false, &"occupant": null}
			tile_zones[hex] = Zone.NEUTRAL


## Create a filled hex cluster of the given radius around center, assigning zone.
func _create_hex_cluster(center: Vector2i, radius: int, zone: Zone) -> void:
	for dq in range(-radius, radius + 1):
		for dr in range(-radius, radius + 1):
			var ds := -dq - dr
			if abs(dq) <= radius and abs(dr) <= radius and abs(ds) <= radius:
				var hex := center + Vector2i(dq, dr)
				tiles[hex] = {&"occupied": false, &"occupant": null}
				tile_zones[hex] = zone


## Return all tile coordinates assigned to the ally zone.
func get_ally_zone() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for hex in tile_zones:
		if tile_zones[hex] == Zone.ALLY:
			result.append(hex)
	return result


## Return all tile coordinates assigned to the enemy zone.
func get_enemy_zone() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for hex in tile_zones:
		if tile_zones[hex] == Zone.ENEMY:
			result.append(hex)
	return result


## Return all grid tiles within hex_range steps of center (inclusive).
func get_hexes_in_range(center: Vector2i, hex_range: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for hex in tiles:
		if hex_distance(center, hex) <= hex_range:
			result.append(hex)
	return result

# ---------------------------------------------------------------------------
# Occupancy
# ---------------------------------------------------------------------------

## Return true if the tile at hex is currently occupied.
func is_occupied(hex: Vector2i) -> bool:
	if not tiles.has(hex):
		return false
	return tiles[hex][&"occupied"]


## Place a combatant on the given tile, marking it occupied.
func place_combatant(hex: Vector2i, combatant: Variant) -> void:
	if not tiles.has(hex):
		push_warning("HexGrid.place_combatant: hex %s is not in the grid." % hex)
		return
	tiles[hex][&"occupied"] = true
	tiles[hex][&"occupant"] = combatant


## Remove the combatant from the given tile, marking it unoccupied.
func remove_combatant(hex: Vector2i) -> void:
	if not tiles.has(hex):
		push_warning("HexGrid.remove_combatant: hex %s is not in the grid." % hex)
		return
	tiles[hex][&"occupied"] = false
	tiles[hex][&"occupant"] = null

# ---------------------------------------------------------------------------
# Pathfinding (A*)
# ---------------------------------------------------------------------------

## Find the shortest path from start to end using A*.
## Occupied tiles are treated as impassable except for the destination.
## Returns an empty array when no path exists.
func find_path(start: Vector2i, end: Vector2i) -> Array[Vector2i]:
	if not tiles.has(start) or not tiles.has(end):
		return []

	var open_set: Array[Vector2i] = [start]

	# came_from maps Vector2i -> Vector2i
	var came_from: Dictionary = {}

	var g_score: Dictionary = { start: 0 }
	var f_score: Dictionary = { start: hex_distance(start, end) }

	while not open_set.is_empty():
		var current: Vector2i = _lowest_f(open_set, f_score)

		if current == end:
			return _reconstruct_path(came_from, current)

		open_set.erase(current)

		for neighbor in get_neighbors(current):
			# Skip occupied tiles unless it is the destination
			if neighbor != end and is_occupied(neighbor):
				continue

			var tentative_g: int = g_score.get(current, INF) + 1

			if tentative_g < g_score.get(neighbor, INF):
				came_from[neighbor] = current
				g_score[neighbor] = tentative_g
				f_score[neighbor] = tentative_g + hex_distance(neighbor, end)
				if not open_set.has(neighbor):
					open_set.append(neighbor)

	# No path found
	return []


## Return the node in open_set with the lowest f_score.
func _lowest_f(open_set: Array[Vector2i], f_score: Dictionary) -> Vector2i:
	var best: Vector2i = open_set[0]
	var best_f: float = f_score.get(best, INF)
	for node in open_set:
		var node_f: float = f_score.get(node, INF)
		if node_f < best_f:
			best = node
			best_f = node_f
	return best


## Reconstruct the path by walking came_from back from current to start.
func _reconstruct_path(came_from: Dictionary, current: Vector2i) -> Array[Vector2i]:
	var path: Array[Vector2i] = [current]
	while came_from.has(current):
		current = came_from[current]
		path.push_front(current)
	return path
