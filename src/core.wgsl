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
    // Kỹ thuật vẽ 1 tam giác khổng lồ phủ kín màn hình không cần Vertex Buffer
    var pos = array<vec2<f32>, 3>(
        vec2<f32>(-1.0, -1.0), vec2<f32>( 3.0, -1.0), vec2<f32>(-1.0,  3.0)
    );
    var out: VertexOutput;
    out.position = vec4<f32>(pos[id], 0.0, 1.0);
    out.uv = pos[id];
    return out;
}

// ==========================================
// 2. THƯ VIỆN TOÁN HỌC & CAMERA CƠ BẢN
// ==========================================
fn setCamera(ro: vec3<f32>, ta: vec3<f32>, cr: f32) -> mat3x3<f32> {
    let cw = normalize(ta - ro);
    let cp = vec3<f32>(sin(cr), cos(cr), 0.0);
    let cu = normalize(cross(cw, cp));
    let cv = cross(cu, cw);
    return mat3x3<f32>(cu, cv, cw);
}

// Các phép toán vector tối ưu cho SDF
fn dot2_v2(v: vec2<f32>) -> f32 { return dot(v, v); }
fn dot2_v3(v: vec3<f32>) -> f32 { return dot(v, v); }
fn ndot(a: vec2<f32>, b: vec2<f32>) -> f32 { return a.x * b.x - a.y * b.y; }

// ==========================================
// 3. CSG (CONSTRUCTIVE SOLID GEOMETRY)
// ==========================================
// Gộp 2 hình (Lấy hình gần hơn)
fn opU(d1: vec2<f32>, d2: vec2<f32>) -> vec2<f32> { 
    return select(d2, d1, d1.x < d2.x); 
}

// Bổ sung thêm opS và opI để Core hoàn chỉnh hơn (tùy chọn)
fn opS(d1: f32, d2: f32) -> f32 { return max(-d1, d2); } // Trừ hình
fn opI(d1: f32, d2: f32) -> f32 { return max(d1, d2); }  // Giao hình