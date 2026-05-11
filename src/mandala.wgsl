fn rot(a: f32) -> mat2x2<f32> {
    let c = cos(a);
    let s = sin(a);
    return mat2x2<f32>(c, s, -s, c);
}

// Đóng gói thuật toán Kali's Fractal vào một hàm để tính toán cho từng lớp (layer)
fn calc_mandala_layer(p_in: vec2<f32>, t: f32, twist_offset: f32) -> vec3<f32> {
    let pi = 3.14159265359;
    var p = p_in;
    
    // CỐ ĐỊNH 4 CÁNH: Toán học đối xứng hoàn hảo, không còn số thập phân
    var a = atan2(p.y, p.x);
    var r = length(p);
    let segment = (2.0 * pi) / 4.0; 

    // Gập không gian
    a = a - segment * floor(a / segment);
    a = abs(a - segment / 2.0);
    p = vec2<f32>(cos(a), sin(a)) * r;

    // Kali's Space Inversion (Lộn trái vũ trụ)
    var q = p;
    let offset = vec2<f32>(
        0.6 + 0.2 * sin(t * 1.1),
        0.6 + 0.2 * cos(t * 1.3)
    );

    var min_dist = 100.0;
    var iter_count = 0.0;

    for (var i = 0u; i < 14u; i++) {
        q = abs(q);
        let mag2 = max(dot(q, q), 0.001); 
        q = q / mag2 - offset;
        
        // twist_offset giúp các lớp không bị giống hệt nhau mà có nhịp thở riêng
        q = q * rot(pi / 4.0 + 0.1 * sin(t * 0.5) + twist_offset); 

        let d = length(q);
        min_dist = min(min_dist, d);
        iter_count += exp(-1.5 * d); 
    }

    // Tính toán màu năng lượng (Energy Glow)
    let phase = vec3<f32>(0.0, 0.33, 0.67) * pi * 2.0 + t * 2.0 + iter_count * 0.6;
    let base_color = 0.5 + 0.5 * cos(phase);
    let glow = 0.015 / max(min_dist, 0.002);
    
    return base_color * glow + vec3<f32>(iter_count * 0.04);
}

@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
    var uv = in.uv;
    let res_y = max(uniforms.resolution.y, 1.0);
    uv.x *= uniforms.resolution.x / res_y;

    let t = uniforms.time * 0.25;
    let pi = 3.14159265359;

    // morph chạy từ 0.0 đến 1.0 (Đóng vai trò là cường độ ánh sáng của cánh hoa phụ)
    let morph = smoothstep(-0.3, 0.3, sin(t * 1.5));

    // Phóng to thu nhỏ không gian tổng thể như nhịp thở
    let zoom = exp(sin(t * 0.8) * 1.2); 
    var p = uv * zoom;
    
    // Xoay từ từ toàn bộ Mandala
    p = p * rot(t * 0.3);

    // ==========================================
    // CƠ CHẾ CHUYỂN HÓA MƯỢT MÀ (ORGANIC BLOOM)
    // ==========================================
    
    // LỚP 1: Tứ Diệu Đế (Luôn tồn tại và phát sáng)
    var col1 = calc_mandala_layer(p, t, 0.0);

    // LỚP 2: Lớp ẩn. Xoay tọa độ đi 45 độ (PI/4) để nằm xem kẽ vào giữa các cánh của lớp 1
    var p2 = p * rot(pi / 4.0);
    // Truyền twist_offset = 0.15 để lớp thứ 2 có vân sáng vặn xoắn hơi khác lớp 1 một chút
    var col2 = calc_mandala_layer(p2, t, 0.15); 

    // KẾT HỢP NĂNG LƯỢNG (Additive Blending)
    // Khi morph = 0.0: col2 bị nhân với 0, biến mất vào bóng tối -> Chỉ thấy 4 cánh.
    // Khi morph = 1.0: Ánh sáng 2 lớp cộng gộp, đan vào nhau rực rỡ -> Nở ra 8 cánh.
    var final_col = col1 + col2 * morph;

    // Hãm độ lóa (auto-exposure) khi cả 8 cánh cùng phát sáng để không bị cháy màn hình
    final_col *= mix(1.0, 0.7, morph);

    // Vignette (Đổ bóng tối ở viền màn hình)
    final_col *= exp(-length(in.uv) * 2.5);
    
    // Diệt lỗi NaN và đẩy độ tương phản
    final_col = max(final_col, vec3<f32>(0.0));
    final_col = pow(final_col, vec3<f32>(1.2));

    return vec4<f32>(final_col, 1.0);
}