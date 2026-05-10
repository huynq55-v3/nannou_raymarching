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
// 2. THƯ VIỆN TOÁN HỌC & CAMERA (TỪ SHADERTOY)
// ==========================================
fn setCamera(ro: vec3<f32>, ta: vec3<f32>, cr: f32) -> mat3x3<f32> {
    let cw = normalize(ta - ro);
    let cp = vec3<f32>(sin(cr), cos(cr), 0.0);
    let cu = normalize(cross(cw, cp));
    let cv = cross(cu, cw);
    return mat3x3<f32>(cu, cv, cw);
}

// ==========================================
// 3. THƯ VIỆN HÌNH HỌC SDF
// ==========================================
fn sdPlane(p: vec3<f32>) -> f32 {
    return p.y;
}

fn sdSphere(p: vec3<f32>, s: f32) -> f32 {
    return length(p) - s;
}

// Bạn có thể copy paste dần các hàm sdBox, sdTorus của IQ vào đây sau...