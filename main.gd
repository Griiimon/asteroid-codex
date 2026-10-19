extends Node2D

const FIELD := Vector2(960.0, 640.0)
const SHIP_RADIUS := 12.0
const BULLET_SPEED := 440.0
const BULLET_LIFETIME := 1.15
const ROCK_RADII := {3: 44.0, 2: 27.0, 1: 15.0}
const ROCK_POINTS := {3: 20, 2: 50, 1: 100}
const WHITE := Color(0.91, 0.94, 1.0)

var rng := RandomNumberGenerator.new()
var state := "title"
var score := 0
var lives := 3
var wave := 1
var ship_position := FIELD * 0.5
var ship_velocity := Vector2.ZERO
var ship_angle := -PI * 0.5
var invulnerable := 0.0
var fire_cooldown := 0.0
var rocks: Array[Dictionary] = []
var bullets: Array[Dictionary] = []
var font: Font


func _ready() -> void:
	rng.randomize()
	font = ThemeDB.fallback_font
	set_process(true)


func _process(delta: float) -> void:
	if state == "playing":
		_update_game(delta)
	queue_redraw()


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
		if state != "playing":
			_start_game()
		return
	if state == "playing" and event.keycode == KEY_SPACE:
		_fire()


func _start_game() -> void:
	score = 0
	lives = 3
	wave = 1
	bullets.clear()
	rocks.clear()
	_reset_ship()
	_spawn_wave()
	state = "playing"


func _reset_ship() -> void:
	ship_position = FIELD * 0.5
	ship_velocity = Vector2.ZERO
	ship_angle = -PI * 0.5
	invulnerable = 2.0


func _spawn_wave() -> void:
	var count := 4 + wave
	for i in range(count):
		var p := Vector2(rng.randf_range(0, FIELD.x), rng.randf_range(0, FIELD.y))
		var attempts := 0
		while p.distance_to(ship_position) < 150.0 and attempts < 30:
			p = Vector2(rng.randf_range(0, FIELD.x), rng.randf_range(0, FIELD.y))
			attempts += 1
		_add_rock(p, 3)


func _add_rock(position: Vector2, size: int) -> void:
	var radius: float = ROCK_RADII[size]
	var vertices := PackedVector2Array()
	var sides := rng.randi_range(9, 13)
	for i in range(sides):
		var angle := TAU * float(i) / float(sides)
		var scale := rng.randf_range(0.78, 1.18)
		vertices.append(Vector2.from_angle(angle) * radius * scale)
	var speed := rng.randf_range(25.0, 70.0) + wave * 2.5
	var direction := Vector2.from_angle(rng.randf_range(0, TAU))
	rocks.append({"position": _wrap(position), "velocity": direction * speed, "size": size, "vertices": vertices, "spin": rng.randf_range(-1.0, 1.0), "rotation": rng.randf_range(0, TAU)})


func _update_game(delta: float) -> void:
	invulnerable = maxf(0.0, invulnerable - delta)
	fire_cooldown = maxf(0.0, fire_cooldown - delta)
	if Input.is_key_pressed(KEY_LEFT):
		ship_angle -= 3.8 * delta
	if Input.is_key_pressed(KEY_RIGHT):
		ship_angle += 3.8 * delta
	if Input.is_key_pressed(KEY_UP):
		ship_velocity += Vector2.from_angle(ship_angle) * 250.0 * delta
	ship_velocity = ship_velocity.limit_length(300.0)
	ship_position = _wrap(ship_position + ship_velocity * delta)
	ship_velocity *= pow(0.985, delta * 60.0)
	if Input.is_key_pressed(KEY_SPACE):
		_fire()

	for i in range(bullets.size() - 1, -1, -1):
		var bullet: Dictionary = bullets[i]
		bullet.position = _wrap(bullet.position + bullet.velocity * delta)
		bullet.life -= delta
		if bullet.life <= 0.0:
			bullets.remove_at(i)

	for rock in rocks:
		rock.position = _wrap(rock.position + rock.velocity * delta)
		rock.rotation += rock.spin * delta

	for bi in range(bullets.size() - 1, -1, -1):
		if bi >= bullets.size():
			continue
		var bullet: Dictionary = bullets[bi]
		var hit_index := -1
		for ri in range(rocks.size()):
			var rock: Dictionary = rocks[ri]
			if _wrapped_distance(bullet.position, rock.position) < float(ROCK_RADII[rock.size]) + 3.0:
				hit_index = ri
				break
		if hit_index >= 0:
			var hit: Dictionary = rocks[hit_index]
			var hit_pos: Vector2 = hit.position
			var hit_size: int = hit.size
			score += ROCK_POINTS[hit_size]
			bullets.remove_at(bi)
			rocks.remove_at(hit_index)
			if hit_size > 1:
				for child in range(2):
					_add_rock(hit_pos + Vector2.from_angle(rng.randf_range(0, TAU)) * 8.0, hit_size - 1)

	if invulnerable <= 0.0:
		for rock in rocks:
			if _wrapped_distance(ship_position, rock.position) < float(ROCK_RADII[rock.size]) + SHIP_RADIUS:
				lives -= 1
				if lives <= 0:
					state = "game_over"
				else:
					_reset_ship()
				break
	if state == "playing" and rocks.is_empty():
		wave += 1
		_spawn_wave()


func _fire() -> void:
	if state != "playing" or fire_cooldown > 0.0:
		return
	var direction := Vector2.from_angle(ship_angle)
	bullets.append({"position": _wrap(ship_position + direction * 15.0), "velocity": direction * BULLET_SPEED + ship_velocity * 0.25, "life": BULLET_LIFETIME})
	fire_cooldown = 0.19


func _wrap(position: Vector2) -> Vector2:
	return Vector2(fposmod(position.x, FIELD.x), fposmod(position.y, FIELD.y))


func _wrapped_distance(a: Vector2, b: Vector2) -> float:
	var dx := absf(a.x - b.x)
	var dy := absf(a.y - b.y)
	dx = minf(dx, FIELD.x - dx)
	dy = minf(dy, FIELD.y - dy)
	return Vector2(dx, dy).length()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, FIELD), Color.BLACK, true)
	if state == "title":
		_draw_centered("ASTEROIDS", 68, 250, WHITE)
		_draw_centered("ARCADE FIELD", 20, 292, Color(0.55, 0.62, 0.76))
		_draw_centered("LEFT / RIGHT  TURN     UP  THRUST     SPACE  FIRE", 17, 390, WHITE)
		_draw_centered("PRESS ENTER TO START", 22, 462, WHITE)
		_draw_ship(FIELD * 0.5 + Vector2(0, -45), -PI * 0.5, WHITE)
		return

	for rock in rocks:
		_draw_wrapped_rock(rock)
	for bullet in bullets:
		_draw_wrapped_circle(bullet.position, 2.5, WHITE)
	if invulnerable <= 0.0 or int(Time.get_ticks_msec() / 120) % 2 == 0:
		_draw_wrapped_ship()
	_draw_hud()
	if state == "game_over":
		draw_rect(Rect2(Vector2.ZERO, FIELD), Color(0, 0, 0, 0.7), true)
		_draw_centered("GAME OVER", 54, 270, WHITE)
		_draw_centered("FINAL SCORE  %06d" % score, 22, 324, WHITE)
		_draw_centered("PRESS ENTER TO PLAY AGAIN", 20, 382, WHITE)


func _draw_hud() -> void:
	draw_string(font, Vector2(28, 38), "SCORE  %06d" % score, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, WHITE)
	draw_string(font, Vector2(28, 68), "WAVE  %02d" % wave, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.65, 0.73, 0.88))
	draw_string(font, Vector2(FIELD.x - 28, 38), "LIVES  %d" % lives, HORIZONTAL_ALIGNMENT_RIGHT, -1, 20, WHITE)


func _draw_centered(text: String, size: int, y: float, color: Color) -> void:
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	draw_string(font, Vector2((FIELD.x - width) * 0.5, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


func _draw_ship(position: Vector2, angle: float, color: Color) -> void:
	var forward := Vector2.from_angle(angle)
	var side := forward.rotated(PI * 0.5)
	var points := PackedVector2Array([position + forward * 15.0, position - forward * 10.0 + side * 10.0, position - forward * 6.0, position - forward * 10.0 - side * 10.0])
	draw_polyline(points, color, 1.8, true)
	draw_line(points[3], points[0], color, 1.8, true)


func _draw_wrapped_ship() -> void:
	for offset in _nearby_offsets(ship_position, 20.0):
		_draw_ship(ship_position + offset, ship_angle, WHITE)


func _draw_wrapped_rock(rock: Dictionary) -> void:
	var points := PackedVector2Array()
	for vertex in rock.vertices:
		points.append(rock.position + vertex.rotated(rock.rotation))
	points.append(points[0])
	for offset in _nearby_offsets(rock.position, float(ROCK_RADII[rock.size]) + 2.0):
		var shifted := PackedVector2Array()
		for point in points:
			shifted.append(point + offset)
		draw_polyline(shifted, WHITE, 1.35, true)


func _draw_wrapped_circle(position: Vector2, radius: float, color: Color) -> void:
	for offset in _nearby_offsets(position, radius):
		draw_circle(position + offset, radius, color)


func _nearby_offsets(position: Vector2, margin: float) -> Array[Vector2]:
	var xs: Array[float] = [0.0]
	var ys: Array[float] = [0.0]
	if position.x < margin:
		xs.append(FIELD.x)
	if position.x > FIELD.x - margin:
		xs.append(-FIELD.x)
	if position.y < margin:
		ys.append(FIELD.y)
	if position.y > FIELD.y - margin:
		ys.append(-FIELD.y)
	var offsets: Array[Vector2] = []
	for x in xs:
		for y in ys:
			offsets.append(Vector2(x, y))
	return offsets
