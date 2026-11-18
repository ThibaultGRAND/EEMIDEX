extends CharacterBody2D
## Personnage jouable : déplacement 8 directions, Maj pour aller plus vite.

const DIRECTIONS := ["right", "down_right", "down", "down_left", "left", "up_left", "up", "up_right"]

@export var speed: float = 140.0
@export var run_speed: float = 240.0
## Seul le personnage contrôlé réagit au clavier (et porte la caméra active).
@export var controllable: bool = true:
	set(value):
		controllable = value
		if is_node_ready():
			$Camera2D.enabled = value

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var facing := "down"


func _ready() -> void:
	$Camera2D.enabled = controllable
	sprite.play("idle_down")


func _physics_process(_delta: float) -> void:
	var dir := Vector2.ZERO
	if controllable:
		dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var running := Input.is_key_pressed(KEY_SHIFT)
	velocity = dir * (run_speed if running else speed)
	move_and_slide()

	if dir == Vector2.ZERO:
		sprite.speed_scale = 1.0
		sprite.play("idle_" + facing)
		return

	# Angle -> secteur de 45° (0 = droite, sens horaire car l'axe Y descend).
	var sector := wrapi(roundi(dir.angle() / (PI / 4.0)), 0, 8)
	facing = DIRECTIONS[sector]
	# Pas d'animation de course dans la planche : on accélère la marche.
	sprite.speed_scale = run_speed / speed if running else 1.0
	sprite.play("walk_" + facing)
