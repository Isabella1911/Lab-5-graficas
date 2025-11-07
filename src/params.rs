use glam::{Mat4, Vec3};

#[repr(C)]
#[derive(Clone, Copy, bytemuck::Pod, bytemuck::Zeroable)]
pub struct Params {
    pub time: f32,
    pub freq: f32,
    pub amp: f32,
    pub speed: f32,
    pub octaves: u32,
    pub seed: u32,
    pub temp_kelvin: f32, // para gradiente de color ( temperatura)
    pub cycle_t: f32,     // 0..1 para ciclo de pulsación
    pub scale: f32,      // escala global
    pub limb_pow: f32,   // factor de oscurecimiento en bordes
    pub rim_pow: f32,    // intensidad de la corona
    pub _padding: u32,   // necesario para alineación
}

#[repr(C)]
#[derive(Clone, Copy, bytemuck::Pod, bytemuck::Zeroable)]
pub struct Camera {
    view_proj: [f32; 16],
    camera_pos: [f32; 3],
    _padding: u32, // necesario para alineación
}

impl Camera {
    pub fn new() -> Self {
        Self {
            view_proj: Mat4::IDENTITY.to_cols_array(),
            camera_pos: [3.0, 2.0, 3.0],
            _padding: 0,
        }
    }

    pub fn update(&mut self, aspect: f32, time: f32) {
        // Movimiento orbital de la cámara
        let radius = 3.0;
        let height = 1.5 + (time * 0.2).sin() * 0.5;
        let angle = time * 0.3;
        
        let eye = Vec3::new(
            radius * angle.cos(),
            height,
            radius * angle.sin(),
        );
        let target = Vec3::ZERO;
        let up = Vec3::Y;

        let view = Mat4::look_at_rh(eye, target, up);
        let proj = Mat4::perspective_rh(45.0f32.to_radians(), aspect, 0.1, 100.0);
        
        self.view_proj = (proj * view).to_cols_array();
        self.camera_pos = eye.to_array();
    }
}