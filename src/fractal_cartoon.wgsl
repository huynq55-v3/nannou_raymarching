// "Fractal Cartoon" by Kali - Translated to WGSL

// --- CÁC THÔNG SỐ CÀI ĐẶT ---
const RAY_STEPS: i32 = 150;
const BRIGHTNESS: f32 = 1.2;
const GAMMA: f32 = 1.4;
const SATURATION: f32 = 0.65;
const DETAIL: f32 = 0.001;

// --- BIẾN TOÀN CỤC (Thay thế cho global variables của GLSL) ---
var<private> det: f32 = 0.0;
var<private> edge: f32 = 0.0;

// --- HÀM BỔ TRỢ TOÁN HỌC ---
// Đã lật ngược vị trí của s và -s để khớp với toán tử *= của GLSL
fn rot(a: f32) -> mat2x2<f32> {
    let s = sin(a); let c = cos(a);
    return mat2x2<f32>(vec2<f32>(c, -s), vec2<f32>(s, c)); 
}

// Bổ sung hàm mod (do WGSL không có sẵn mod() như GLSL)
fn mod_f(x: f32, y: f32) -> f32 { return x - y * floor(x / y); }
fn mod_v3(v: vec3<f32>, y: f32) -> vec3<f32> { return v - y * floor(v / y); }

// --- FRACTAL FORMULA ---
fn formula(p_in: vec4<f32>) -> vec4<f32> {
    var p = p_in;
    
    // p.xz = abs(p.xz+1.)-abs(p.xz-1.)-p.xz;
    let pxz = abs(p.xz + vec2<f32>(1.0)) - abs(p.xz - vec2<f32>(1.0)) - p.xz;
    p.x = pxz.x; p.z = pxz.y;
    
    p.y -= 0.25;
    
    // p.xy *= rot(radians(35.));
    let pxy = rot(radians(35.0)) * p.xy;
    p.x = pxy.x; p.y = pxy.y;
    
    let sq = clamp(dot(p.xyz, p.xyz), 0.2, 1.0);
    p = p * 2.0 / sq;
    return p;
}

// --- DISTANCE ESTIMATOR ---
fn de(pos_in: vec3<f32>) -> f32 {
    var pos = pos_in;
    let t = uniforms.time * 0.5;
    
    // WAVES
    pos.y += sin(pos.z - t * 6.0) * 0.15; 
    
    var tpos = pos;
    tpos.z = abs(3.0 - mod_f(tpos.z, 6.0));
    var p = vec4<f32>(tpos, 1.0);
    
    for (var i = 0; i < 4; i++) {
        p = formula(p);
    }
    
    let fr = (length(max(vec2<f32>(0.0), p.yz - vec2<f32>(1.5))) - 1.0) / p.w;
    var ro = max(abs(pos.x + 1.0) - 0.3, pos.y - 0.35);
    ro = max(ro, -max(abs(pos.x + 1.0) - 0.1, pos.y - 0.5));
    pos.z = abs(0.25 - mod_f(pos.z, 0.5));
    ro = max(ro, -max(abs(pos.z) - 0.2, pos.y - 0.3));
    ro = max(ro, -max(abs(pos.z) - 0.01, -pos.y + 0.32));
    
    return min(fr, ro);
}

// --- CAMERA PATH ---
fn path(ti_in: f32) -> vec3<f32> {
    let ti = ti_in * 1.5;
    return vec3<f32>(sin(ti), (1.0 - sin(ti * 2.0)) * 0.5, -ti * 5.0) * 0.5;
}

// --- NORMAL VÀ EDGE DETECTION ---
fn normal(p: vec3<f32>) -> vec3<f32> {
    let e = vec3<f32>(0.0, det * 5.0, 0.0);
    
    let d1 = de(p - e.yxx); let d2 = de(p + e.yxx);
    let d3 = de(p - e.xyx); let d4 = de(p + e.xyx);
    let d5 = de(p - e.xxy); let d6 = de(p + e.xxy);
    let d = de(p);
    
    // Edge finder
    edge = abs(d - 0.5 * (d2 + d1)) + abs(d - 0.5 * (d4 + d3)) + abs(d - 0.5 * (d6 + d5));
    edge = min(1.0, pow(edge, 0.55) * 15.0);
    
    return normalize(vec3<f32>(d1 - d2, d3 - d4, d5 - d6));
}

// --- CẦU VỒNG ---
fn rainbow(p_in: vec2<f32>) -> vec4<f32> {
    var p = p_in;
    let t = uniforms.time * 0.5;
    let s = sin(p.x * 7.0 + t * 70.0) * 0.08;
    p.y += s;
    p.y *= 1.1;
    
    var c = vec4<f32>(0.0);
    if (p.x > 0.0) { c = vec4<f32>(0.0); } 
    else if (p.y > 0.0 && p.y < 1.0/6.0) { c = vec4<f32>(255.0, 43.0, 14.0, 255.0)/255.0; }
    else if (p.y >= 1.0/6.0 && p.y < 2.0/6.0) { c = vec4<f32>(255.0, 168.0, 6.0, 255.0)/255.0; }
    else if (p.y >= 2.0/6.0 && p.y < 3.0/6.0) { c = vec4<f32>(255.0, 244.0, 0.0, 255.0)/255.0; }
    else if (p.y >= 3.0/6.0 && p.y < 4.0/6.0) { c = vec4<f32>(51.0, 234.0, 5.0, 255.0)/255.0; }
    else if (p.y >= 4.0/6.0 && p.y < 5.0/6.0) { c = vec4<f32>(8.0, 163.0, 255.0, 255.0)/255.0; }
    else if (p.y >= 5.0/6.0 && p.y < 6.0/6.0) { c = vec4<f32>(122.0, 85.0, 255.0, 255.0)/255.0; }
    else if (abs(p.y) - 0.05 < 0.0001) { c = vec4<f32>(0.0, 0.0, 0.0, 1.0); }
    else if (abs(p.y - 1.0) - 0.05 < 0.0001) { c = vec4<f32>(0.0, 0.0, 0.0, 1.0); }
    
    c.w *= 0.8 - min(0.8, abs(p.x * 0.08));
    c = vec4<f32>(mix(c.xyz, vec3<f32>(length(c.xyz)), 0.15), c.w);
    return c;
}

// --- GIẢ LẬP NYAN CAT (Không cần dùng Texture) ---
fn nyan(p_in: vec2<f32>) -> vec4<f32> {
    var uv = p_in * vec2<f32>(0.4, 1.0);
    var color = vec4<f32>(0.0);
    
    // Vẽ khối Poptart màu hồng nhạt làm thân mèo giả lập thay vì load texture
    if (uv.x > -0.3 && uv.x < 0.2 && uv.y > -0.3 && uv.y < 0.3) {
        color = vec4<f32>(0.9, 0.6, 0.7, 1.0); 
    }
    // Viền đen giả lập
    if (abs(uv.x) > 0.15 && abs(uv.y) > 0.2) {
        color = vec4<f32>(0.1, 0.1, 0.1, color.w);
    }

    if (uv.x < -0.3 || uv.x > 0.2 || uv.y > 0.3 || uv.y < -0.3) {
        color.w = 0.0;
    }
    return color;
}

// --- CAMERA MOVEMENT (Đã sửa lỗi Vector) ---
fn calculate_camera(dir_in: vec3<f32>) -> CameraData {
    var dir = dir_in;
    let t = uniforms.time * 0.5;
    
    let go = path(t);
    let adv = path(t + 0.7);
    let advec = normalize(adv - go);
    
    var an = adv.x - go.x;
    an *= min(1.0, abs(adv.z - go.z)) * sign(adv.z - go.z) * 0.7;
    
    // FIX: Dùng biến tạm để không bị đè giá trị
    let dxy = rot(an) * dir.xy;
    dir.x = dxy.x; dir.y = dxy.y;
    
    an = advec.y * 1.7;
    let dyz = rot(an) * dir.yz;
    dir.y = dyz.x; dir.z = dyz.y;
    
    an = atan2(advec.x, advec.z);
    let dxz = rot(an) * dir.xz;
    dir.x = dxz.x; dir.z = dxz.y;
    
    return CameraData(go, dir);
}

struct CameraData {
    origin: vec3<f32>,
    dir: vec3<f32>,
}

// --- RAYMARCHING VÀ ĐỔ MÀU ---
fn raymarch(ro: vec3<f32>, dir_in: vec3<f32>) -> vec3<f32> {
    var dir = dir_in;
    let t = uniforms.time * 0.5;
    
    edge = 0.0;
    var p = vec3<f32>(0.0);
    var norm = vec3<f32>(0.0);
    var d = 100.0;
    var totdist = 0.0;
    
    // Raymarching loop
    for (var i = 0; i < RAY_STEPS; i++) {
        if (d > det && totdist < 25.0) {
            p = ro + totdist * dir;
            d = de(p);
            det = DETAIL * exp(0.13 * totdist);
            totdist += d;
        }
    }
    
    var col = vec3<f32>(0.0);
    p -= (det - d) * dir;
    norm = normal(p);
    
    // Tô màu theo vector Pháp tuyến (Normal) kết hợp viền tối
    col = (1.0 - abs(norm)) * max(0.0, 1.0 - edge * 0.8);
    
    totdist = clamp(totdist, 0.0, 26.0);
    dir.y -= 0.02;
    
    // Mặt trời giả lập (Thay thế iChannel0 Audio)
    let sun_pulse = sin(uniforms.time * 5.0) * 0.5 + 0.5;
    let sunsize = 7.0 - max(0.0, sun_pulse) * 5.0; 
    let an = atan2(dir.x, dir.y) + uniforms.time * 1.5; 
    
    let s = pow(clamp(1.0 - length(dir.xy) * sunsize - abs(0.2 - mod_f(an, 0.4)), 0.0, 1.0), 0.1);
    let sb = pow(clamp(1.0 - length(dir.xy) * (sunsize - 0.2) - abs(0.2 - mod_f(an, 0.4)), 0.0, 1.0), 0.1);
    let sg = pow(clamp(1.0 - length(dir.xy) * (sunsize - 4.5) - 0.5 * abs(0.2 - mod_f(an, 0.4)), 0.0, 1.0), 3.0);
    let y = mix(0.45, 1.2, pow(smoothstep(0.0, 1.0, 0.75 - dir.y), 2.0)) * (1.0 - sb * 0.5);
    
    // Nền trời
    var backg = vec3<f32>(0.5, 0.0, 1.0) * ((1.0 - s) * (1.0 - sg) * y + (1.0 - sb) * sg * vec3<f32>(1.0, 0.8, 0.15) * 3.0);
    backg += vec3<f32>(1.0, 0.9, 0.1) * s;
    backg = max(backg, sg * vec3<f32>(1.0, 0.9, 0.5));
    
    col = mix(vec3<f32>(1.0, 0.9, 0.3), col, exp(-0.004 * totdist * totdist));
    if (totdist > 25.0) { col = backg; } // Hit background
    
    col = pow(col, vec3<f32>(GAMMA)) * BRIGHTNESS;
    col = mix(vec3<f32>(length(col)), col, SATURATION);
    col *= vec3<f32>(1.0, 0.9, 0.85);
    
    // NYAN CAT VÀ CẦU VỒNG (Bay trên bầu trời)
    let d_xy = rot(dir.x) * dir.yx;
    var n_dir = dir;
    n_dir.y = d_xy.x; n_dir.x = d_xy.y;
    
    let ncatpos = n_dir.xy + vec2<f32>(-3.0 + mod_f(-t, 6.0), -0.27);
    let ncat = nyan(ncatpos * 5.0);
    let rain = rainbow(ncatpos * 10.0 + vec2<f32>(0.8, 0.5));
    
    if (totdist > 8.0) { col = mix(col, max(vec3<f32>(0.2), rain.xyz), rain.w * 0.9); }
    if (totdist > 8.0) { col = mix(col, max(vec3<f32>(0.2), ncat.xyz), ncat.w * 0.9); }
    
    return col;
}

// ==========================================
// ĐIỂM VÀO SHADER (MAIN IMAGE)
// ==========================================
@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
    let fragCoord = vec2<f32>(in.position.x, uniforms.resolution.y - in.position.y);
    let iResolution = uniforms.resolution;
    
    var uv = fragCoord.xy / iResolution.xy * 2.0 - vec2<f32>(1.0);
    let oriuv = uv;
    uv.y *= iResolution.y / iResolution.x;
    
    let mouse = vec2<f32>(0.0, -0.05); 
    
    let fov = 0.9 - max(0.0, 0.7 - uniforms.time * 0.3);
    var dir = normalize(vec3<f32>(uv * fov, 1.0));
    
    // FIX: Sửa lỗi xoay chuột ở đây
    let dyz = rot(mouse.y) * dir.yz;
    dir.y = dyz.x; dir.z = dyz.y;
    
    let dxz = rot(mouse.x) * dir.xz;
    dir.x = dxz.x; dir.z = dxz.y;
    
    let origin = vec3<f32>(-1.0, 0.7, 0.0);
    let cam = calculate_camera(dir);
    let ro = origin + cam.origin;
    dir = cam.dir;
    
    var color = raymarch(ro, dir);
    
    let sq_uv = oriuv * oriuv * oriuv * vec2<f32>(1.05, 1.1);
    color = mix(vec3<f32>(0.0), color, pow(max(0.0, 0.95 - length(sq_uv)), 0.3));
    
    return vec4<f32>(color, 1.0);
}