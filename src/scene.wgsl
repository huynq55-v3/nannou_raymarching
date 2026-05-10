// ==========================================
// 1. ĐỊNH NGHĨA THẾ GIỚI (MAP)
// ==========================================
fn map(pos: vec3<f32>) -> vec2<f32> {
    var res = vec2<f32>(pos.y, 0.0);

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
// 2. RAYCASTING, NORMALS VÀ LIGHTING
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
// 3. ĐIỂM BẮT ĐẦU (MAIN IMAGE)
// ==========================================
@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
    // SỬA TRỤC Y: WGPU trục Y hướng xuống, Shadertoy hướng lên. 
    // Chúng ta lật ngược giá trị Y tại đây để thế giới không bị chổng ngược.
    let fragCoord = vec2<f32>(in.position.x, uniforms.resolution.y - in.position.y);
    let iResolution = uniforms.resolution;

    // Chuẩn bị các tia cho Anti-Aliasing/Lưới Caro thủ công (Ray Differentials)
    let p = (2.0 * fragCoord - iResolution.xy) / iResolution.y;
    let px = (2.0 * (fragCoord + vec2<f32>(1.0, 0.0)) - iResolution.xy) / iResolution.y;
    let py = (2.0 * (fragCoord + vec2<f32>(0.0, 1.0)) - iResolution.xy) / iResolution.y;

    let time = 32.0 + uniforms.time * 1.5;

    // Thiết lập Camera
    let ta = vec3<f32>(0.25, -0.75, -0.75);
    // Lưu ý: Đã bỏ qua mouse interaction (mo.x) để giữ chuẩn framework hiện tại của bạn
    let ro = ta + vec3<f32>(4.5 * cos(0.1 * time), 2.2, 4.5 * sin(0.1 * time));
    let ca = setCamera(ro, ta, 0.0);

    let fl = 2.5; // Focal length
    
    // Tạo 3 luồng tia để truyền vào cho việc xử lý răng cưa nền Caro 
    let rd = ca * normalize(vec3<f32>(p, fl));
    let rdx = ca * normalize(vec3<f32>(px, fl));
    let rdy = ca * normalize(vec3<f32>(py, fl));

    // Render cảnh
    var col = render(ro, rd, rdx, rdy);

    // Cân bằng sáng Gamma
    col = pow(col, vec3<f32>(0.4545));

    return vec4<f32>(col, 1.0);
}