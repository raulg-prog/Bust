extends Node

signal badge_earned(town_id: int)

const STARTING_BANKROLL := 1000.0
const TOWN_COUNT := 5
const FAME_TARGETS: Array[float] = [5000.0, 25000.0, 100000.0, 400000.0, 1500000.0]
const WHEEL_BASE: Array[float] = [200.0, 1000.0, 5000.0, 25000.0, 100000.0]
const WHEEL_COOLDOWN := 14400.0  # 4 hours in seconds

var bankroll: float = STARTING_BANKROLL
var town_fame: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0]
var badges: Array[bool] = [false, false, false, false, false]
var furthest_town: int = 0
var wheel_last_claimed: float = 0.0
var last_fame_earned: float = 0.0   # resets each time player returns to a town

var return_pos: Vector2    = Vector2.ZERO
var return_active: bool    = false


func add_fame(town_id: int, amount: float) -> void:
	if amount <= 0.0:
		return
	town_fame[town_id] += amount
	last_fame_earned   += amount
	if not badges[town_id] and town_fame[town_id] >= FAME_TARGETS[town_id]:
		badges[town_id] = true
		furthest_town = max(furthest_town, min(town_id + 1, TOWN_COUNT - 1))
		badge_earned.emit(town_id)


func ensure_minimum() -> bool:
	if bankroll < 100.0:
		bankroll = 100.0
		return true
	return false


func badge_count() -> int:
	var count := 0
	for b in badges:
		if b:
			count += 1
	return count


func can_spin_wheel() -> bool:
	return Time.get_unix_time_from_system() - wheel_last_claimed >= WHEEL_COOLDOWN


func wheel_seconds_remaining() -> float:
	return max(0.0, WHEEL_COOLDOWN - (Time.get_unix_time_from_system() - wheel_last_claimed))


func wheel_base_value() -> float:
	return WHEEL_BASE[furthest_town]


func claim_wheel_spin() -> float:
	wheel_last_claimed = Time.get_unix_time_from_system()
	var weights := [40.0, 35.0, 17.4, 5.0, 2.5, 0.1]
	var multipliers := [0.5, 1.0, 2.0, 5.0, 10.0, 50.0]
	var roll := randf() * 100.0
	var cumulative := 0.0
	for i in range(weights.size()):
		cumulative += weights[i]
		if roll <= cumulative:
			return wheel_base_value() * multipliers[i]
	return wheel_base_value()


func reset() -> void:
	bankroll = STARTING_BANKROLL
	town_fame = [0.0, 0.0, 0.0, 0.0, 0.0]
	badges = [false, false, false, false, false]
	furthest_town = 0
	wheel_last_claimed = 0.0
	return_pos    = Vector2.ZERO
	return_active = false
