var<private> gTime: f32 = 0.0;

fn apply_rot(v: vec2<f32>, a: f32) -> vec2<f32> {
    let c = cos(a);
    let s = sin(a);
    return vec2<f32>(
        v.x * c + v.y * s,
        v.x * -s + v.y * c
    );
}

fn mod_vec3_f32(x: vec3<f32>, y: f32) -> vec3<f32> {
    return x - y * floor(x / y);
}

fn sdBox(p: vec3<f32>, b: vec3<f32>) -> f32 {
    let q = abs(p) - b;
    return length(max(q, vec3<f32>(0.0))) + min(max(q.x, max(q.y, q.z)), 0.0);
}

fn box(pos_in: vec3<f32>, scale: f32) -> f32 {
    var pos = pos_in * scale;
    let base = sdBox(pos, vec3<f32>(0.4, 0.4, 0.1)) / 1.5;
    
    pos.x *= 5.0;
    pos.y *= 5.0;
    pos.y -= 3.5;
    
    // Sửa lỗi Swizzle: Đọc từ xy thì được, nhưng phải gán từng biến
    let r = apply_rot(pos.xy, 0.75);
    pos.x = r.x;
    pos.y = r.y;
    
    return -base;
}

fn box_set(pos_in: vec3<f32>, iTime: f32) -> f32 {
    let pos_origin = pos_in;
    var pos = pos_origin;
    var r: vec2<f32>; // Biến tạm để lưu kết quả xoay
    
    pos.y += sin(gTime * 0.4) * 2.5;
    r = apply_rot(pos.xy, 0.8);
    pos.x = r.x; pos.y = r.y;
    let box1 = box(pos, 2.0 - abs(sin(gTime * 0.4)) * 1.5);
    
    pos = pos_origin;
    pos.y -= sin(gTime * 0.4) * 2.5;
    r = apply_rot(pos.xy, 0.8);
    pos.x = r.x; pos.y = r.y;
    let box2 = box(pos, 2.0 - abs(sin(gTime * 0.4)) * 1.5);
    
    pos = pos_origin;
    pos.x += sin(gTime * 0.4) * 2.5;
    r = apply_rot(pos.xy, 0.8);
    pos.x = r.x; pos.y = r.y;
    let box3 = box(pos, 2.0 - abs(sin(gTime * 0.4)) * 1.5);    
    
    pos = pos_origin;
    pos.x -= sin(gTime * 0.4) * 2.5;
    r = apply_rot(pos.xy, 0.8);
    pos.x = r.x; pos.y = r.y;
    let box4 = box(pos, 2.0 - abs(sin(gTime * 0.4)) * 1.5);    
    
    pos = pos_origin;
    r = apply_rot(pos.xy, 0.8);
    pos.x = r.x; pos.y = r.y;
    let box5 = box(pos, 0.5) * 6.0;    
    
    pos = pos_origin;
    let box6 = box(pos, 0.5) * 6.0;    
    
    return max(max(max(max(max(box1, box2), box3), box4), box5), box6);
}

fn map(pos: vec3<f32>, iTime: f32) -> f32 {
    return box_set(pos, iTime);
}

@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
    let iResolution = uniforms.resolution;
    let iTime = uniforms.time;
    
    var p = in.uv;
    let min_res = min(iResolution.x, iResolution.y);
    p.x *= iResolution.x / min_res;
    p.y *= iResolution.y / min_res;
    
    var ro = vec3<f32>(0.0, -0.2, iTime * 4.0);
    var ray = normalize(vec3<f32>(p, 1.5));
    
    // Sửa lỗi Swizzle cho việc xoay Camera
    let ray_xy = apply_rot(ray.xy, sin(iTime * 0.03) * 5.0);
    ray.x = ray_xy.x;
    ray.y = ray_xy.y;
    
    let ray_yz = apply_rot(vec2<f32>(ray.y, ray.z), sin(iTime * 0.05) * 0.2);
    ray.y = ray_yz.x;
    ray.z = ray_yz.y;
    
    var t = 0.1;
    var col = vec3<f32>(0.0);
    var ac = 0.0;
    
    for (var i = 0u; i < 99u; i++) {
        var pos = ro + ray * t;
        pos = mod_vec3_f32(pos - vec3<f32>(2.0), 4.0) - vec3<f32>(2.0);
        gTime = iTime - f32(i) * 0.01;
        
        var d = map(pos, iTime);
        d = max(abs(d), 0.01);
        ac += exp(-d * 23.0);
        
        t += d * 0.55;
    }
    
    col = vec3<f32>(ac * 0.02);
    col += vec3<f32>(0.0, 0.2 * abs(sin(iTime)), 0.5 + sin(iTime) * 0.2);
    
    let alpha = 1.0 - t * (0.02 + 0.02 * sin(iTime));
    return vec4<f32>(col, alpha);
}