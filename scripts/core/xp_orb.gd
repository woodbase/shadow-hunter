## XPOrb — a collectible XP token dropped by defeated enemies.
##
## Spawn at the enemy's position and set [member xp_amount] before adding to the scene tree.
## Any physics body in the [code]"player"[/code] group that exposes [method add_xp] will
## automatically collect the orb on contact, receive the XP, and cause the orb to disappear.
class_name XPOrb
extends Area2D

## XP granted to the collecting player.
var xp_amount: int = 10

@onready var _visual: Polygon2D = $Visual

var _float_tween: Tween = null
var _collected: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_start_float_animation()


func _on_body_entered(body: Node2D) -> void:
	if _collected:
		return
	if not body.is_in_group("player"):
		return
	if not body.has_method("add_xp"):
		return
	_collected = true
	body.add_xp(xp_amount)
	_collect()


## Animate a brief pop then remove the orb from the scene.
func _collect() -> void:
	set_deferred("monitoring", false)
	if _float_tween != null:
		_float_tween.kill()
		_float_tween = null
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_visual, "scale", Vector2(1.6, 1.6), 0.12)
	tween.tween_property(_visual, "modulate:a", 0.0, 0.12)
	await tween.finished
	queue_free()


func _start_float_animation() -> void:
	_float_tween = create_tween()
	_float_tween.set_loops()
	_float_tween.tween_property(_visual, "position:y", -5.0, 0.55).set_trans(Tween.TRANS_SINE)
	_float_tween.tween_property(_visual, "position:y", 5.0, 0.55).set_trans(Tween.TRANS_SINE)
