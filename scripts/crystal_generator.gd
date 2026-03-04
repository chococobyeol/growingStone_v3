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
		"termination_height": 0.6, # 0..1 비율
		"termination_region": 0.2,
		"asymmetry": 0.3,

		"chip": 0.2,
		"etch": 0.1,
		"crease_angle_deg": 30.0, # (현재 미사용)

		"base_color": Color(0.85, 0.9, 1.0),
		"opacity": 0.95,

		"cap_bottom": true
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

	var bias_angle = rng.randf() * PI2
	var bias_dir = Vector3(cos(bias_angle), 0.0, sin(bias_angle))

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

	if etch > 0.0001:
		for i in range(sides):
			var e = etch * 0.02 * _hash_noise(int(p.seed) ^ 0x9e3779b9, i + 101)  # 조금 더 키움
			var radial_b = Vector3(bottom[i].x, 0.0, bottom[i].z).normalized()
			var radial_t = Vector3(top[i].x, 0.0, top[i].z).normalized()

			bottom[i] += radial_b * (e * 0.7)
			top[i] += radial_t * (e * 1.1) + Vector3.UP * (e * 0.35)
			crown[i] += Vector3(radial_t.x, 0.0, radial_t.z) * (e * 0.9) + Vector3.UP * (e * 0.25)

		crown_center += Vector3(etch * 0.006, etch * 0.01, etch * 0.006)

	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var uvs := PackedVector2Array()

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

		_add_tri(verts, norms, uvs, b0, t0, t1, Vector2(u0, 0.0), Vector2(ut0, 0.75), Vector2(ut1, 0.75))
		_add_tri(verts, norms, uvs, b0, t1, b1, Vector2(u0, 0.0), Vector2(ut1, 0.75), Vector2(u1, 0.0))

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

		_add_tri(verts, norms, uvs, t0, c0, c1, Vector2(ut0, 0.75), Vector2(uc0, 0.95), Vector2(uc1, 0.95))
		_add_tri(verts, norms, uvs, t0, c1, t1, Vector2(ut0, 0.75), Vector2(uc1, 0.95), Vector2(ut1, 0.75))

	for i in range(sides):
		var i1 = (i + 1) % sides
		var c0 = crown[i]
		var c1 = crown[i1]

		var uc0 = atan2(c0.z, c0.x) / PI2 + 0.5
		var uc1 = atan2(c1.z, c1.x) / PI2 + 0.5
		_add_tri(verts, norms, uvs, c0, crown_center, c1, Vector2(uc0, 0.95), Vector2(0.5, 1.0), Vector2(uc1, 0.95))

	if cap_bottom:
		var bottom_center := Vector3.ZERO
		for i in range(sides):
			bottom_center += bottom[i]
		bottom_center /= float(sides)

		for i in range(sides):
			var i1 = (i + 1) % sides
			var b0 = bottom[i]
			var b1 = bottom[i1]

			var u0 = atan2(b0.z, b0.x) / PI2 + 0.5
			var u1 = atan2(b1.z, b1.x) / PI2 + 0.5
			_add_tri(verts, norms, uvs, b1, bottom_center, b0, Vector2(u1, 0.0), Vector2(0.5, 0.0), Vector2(u0, 0.0))

	# 핵심: 메시를 원점 중심으로 재정렬해서 오비트 pivot 문제 제거
	_recenter_in_place(verts)

	return {
		"vertices": verts,
		"normals": norms,
		"uvs": uvs
	}

func _recenter_in_place(verts: PackedVector3Array) -> void:
	if verts.size() == 0:
		return
	var mn := verts[0]
	var mx := verts[0]
	for v in verts:
		mn = Vector3(minf(mn.x, v.x), minf(mn.y, v.y), minf(mn.z, v.z))
		mx = Vector3(maxf(mx.x, v.x), maxf(mx.y, v.y), maxf(mx.z, v.z))
	var center := (mn + mx) * 0.5
	for i in range(verts.size()):
		verts[i] = verts[i] - center

func _add_tri(verts: PackedVector3Array, norms: PackedVector3Array, uvs: PackedVector2Array,
	a: Vector3, b: Vector3, c: Vector3, uv_a: Vector2, uv_b: Vector2, uv_c: Vector2) -> void:
	var n = (b - a).cross(c - a).normalized()
	verts.append(a)
	verts.append(b)
	verts.append(c)
	norms.append(n)
	norms.append(n)
	norms.append(n)
	uvs.append(uv_a)
	uvs.append(uv_b)
	uvs.append(uv_c)

func _smoothstep(edge0: float, edge1: float, x: float) -> float:
	var t = clampf((x - edge0) / maxf(0.000001, edge1 - edge0), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)

func _hash_noise(seed_val: int, i: int) -> float:
	var h = (seed_val * 73856093) ^ (i * 19349663)
	h = (h ^ (h >> 16)) * 0x85ebca6b
	h = (h ^ (h >> 13)) * 0xc2b2ae35
	h = h ^ (h >> 16)
	return (float(h & 0x7FFFFFFF) / 2147483647.0) * 2.0 - 1.0
