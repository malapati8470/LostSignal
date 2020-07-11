extends KinematicBody2D

const SPEED = 300
const TILEMAP_SCALE = 2
const TILEMAP_HALF_CELL_SIZE = Vector2(32, 32)

const TILE_DEATH = 0
const TILE_RESET = 1
const TILE_GOAL = 2

const U = 0
const L = 1
const D = 2
const R = 3

var moveState = {}

var inputMap = {
	KEY_W: U,
	KEY_A: L,
	KEY_S: D,
	KEY_D: R,
}

var spawn: Vector2 = Vector2.ZERO
var target: Vector2 = Vector2.ZERO
var isTargetReached: bool = true
var velocity: Vector2 = Vector2.ZERO

var walls: TileMap = null
var interactive: TileMap = null
var lastInteractiveTile: int = TileMap.INVALID_CELL

func resetMovements():
	moveState = {
		U: false,
		L: false,
		D: false,
		R: false,
	}
	target = position
	isTargetReached = true

func _enter_tree():
	resetMovements()
	spawn = position
	
	walls = get_parent().find_node("Walls")
	interactive = get_parent().find_node("Interactive")

func isTileFree(tilePos: Vector2):
	return walls.get_cellv(tilePos) == TileMap.INVALID_CELL
	
func moveToTargetSimple(tileOffset: Vector2):
	var tilePos = walls.world_to_map(position / TILEMAP_SCALE)
	var targetTilePos = tilePos + tileOffset
	if isTileFree(targetTilePos):
		target = walls.map_to_world(targetTilePos) * TILEMAP_SCALE + TILEMAP_HALF_CELL_SIZE

func moveToTargetDiagonal(tileOffset: Vector2):
	var tilePos = walls.world_to_map(position / TILEMAP_SCALE)
	
	# To be able to move straight diagonally,
	# we make sure there is clearance in both axes
	var tileOffsetX = tileOffset
	tileOffsetX.y = 0
	
	var tileOffsetY = tileOffset
	tileOffsetY.x = 0
	
	if not isTileFree(tilePos + tileOffsetX):
		moveToTargetSimple(tileOffsetY)
		return
	
	if not isTileFree(tilePos + tileOffsetY):
		moveToTargetSimple(tileOffsetX)
		return
	
	# Both axes clear, go straignt
	moveToTargetSimple(tileOffset)

func updateTarget():
	var tileOffset = Vector2.ZERO
	if moveState[U]:
		tileOffset.y -= 1
	if moveState[L]:
		tileOffset.x -= 1
	if moveState[D]:
		tileOffset.y += 1
	if moveState[R]:
		tileOffset.x += 1
	
	if tileOffset.x != 0 and tileOffset.y != 0:
		moveToTargetDiagonal(tileOffset)
	else:
		moveToTargetSimple(tileOffset)

func _input(event):
	if event is InputEventKey:
		if event.scancode in inputMap:
			var dir = inputMap[event.scancode]
			moveState[dir] = true

func checkInteractives():
	var tilePos = interactive.world_to_map(position / TILEMAP_SCALE)
	var tileID = interactive.get_cellv(tilePos)
	
	if tileID == lastInteractiveTile:
		return
	
	match tileID:
		TILE_DEATH:
			get_tree().reload_current_scene()
		TILE_RESET:
			resetMovements()
		TILE_GOAL:
			LevelInfo.startNextLevel()
		_:
			return
	
	lastInteractiveTile = tileID

func _physics_process(delta):
	checkInteractives()
	
	if isTargetReached:
		isTargetReached = false
		updateTarget()
	
	var distance = position.distance_to(target)
	velocity = position.direction_to(target) * min(distance, SPEED * delta)
	position += velocity
	
	if position.distance_squared_to(target) < 8:
		isTargetReached = true
