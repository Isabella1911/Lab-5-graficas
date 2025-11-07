use wgpu::util::DeviceExt;

#[repr(C)]
#[derive(Clone, Copy, bytemuck::Pod, bytemuck::Zeroable)]
pub struct Vertex {
    pub position: [f32;3],
    pub normal: [f32;3],
}

impl Vertex {
    pub const ATTRS: [wgpu::VertexAttribute; 2] = wgpu::vertex_attr_array![0 => Float32x3, 1 => Float32x3];
    pub fn layout<'a>() -> wgpu::VertexBufferLayout<'a> {
        wgpu::VertexBufferLayout{
            array_stride: std::mem::size_of::<Vertex>() as u64,
            step_mode: wgpu::VertexStepMode::Vertex,
            attributes: &Self::ATTRS,
        }
    }
}

// UV sphere simple
pub fn build_uv_sphere(segments: u32, rings: u32, radius: f32) -> (Vec<Vertex>, Vec<u32>) {
    let mut v = Vec::new();
    let mut i = Vec::new();
    for y in 0..=rings {
        let vty = y as f32 / rings as f32;
        let theta = vty * std::f32::consts::PI;
        for x in 0..=segments {
            let vtx = x as f32 / segments as f32;
            let phi = vtx * std::f32::consts::TAU;
            let nx = phi.cos() * theta.sin();
            let ny = theta.cos();
            let nz = phi.sin() * theta.sin();
            v.push(Vertex{
                position: [radius*nx, radius*ny, radius*nz],
                normal:   [nx, ny, nz],
            });
        }
    }
    let stride = segments + 1;
    for y in 0..rings {
        for x in 0..segments {
            let a = y*stride + x;
            let b = a + 1;
            let c = a + stride;
            let d = c + 1;
            i.extend_from_slice(&[a, c, b, b, c, d].map(|k| k as u32));
        }
    }
    (v, i)
}

pub struct Mesh {
    pub vbuf: wgpu::Buffer,
    pub ibuf: wgpu::Buffer,
    pub idx_count: u32,
}

impl Mesh {
    pub fn new(device: &wgpu::Device, segments: u32, rings: u32, radius: f32) -> Self {
        let (verts, idx) = build_uv_sphere(segments, rings, radius);
        let vbuf = device.create_buffer_init(&wgpu::util::BufferInitDescriptor{
            label: Some("Sphere VBO"),
            contents: bytemuck::cast_slice(&verts),
            usage: wgpu::BufferUsages::VERTEX,
        });
        let ibuf = device.create_buffer_init(&wgpu::util::BufferInitDescriptor{
            label: Some("Sphere IBO"),
            contents: bytemuck::cast_slice(&idx),
            usage: wgpu::BufferUsages::INDEX,
        });
        Self{ vbuf, ibuf, idx_count: idx.len() as u32 }
    }
}