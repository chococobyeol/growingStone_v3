# res://scripts/poly_crystal_generator.gd
extends RefCounted
class_name PolyCrystalGenerator

const MAX_TRIES_PER_CRYSTAL := 18

var _single_gen: CrystalGenerator

func _init() -> void:
	_single_gen = CrystalGenerator.new()

static func default_params() -> Dictionary:
	return {
		"seed": 123,

		"F": 0.55,
		"C": 0.55,
		"K": 0.45,
		"A": 0.35,

		"N_min": 3,
		"N_max": 40,

		"mesh_presets": 4,

		"single": {
			"sides": 6,
			"height": 2.0,
			"radius_top": 0.5,
			"radius_bottom": 0.7,
			"termination": 0.7,
			"termination_height": 0.6,
			"termination_region": 0.2,
			"asymmetry": 0.3,
			"chip": 0.15,
			"etch": 0.10,
			"crease_angle_deg": 30.0,
			"base_color": Color(0.8, 0.9, 1.0),
			"opacity": 1.0,
			"cap_bottom": true
		},

		"matrix_enabled": true,
		"matrix_scale": 0.95,

		"matrix_double_sided": true,

		"matrix_blob": {
			"seg_u": 36,
			"seg_v": 18,
			"subdiv": 3,
			"noise_amp": 0.18,
			"noise_freq": 1.8,
			"y_squash": 0.65,
			"bottom_flat": 0.35,
			"seed_add": 777
		},

		"align_to_matrix_normal": true,
		"align_strength": 0.75,
		"align_up_bias": 0.25,

		"matrix_contact_iters": 10,
		"matrix_contact_eps": 0.002,
		"matrix_contact_samples": 5,
		"matrix_embed": 0.22,

		"clamp_to_matrix": true,
		"clamp_margin": 0.92
	}

# 반환: { "N": int, "created_nodes": int, "instances": int }
func build_cluster_into(parent: Node3D, params: Dictionary) -> Dictionary:
	_clear_children(parent)

	var p := default_params()
	for k in params:
		p[k] = params[k]

	var seed_val := int(p.seed)
	var rng := PRNG.new(seed_val)

	var F := clampf(float(p.F), 0.0, 1.0)
	var C := clampf(float(p.C), 0.0, 1.0)
	var K := clampf(float(p.K), 0.0, 1.0)
	var A := clampf(float(p.A), 0.0, 1.0)

	var N_min := int(p.N_min)
	var N_max := int(p.N_max)
	var muN := lerpf(float(N_min), float(N_max), F)
	var N := clampi(_poisson(rng, muN), N_min, N_max)

	var preset_count := clampi(int(p.mesh_presets), 1, 8)

	# ---- 1) 프리셋 메시 생성 ----
	var preset_meshes: Array[ArrayMesh] = []
	preset_meshes.resize(preset_count)

	var single_base: Dictionary = p.single
	for i in range(preset_count):
		var sp := single_base.duplicate(true)
		sp["seed"] = seed_val * 10007 + i * 9176 + 13
		sp["chip"] = clampf(float(sp.get("chip", 0.15)) * (0.75 + 0.6 * rng.randf()), 0.0, 1.0)
		sp["etch"] = clampf(float(sp.get("etch", 0.10)) * (0.75 + 0.6 * rng.randf()), 0.0, 1.0)
		preset_meshes[i] = _single_gen.build_single_crystal(sp)

	# ---- 2) 멀티메시 인스턴스 생성 ----
	var mmis: Array[MultiMeshInstance3D] = []
	mmis.resize(preset_count)

	for i in range(preset_count):
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "Crystals_%d" % i
		var mm := MultiMesh.new()
		mm.mesh = preset_meshes[i]
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.instance_count = 0
		mmi.multimesh = mm
		parent.add_child(mmi)
		mmis[i] = mmi

	# ---- 3) 배치 생성 + bounds ----
	var fan_axis := _rand_unit_xz(rng)
	var chain_axis := _rand_unit_xz(rng)

	var placed_positions: Array[Vector3] = []
	var placed_radii: Array[float] = []
	var per_preset_xforms: Array[Array] = []
	per_preset_xforms.resize(preset_count)
	for i in range(preset_count):
		per_preset_xforms[i] = []

	var radii_xz: Array[float] = []

	for idx in range(N):
		var s := _sample_scale(rng, F, K)
		var base_rb := float(single_base.get("radius_bottom", 0.7))
		var approx_r := 0.45 * s * base_rb

		var pos := Vector3.ZERO
		for _try in range(MAX_TRIES_PER_CRYSTAL):
			pos = _sample_position_mixed(rng, fan_axis, chain_axis, K, A)
			if _check_spacing(pos, approx_r, placed_positions, placed_radii, K):
				break

		var dir0 := _orientation_field(pos, fan_axis, chain_axis, A, rng)
		var dir := _blend_dir(dir0, _rand_unit_sphere(rng), C)

		var basis := _basis_from_up(dir)
		var roll := (rng.randf() * 2.0 - 1.0) * lerpf(PI, 0.25, C)
		basis = basis.rotated(dir, roll)

		var xform := Transform3D(basis.scaled(Vector3.ONE * s), pos)

		var r_xz := Vector2(pos.x, pos.z).length() + approx_r
		radii_xz.append(r_xz)

		placed_positions.append(pos)
		placed_radii.append(approx_r)

		var preset := idx % preset_count
		per_preset_xforms[preset].append(xform)

	# cluster_r: 92% 퍼센타일
	var cluster_r := 1.0
	if radii_xz.size() > 0:
		radii_xz.sort()
		var pick := int(clampf(float(radii_xz.size() - 1) * 0.92, 0.0, float(radii_xz.size() - 1)))
		cluster_r = maxf(0.6, radii_xz[pick])

	# ---- 4) 매트릭스 생성(icosphere) ----
	var matrix_enabled := bool(p.matrix_enabled)
	var matrix_node: MeshInstance3D = null

	var cfg: Dictionary = p.get("matrix_blob", {})
	var seed_val_matrix := seed_val ^ int(cfg.get("seed_add", 777))
	var radius_matrix := cluster_r * float(p.get("matrix_scale", 0.95)) * 1.15

	if matrix_enabled:
		matrix_node = MeshInstance3D.new()
		matrix_node.name = "Matrix"
		matrix_node.mesh = _build_matrix_mesh(rng, cluster_r, p)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.55, 0.55, 0.60)
		mat.roughness = 0.95
		mat.metallic = 0.0
		if bool(p.get("matrix_double_sided", true)):
			mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		else:
			mat.cull_mode = BaseMaterial3D.CULL_BACK
		matrix_node.material_override = mat
		parent.add_child(matrix_node)

	# ---- 5) 배치 클램프(표면 교차 실패 = 날아다님 방지) ----
	if matrix_enabled and bool(p.get("clamp_to_matrix", true)):
		var margin := clampf(float(p.get("clamp_margin", 0.92)), 0.6, 0.98)
		var max_r := radius_matrix * margin
		for i in range(preset_count):
			var list: Array = per_preset_xforms[i]
			for j in range(list.size()):
				var xf: Transform3D = list[j]
				var xz := Vector2(xf.origin.x, xf.origin.z)
				var xz_len := xz.length()
				if xz_len > max_r and xz_len > 0.0001:
					xz = xz * (max_r / xz_len)
					xf.origin.x = xz.x
					xf.origin.z = xz.y
					list[j] = xf

	# ---- 6) 표면 접지(다점) + 노멀 정렬(자세 맞추기) ----
	if matrix_enabled:
		var align_enabled := bool(p.get("align_to_matrix_normal", true))
		var align_strength_base := float(p.get("align_strength", 0.75))
		var align_up_bias := float(p.get("align_up_bias", 0.25))

		var iters := int(p.get("matrix_contact_iters", 10))
		var eps := float(p.get("matrix_contact_eps", 0.002))

		var samples := int(p.get("matrix_contact_samples", 5))
		var embed := clampf(float(p.get("matrix_embed", 0.22)), 0.0, 0.5)

		for i in range(preset_count):
			var list: Array = per_preset_xforms[i]
			for j in range(list.size()):
				var xf: Transform3D = list[j]
				var s := xf.basis.get_scale().x
				var basis := xf.basis.orthonormalized()
				var pos := xf.origin

				# 6-1) 노멀 정렬(자세 맞추기)
				if align_enabled:
					var nrm := _matrix_normal(pos, seed_val_matrix, radius_matrix, cfg)
					nrm = (nrm + Vector3.UP * align_up_bias).normalized()

					var align_t := clampf(align_strength_base * lerpf(0.35, 1.0, A), 0.0, 1.0)
					if align_t > 0.0001:
						var right0 := basis.x.normalized()
						var rightN := (right0 - nrm * right0.dot(nrm))
						if rightN.length() < 0.0001:
							rightN = Vector3.FORWARD.cross(nrm)
							if rightN.length() < 0.0001:
								rightN = Vector3.RIGHT
						rightN = rightN.normalized()
						var fwdN := nrm.cross(rightN).normalized()
						var basisN := Basis(rightN, nrm, fwdN)

						var q0 := basis.get_rotation_quaternion()
						var qN := basisN.get_rotation_quaternion()
						var q := q0.slerp(qN, align_t)
						basis = Basis(q)

				# 6-2) 접지: 다점 샘플 + 매립
				var approx_r := 0.45 * s * float(single_base.get("radius_bottom", 0.7))
				var r_samp := approx_r * 0.85

				var y_best := _matrix_surface_y(pos.x, pos.z, seed_val_matrix, radius_matrix, cfg, iters, eps)

				if samples >= 5:
					y_best = maxf(y_best, _matrix_surface_y(pos.x + r_samp, pos.z, seed_val_matrix, radius_matrix, cfg, iters, eps))
					y_best = maxf(y_best, _matrix_surface_y(pos.x - r_samp, pos.z, seed_val_matrix, radius_matrix, cfg, iters, eps))
					y_best = maxf(y_best, _matrix_surface_y(pos.x, pos.z + r_samp, seed_val_matrix, radius_matrix, cfg, iters, eps))
					y_best = maxf(y_best, _matrix_surface_y(pos.x, pos.z - r_samp, seed_val_matrix, radius_matrix, cfg, iters, eps))

				pos.y = y_best
				pos.y -= (approx_r * embed)

				# 6-3) 롤
				var roll := (rng.randf() * 2.0 - 1.0) * lerpf(PI, 0.25, C)
				basis = basis.rotated(basis.y.normalized(), roll)

				if basis.determinant() < 0.0:
					basis = Basis(-basis.x, basis.y, basis.z)

				xf = Transform3D(basis.scaled(Vector3.ONE * s), pos)
				list[j] = xf

	# ---- 7) 멀티메시에 세팅 ----
	var total_instances := 0
	for i in range(preset_count):
		var list: Array = per_preset_xforms[i]
		var mm := mmis[i].multimesh
		mm.instance_count = list.size()
		for j in range(list.size()):
			mm.set_instance_transform(j, list[j])
		total_instances += list.size()

	return {"N": N, "created_nodes": parent.get_child_count(), "instances": total_instances}

func _clear_children(n: Node) -> void:
	for c in n.get_children():
		n.remove_child(c)
		c.queue_free()

# -------------------------
# Sampling / placement utils
# -------------------------

func _poisson(rng: PRNG, mu: float) -> int:
	mu = maxf(mu, 0.01)
	var L := exp(-mu)
	var k := 0
	var p_val := 1.0
	while p_val > L and k < 512:
		k += 1
		p_val *= rng.randf()
	return maxi(1, k - 1)

func _sample_scale(rng: PRNG, F: float, K: float) -> float:
	var a := lerpf(0.7, 2.2, F)
	var b := lerpf(1.2, 0.8, K)
	var u := pow(rng.randf(), a)
	return lerpf(0.35, 1.25, u) * b

func _sample_position_mixed(rng: PRNG, fan_axis: Vector3, chain_axis: Vector3, K: float, A: float) -> Vector3:
	var t := rng.randf()
	var p := Vector3.ZERO

	var w_mass := clampf(lerpf(0.65, 0.15, A) * lerpf(0.35, 1.0, K), 0.0, 1.0)
	var w_fan := clampf(lerpf(0.20, 0.55, A) * lerpf(0.90, 0.55, K), 0.0, 1.0)
	var w_chain := clampf(lerpf(0.15, 0.30, A), 0.0, 1.0)
	var w_sum := maxf(0.0001, w_mass + w_fan + w_chain)
	w_mass /= w_sum
	w_fan /= w_sum
	w_chain /= w_sum

	var radius := lerpf(0.35, 1.40, 1.0 - K)

	if t < w_mass:
		p = _rand_in_sphere(rng, radius)
	elif t < w_mass + w_fan:
		var r := lerpf(0.3, 1.6, rng.randf())
		var spread := lerpf(0.25, 1.05, A)
		var tangent := _rand_unit_xz(rng)
		var d := (fan_axis + tangent * spread).normalized()
		p = d * r
		p.y = rng.rand_range(-0.12, 0.12) * (1.0 - K)
	else:
		var u := rng.rand_range(-1.3, 1.3)
		var off := _rand_unit_xz(rng) * rng.rand_range(0.0, lerpf(0.25, 0.55, 1.0 - K))
		p = chain_axis * u + off
		p.y = rng.rand_range(-0.10, 0.10)

	p *= lerpf(0.9, 1.25, A)
	return p

func _check_spacing(pos: Vector3, r: float, pos_list: Array, r_list: Array, K: float) -> bool:
	var min_mul := lerpf(1.25, 0.55, K)
	for i in range(pos_list.size()):
		var d := pos.distance_to(pos_list[i])
		var need := (r + float(r_list[i])) * min_mul
		if d < need:
			return false
	return true

func _orientation_field(pos: Vector3, fan_axis: Vector3, chain_axis: Vector3, A: float, rng: PRNG) -> Vector3:
	if A < 0.18:
		return _rand_unit_sphere(rng)

	var radial := Vector3(pos.x, 0.0, pos.z)
	radial = fan_axis if radial.length() < 0.0001 else radial.normalized()

	var mix_chain := _smoothstep(0.35, 0.85, A)
	var d0 := (radial * (1.0 - mix_chain) + chain_axis * mix_chain).normalized()
	return (d0 + Vector3.UP * lerpf(0.25, 0.55, A)).normalized()

func _blend_dir(a: Vector3, b: Vector3, t: float) -> Vector3:
	return (a * t + b * (1.0 - t)).normalized()

func _basis_from_up(up_dir: Vector3) -> Basis:
	var up := up_dir.normalized()
	var tangent := Vector3.FORWARD
	if absf(up.dot(tangent)) > 0.98:
		tangent = Vector3.RIGHT
	var right := tangent.cross(up).normalized()
	var fwd := up.cross(right).normalized()
	return Basis(right, up, fwd)

func _rand_unit_xz(rng: PRNG) -> Vector3:
	var a := rng.randf() * TAU
	return Vector3(cos(a), 0.0, sin(a)).normalized()

func _rand_unit_sphere(rng: PRNG) -> Vector3:
	var x := 0.0
	var y := 0.0
	var s := 2.0
	var guard := 0
	while (s >= 1.0 or s == 0.0) and guard < 64:
		x = rng.randf() * 2.0 - 1.0
		y = rng.randf() * 2.0 - 1.0
		s = x * x + y * y
		guard += 1
	if guard >= 64:
		return Vector3.UP
	var z := 1.0 - 2.0 * s
	var k := 2.0 * sqrt(1.0 - s)
	return Vector3(x * k, z, y * k).normalized()

func _rand_in_sphere(rng: PRNG, radius: float) -> Vector3:
	var d := _rand_unit_sphere(rng)
	var r := pow(rng.randf(), 1.0 / 3.0) * radius
	return d * r

func _smoothstep(e0: float, e1: float, x: float) -> float:
	var t := clampf((x - e0) / maxf(0.000001, e1 - e0), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)

# -------------------------
# Matrix mesh (icosphere, outward winding 강제, 노멀 재생성)
# -------------------------

func _build_matrix_mesh(_rng: PRNG, cluster_r: float, params: Dictionary) -> ArrayMesh:
	var cfg: Dictionary = params.get("matrix_blob", {})
	var subdiv := clampi(int(cfg.get("subdiv", 3)), 1, 6)

	var noise_amp := float(cfg.get("noise_amp", 0.18))
	var noise_freq := float(cfg.get("noise_freq", 1.8))
	var y_squash := float(cfg.get("y_squash", 0.65))
	var bottom_flat := float(cfg.get("bottom_flat", 0.35))
	var seed_add := int(cfg.get("seed_add", 777))

	var seed_val := int(params.get("seed", 0)) ^ seed_add
	var radius := cluster_r * float(params.get("matrix_scale", 0.95)) * 1.15

	var data := _icosphere_build(subdiv)
	var verts: Array = data["verts"]
	var tris: Array = data["tris"]

	for i in range(verts.size()):
		var dir: Vector3 = (verts[i] as Vector3).normalized()

		var n := _hash3_to_01(seed_val, dir * noise_freq)
		var r := radius * (1.0 + (n * 2.0 - 1.0) * noise_amp)
		var p3 := dir * r

		var yflat := 1.0
		if p3.y < 0.0:
			var t := clampf((p3.y / maxf(0.0001, -radius)), 0.0, 1.0)
			yflat = lerpf(1.0 - bottom_flat, 1.0, 1.0 - t)

		p3.y *= y_squash * yflat
		verts[i] = p3

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	for k in range(0, tris.size(), 3):
		var ia := int(tris[k])
		var ib := int(tris[k + 1])
		var ic := int(tris[k + 2])

		var a: Vector3 = verts[ia]
		var b: Vector3 = verts[ib]
		var c: Vector3 = verts[ic]

		var center := (a + b + c) / 3.0
		var ntri := (b - a).cross(c - a)

		if ntri.dot(center) < 0.0:
			st.set_uv(_sphere_uv(a.normalized())); st.add_vertex(a)
			st.set_uv(_sphere_uv(c.normalized())); st.add_vertex(c)
			st.set_uv(_sphere_uv(b.normalized())); st.add_vertex(b)
		else:
			st.set_uv(_sphere_uv(a.normalized())); st.add_vertex(a)
			st.set_uv(_sphere_uv(b.normalized())); st.add_vertex(b)
			st.set_uv(_sphere_uv(c.normalized())); st.add_vertex(c)

	st.generate_normals()
	return st.commit()

func _sphere_uv(dir: Vector3) -> Vector2:
	var u := atan2(dir.z, dir.x) / TAU + 0.5
	var v := acos(clampf(dir.y, -1.0, 1.0)) / PI
	return Vector2(u, v)

func _icosphere_build(subdiv: int) -> Dictionary:
	var t := (1.0 + sqrt(5.0)) * 0.5

	var verts: Array = [
		Vector3(-1,  t,  0), Vector3( 1,  t,  0),
		Vector3(-1, -t,  0), Vector3( 1, -t,  0),
		Vector3( 0, -1,  t), Vector3( 0,  1,  t),
		Vector3( 0, -1, -t), Vector3( 0,  1, -t),
		Vector3( t,  0, -1), Vector3( t,  0,  1),
		Vector3(-t,  0, -1), Vector3(-t,  0,  1)
	]

	for i in range(verts.size()):
		verts[i] = (verts[i] as Vector3).normalized()

	var tris: Array = [
		0,11,5,  0,5,1,  0,1,7,  0,7,10, 0,10,11,
		1,5,9,  5,11,4, 11,10,2, 10,7,6,  7,1,8,
		3,9,4,  3,4,2,  3,2,6,  3,6,8,  3,8,9,
		4,9,5,  2,4,11, 6,2,10, 8,6,7,  9,8,1
	]

	var mid_cache := {}
	for _s in range(subdiv):
		var new_tris: Array = []
		for k in range(0, tris.size(), 3):
			var a := int(tris[k])
			var b := int(tris[k + 1])
			var c := int(tris[k + 2])

			var ab := _icosphere_midpoint(a, b, verts, mid_cache)
			var bc := _icosphere_midpoint(b, c, verts, mid_cache)
			var ca := _icosphere_midpoint(c, a, verts, mid_cache)

			new_tris.append_array([a, ab, ca])
			new_tris.append_array([b, bc, ab])
			new_tris.append_array([c, ca, bc])
			new_tris.append_array([ab, bc, ca])
		tris = new_tris

	return {"verts": verts, "tris": tris}

func _icosphere_midpoint(i0: int, i1: int, verts: Array, cache: Dictionary) -> int:
	var a := mini(i0, i1)
	var b := maxi(i0, i1)
	var key := "%d_%d" % [a, b]
	if cache.has(key):
		return int(cache[key])

	var p0: Vector3 = verts[a]
	var p1: Vector3 = verts[b]
	var pm := (p0 + p1) * 0.5
	pm = pm.normalized()

	var idx := verts.size()
	verts.append(pm)
	cache[key] = idx
	return idx

func _hash3_to_01(seed_val: int, p: Vector3) -> float:
	var x := int(floor(p.x * 97.0))
	var y := int(floor(p.y * 193.0))
	var z := int(floor(p.z * 389.0))
	var h := seed_val ^ (x * 73856093) ^ (y * 19349663) ^ (z * 83492791)
	h = (h ^ (h >> 16)) * 0x7feb352d
	h = (h ^ (h >> 15)) * 0x846ca68b
	h = (h ^ (h >> 16))
	return float(h & 0x7FFFFFFF) / 2147483647.0

# -------------------------
# Matrix implicit (접지 + 노멀 샘플링)
# -------------------------

func _matrix_f(p: Vector3, seed_val: int, radius: float, cfg: Dictionary) -> float:
	var noise_amp := float(cfg.get("noise_amp", 0.18))
	var noise_freq := float(cfg.get("noise_freq", 1.8))
	var y_squash := float(cfg.get("y_squash", 0.65))
	var bottom_flat := float(cfg.get("bottom_flat", 0.35))

	var q := p
	q.y /= maxf(0.0001, y_squash)

	if q.y < 0.0:
		var t := clampf((-q.y) / maxf(0.0001, radius), 0.0, 1.0)
		var flat_mul := lerpf(1.0, 1.0 - bottom_flat, t)
		q.y /= maxf(0.0001, flat_mul)

	if q.length() < 0.000001:
		return -radius

	var dir := q.normalized()
	var n := _hash3_to_01(seed_val, dir * noise_freq)
	var r := radius * (1.0 + (n * 2.0 - 1.0) * noise_amp)

	return q.length() - r

func _matrix_normal(p: Vector3, seed_val: int, radius: float, cfg: Dictionary) -> Vector3:
	var e := 0.003 * maxf(1.0, radius)
	var fx1 := _matrix_f(p + Vector3(e, 0, 0), seed_val, radius, cfg)
	var fx0 := _matrix_f(p - Vector3(e, 0, 0), seed_val, radius, cfg)
	var fy1 := _matrix_f(p + Vector3(0, e, 0), seed_val, radius, cfg)
	var fy0 := _matrix_f(p - Vector3(0, e, 0), seed_val, radius, cfg)
	var fz1 := _matrix_f(p + Vector3(0, 0, e), seed_val, radius, cfg)
	var fz0 := _matrix_f(p - Vector3(0, 0, e), seed_val, radius, cfg)

	var n := Vector3(fx1 - fx0, fy1 - fy0, fz1 - fz0)
	return (n.normalized() if n.length() > 0.000001 else Vector3.UP)

func _matrix_surface_y(x: float, z: float, seed_val: int, radius: float, cfg: Dictionary, iters: int, eps: float) -> float:
	var y_top := radius * 2.2
	var y_bot := -radius * 2.2

	var f_top := _matrix_f(Vector3(x, y_top, z), seed_val, radius, cfg)
	var f_bot := _matrix_f(Vector3(x, y_bot, z), seed_val, radius, cfg)

	var guard := 0
	while f_top <= 0.0 and guard < 20:
		y_top *= 1.5
		f_top = _matrix_f(Vector3(x, y_top, z), seed_val, radius, cfg)
		guard += 1

	guard = 0
	while f_bot >= 0.0 and guard < 20:
		y_bot *= 1.5
		f_bot = _matrix_f(Vector3(x, y_bot, z), seed_val, radius, cfg)
		guard += 1

	if f_top <= 0.0 or f_bot >= 0.0:
		return 0.0

	for _i in range(iters):
		var y_mid := 0.5 * (y_top + y_bot)
		var f_mid := _matrix_f(Vector3(x, y_mid, z), seed_val, radius, cfg)
		if absf(f_mid) < eps:
			return y_mid
		if f_mid > 0.0:
			y_top = y_mid
		else:
			y_bot = y_mid

	return 0.5 * (y_top + y_bot)
