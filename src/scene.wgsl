// ==========================================
// 1. THƯ VIỆN HÌNH HỌC SDF DÀNH CHO SCENE NÀY
// ==========================================
fn sdPlane(p: vec3<f32>) -> f32 { return p.y; }
fn sdSphere(p: vec3<f32>, s: f32) -> f32 { return length(p) - s; }

fn sdBox(p: vec3<f32>, b: vec3<f32>) -> f32 {
    let d = abs(p) - b;
    return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, vec3<f32>(0.0)));
}

fn sdBoxFrame(p: vec3<f32>, b: vec3<f32>, e: f32) -> f32 {
    let p1 = abs(p) - b;
    let q = abs(p1 + vec3<f32>(e)) - vec3<f32>(e);
    let d1 = length(max(vec3<f32>(p1.x, q.y, q.z), vec3<f32>(0.0))) + min(max(p1.x, max(q.y, q.z)), 0.0);
    let d2 = length(max(vec3<f32>(q.x, p1.y, q.z), vec3<f32>(0.0))) + min(max(q.x, max(p1.y, q.z)), 0.0);
    let d3 = length(max(vec3<f32>(q.x, q.y, p1.z), vec3<f32>(0.0))) + min(max(q.x, max(q.y, p1.z)), 0.0);
    return min(min(d1, d2), d3);
}

fn sdEllipsoid(p: vec3<f32>, r: vec3<f32>) -> f32 {
    let k0 = length(p / r);
    let k1 = length(p / (r * r));
    return k0 * (k0 - 1.0) / k1;
}

fn sdTorus(p: vec3<f32>, t: vec2<f32>) -> f32 {
    return length(vec2<f32>(length(p.xz) - t.x, p.y)) - t.y;
}

fn sdCappedTorus(p_in: vec3<f32>, sc: vec2<f32>, ra: f32, rb: f32) -> f32 {
    var p = p_in; p.x = abs(p.x);
    let k = select(length(p.xy), dot(p.xy, sc), sc.y * p.x > sc.x * p.y);
    return sqrt(dot(p, p) + ra * ra - 2.0 * ra * k) - rb;
}

fn sdHexPrism(p_in: vec3<f32>, h: vec2<f32>) -> f32 {
    let k = vec3<f32>(-0.8660254, 0.5, 0.57735);
    var p = abs(p_in);
    p = vec3<f32>(p.xy - 2.0 * min(dot(k.xy, p.xy), 0.0) * k.xy, p.z);
    let d = vec2<f32>(length(p.xy - vec2<f32>(clamp(p.x, -k.z * h.x, k.z * h.x), h.x)) * sign(p.y - h.x), p.z - h.y);
    return min(max(d.x, d.y), 0.0) + length(max(d, vec2<f32>(0.0)));
}

fn sdOctogonPrism(p_in: vec3<f32>, r: f32, h: f32) -> f32 {
    let k = vec3<f32>(-0.9238795325, 0.3826834323, 0.4142135623);
    var p = abs(p_in);
    p = vec3<f32>(p.xy - 2.0 * min(dot(vec2<f32>(k.x, k.y), p.xy), 0.0) * vec2<f32>(k.x, k.y), p.z);
    p = vec3<f32>(p.xy - 2.0 * min(dot(vec2<f32>(-k.x, k.y), p.xy), 0.0) * vec2<f32>(-k.x, k.y), p.z);
    p = vec3<f32>(p.xy - vec2<f32>(clamp(p.x, -k.z * r, k.z * r), r), p.z);
    let d = vec2<f32>(length(p.xy) * sign(p.y), p.z - h);
    return min(max(d.x, d.y), 0.0) + length(max(d, vec2<f32>(0.0)));
}

fn sdCapsule(p: vec3<f32>, a: vec3<f32>, b: vec3<f32>, r: f32) -> f32 {
    let pa = p - a; let ba = b - a;
    let h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h) - r;
}

fn sdRoundCone(p: vec3<f32>, r1: f32, r2: f32, h: f32) -> f32 {
    let q = vec2<f32>(length(p.xz), p.y);
    let b = (r1 - r2) / h; let a = sqrt(1.0 - b * b);
    let k = dot(q, vec2<f32>(-b, a));
    if (k < 0.0) { return length(q) - r1; }
    if (k > a * h) { return length(q - vec2<f32>(0.0, h)) - r2; }
    return dot(q, vec2<f32>(a, b)) - r1;
}

fn sdRoundCone2(p: vec3<f32>, a: vec3<f32>, b: vec3<f32>, r1: f32, r2: f32) -> f32 {
    let ba = b - a; let l2 = dot(ba, ba); let rr = r1 - r2;
    let a2 = l2 - rr * rr; let il2 = 1.0 / l2;
    let pa = p - a; let y = dot(pa, ba); let z = y - l2;
    let x2 = dot2_v3(pa * l2 - ba * y); let y2 = y * y * l2; let z2 = z * z * l2;
    let k = sign(rr) * rr * rr * x2;
    if (sign(z) * a2 * z2 > k) { return sqrt(x2 + z2) * il2 - r2; }
    if (sign(y) * a2 * y2 < k) { return sqrt(x2 + y2) * il2 - r1; }
    return (sqrt(x2 * a2 * il2) + y * rr) * il2 - r1;
}

fn sdTriPrism(p_in: vec3<f32>, h_in: vec2<f32>) -> f32 {
    let k = sqrt(3.0);
    var h = h_in; h.x *= 0.5 * k;
    var p = p_in; p = vec3<f32>(p.xy / h.x, p.z);
    p.x = abs(p.x) - 1.0; p.y = p.y + 1.0 / k;
    if (p.x + k * p.y > 0.0) { p = vec3<f32>(vec2<f32>(p.x - k * p.y, -k * p.x - p.y) / 2.0, p.z); }
    p.x -= clamp(p.x, -2.0, 0.0);
    let d1 = length(p.xy) * sign(-p.y) * h.x;
    let d2 = abs(p.z) - h.y;
    return length(max(vec2<f32>(d1, d2), vec2<f32>(0.0))) + min(max(d1, d2), 0.0);
}

fn sdCylinder(p: vec3<f32>, h: vec2<f32>) -> f32 {
    let d = abs(vec2<f32>(length(p.xz), p.y)) - h;
    return min(max(d.x, d.y), 0.0) + length(max(d, vec2<f32>(0.0)));
}

fn sdCylinder2(p: vec3<f32>, a: vec3<f32>, b: vec3<f32>, r: f32) -> f32 {
    let pa = p - a; let ba = b - a;
    let baba = dot(ba, ba); let paba = dot(pa, ba);
    let x = length(pa * baba - ba * paba) - r * baba;
    let y = abs(paba - baba * 0.5) - baba * 0.5;
    let x2 = x * x; let y2 = y * y * baba;
    var d: f32;
    if (max(x, y) < 0.0) { d = -min(x2, y2); } 
    else { d = select(0.0, x2, x > 0.0) + select(0.0, y2, y > 0.0); }
    return sign(d) * sqrt(abs(d)) / baba;
}

fn sdCone(p: vec3<f32>, c: vec2<f32>, h: f32) -> f32 {
    let q = h * vec2<f32>(c.x, -c.y) / c.y;
    let w = vec2<f32>(length(p.xz), p.y);
    let a = w - q * clamp(dot(w, q) / dot(q, q), 0.0, 1.0);
    let b = w - q * vec2<f32>(clamp(w.x / q.x, 0.0, 1.0), 1.0);
    let k = sign(q.y);
    let d = min(dot(a, a), dot(b, b));
    let s = max(k * (w.x * q.y - w.y * q.x), k * (w.y - q.y));
    return sqrt(d) * sign(s);
}

fn sdCappedCone(p: vec3<f32>, h: f32, r1: f32, r2: f32) -> f32 {
    let q = vec2<f32>(length(p.xz), p.y);
    let k1 = vec2<f32>(r2, h); let k2 = vec2<f32>(r2 - r1, 2.0 * h);
    let ca = vec2<f32>(q.x - min(q.x, select(r2, r1, q.y < 0.0)), abs(q.y) - h);
    let cb = q - k1 + k2 * clamp(dot(k1 - q, k2) / dot2_v2(k2), 0.0, 1.0);
    let s = select(1.0, -1.0, cb.x < 0.0 && ca.y < 0.0);
    return s * sqrt(min(dot2_v2(ca), dot2_v2(cb)));
}

fn sdCappedCone2(p: vec3<f32>, a: vec3<f32>, b: vec3<f32>, ra: f32, rb: f32) -> f32 {
    let rba = rb - ra; let baba = dot(b - a, b - a);
    let papa = dot(p - a, p - a); let paba = dot(p - a, b - a) / baba;
    let x = sqrt(papa - paba * paba * baba);
    let cax = max(0.0, x - select(rb, ra, paba < 0.5));
    let cay = abs(paba - 0.5) - 0.5;
    let k = rba * rba + baba;
    let f = clamp((rba * (x - ra) + paba * baba) / k, 0.0, 1.0);
    let cbx = x - ra - f * rba; let cby = paba - f;
    let s = select(1.0, -1.0, cbx < 0.0 && cay < 0.0);
    return s * sqrt(min(cax * cax + cay * cay * baba, cbx * cbx + cby * cby * baba));
}

fn sdSolidAngle(pos: vec3<f32>, c: vec2<f32>, ra: f32) -> f32 {
    let p = vec2<f32>(length(pos.xz), pos.y);
    let l = length(p) - ra;
    let m = length(p - c * clamp(dot(p, c), 0.0, ra));
    return max(l, m * sign(c.y * p.x - c.x * p.y));
}

fn sdOctahedron(p_in: vec3<f32>, s: f32) -> f32 {
    let p = abs(p_in);
    let m = p.x + p.y + p.z - s;
    var q: vec3<f32>;
         if (3.0 * p.x < m) { q = p.xyz; }
    else if (3.0 * p.y < m) { q = p.yzx; }
    else if (3.0 * p.z < m) { q = p.zxy; }
    else { return m * 0.57735027; }
    let k = clamp(0.5 * (q.z - q.y + s), 0.0, s);
    return length(vec3<f32>(q.x, q.y - s + k, q.z - k));
}

fn sdPyramid(p_in: vec3<f32>, h: f32) -> f32 {
    let m2 = h * h + 0.25;
    var p = p_in; p.x = abs(p.x); p.z = abs(p.z);
    p = vec3<f32>(select(p.xz, p.zx, p.z > p.x), p.y).xzy;
    p.x -= 0.5; p.z -= 0.5;
    let q = vec3<f32>(p.z, h * p.y - 0.5 * p.x, h * p.x + 0.5 * p.y);
    let s = max(-q.x, 0.0);
    let t = clamp((q.y - 0.5 * p.z) / (m2 + 0.25), 0.0, 1.0);
    let a = m2 * (q.x + s) * (q.x + s) + q.y * q.y;
    let b = m2 * (q.x + 0.5 * t) * (q.x + 0.5 * t) + (q.y - m2 * t) * (q.y - m2 * t);
    let d2 = select(min(a, b), 0.0, min(q.y, -q.x * m2 - q.y * 0.5) > 0.0);
    return sqrt((d2 + q.z * q.z) / m2) * sign(max(q.z, -p.y));
}

fn sdRhombus(p_in: vec3<f32>, la: f32, lb: f32, h: f32, ra: f32) -> f32 {
    let p = abs(p_in); let b = vec2<f32>(la, lb);
    let f = clamp((ndot(b, b - 2.0 * p.xz)) / dot(b, b), -1.0, 1.0);
    let q = vec2<f32>(length(p.xz - 0.5 * b * vec2<f32>(1.0 - f, 1.0 + f)) * sign(p.x * b.y + p.z * b.x - b.x * b.y) - ra, p.y - h);
    return min(max(q.x, q.y), 0.0) + length(max(q, vec2<f32>(0.0)));
}

fn sdHorseshoe(p_in: vec3<f32>, c: vec2<f32>, r: f32, le: f32, w: vec2<f32>) -> f32 {
    var p = p_in; p.x = abs(p.x);
    let l = length(p.xy);
    p = vec3<f32>(mat2x2<f32>(-c.x, c.y, c.y, c.x) * p.xy, p.z);
    p = vec3<f32>(select(l * sign(-c.x), p.x, p.y > 0.0 || p.x > 0.0), select(l, p.y, p.x > 0.0), p.z);
    p = vec3<f32>(vec2<f32>(p.x, abs(p.y - r)) - vec2<f32>(le, 0.0), p.z);
    let q = vec2<f32>(length(max(p.xy, vec2<f32>(0.0))) + min(0.0, max(p.x, p.y)), p.z);
    let d = abs(q) - w;
    return min(max(d.x, d.y), 0.0) + length(max(d, vec2<f32>(0.0)));
}

// ==========================================
// 2. ĐỊNH NGHĨA THẾ GIỚI (MAP)
// ==========================================
fn map(pos: vec3<f32>) -> vec2<f32> {
    var res = vec2<f32>(pos.y, 0.0); // Mặt đất (Plane ngầm định pos.y)

    if (sdBox(pos - vec3<f32>(-2.0, 0.3, 0.25), vec3<f32>(0.3, 0.3, 1.0)) < res.x) {
        res = opU(res, vec2<f32>(sdSphere(pos - vec3<f32>(-2.0, 0.25, 0.0), 0.25), 26.9));
        res = opU(res, vec2<f32>(sdRhombus((pos - vec3<f32>(-2.0, 0.25, 1.0)).xzy, 0.15, 0.25, 0.04, 0.08), 17.0));
    }

    if (sdBox(pos - vec3<f32>(0.0, 0.3, -1.0), vec3<f32>(0.35, 0.3, 2.5)) < res.x) {
        res = opU(res, vec2<f32>(sdCappedTorus((pos - vec3<f32>(0.0, 0.30, 1.0)) * vec3<f32>(1.0, -1.0, 1.0), vec2<f32>(0.866025, -0.5), 0.25, 0.05), 25.0));
        res = opU(res, vec2<f32>(sdBoxFrame(pos - vec3<f32>(0.0, 0.25, 0.0), vec3<f32>(0.3, 0.25, 0.2), 0.025), 16.9));
        res = opU(res, vec2<f32>(sdCone(pos - vec3<f32>(0.0, 0.45, -1.0), vec2<f32>(0.6, 0.8), 0.45), 55.0));
        res = opU(res, vec2<f32>(sdCappedCone(pos - vec3<f32>(0.0, 0.25, -2.0), 0.25, 0.25, 0.1), 13.67));
        res = opU(res, vec2<f32>(sdSolidAngle(pos - vec3<f32>(0.0, 0.00, -3.0), vec2<f32>(3.0, 4.0) / 5.0, 0.4), 49.13));
    }

    if (sdBox(pos - vec3<f32>(1.0, 0.3, -1.0), vec3<f32>(0.35, 0.3, 2.5)) < res.x) {
        res = opU(res, vec2<f32>(sdTorus((pos - vec3<f32>(1.0, 0.30, 1.0)).xzy, vec2<f32>(0.25, 0.05)), 7.1));
        res = opU(res, vec2<f32>(sdBox(pos - vec3<f32>(1.0, 0.25, 0.0), vec3<f32>(0.3, 0.25, 0.1)), 3.0));
        res = opU(res, vec2<f32>(sdCapsule(pos - vec3<f32>(1.0, 0.00, -1.0), vec3<f32>(-0.1, 0.1, -0.1), vec3<f32>(0.2, 0.4, 0.2), 0.1), 31.9));
        res = opU(res, vec2<f32>(sdCylinder(pos - vec3<f32>(1.0, 0.25, -2.0), vec2<f32>(0.15, 0.25)), 8.0));
        res = opU(res, vec2<f32>(sdHexPrism(pos - vec3<f32>(1.0, 0.2, -3.0), vec2<f32>(0.2, 0.05)), 18.4));
    }

    if (sdBox(pos - vec3<f32>(-1.0, 0.35, -1.0), vec3<f32>(0.35, 0.35, 2.5)) < res.x) {
        res = opU(res, vec2<f32>(sdPyramid(pos - vec3<f32>(-1.0, -0.6, -3.0), 1.0), 13.56));
        res = opU(res, vec2<f32>(sdOctahedron(pos - vec3<f32>(-1.0, 0.15, -2.0), 0.35), 23.56));
        res = opU(res, vec2<f32>(sdTriPrism(pos - vec3<f32>(-1.0, 0.15, -1.0), vec2<f32>(0.3, 0.05)), 43.5));
        res = opU(res, vec2<f32>(sdEllipsoid(pos - vec3<f32>(-1.0, 0.25, 0.0), vec3<f32>(0.2, 0.25, 0.05)), 43.17));
        res = opU(res, vec2<f32>(sdHorseshoe(pos - vec3<f32>(-1.0, 0.25, 1.0), vec2<f32>(cos(1.3), sin(1.3)), 0.2, 0.3, vec2<f32>(0.03, 0.08)), 11.5));
    }

    if (sdBox(pos - vec3<f32>(2.0, 0.3, -1.0), vec3<f32>(0.35, 0.3, 2.5)) < res.x) {
        res = opU(res, vec2<f32>(sdOctogonPrism(pos - vec3<f32>(2.0, 0.2, -3.0), 0.2, 0.05), 51.8));
        res = opU(res, vec2<f32>(sdCylinder2(pos - vec3<f32>(2.0, 0.14, -2.0), vec3<f32>(0.1, -0.1, 0.0), vec3<f32>(-0.2, 0.35, 0.1), 0.08), 31.2));
        res = opU(res, vec2<f32>(sdCappedCone2(pos - vec3<f32>(2.0, 0.09, -1.0), vec3<f32>(0.1, 0.0, 0.0), vec3<f32>(-0.2, 0.40, 0.1), 0.15, 0.05), 46.1));
        res = opU(res, vec2<f32>(sdRoundCone2(pos - vec3<f32>(2.0, 0.15, 0.0), vec3<f32>(0.1, 0.0, 0.0), vec3<f32>(-0.1, 0.35, 0.1), 0.15, 0.05), 51.7));
        res = opU(res, vec2<f32>(sdRoundCone(pos - vec3<f32>(2.0, 0.20, 1.0), 0.2, 0.1, 0.3), 37.0));
    }

    return res;
}

// ==========================================
// 3. RAYCASTING, NORMALS VÀ LIGHTING
// ==========================================
fn iBox(ro: vec3<f32>, rd: vec3<f32>, rad: vec3<f32>) -> vec2<f32> {
    let m = 1.0 / rd; let n = m * ro; let k = abs(m) * rad;
    let t1 = -n - k; let t2 = -n + k;
    return vec2<f32>(max(max(t1.x, t1.y), t1.z), min(min(t2.x, t2.y), t2.z));
}

fn raycast(ro: vec3<f32>, rd: vec3<f32>) -> vec2<f32> {
    var res = vec2<f32>(-1.0, -1.0);
    var tmin = 1.0; var tmax = 20.0;

    let tp1 = (0.0 - ro.y) / rd.y;
    if (tp1 > 0.0) { tmax = min(tmax, tp1); res = vec2<f32>(tp1, 1.0); }

    let tb = iBox(ro - vec3<f32>(0.0, 0.4, -0.5), rd, vec3<f32>(2.5, 0.41, 3.0));
    if (tb.x < tb.y && tb.y > 0.0 && tb.x < tmax) {
        tmin = max(tb.x, tmin);
        tmax = min(tb.y, tmax);
        var t = tmin;
        for (var i = 0u; i < 70u && t < tmax; i++) {
            let h = map(ro + rd * t);
            if (abs(h.x) < (0.0001 * t)) { return vec2<f32>(t, h.y); }
            t += h.x;
        }
    }
    return res;
}

fn calcSoftshadow(ro: vec3<f32>, rd: vec3<f32>, mint: f32, tmax_in: f32) -> f32 {
    var tmax = tmax_in;
    let tp = (0.8 - ro.y) / rd.y; if (tp > 0.0) { tmax = min(tmax, tp); }
    var res = 1.0; var t = mint;
    
    for (var i = 0u; i < 24u; i++) {
        let h = map(ro + rd * t).x;
        let s = clamp(8.0 * h / t, 0.0, 1.0);
        res = min(res, s);
        t += clamp(h, 0.01, 0.2);
        if (res < 0.004 || t > tmax) { break; }
    }
    res = clamp(res, 0.0, 1.0);
    return res * res * (3.0 - 2.0 * res);
}

fn calcNormal(pos: vec3<f32>) -> vec3<f32> {
    var n = vec3<f32>(0.0);
    for (var i = 0u; i < 4u; i++) {
        let e = 0.5773 * (2.0 * vec3<f32>( f32(((i+3u)>>1u)&1u), f32(((i>>1u)&1u)), f32(i&1u) ) - 1.0);
        n += e * map(pos + 0.0005 * e).x;
    }
    return normalize(n);
}

fn calcAO(pos: vec3<f32>, nor: vec3<f32>) -> f32 {
    var occ = 0.0; var sca = 1.0;
    for (var i = 0u; i < 5u; i++) {
        let h = 0.01 + 0.12 * f32(i) / 4.0;
        let d = map(pos + h * nor).x;
        occ += (h - d) * sca;
        sca *= 0.95;
        if (occ > 0.35) { break; }
    }
    return clamp(1.0 - 3.0 * occ, 0.0, 1.0) * (0.5 + 0.5 * nor.y);
}

fn checkersGradBox(p: vec2<f32>, dpdx: vec2<f32>, dpdy: vec2<f32>) -> f32 {
    let w = abs(dpdx) + abs(dpdy) + vec2<f32>(0.001);
    let i = 2.0 * (abs(fract((p - 0.5 * w) * 0.5) - 0.5) - abs(fract((p + 0.5 * w) * 0.5) - 0.5)) / w;
    return 0.5 - 0.5 * i.x * i.y;
}

fn render(ro: vec3<f32>, rd: vec3<f32>, rdx: vec3<f32>, rdy: vec3<f32>) -> vec3<f32> {
    var col = vec3<f32>(0.7, 0.7, 0.9) - max(rd.y, 0.0) * 0.3;
    let res = raycast(ro, rd);
    let t = res.x; let m = res.y;

    if (m > -0.5) {
        let pos = ro + t * rd;
        let nor = select(calcNormal(pos), vec3<f32>(0.0, 1.0, 0.0), m < 1.5);
        let refl = reflect(rd, nor);
        
        col = 0.2 + 0.2 * sin(m * 2.0 + vec3<f32>(0.0, 1.0, 2.0));
        var ks = 1.0;
        
        if (m < 1.5) {
            let dpdx = ro.y * (rd / rd.y - rdx / rdx.y);
            let dpdy = ro.y * (rd / rd.y - rdy / rdy.y);
            let f = checkersGradBox(3.0 * pos.xz, 3.0 * dpdx.xz, 3.0 * dpdy.xz);
            col = vec3<f32>(0.15) + f * vec3<f32>(0.05);
            ks = 0.4;
        }

        let occ = calcAO(pos, nor);
        var lin = vec3<f32>(0.0);

        // Sun
        let lig = normalize(vec3<f32>(-0.5, 0.4, -0.6));
        let hal = normalize(lig - rd);
        let dif_sun = clamp(dot(nor, lig), 0.0, 1.0) * calcSoftshadow(pos, lig, 0.02, 2.5);
        let spe_sun = pow(clamp(dot(nor, hal), 0.0, 1.0), 16.0) * dif_sun * (0.04 + 0.96 * pow(clamp(1.0 - dot(hal, lig), 0.0, 1.0), 5.0));
        lin += col * 2.20 * dif_sun * vec3<f32>(1.30, 1.00, 0.70);
        lin += 5.00 * spe_sun * vec3<f32>(1.30, 1.00, 0.70) * ks;

        // Sky
        let dif_sky = sqrt(clamp(0.5 + 0.5 * nor.y, 0.0, 1.0)) * occ;
        let spe_sky = smoothstep(-0.2, 0.2, refl.y) * dif_sky * (0.04 + 0.96 * pow(clamp(1.0 + dot(nor, rd), 0.0, 1.0), 5.0)) * calcSoftshadow(pos, refl, 0.02, 2.5);
        lin += col * 0.60 * dif_sky * vec3<f32>(0.40, 0.60, 1.15);
        lin += 2.00 * spe_sky * vec3<f32>(0.40, 0.60, 1.30) * ks;

        // Back
        let dif_back = clamp(dot(nor, normalize(vec3<f32>(0.5, 0.0, 0.6))), 0.0, 1.0) * clamp(1.0 - pos.y, 0.0, 1.0) * occ;
        lin += col * 0.55 * dif_back * vec3<f32>(0.25, 0.25, 0.25);

        // SSS
        let dif_sss = pow(clamp(1.0 + dot(nor, rd), 0.0, 1.0), 2.0) * occ;
        lin += col * 0.25 * dif_sss * vec3<f32>(1.0, 1.0, 1.0);
        
        col = clamp(lin, vec3<f32>(0.0), vec3<f32>(1.0));
        col = mix(col, vec3<f32>(0.7, 0.7, 0.9), 1.0 - exp(-0.0001 * t * t * t));
    }
    return col;
}

// ==========================================
// 4. ĐIỂM BẮT ĐẦU (MAIN IMAGE)
// ==========================================
@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
    let fragCoord = vec2<f32>(in.position.x, uniforms.resolution.y - in.position.y);
    let iResolution = uniforms.resolution;

    let p = (2.0 * fragCoord - iResolution.xy) / iResolution.y;
    let px = (2.0 * (fragCoord + vec2<f32>(1.0, 0.0)) - iResolution.xy) / iResolution.y;
    let py = (2.0 * (fragCoord + vec2<f32>(0.0, 1.0)) - iResolution.xy) / iResolution.y;

    let time = 32.0 + uniforms.time * 1.5;

    let ta = vec3<f32>(0.25, -0.75, -0.75);
    let ro = ta + vec3<f32>(4.5 * cos(0.1 * time), 2.2, 4.5 * sin(0.1 * time));
    let ca = setCamera(ro, ta, 0.0);

    let fl = 2.5; 
    let rd = ca * normalize(vec3<f32>(p, fl));
    let rdx = ca * normalize(vec3<f32>(px, fl));
    let rdy = ca * normalize(vec3<f32>(py, fl));

    var col = render(ro, rd, rdx, rdy);
    col = pow(col, vec3<f32>(0.4545));

    return vec4<f32>(col, 1.0);
}