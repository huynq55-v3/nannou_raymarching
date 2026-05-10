use nannou::prelude::*;

// 1. Định nghĩa "Kiện hàng" chứa dữ liệu truyền xuống GPU
// Phải dùng bytemuck để có thể ép kiểu thành mảng byte an toàn
#[repr(C)]
#[derive(Copy, Clone, Debug, bytemuck::Pod, bytemuck::Zeroable)]
struct Uniforms {
    resolution: [f32; 2],
    time: f32,
    _padding: f32, // Quy tắc của GPU: Dữ liệu phải vừa vặn với block 16 byte
}

// 2. Struct Model chứa các thành phần của GPU
struct Model {
    render_pipeline: wgpu::RenderPipeline,
    bind_group: wgpu::BindGroup,
    uniform_buffer: wgpu::Buffer,
}

fn main() {
    nannou::app(model).update(update).run();
}

fn model(app: &App) -> Model {
    let w_id = app.new_window().size(800, 600).view(view).build().unwrap();
    let window = app.window(w_id).unwrap();
    let device = window.device();

    let sample_count = window.msaa_samples();

    // Đọc 2 file riêng biệt (Lưu ý: bạn cần tạo 2 file này trong thư mục src)
    let core_shader = include_str!("core.wgsl");
    let scene_shader = include_str!("scene.wgsl");
    
    // Nối code Core lên trên, code Scene xuống dưới
    let combined_shader = format!("{}\n{}", core_shader, scene_shader);

    // Khởi tạo Shader từ chuỗi đã nối
    let shader = device.create_shader_module(wgpu::ShaderModuleDescriptor {
        label: Some("Ray Marching Shader"),
        // Lưu ý: dùng Cow::Owned vì biến combined_shader được tạo ra ở runtime
        source: wgpu::ShaderSource::Wgsl(std::borrow::Cow::Owned(combined_shader)), 
    });

    // Tạo Buffer trống trên GPU để chứa biến Uniforms
    let uniform_buffer = device.create_buffer(&wgpu::BufferDescriptor {
        label: Some("Uniform Buffer"),
        size: std::mem::size_of::<Uniforms>() as wgpu::BufferAddress,
        usage: wgpu::BufferUsages::UNIFORM | wgpu::BufferUsages::COPY_DST,
        mapped_at_creation: false,
    });

    // Định nghĩa cấu trúc khe cắm (Bind Group Layout)
    let bind_group_layout = device.create_bind_group_layout(&wgpu::BindGroupLayoutDescriptor {
        label: Some("Uniform Bind Group Layout"),
        entries: &[wgpu::BindGroupLayoutEntry {
            binding: 0,
            visibility: wgpu::ShaderStages::FRAGMENT, // Chỉ Fragment Shader mới cần thông số này
            ty: wgpu::BindingType::Buffer {
                ty: wgpu::BufferBindingType::Uniform,
                has_dynamic_offset: false,
                min_binding_size: None,
            },
            count: None,
        }],
    });

    // Cắm Buffer vào Khe cắm (Tạo Bind Group)
    let bind_group = device.create_bind_group(&wgpu::BindGroupDescriptor {
        label: Some("Uniform Bind Group"),
        layout: &bind_group_layout,
        entries: &[wgpu::BindGroupEntry {
            binding: 0,
            resource: uniform_buffer.as_entire_binding(),
        }],
    });

    // Lắp ráp Pipeline
    let pipeline_layout = device.create_pipeline_layout(&wgpu::PipelineLayoutDescriptor {
        label: Some("Pipeline Layout"),
        bind_group_layouts: &[&bind_group_layout],
        push_constant_ranges: &[],
    });

    let render_pipeline = device.create_render_pipeline(&wgpu::RenderPipelineDescriptor {
        label: Some("Ray Marching Pipeline"),
        layout: Some(&pipeline_layout),
        vertex: wgpu::VertexState {
            module: &shader,
            entry_point: "vs_main",
            buffers: &[], // Trống, vì ta dùng trick sinh đỉnh
        },
        fragment: Some(wgpu::FragmentState {
            module: &shader,
            entry_point: "fs_main",
            targets: &[Some(wgpu::ColorTargetState {
                format: Frame::TEXTURE_FORMAT,
                blend: Some(wgpu::BlendState::REPLACE),
                write_mask: wgpu::ColorWrites::ALL,
            })],
        }),
        primitive: wgpu::PrimitiveState::default(),
        depth_stencil: None,
        multisample: wgpu::MultisampleState {
            count: sample_count,
            ..Default::default()
        },
        multiview: None,
    });

    Model {
        render_pipeline,
        bind_group,
        uniform_buffer,
    }
}

// 3. Hàm update chạy liên tục (nhịp tim của Engine)
fn update(app: &App, model: &mut Model, _update: Update) {
    let window = app.main_window();
    let win_rect = window.rect();
    
    // Gói dữ liệu hiện tại
    let uniforms = Uniforms {
        resolution: [win_rect.w() as f32, win_rect.h() as f32],
        time: app.time, // Thời gian tính bằng giây từ lúc mở app
        _padding: 0.0,
    };

    // Truyền dữ liệu mới nhất xuống Buffer trên GPU
    window.queue().write_buffer(
        &model.uniform_buffer,
        0,
        bytemuck::cast_slice(&[uniforms]),
    );
}

// 4. Hàm vẽ: Kích hoạt Shader
fn view(_app: &App, model: &Model, frame: Frame) {
    // Không dùng frame.clear() nữa, ta tự tạo Render Pass thô
    let mut encoder = frame.command_encoder();
    let mut render_pass = encoder.begin_render_pass(&wgpu::RenderPassDescriptor {
        label: Some("Ray Marching Pass"),
        color_attachments: &[Some(wgpu::RenderPassColorAttachment {
            view: frame.texture_view(),
            resolve_target: None,
            ops: wgpu::Operations {
                load: wgpu::LoadOp::Clear(wgpu::Color::BLACK),
                store: true, // wgpu cũ dùng boolean
            },
        })],
        depth_stencil_attachment: None, // Bắt buộc phải giữ lại dòng này và đặt là None
    });

    // Gắn Shader và Uniforms, sau đó phát lệnh vẽ 3 đỉnh giả
    render_pass.set_pipeline(&model.render_pipeline);
    render_pass.set_bind_group(0, &model.bind_group, &[]);
    render_pass.draw(0..3, 0..1);
}