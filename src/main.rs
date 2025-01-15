#[macro_use]
extern crate glium;

use glium::backend::glutin::glutin::dpi::PhysicalPosition;
use glium::glutin::event::WindowEvent::MouseInput;
use glium::glutin::event::{ElementState, MouseButton, VirtualKeyCode};
use glium::glutin::*;
use glium::{glutin, Surface};

fn main() {
    let mut width: i32 = 400;
    let mut height: i32 = 400;

    let event_loop = glutin::event_loop::EventLoop::new();
    let size: glutin::dpi::LogicalSize<u32> = (width, height).into();
    let wb = glutin::window::WindowBuilder::new()
        .with_title("Mandelbrot on GPU")
        .with_inner_size(size);
    let cb = glutin::ContextBuilder::new();
    let display = glium::Display::new(wb, cb, &event_loop).unwrap();

    let vertex_shader = include_str!("vertex.glsl");
    let fragment_shader = include_str!("fractal.glsl");

    // Compile shaders
    let program =
        glium::Program::from_source(&display, vertex_shader, fragment_shader, None).unwrap();

    #[derive(Copy, Clone)]
    struct Vertex {
        position: [f32; 2],
    }

    implement_vertex!(Vertex, position);

    // Render 2 triangles covering the whole screen
    let vertices = [
        // Top-left corner
        Vertex {
            position: [-1.0, 1.0],
        },
        Vertex {
            position: [1.0, 1.0],
        },
        Vertex {
            position: [-1.0, -1.0],
        },
        // Bottom-right corner
        Vertex {
            position: [-1.0, -1.0],
        },
        Vertex {
            position: [1.0, 1.0],
        },
        Vertex {
            position: [1.0, -1.0],
        },
    ];

    let vertex_buffer = glium::VertexBuffer::new(&display, &vertices).unwrap();
    let indices = glium::index::NoIndices(glium::index::PrimitiveType::TrianglesList);

    // depiction variables
    let mut zoom: f32 = 4.0;
    let mut c_x: f32 = 0.0;
    let mut c_y: f32 = 0.0;
    let mut max_iterations: i32 = 50;

    // keyboard input variables
    let mut dragging = false;
    let mut mouse_x: f32 = 0.0;
    let mut mouse_y: f32 = 0.0;
    let mut drag_offset_x: f32 = 0.0;
    let mut drag_offset_y: f32 = 0.0;

    // modes
    let mut color_algorithm: i32 = 0;
    let mut set: i32 = 0;
    let mut fractal_algorithm: i32 = 0;

    // Run Window
    event_loop.run(move |event, _, control_flow| {
        match event {
            // User input gets handled in this arm
            event::Event::WindowEvent { event, .. } => match event {
                // Close the window
                event::WindowEvent::CloseRequested => {
                    *control_flow = event_loop::ControlFlow::Exit;
                    return;
                }

                // When hitting Space
                // Switch between coloring alorithms
                event::WindowEvent::KeyboardInput {
                    input:
                        event::KeyboardInput {
                            virtual_keycode: Some(VirtualKeyCode::Space),
                            state: ElementState::Pressed,
                            ..
                        },
                    ..
                } => match color_algorithm {
                    0 => color_algorithm = 1,
                    1 => color_algorithm = 2,
                    2 => color_algorithm = 0,
                    _ => return,
                },

                // When hitting Tab
                // Switch between fractal algorithms
                event::WindowEvent::KeyboardInput {
                    input:
                        event::KeyboardInput {
                            virtual_keycode: Some(VirtualKeyCode::Tab),
                            state: ElementState::Pressed,
                            ..
                        },
                    ..
                } => match fractal_algorithm {
                    0 => fractal_algorithm = 1,
                    1 => fractal_algorithm = 2,
                    2 => fractal_algorithm = 3,
                    3 => fractal_algorithm = 4,
                    4 => fractal_algorithm = 5,
                    5 => fractal_algorithm = 0,
                    _ => return,
                },

                // When hitting Enter/Return
                // Switch between julia or mandelbrot set
                event::WindowEvent::KeyboardInput {
                    input:
                        event::KeyboardInput {
                            virtual_keycode: Some(VirtualKeyCode::Return),
                            state: ElementState::Pressed,
                            ..
                        },
                    ..
                } => match set {
                    0 => {
                        set = 1;
                        println!("re: {}, im: {}", drag_offset_x, drag_offset_y);
                    }
                    1 => {
                        set = 0;
                        println!("re: {}, im: {}", drag_offset_x, drag_offset_y);
                    }
                    _ => return,
                },

                // Do something when the mouse is moving
                glutin::event::WindowEvent::CursorMoved {
                    position: PhysicalPosition { x, y },
                    ..
                } => {
                    let x = x as f32;
                    let y = y as f32;
                    mouse_x = x;
                    mouse_y = y;
                }

                // Do something when the left mouse button is pressed or released
                MouseInput {
                    state: ElementState::Pressed,
                    button: MouseButton::Left,
                    ..
                } => {
                    dragging = true;
                    drag_offset_x = (mouse_x / width as f32 - 0.5) * zoom + c_x;
                    drag_offset_y = (mouse_y / height as f32 - 0.5) * zoom - c_y;
                }
                MouseInput {
                    state: ElementState::Released,
                    button: MouseButton::Left,
                    ..
                } => dragging = false,

                // Do something when the mouse wheel is being used
                glutin::event::WindowEvent::MouseWheel {
                    delta: glutin::event::MouseScrollDelta::LineDelta(_source, direction),
                    ..
                } => {
                    if direction == 1.0 {
                        zoom *= 0.9;
                    }
                    if direction == -1.0 {
                        zoom *= 1.0 / 0.9;
                    }
                }

                // else
                _ => return,
            },
            event::Event::NewEvents(cause) => match cause {
                event::StartCause::ResumeTimeReached { .. } => (),
                event::StartCause::Init => (),
                _ => return,
            },

            _ => (),
        }

        if dragging {
            c_x = -(mouse_x / width as f32 - 0.5) * zoom + drag_offset_x;
            c_y = (mouse_y / height as f32 - 0.5) * zoom - drag_offset_y;
        }

        // Frame Time
        let next_frame_time =
            std::time::Instant::now() + std::time::Duration::from_nanos(16_666_667);
        *control_flow = event_loop::ControlFlow::WaitUntil(next_frame_time);

        // update variables in this frame
        zoom = zoom;
        max_iterations = max_iterations;
        c_x = c_x;
        c_y = c_y;
        width = width;
        height = height;

        // update frame buffer
        let mut target = display.draw();
        target.clear_color(0.0, 0.0, 0.0, 1.0);
        let uniforms = uniform! {
            zoom: zoom,
            c_x: c_x,
            c_y: c_y,
            max_iterations: max_iterations,
            color_algorithm: color_algorithm,
            width: width,
            heigth: height,
            set: set,
            fractal_algorithm: fractal_algorithm
        };
        target
            .draw(
                &vertex_buffer,
                &indices,
                &program,
                &uniforms,
                &Default::default(),
            )
            .unwrap();
        target.finish().unwrap();
    });
}
