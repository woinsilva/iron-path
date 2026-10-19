class_name StatusComponent extends Node

enum EffectType { NONE, SLOW, POISON, BLEED }

class StatusEffect:
	var type: EffectType
	var source_id: int
	var power: float
	var duration: float
	var max_duration: float

var effects: Array[StatusEffect] = []
var tick_accumulator: float = 0.0
@onready var health_component: HealthComponent = $"../HealthComponent"
@onready var movement_component: MovementComponent = $"../MovementComponent"

func _process(delta: float) -> void:
	tick_accumulator += delta
	var should_tick = tick_accumulator >= 0.5
	if should_tick:
		tick_accumulator -= 0.5
		
	# Process effects
	var to_remove = []
	var max_slow = 0.0
	
	for effect in effects:
		effect.duration -= delta
		if effect.duration <= 0:
			to_remove.append(effect)
			continue
			
		if effect.type == EffectType.SLOW:
			if effect.power > max_slow:
				max_slow = effect.power
				
		elif effect.type == EffectType.POISON and should_tick:
			# Dano puro, 1 tick a cada 0.5s = power / 2 por tick
			health_component.take_damage(effect.power * 0.5, 2)
			
		elif effect.type == EffectType.BLEED and should_tick:
			var dmg = effect.power * 0.5
			if movement_component and movement_component.is_moving:
				dmg *= 1.25
			health_component.take_damage(dmg, 2)
			
	for e in to_remove:
		effects.erase(e)
		
	# Apply slow
	if movement_component:
		movement_component.current_slow = max_slow

func apply_effect(type: EffectType, power: float, duration: float, source_id: int) -> void:
	# Check for existing effect from same source
	var existing = null
	var effect_count = 0
	
	for e in effects:
		if e.type == type:
			effect_count += 1
			if e.source_id == source_id:
				existing = e
				
	if existing:
		existing.power = power
		existing.duration = duration
		existing.max_duration = duration
		return
		
	# If different source, check stack limit for DoTs
	if type in [EffectType.POISON, EffectType.BLEED]:
		if effect_count >= 3:
			# Replace the weakest or shortest? Specification says up to 3 stacks from different sources.
			# Let's just ignore if already at max stacks for simplicity, or replace weakest.
			# MVP: ignore if we already have 3.
			return
			
	var eff = StatusEffect.new()
	eff.type = type
	eff.power = power
	eff.duration = duration
	eff.max_duration = duration
	eff.source_id = source_id
	effects.append(eff)
