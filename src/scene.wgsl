// ==========================================
// 1. ĐỊNH NGHĨA THẾ GIỚI (MAP)
// ==========================================
fn map(pos: vec3<f32>) -> vec2<f32> {
    // Trả về vec2: x = khoảng cách, y = ID vật liệu
    // Trong bài này, ta chỉ vẽ 1 mặt phẳng, gắn cho nó ID là 1.0
    return vec2<f32>(sdPlane(pos), 1.0); 
}

// ==========================================
// 2. LOGIC TÔ MÀU & ĐỔ BÓNG (RENDER)
// ==========================================
fn render(ro: vec3<f32>, rd: vec3<f32>) -> vec3<f32> {
    // Màu nền trời (giống IQ)
    var col = vec3<f32>(0.7, 0.7, 0.9) - max(rd.y, 0.0) * 0.3; 

    // Vòng lặp Ray Marching
    var t = 0.0;
    var material_id = -1.0;
    
    for (var i = 0; i < 100; i++) {
        let p = ro + rd * t;
        let h = map(p);
        
        if (abs(h.x) < 0.001) {
            material_id = h.y;
            break;
        }
        t += h.x;
        if (t > 50.0) { break; }
    }

    // Nếu chạm vào vật thể (material_id > 0)
    if (material_id > 0.0) {
        let p = ro + rd * t;
        
        // Vẽ lưới Caro cho sàn (ID = 1.0)
        if (material_id == 1.0) {
            let cx = floor(p.x * 2.0);
            let cz = floor(p.z * 2.0);
            if (abs((cx + cz) % 2.0) < 0.5) {
                col = vec3<f32>(0.15); // Xám đậm
            } else {
                col = vec3<f32>(0.2);  // Xám nhạt
            }
        }
        
        // Hiệu ứng sương mù che lấp chân trời (Fog)
        col = mix(col, vec3<f32>(0.7, 0.7, 0.9), 1.0 - exp(-0.005 * t * t));
    }

    return col;
}

// ==========================================
// 3. ĐIỂM BẮT ĐẦU (MAIN IMAGE)
// ==========================================
@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
    // 1. Lấy tọa độ màn hình và sửa tỷ lệ (Aspect Ratio)
    var uv = in.uv;
    uv.x = uv.x * (uniforms.resolution.x / uniforms.resolution.y);

    // 2. Chuyển động Camera y hệt Shadertoy
    let time = uniforms.time;
    let ta = vec3<f32>(0.25, -0.75, -0.75); // Nhìn chéo xuống đất một chút
    // Phương trình quay vòng tròn bán kính 4.5
    let ro = ta + vec3<f32>(4.5 * cos(0.1 * time), 2.2, 4.5 * sin(0.1 * time)); 

    // 3. Tính toán tia sáng
    let cam = setCamera(ro, ta, 0.0);
    let fl = 2.5; // Focal length
    let rd = cam * normalize(vec3<f32>(uv, fl));

    // 4. Render
    var col = render(ro, rd);

    // 5. Gamma Correction (Nâng sáng vùng tối)
    col = pow(col, vec3<f32>(0.4545));

    return vec4<f32>(col, 1.0);
}