extends Node3D

var time_elapsed: float = 0.0
var growth_speed: float = 0.5
var initial_scale: float = 1.0

class StonePRNGInner:
	var state: int
	func _init(seed_val: int) -> void:
		state = seed_val & 0x7FFFFFFF
		if state == 0:
			state = 1
	func rand() -> int:
		state = (state * 1103515245 + 12345) & 0x7FFFFFFF
		return state
	func randf() -> float:
		return float(rand()) / 2147483648.0
	func randf_range(min_val: float, max_val: float) -> float:
		return min_val + randf() * (max_val - min_val)
	func randi_range(min_val: int, max_val: int) -> int:
		if min_val >= max_val:
			return min_val
		return min_val + (rand() % (max_val - min_val + 1))

const TOON_SHADER_CODE = """
shader_type spatial;
render_mode unshaded, cull_back;

uniform vec3 base_color : source_color = vec3(0.9, 0.88, 0.85);
uniform vec3 light_color : source_color = vec3(1.0, 1.0, 1.0);
uniform vec3 shadow_color : source_color = vec3(0.5, 0.45, 0.45);
uniform float cloudiness = 0.0;
uniform float grain_size = 0.0;

const vec3 LIGHT_DIR = normalize(vec3(0.5, 0.9, 0.3));

void fragment() {
	vec3 n = NORMAL;
	if (grain_size > 0.0) {
		float noise = fract(sin(dot(VERTEX.xy, vec2(12.9898, 78.233))) * 43758.5453);
		n = normalize(NORMAL + (noise - 0.5) * grain_size * 0.4);
	}
	vec3 world_normal = normalize((MODEL_MATRIX * vec4(n, 0.0)).xyz);
	float NdotL = dot(world_normal, LIGHT_DIR);

	vec3 albedo = mix(base_color, vec3(0.82), cloudiness * 0.5);
	vec3 shadow_tint = mix(shadow_color, base_color * 0.7, cloudiness * 0.5);
	vec3 out_color;
	if (NdotL > 0.5) {
		out_color = light_color;
	} else if (NdotL > 0.0) {
		out_color = albedo;
	} else {
		out_color = shadow_tint;
	}
	if (cloudiness > 0.5 || grain_size > 0.3) {
		out_color = mix(shadow_tint, albedo, clamp(NdotL * 0.6 + 0.5, 0.0, 1.0));
	}
	ALBEDO = out_color;
}
"""

const OUTLINE_SHADER_CODE = """
shader_type spatial;
render_mode unshaded, cull_front;
uniform float outline_thickness = 0.06;
uniform vec3 outline_color : source_color = vec3(0.1, 0.1, 0.1);
void vertex() { VERTEX += NORMAL * outline_thickness; }
void fragment() { ALBEDO = outline_color; }
"""

var toon_material: ShaderMaterial
var outline_material: ShaderMaterial

const TRACE_COLOR_MATRIX = {
	"Cr": [Color.CRIMSON, Color.SEA_GREEN, Color.YELLOW_GREEN],
	"Fe": [Color.GOLDENROD, Color.BLUE_VIOLET, Color.SADDLE_BROWN],
	"Cu": [Color.CYAN, Color.DEEP_SKY_BLUE, Color.DARK_GREEN],
	"Mn": [Color.LIGHT_PINK, Color.MEDIUM_VIOLET_RED, Color.DARK_RED],
	"Co": [Color.ROYAL_BLUE, Color.DEEP_PINK, Color.DARK_MAGENTA],
	"V": [Color.LIME, Color.MEDIUM_SPRING_GREEN, Color.DARK_OLIVE_GREEN],
	"Ti": [Color.LIGHT_YELLOW, Color.MIDNIGHT_BLUE, Color.DARK_GRAY],
	"Ni": [Color.PALE_GREEN, Color.LIGHT_GREEN, Color.YELLOW_GREEN]
}

func _ready() -> void:
	var toon_shader := Shader.new()
	toon_shader.code = TOON_SHADER_CODE
	toon_material = ShaderMaterial.new()
	toon_material.shader = toon_shader

	var out_shader := Shader.new()
	out_shader.code = OUTLINE_SHADER_CODE
	outline_material = ShaderMaterial.new()
	outline_material.shader = out_shader

func _process(delta: float) -> void:
	time_elapsed += delta
	var new_scale := initial_scale + (log(time_elapsed + 1.0) * growth_speed)
	self.scale = Vector3(new_scale, new_scale, new_scale)

func apply_stone_data(stone_data: Dictionary) -> void:
	for child in get_children():
		child.queue_free()

	var recipe: Dictionary = stone_data.get("mineral_recipes", {})
	var dna: Dictionary = stone_data.get("dna", {})
	var crystal_structure := str(dna.get("crystal_system", "isometric")).to_lower()
	var base_color_val := Color.from_string(str(recipe.get("base_color", "#E6E0D4")), Color.GRAY)

	var env: Dictionary = dna.get("environment", {})
	var temperature: int = int(env.get("temperature", 3))
	var pressure: String = str(env.get("pressure", "low"))
	var trace_elements: Array = dna.get("trace_elements", [])

	var seed_val: int = int(dna.get("seed", 12345))
	var prng := StonePRNGInner.new(seed_val)

	initial_scale = max(0.05, float(stone_data.get("current_mass", 1.0)) * 0.03)
	time_elapsed = 0.0

	var shape_type := 0
	var crystal_group := 0
	if crystal_structure in ["hexagonal", "trigonal"]:
		shape_type = 1
		crystal_group = 1
	elif crystal_structure in ["orthorhombic", "monoclinic", "triclinic"]:
		shape_type = 2
		crystal_group = 2

	var grain_size_val := map_value(float(temperature), 1.0, 5.0, 1.0, 0.0)
	if pressure == "high" or crystal_structure == "amorphous":
		shape_type = 3
		grain_size_val = max(grain_size_val, 0.8)

	var final_color: Color = base_color_val
	var cloudiness_val: float = 0.0
	for te in trace_elements:
		var elem := str(te.get("element", ""))
		var amt: int = int(te.get("amount_level", 1))
		if TRACE_COLOR_MATRIX.has(elem):
			var blend: float = clamp(prng.randf_range(amt * 0.3 - 0.1, amt * 0.3 + 0.1), 0.0, 1.0)
			final_color = final_color.lerp(TRACE_COLOR_MATRIX[elem][crystal_group], blend)
			if amt >= 2:
				final_color = Color.from_hsv(final_color.h, final_color.s, max(0.2, final_color.v - (amt * 0.15)))
		else:
			cloudiness_val += amt * 0.25

	cloudiness_val = clamp(cloudiness_val, 0.0, 1.0)

	var color_light_val := Color.from_hsv(final_color.h, final_color.s, min(1.0, final_color.v + 0.5))
	var color_shadow_val := Color.from_hsv(final_color.h, final_color.s, max(0.1, final_color.v - 0.3))

	var mat := toon_material.duplicate()
	mat.next_pass = outline_material.duplicate()
	mat.set_shader_parameter("base_color", Vector3(final_color.r, final_color.g, final_color.b))
	mat.set_shader_parameter("light_color", Vector3(color_light_val.r, color_light_val.g, color_light_val.b))
	mat.set_shader_parameter("shadow_color", Vector3(color_shadow_val.r, color_shadow_val.g, color_shadow_val.b))
	mat.set_shader_parameter("cloudiness", cloudiness_val)
	mat.set_shader_parameter("grain_size", grain_size_val)

	var cluster_count := int(map_value(float(temperature), 1.0, 5.0, 7.0, 1.0))
	var spread_angle := map_value(float(temperature), 1.0, 5.0, PI / 1.8, 0.1)
	if shape_type == 3:
		cluster_count = prng.randi_range(1, 2)
		spread_angle = 0.3

	for i in range(cluster_count):
		var mesh_inst := MeshInstance3D.new()
		var mesh_shape: Mesh

		match shape_type:
			1:
				var cyl := CylinderMesh.new()
				cyl.radial_segments = 6
				cyl.top_radius = 0.0
				cyl.bottom_radius = prng.randf_range(0.3, 0.5)
				cyl.height = prng.randf_range(1.5, 3.0)
				mesh_shape = cyl
			2:
				var box := BoxMesh.new()
				box.size = Vector3(prng.randf_range(0.5, 1.2), prng.randf_range(1.5, 2.5), prng.randf_range(0.4, 0.8))
				mesh_shape = box
			3:
				var sphere := SphereMesh.new()
				sphere.radius = prng.randf_range(0.6, 1.0)
				sphere.height = sphere.radius * prng.randf_range(1.5, 2.2)
				sphere.radial_segments = 8
				sphere.rings = 6
				mesh_shape = sphere
			_:
				var box := BoxMesh.new()
				var s := prng.randf_range(0.8, 1.2)
				box.size = Vector3(s, s, s)
				mesh_shape = box

		mesh_inst.mesh = mesh_shape
		mesh_inst.material_override = mat

		if i == 0:
			mesh_inst.scale = Vector3(1.2, 1.2, 1.2)
		else:
			mesh_inst.rotation = Vector3(prng.randf_range(-spread_angle, spread_angle), prng.randf_range(0.0, TAU), prng.randf_range(-spread_angle, spread_angle))
			mesh_inst.position = Vector3(prng.randf_range(-0.3, 0.3), prng.randf_range(-0.5, 0.2), prng.randf_range(-0.3, 0.3))

		add_child(mesh_inst)


func map_value(v: float, in_min: float, in_max: float, out_min: float, out_max: float) -> float:
	return clamp((v - in_min) * (out_max - out_min) / (in_max - in_min) + out_min, min(out_min, out_max), max(out_min, out_max))
