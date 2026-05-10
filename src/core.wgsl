// ==========================================
// 1. DATA TỪ RUST & VERTEX SHADER TRICK
// ==========================================
struct Uniforms {
    resolution: vec2<f32>,
    time: f32,
};
@group(0) @binding(0) var<uniform> uniforms: Uniforms;

struct VertexOutput {
    @builtin(position) position: vec4<f32>,
    @location(0) uv: vec2<f32>,
};

@vertex
fn vs_main(@builtin(vertex_index) id: u32) -> VertexOutput {
    var pos = array<vec2<f32>, 3>(
        vec2<f32>(-1.0, -1.0), vec2<f32>( 3.0, -1.0), vec2<f32>(-1.0,  3.0)
    );
    var out: VertexOutput;
    out.position = vec4<f32>(pos[id], 0.0, 1.0);
    out.uv = pos[id];
    return out;
}

// ==========================================
// 2. THƯ VIỆN TOÁN HỌC & CAMERA
// ==========================================
fn setCamera(ro: vec3<f32>, ta: vec3<f32>, cr: f32) -> mat3x3<f32> {
    let cw = normalize(ta - ro);
    let cp = vec3<f32>(sin(cr), cos(cr), 0.0);
    let cu = normalize(cross(cw, cp));
    let cv = cross(cu, cw);
    return mat3x3<f32>(cu, cv, cw);
}

fn dot2_v2(v: vec2<f32>) -> f32 { return dot(v, v); }
fn dot2_v3(v: vec3<f32>) -> f32 { return dot(v, v); }
fn ndot(a: vec2<f32>, b: vec2<f32>) -> f32 { return a.x * b.x - a.y * b.y; }
fn opU(d1: vec2<f32>, d2: vec2<f32>) -> vec2<f32> { return select(d2, d1, d1.x < d2.x); }

// ==========================================
// 3. THƯ VIỆN HÌNH HỌC SDF
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
    var p = p_in;
    p.x = abs(p.x);
    let k = select(length(p.xy), dot(p.xy, sc), sc.y * p.x > sc.x * p.y);
    return sqrt(dot(p, p) + ra * ra - 2.0 * ra * k) - rb;
}

fn sdHexPrism(p_in: vec3<f32>, h: vec2<f32>) -> f32 {
    let k = vec3<f32>(-0.8660254, 0.5, 0.57735);
    var p = abs(p_in);
    p = vec3<f32>(p.xy - 2.0 * min(dot(k.xy, p.xy), 0.0) * k.xy, p.z);
    let d = vec2<f32>(
        length(p.xy - vec2<f32>(clamp(p.x, -k.z * h.x, k.z * h.x), h.x)) * sign(p.y - h.x),
        p.z - h.y
    );
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
    let b = (r1 - r2) / h;
    let a = sqrt(1.0 - b * b);
    let k = dot(q, vec2<f32>(-b, a));
    if (k < 0.0) { return length(q) - r1; }
    if (k > a * h) { return length(q - vec2<f32>(0.0, h)) - r2; }
    return dot(q, vec2<f32>(a, b)) - r1;
}

fn sdRoundCone2(p: vec3<f32>, a: vec3<f32>, b: vec3<f32>, r1: f32, r2: f32) -> f32 {
    let ba = b - a; let l2 = dot(ba, ba); let rr = r1 - r2;
    let a2 = l2 - rr * rr; let il2 = 1.0 / l2;
    let pa = p - a; let y = dot(pa, ba); let z = y - l2;
    let x2 = dot2_v3(pa * l2 - ba * y);
    let y2 = y * y * l2; let z2 = z * z * l2;
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