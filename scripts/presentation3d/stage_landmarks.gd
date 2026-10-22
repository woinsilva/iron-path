class_name StageLandmarksV2 extends Node3D
var show_mill: bool = true
var orchard_enabled: bool = false
var guard_gate_enabled: bool = false
var quarry_enabled: bool = false
var fortress_enabled: bool = false
var forge_enabled: bool = false
var rotor: Node3D
var entrance: Vector3 = Vector3(-18.4, 0, -7)
var endpoint: Vector3 = Vector3(1, 0, 1)
func _ready() -> void:
	if forge_enabled: _build_forge()
	if fortress_enabled: _build_fortress()
	if quarry_enabled: _build_quarry()
	if orchard_enabled: _build_orchard()
	if guard_gate_enabled: _build_guard_gate()
	var stone: StandardMaterial3D = SceneCraft3D.material(Color("c5bba2"))
	var wood: StandardMaterial3D = SceneCraft3D.material(Color("77583b"))
	var roof: StandardMaterial3D = SceneCraft3D.material(Color("995b43"))
	var cloth: StandardMaterial3D = SceneCraft3D.material(Color("e5d6ae"))
	var mill: Node3D = Node3D.new()
	mill.position = endpoint + Vector3(2.1, 0.1, -0.5)
	add_child(mill)
	SceneCraft3D.cylinder(mill, 1.15, 0.35, Vector3(0, 0.17, 0), stone, 12)
	var body: CylinderMesh = CylinderMesh.new()
	body.top_radius = 0.72
	body.bottom_radius = 1.0
	body.height = 3.4
	body.radial_segments = 12
	SceneCraft3D.mesh(mill, body, Vector3(0, 1.95, 0), stone)
	var cap: CylinderMesh = CylinderMesh.new()
	cap.top_radius = 0.0
	cap.bottom_radius = 1.15
	cap.height = 1.5
	cap.radial_segments = 12
	SceneCraft3D.mesh(mill, cap, Vector3(0, 4.3, 0), roof)
	for y: float in [1.1, 2.4, 3.5]:
		SceneCraft3D.cylinder(mill, 1.01 - y * 0.07, 0.1, Vector3(0, y, 0), wood, 12)
	SceneCraft3D.box(mill, Vector3(0.6, 1.05, 0.12), Vector3(0, 0.87, 1.0), wood)
	rotor = Node3D.new()
	rotor.position = Vector3(0, 3.3, 1.04)
	mill.add_child(rotor)
	for index in range(4):
		var blade: Node3D = Node3D.new()
		blade.rotation.z = index * PI * 0.5
		rotor.add_child(blade)
		SceneCraft3D.box(blade, Vector3(0.09, 2.2, 0.12), Vector3(0, 1.1, 0), wood)
		SceneCraft3D.box(blade, Vector3(0.42, 1.2, 0.07), Vector3(0.21, 1.5, 0.01), cloth)
		for rung in range(4):
			SceneCraft3D.box(blade, Vector3(0.48, 0.045, 0.12), Vector3(0.2, 0.95 + rung * 0.35, 0.04), wood)
	SceneCraft3D.sphere(rotor, 0.22, Vector3.ZERO, wood)
	mill.visible = show_mill
	var entry: Node3D = Node3D.new()
	entry.position = entrance + Vector3(0, 0.1, 0)
	add_child(entry)
	for z: float in [-1.6, 1.6]:
		SceneCraft3D.box(entry, Vector3(0.28, 2.2, 0.28), Vector3(0, 1.1, z), wood)
	SceneCraft3D.box(entry, Vector3(0.3, 0.3, 3.6), Vector3(0, 2.3, 0), wood)
	SceneCraft3D.box(entry, Vector3(0.12, 0.8, 0.5), Vector3(0, 1.8, 0.8), SceneCraft3D.material(Color("a6473b")))
	var goal: Node3D = Node3D.new()
	goal.position = endpoint + Vector3(0, 0.15, 0)
	add_child(goal)
	SceneCraft3D.cylinder(goal, 0.75, 0.12, Vector3.ZERO, stone, 16)
	SceneCraft3D.cylinder(goal, 0.06, 2.3, Vector3(0, 1.15, 0), wood, 8)
	SceneCraft3D.box(goal, Vector3(0.7, 0.55, 0.07), Vector3(0.35, 2.0, 0), SceneCraft3D.material(Color("358f94")))
func _process(delta: float) -> void:
	rotor.rotation.z -= delta * 0.38

func _build_orchard() -> void:
	var bark: StandardMaterial3D = SceneCraft3D.material(Color("785638"))
	var leaves: StandardMaterial3D = SceneCraft3D.material(Color("68864a"))
	var fruit: StandardMaterial3D = SceneCraft3D.material(Color("c35e42"))
	for x: float in [-18, -15.5]:
		for z: float in [-2.5, 0, 2.5]:
			var tree: Node3D = Node3D.new()
			tree.position = Vector3(x, 0.1, z)
			add_child(tree)
			SceneCraft3D.cylinder(tree, 0.13, 1.4, Vector3(0, 0.7, 0), bark, 8)
			var crown: MeshInstance3D = SceneCraft3D.sphere(tree, 0.72, Vector3(0, 1.65, 0), leaves)
			crown.scale.y = 0.85
			for index in range(5):
				var angle: float = index * TAU / 5
				SceneCraft3D.sphere(tree, 0.12, Vector3(sin(angle) * 0.6, 1.4 + (index % 2) * 0.25, cos(angle) * 0.6), fruit)
	for z: float in [-4, 4]:
		for x: float in [-19, -16.5, -14.3]:
			SceneCraft3D.box(self, Vector3(0.12, 0.8, 0.12), Vector3(x, 0.4, z), bark)
		for y: float in [0.3, 0.65]:
			SceneCraft3D.box(self, Vector3(4.8, 0.1, 0.1), Vector3(-16.6, y, z), bark)

func _build_guard_gate() -> void:
	var gate: Node3D = Node3D.new()
	gate.position = endpoint + Vector3(2.8, 0.1, 0)
	add_child(gate)
	var stone: StandardMaterial3D = SceneCraft3D.material(Color("a3a48f"))
	var roof: StandardMaterial3D = SceneCraft3D.material(Color("506c76"))
	var wood: StandardMaterial3D = SceneCraft3D.material(Color("72543b"))
	for side: float in [-1, 1]:
		SceneCraft3D.cylinder(gate, 0.66, 3.0, Vector3(0, 1.5, side * 1.65), stone, 8)
		SceneCraft3D.cylinder(gate, 0.78, 0.25, Vector3(0, 3.0, side * 1.65), stone, 8)
		var cap: CylinderMesh = CylinderMesh.new()
		cap.top_radius = 0
		cap.bottom_radius = 0.85
		cap.height = 1.2
		cap.radial_segments = 8
		SceneCraft3D.mesh(gate, cap, Vector3(0, 3.7, side * 1.65), roof)
	SceneCraft3D.box(gate, Vector3(0.75, 0.7, 3.1), Vector3(0, 2.3, 0), stone)
	for z: float in [-1.0, -0.5, 0.0, 0.5, 1.0]:
		SceneCraft3D.box(gate, Vector3(0.13, 1.5, 0.13), Vector3(0, 1.1, z), wood)

func _build_quarry() -> void:
	var wood: StandardMaterial3D = SceneCraft3D.material(Color("694632"))
	var steel: StandardMaterial3D = SceneCraft3D.material(Color("778080"), 0.6, 0.6)
	var stone: StandardMaterial3D = SceneCraft3D.material(Color("b8aa91"))
	var crane: Node3D = Node3D.new()
	crane.position = Vector3(-15, 0, -10)
	add_child(crane)
	for x: float in [-1.1, 1.1]:
		SceneCraft3D.box(crane, Vector3(0.25, 3.4, 0.25), Vector3(x, 1.7, 0), wood)
	SceneCraft3D.box(crane, Vector3(4.8, 0.3, 0.3), Vector3(0.7, 3.3, 0), wood)
	SceneCraft3D.beam(crane, Vector3(2.7, 3.3, 0), Vector3(2.7, 1.2, 0), 0.045, steel)
	SceneCraft3D.box(crane, Vector3(1.1, 0.75, 0.9), Vector3(2.7, 0.75, 0), stone)
	for index in range(5):
		var cart: Node3D = Node3D.new()
		cart.position = Vector3(-10 + index * 2.5, 0.1, -11)
		add_child(cart)
		SceneCraft3D.box(cart, Vector3(1.25, 0.5, 0.85), Vector3(0, 0.4, 0), wood)
		SceneCraft3D.box(cart, Vector3(0.8, 0.5, 0.6), Vector3(0, 0.8, 0), stone)
		for x: float in [-0.45, 0.45]:
			for z: float in [-0.5, 0.5]:
				var wheel: MeshInstance3D = SceneCraft3D.cylinder(cart, 0.22, 0.12, Vector3(x, 0.2, z), steel, 10)
				wheel.rotation.x = PI * 0.5

func _build_fortress() -> void:
	var stone: StandardMaterial3D = SceneCraft3D.material(Color("8d8b7d"))
	var dark: StandardMaterial3D = SceneCraft3D.material(Color("5f665f"))
	var wall: Node3D = Node3D.new()
	wall.position = Vector3(-13, 0, -11)
	add_child(wall)
	for index in range(9):
		var height: float = 2.2 if index in [3, 4, 7] else 3.3
		SceneCraft3D.box(wall, Vector3(1.5, height, 0.8), Vector3(index * 1.5, height * 0.5, 0), stone)
		if index not in [3, 4, 7]: SceneCraft3D.box(wall, Vector3(0.7, 0.7, 1.0), Vector3(index * 1.5, height + 0.25, 0), dark)
	for x: float in [-1.3, 14]:
		SceneCraft3D.cylinder(wall, 1.2, 3.6, Vector3(x, 1.8, 0), stone, 10)
		SceneCraft3D.cylinder(wall, 1.35, 0.3, Vector3(x, 3.6, 0), dark, 10)
	for index in range(7):
		var rubble: MeshInstance3D = SceneCraft3D.box(wall, Vector3(0.8, 0.5, 0.7), Vector3(3 + index * 0.7, 0.25, 1 + (index % 2) * 0.5), dark)
		rubble.rotation.y = index * 0.9

func _build_forge() -> void:
	var stone: StandardMaterial3D = SceneCraft3D.material(Color("626b66"))
	var steel: StandardMaterial3D = SceneCraft3D.material(Color("3f4b4b"), 0.55, 0.6)
	var ember: StandardMaterial3D = SceneCraft3D.material(Color("dc7a31"))
	ember.emission_enabled = true
	ember.emission = Color("bf5325")
	ember.emission_energy_multiplier = 0.7
	var furnace: Node3D = Node3D.new()
	furnace.position = Vector3(-13, 0, -11)
	add_child(furnace)
	SceneCraft3D.cylinder(furnace, 1.6, 0.35, Vector3(0, 0.18, 0), stone, 10)
	SceneCraft3D.box(furnace, Vector3(2.3, 2.5, 1.9), Vector3(0, 1.55, 0), stone)
	SceneCraft3D.box(furnace, Vector3(1.3, 1.3, 0.09), Vector3(0, 1.1, 0.98), steel)
	SceneCraft3D.box(furnace, Vector3(1.0, 0.45, 0.12), Vector3(0, 0.8, 1.01), ember)
	SceneCraft3D.cylinder(furnace, 0.6, 1.6, Vector3(0, 3.5, 0), stone, 8)
	for x: float in [-0.65, 0, 0.65]:
		SceneCraft3D.box(furnace, Vector3(0.075, 1.4, 0.12), Vector3(x, 1.1, 1.05), steel)
	for index in range(3):
		var anvil: Node3D = Node3D.new()
		anvil.position = Vector3(-8 + index * 4, 0.1, -11)
		add_child(anvil)
		SceneCraft3D.box(anvil, Vector3(1.15, 0.6, 1.1), Vector3(0, 0.3, 0), stone)
		SceneCraft3D.box(anvil, Vector3(0.7, 0.7, 0.7), Vector3(0, 0.9, 0), steel)
		SceneCraft3D.box(anvil, Vector3(1.7, 0.35, 0.8), Vector3(0.2, 1.35, 0), steel)
