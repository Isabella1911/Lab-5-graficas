mod renderer;
mod mesh;
mod uniforms;
mod params;

use std::time::Instant;
use params::Params;

fn main() -> anyhow::Result<()> {
    env_logger::try_init().ok();
    pollster::block_on(run())
}


async fn run() -> anyhow::Result<()> {
    use winit::event::{Event, WindowEvent};
    use winit::event_loop::EventLoop;
    use winit::window::WindowBuilder;

    // winit 0.29: new() -> Result<EventLoop, EventLoopError>
    let event_loop = EventLoop::new()?;
    let window = WindowBuilder::new()
        .with_title("Rust Star - Shaders + Noise")
        .build(&event_loop)?; // también Result

    let mut renderer = renderer::Renderer::new(&window).await?;

    let start = Instant::now();

    // winit 0.29: run(...) -> Result<(), EventLoopError>
   event_loop.run(|event, elwt| {
        match event {
            Event::WindowEvent { event: WindowEvent::CloseRequested, .. } => elwt.exit(),
            Event::WindowEvent { event: WindowEvent::Resized(size), .. } => {
                renderer.resize(size.width, size.height);
                window.request_redraw();
            }
            Event::AboutToWait => {
                let t = start.elapsed().as_secs_f32();
                let cycle = (t * 0.25).fract();

                let params = Params {
                    time: t,
                    freq: 4.0,     
                    amp: 0.35,     
                    speed: 0.5,    
                    octaves: 6,    
                    seed: 1337,
                    temp_kelvin: 6000.0,  
                    cycle_t: cycle,
                    scale: 1.0,
                    limb_pow: 0.3, 
                    rim_pow: 4.0,  
                    _padding: 0,
                };
                renderer.queue.write_buffer(&renderer.uniforms.params_buffer, 0, bytemuck::bytes_of(&params));

                if let Err(e) = renderer.render(t) {
                    eprintln!("Render error: {e:?}");
                }
                window.request_redraw();
            }
            _ => {}
        }
    })?; 

    Ok(())
}