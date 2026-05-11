use nannou::prelude::*;
use nannou_egui::{egui, Egui};
use std::fs;

#[repr(C)]
#[derive(Copy, Clone, Debug, bytemuck::Pod, bytemuck::Zeroable)]
struct Uniforms {
    resolution: [f32; 2],
    time: f32,
    _padding: f32,
}

struct Model {
    egui: Egui,
    // Cho vào Option để dễ dàng thay thế pipeline lúc đang chạy
    render_pipeline: Option<wgpu::RenderPipeline>,
    bind_group: wgpu::BindGroup,
    uniform_buffer: wgpu::Buffer,
    pipeline_layout: wgpu::PipelineLayout, // Giữ lại layout để tái sử dụng
    current_scene_path: String,
}

fn main() {
    nannou::app(model).update(update).run();
}

fn model(app: &App) -> Model {
    let w_id = app.new_window().size(800, 600).raw_event(raw_window_event).view(view).build().unwrap();
    let window = app.window(w_id).unwrap();
    let device = window.device();

    // 1. Khởi tạo UI Egui
    let egui = Egui::from_window(&window);

    // 2. Khởi tạo Buffer và Bind Group (như cũ)
    let uniform_buffer = device.create_buffer(&wgpu::BufferDescriptor {
        label: Some("Uniform Buffer"),
        size: std::mem::size_of::<Uniforms>() as wgpu::BufferAddress,
        usage: wgpu::BufferUsages::UNIFORM | wgpu::BufferUsages::COPY_DST,
        mapped_at_creation: false,
    });

    let bind_group_layout = device.create_bind_group_layout(&wgpu::BindGroupLayoutDescriptor {
        label: Some("Uniform Bind Group Layout"),
        entries: &[wgpu::BindGroupLayoutEntry {
            binding: 0,
            visibility: wgpu::ShaderStages::FRAGMENT,
            ty: wgpu::BindingType::Buffer {
                ty: wgpu::BufferBindingType::Uniform,
                has_dynamic_offset: false,
                min_binding_size: None,
            },
            count: None,
        }],
    });

    let bind_group = device.create_bind_group(&wgpu::BindGroupDescriptor {
        label: Some("Uniform Bind Group"),
        layout: &bind_group_layout,
        entries: &[wgpu::BindGroupEntry {
            binding: 0,
            resource: uniform_buffer.as_entire_binding(),
        }],
    });

    let pipeline_layout = device.create_pipeline_layout(&wgpu::PipelineLayoutDescriptor {
        label: Some("Pipeline Layout"),
        bind_group_layouts: &[&bind_group_layout],
        push_constant_ranges: &[],
    });

    // Lúc mới khởi tạo, Pipeline có thể là None, hoặc load file mặc định
    let model = Model {
        egui,
        render_pipeline: None,
        bind_group,
        uniform_buffer,
        pipeline_layout,
        current_scene_path: "Chưa load file nào".to_string(),
    };

    // Tự động load file mặc định nếu muốn
    // load_shader(&window, &mut model, "src/scene.wgsl");

    model
}

// Bắt sự kiện bàn phím/chuột cho giao diện Egui
fn raw_window_event(_app: &App, model: &mut Model, event: &nannou::winit::event::WindowEvent) {
    model.egui.handle_raw_event(event);
}

fn update(app: &App, model: &mut Model, update: Update) {
    let window = app.main_window();
    let win_rect = window.rect();

    // Biến tạm để lưu đường dẫn file nếu người dùng chọn
    let mut file_to_load: Option<String> = None;

    // --- XỬ LÝ GIAO DIỆN NÚT BẤM ---
    {
        // Scope này giới hạn borrow của egui
        let egui = &mut model.egui;
        egui.set_elapsed_time(update.since_start);
        let ctx = egui.begin_frame();

        egui::Window::new("Shader Controller").show(&ctx, |ui| {
            ui.label(format!("Đang load: {}", model.current_scene_path));
            
            if ui.button("📁 Load Scene Shader...").clicked() {
                if let Some(path) = rfd::FileDialog::new()
                    .add_filter("WGSL Shader", &["wgsl"])
                    .pick_file() 
                {
                    // Chỉ lưu đường dẫn, không gọi model ở đây
                    file_to_load = Some(path.display().to_string());
                }
            }
        });
    } // egui trả lại quyền borrow model tại đây

    // --- XỬ LÝ LOAD FILE SAU KHI EGUI ĐÃ NHẢ MODEL ---
    if let Some(path_str) = file_to_load {
        model.current_scene_path = path_str.clone();
        load_shader(&window, model, &path_str);
    }

    // --- CẬP NHẬT UNIFORMS VÀO GPU ---
    let uniforms = Uniforms {
        resolution: [win_rect.w() as f32, win_rect.h() as f32],
        time: app.time,
        _padding: 0.0,
    };
    window.queue().write_buffer(&model.uniform_buffer, 0, bytemuck::cast_slice(&[uniforms]));
}

// Hàm phụ trách đọc file, ghép code và tạo lại Pipeline
fn load_shader(window: &Window, model: &mut Model, scene_path: &str) {
    let device = window.device();
    
    // Đọc file scene động từ đĩa
    let scene_shader_content = match fs::read_to_string(scene_path) {
        Ok(c) => c,
        Err(e) => {
            println!("Lỗi khi đọc file {}: {}", scene_path, e);
            return;
        }
    };

    // Chúng ta vẫn có thể dùng include_str! cho core vì nó hiếm khi thay đổi (thư viện toán học)
    // Hoặc bạn cũng có thể fs::read_to_string("src/core.wgsl") nếu muốn load động cả core.
    let core_shader = include_str!("core.wgsl");
    
    // Nối code lại với nhau
    let combined_shader = format!("{}\n{}", core_shader, scene_shader_content);

    // Tạo Shader Module mới
    let shader = device.create_shader_module(wgpu::ShaderModuleDescriptor {
        label: Some("Dynamic Ray Marching Shader"),
        source: wgpu::ShaderSource::Wgsl(std::borrow::Cow::Owned(combined_shader)),
    });

    // Tạo lại Render Pipeline
    let render_pipeline = device.create_render_pipeline(&wgpu::RenderPipelineDescriptor {
        label: Some("Dynamic Pipeline"),
        layout: Some(&model.pipeline_layout),
        vertex: wgpu::VertexState {
            module: &shader,
            entry_point: "vs_main",
            buffers: &[],
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
            count: window.msaa_samples(),
            ..Default::default()
        },
        multiview: None,
    });

    // Thay thế Pipeline cũ bằng Pipeline mới
    model.render_pipeline = Some(render_pipeline);
    println!("Nạp Shader thành công!");
}

// Thêm dấu gạch dưới vào _app để hết cảnh báo
fn view(_app: &App, model: &Model, frame: Frame) {
    
    // 1. VẼ SHADER RAYMARCHING
    if let Some(pipeline) = &model.render_pipeline {
        // --- Bắt đầu mượn encoder ---
        // Chúng ta đưa toàn bộ lệnh vẽ WGPU vào một Block { } 
        {
            let mut encoder = frame.command_encoder();
            let mut render_pass = encoder.begin_render_pass(&wgpu::RenderPassDescriptor {
                label: Some("Ray Marching Pass"),
                color_attachments: &[Some(wgpu::RenderPassColorAttachment {
                    view: frame.texture_view(),
                    resolve_target: None,
                    ops: wgpu::Operations {
                        load: wgpu::LoadOp::Clear(wgpu::Color::BLACK),
                        store: true,
                    },
                })],
                depth_stencil_attachment: None,
            });

            render_pass.set_pipeline(pipeline);
            render_pass.set_bind_group(0, &model.bind_group, &[]);
            render_pass.draw(0..3, 0..1);
        } // <--- Block kết thúc ở đây. Biến `encoder` và `render_pass` bị drop, trả lại quyền cho frame.
        // --- Kết thúc mượn encoder ---

    } else {
        // frame.clear tự động mượn và trả encoder ở bên trong
        frame.clear(nannou::color::DARKGRAY);
    }

    // 2. VẼ GIAO DIỆN EGUI ĐÈ LÊN TRÊN
    // Giờ đây frame hoàn toàn rảnh rỗi, Egui có thể mượn an toàn!
    model.egui.draw_to_frame(&frame).unwrap();
}