# res://scripts/crystal_generator.gd
extends RefCounted
class_name CrystalGenerator

static func default_params() -> Dictionary:
	return {
		"seed": 42,
		"sides": 6,
		"height": 2.0,
		"radius_top": 0.5,
		"radius_bottom": 0.7,

		"termination": 0.7,
		# 0..1 비율값 (height 곱함)
		"termination_height": 0.6,
		"termination_region": 0.2,
		"asymmetry": 0.3,

		"chip": 0.2,
		"etch": 0.1,
		"crease_angle_deg": 30.0,

		"base_color": Color(0.85, 0.9, 1.0),
		"opacity": 0.95,

		"cap_bottom": true,
		"base_roughness": 0.0
	}

func build_single_crystal(params: Dictionary) -> ArrayMesh:
	var arrs = build_single_crystal_arrays(params)
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = arrs["vertices"]
	arrays[Mesh.ARRAY_NORMAL] = arrs["normals"]
	arrays[Mesh.ARRAY_TEX_UV] = arrs["uvs"]

	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = params.get("base_color", default_params()["base_color"])
	mat.roughness = 0.4
	mat.metallic = 0.1

	var op := float(params.get("opacity", 1.0))
	if op < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color.a = op

	# CULL_BACK 유지 (winding을 안정화해서 해결)
	mat.cull_mode = BaseMaterial3D.CULL_BACK

	m.surface_set_material(0, mat)
	return m

func build_single_crystal_arrays(params: Dictionary) -> Dictionary:
	var p := default_params()
	for k in params:
		p[k] = params[k]

	var rng := PRNG.new(int(p.seed))

	var sides: int = clampi(int(p.sides), 3, 12)
	var height: float = maxf(float(p.height), 0.01)
	var rt: float = maxf(float(p.radius_top), 0.01)
	var rb: float = maxf(float(p.radius_bottom), 0.01)

	var term: float = clampf(float(p.termination), 0.0, 1.0)
	var term_h: float = clampf(float(p.termination_height), 0.05, 0.95) * height
	var term_reg: float = clampf(float(p.termination_region), 0.02, 0.6)
	var asym: float = clampf(float(p.asymmetry), 0.0, 1.0)

	var chip: float = clampf(float(p.chip), 0.0, 1.0)
	var etch: float = clampf(float(p.etch), 0.0, 1.0)

	var cap_bottom: bool = bool(p.get("cap_bottom", true))
	var PI2 := TAU

	# rings
	var bottom := PackedVector3Array()
	var top := PackedVector3Array()
	bottom.resize(sides)
	top.resize(sides)

	for i in range(sides):
		var a = PI2 * float(i) / float(sides)
		var ca = cos(a)
		var sa = sin(a)
		bottom[i] = Vector3(ca * rb, 0.0, sa * rb)
		top[i] = Vector3(ca * rt, height, sa * rt)

	var base_rough := clampf(float(p.get("base_roughness", 0.0)), 0.0, 1.0)
	if base_rough > 0.0001:
		for i in range(sides):
			var n = _hash_noise(int(p.seed) ^ 0x51a3f2d, i + 777)
			bottom[i].y += n * (0.06 * base_rough) * rb
			var radial = Vector3(bottom[i].x, 0.0, bottom[i].z).normalized()
			bottom[i] += radial * (n * (0.05 * base_rough) * rb)

	# bias direction
	var bias_angle = rng.randf() * PI2
	var bias_dir = Vector3(cos(bias_angle), 0.0, sin(bias_angle))

	# termination shaping
	for i in range(sides):
		var v := top[i]
		var radial = Vector3(v.x, 0.0, v.z).normalized()
		var dot_bias = clampf(radial.dot(bias_dir), -1.0, 1.0)

		var n = 0.5 + 0.5 * _hash_noise(int(p.seed), i)
		var mixv = lerpf(n, (dot_bias * 0.5 + 0.5), asym)
		var region_factor = clampf(mixv, 0.0, 1.0)

		var w = term * term_reg * region_factor
		var inward = 1.0 - w * 0.55
		var y_drop = -w * height * 0.18

		var ny = clampf(v.y + y_drop, term_h, height + 0.001)
		top[i] = Vector3(v.x * inward, ny, v.z * inward)

	# crown ring
	var crown := PackedVector3Array()
	crown.resize(sides)
	var crown_center := Vector3.ZERO

	for i in range(sides):
		var t := top[i]
		var inward_scale = lerpf(0.62, 0.22, term)
		var lift = height * lerpf(0.02, 0.12, term)
		var c = Vector3(t.x * inward_scale, t.y + lift, t.z * inward_scale)
		crown[i] = c
		crown_center += c

	crown_center /= float(sides)
	crown_center += Vector3(
		rng.rand_range(-0.02, 0.02),
		rng.rand_range(0.00, 0.03),
		rng.rand_range(-0.02, 0.02)
	)

	# chip (continuous)
	if chip > 0.0001:
		var nrm = Vector3(rng.randf() - 0.5, 0.18, rng.randf() - 0.5).normalized()
		var d0 = crown_center.dot(nrm)
		var width = maxf(0.02, 0.25 * rb)

		for i in range(sides):
			var v = top[i]
			var dist = (v.dot(nrm) - d0)
			var m = _smoothstep(0.0, width, dist)
			var top_w = clampf((v.y - term_h) / maxf(0.001, (height - term_h)), 0.0, 1.0)
			var fac = chip * m * top_w
			var radial_top = Vector3(v.x, 0.0, v.z).normalized()
			top[i] = v - radial_top * (0.06 * fac) - Vector3.UP * (0.04 * fac)

			v = crown[i]
			dist = (v.dot(nrm) - d0)
			m = _smoothstep(0.0, width, dist)
			fac = chip * m
			var radial_crown = Vector3(v.x, 0.0, v.z).normalized()
			crown[i] = v - radial_crown * (0.04 * fac) - Vector3.UP * (0.02 * fac)

		crown_center -= Vector3.UP * (0.015 * chip)

	# etch
	if etch > 0.0001:
		for i in range(sides):
			var e = etch * 0.015 * _hash_noise(int(p.seed) ^ 0x9e3779b9, i + 101)
			var radial_b = Vector3(bottom[i].x, 0.0, bottom[i].z).normalized()
			var radial_t = Vector3(top[i].x, 0.0, top[i].z).normalized()

			bottom[i] += radial_b * (e * 0.6)
			top[i] += radial_t * (e * 1.0) + Vector3.UP * (e * 0.3)
			crown[i] += Vector3(radial_t.x, 0.0, radial_t.z) * (e * 0.8) + Vector3.UP * (e * 0.2)

		crown_center += Vector3(etch * 0.006, etch * 0.01, etch * 0.006)

	# -----------------------------
	# 핵심 1) winding 판정용 "진짜 중심" 계산
	# (이게 흔들리면 보이는 면이 다시 뚫림)
	# -----------------------------
	var shape_center := Vector3.ZERO
	var cnt := 0
	for i in range(sides):
		shape_center += bottom[i]; cnt += 1
		shape_center += top[i]; cnt += 1
		shape_center += crown[i]; cnt += 1
	shape_center += crown_center; cnt += 1
	shape_center /= float(maxi(cnt, 1))

	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var uvs := PackedVector2Array()

	# side faces
	for i in range(sides):
		var i1 = (i + 1) % sides
		var b0 = bottom[i]
		var b1 = bottom[i1]
		var t0 = top[i]
		var t1 = top[i1]

		var u0 = atan2(b0.z, b0.x) / PI2 + 0.5
		var u1 = atan2(b1.z, b1.x) / PI2 + 0.5
		var ut0 = atan2(t0.z, t0.x) / PI2 + 0.5
		var ut1 = atan2(t1.z, t1.x) / PI2 + 0.5

		_add_tri_outward(verts, norms, uvs, b0, t0, t1, Vector2(u0, 0.0), Vector2(ut0, 0.75), Vector2(ut1, 0.75), shape_center)
		_add_tri_outward(verts, norms, uvs, b0, t1, b1, Vector2(u0, 0.0), Vector2(ut1, 0.75), Vector2(u1, 0.0), shape_center)

	# termination: top -> crown
	for i in range(sides):
		var i1 = (i + 1) % sides
		var t0 = top[i]
		var t1 = top[i1]
		var c0 = crown[i]
		var c1 = crown[i1]

		var ut0 = atan2(t0.z, t0.x) / PI2 + 0.5
		var ut1 = atan2(t1.z, t1.x) / PI2 + 0.5
		var uc0 = atan2(c0.z, c0.x) / PI2 + 0.5
		var uc1 = atan2(c1.z, c1.x) / PI2 + 0.5

		_add_tri_outward(verts, norms, uvs, t0, c0, c1, Vector2(ut0, 0.75), Vector2(uc0, 0.95), Vector2(uc1, 0.95), shape_center)
		_add_tri_outward(verts, norms, uvs, t0, c1, t1, Vector2(ut0, 0.75), Vector2(uc1, 0.95), Vector2(ut1, 0.75), shape_center)

	# crown -> center (윗면)
	for i in range(sides):
		var i1 = (i + 1) % sides
		var c0 = crown[i]
		var c1 = crown[i1]

		var uc0 = atan2(c0.z, c0.x) / PI2 + 0.5
		var uc1 = atan2(c1.z, c1.x) / PI2 + 0.5
		_add_tri_outward(verts, norms, uvs, c0, crown_center, c1, Vector2(uc0, 0.95), Vector2(0.5, 1.0), Vector2(uc1, 0.95), shape_center)

	# bottom cap
	if cap_bottom:
		var bottom_center := Vector3.ZERO
		for i in range(sides):
			bottom_center += bottom[i]
		bottom_center /= float(sides)

		base_rough = clampf(float(p.get("base_roughness", 0.0)), 0.0, 1.0)
		bottom_center.y -= rb * 0.06 * base_rough

		for i in range(sides):
			var i1 = (i + 1) % sides
			var b0 = bottom[i]
			var b1 = bottom[i1]

			var u0b = atan2(b0.z, b0.x) / PI2 + 0.5
			var u1b = atan2(b1.z, b1.x) / PI2 + 0.5
			_add_tri_outward(verts, norms, uvs, b1, bottom_center, b0, Vector2(u1b, 0.0), Vector2(0.5, 0.0), Vector2(u0b, 0.0), shape_center)

	return {"vertices": verts, "normals": norms, "uvs": uvs}

func _add_tri_outward(
	verts: PackedVector3Array, norms: PackedVector3Array, uvs: PackedVector2Array,
	a: Vector3, b: Vector3, c: Vector3,
	uv_a: Vector2, uv_b: Vector2, uv_c: Vector2,
	shape_center: Vector3
) -> void:
	var n := (b - a).cross(c - a)
	if n.length() < 0.000001:
		return
	n = n.normalized()

	var tri_center := (a + b + c) / 3.0
	if n.dot(tri_center - shape_center) < 0.0:
		# winding flip
		var tb := b
		b = c
		c = tb
		var tuv := uv_b
		uv_b = uv_c
		uv_c = tuv
		n = (b - a).cross(c - a).normalized()

	verts.append(a); verts.append(b); verts.append(c)
	norms.append(n); norms.append(n); norms.append(n)
	uvs.append(uv_a); uvs.append(uv_b); uvs.append(uv_c)

func _smoothstep(edge0: float, edge1: float, x: float) -> float:
	var t = clampf((x - edge0) / maxf(0.000001, edge1 - edge0), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)

func _hash_noise(seed_val: int, i: int) -> float:
	var h = (seed_val * 73856093) ^ (i * 19349663)
	h = (h ^ (h >> 16)) * 0x85ebca6b
	h = (h ^ (h >> 13)) * 0xc2b2ae35
	h = h ^ (h >> 16)
	return (float(h & 0x7FFFFFFF) / 2147483647.0) * 2.0 - 1.0
