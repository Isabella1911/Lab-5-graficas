// ---------- noise (value noise 3D + fbm) ----------
fn hash3(p: vec3<f32>) -> f32 {
    let h = dot(p, vec3<f32>(127.1, 311.7, 74.7));
    return fract(sin(h) * 43758.5453);
}

fn noise3(p: vec3<f32>) -> f32 {
    let i = floor(p);
    let f = fract(p);

    let n000 = hash3(i + vec3<f32>(0.0,0.0,0.0));
    let n100 = hash3(i + vec3<f32>(1.0,0.0,0.0));
    let n010 = hash3(i + vec3<f32>(0.0,1.0,0.0));
    let n110 = hash3(i + vec3<f32>(1.0,1.0,0.0));
    let n001 = hash3(i + vec3<f32>(0.0,0.0,1.0));
    let n101 = hash3(i + vec3<f32>(1.0,0.0,1.0));
    let n011 = hash3(i + vec3<f32>(0.0,1.0,1.0));
    let n111 = hash3(i + vec3<f32>(1.0,1.0,1.0));

    let u = f * f * (3.0 - 2.0 * f);

    let nx00 = mix(n000, n100, u.x);
    let nx10 = mix(n010, n110, u.x);
    let nx01 = mix(n001, n101, u.x);
    let nx11 = mix(n011, n111, u.x);

    let nxy0 = mix(nx00, nx10, u.y);
    let nxy1 = mix(nx01, nx11, u.y);

    return mix(nxy0, nxy1, u.z);
}

fn ridgenoise(p: vec3<f32>) -> f32 {
    return 1.0 - abs(noise3(p) * 2.0 - 1.0);
}

fn voronoi(p: vec3<f32>) -> f32 {
    let i = floor(p);
    let f = fract(p);

    var min_dist = 1.0;
    for (var x: i32 = -1; x <= 1; x = x + 1) {
        for (var y: i32 = -1; y <= 1; y = y + 1) {
            for (var z: i32 = -1; z <= 1; z = z + 1) {
                let neighbor = vec3<f32>(f32(x), f32(y), f32(z));
                let point = neighbor + vec3<f32>(
                    hash3(i + neighbor),
                    hash3(i + neighbor + vec3<f32>(37.0, 17.0, 53.0)),
                    hash3(i + neighbor + vec3<f32>(13.0, 71.0, 29.0))
                ) - f;
                min_dist = min(min_dist, dot(point, point));
            }
        }
    }
    return sqrt(min_dist);
}

fn fbm(p: vec3<f32>, octaves: u32) -> f32 {
    var sum = 0.0;
    var amp = 0.5;
    var freq = 1.0;
    var i: u32 = 0u;
    loop {
        if (i >= octaves) { break; }
        sum = sum + amp * noise3(p * freq);
        freq = freq * 2.0;
        amp  = amp * 0.5;
        i = i + 1u;
    }
    return sum;
}

fn ridge_fbm(p: vec3<f32>, octaves: u32) -> f32 {
    var sum = 0.0;
    var amp = 0.5;
    var freq = 1.0;
    var i: u32 = 0u;
    loop {
        if (i >= octaves) { break; }
        sum = sum + amp * ridgenoise(p * freq);
        freq = freq * 2.0;
        amp  = amp * 0.5;
        i = i + 1u;
    }
    return sum;
}

// ---------- uniforms ----------
struct Camera {
    view_proj: mat4x4<f32>,
    camera_pos: vec3<f32>,
};

struct Params {
    time: f32,
    freq: f32,
    amp: f32,
    speed: f32,
    octaves: u32,
    seed: u32,
    temp_kelvin: f32,
    cycle_t: f32,
};

@group(0) @binding(0) var<uniform> params: Params;
@group(0) @binding(1) var<uniform> camera: Camera;

// ---------- VS/FS IO ----------
struct VSIn {
    @location(0) pos: vec3<f32>,
    @location(1) nrm: vec3<f32>,
};

struct VSOut {
    @builtin(position) pos_cs: vec4<f32>,
    @location(0) nrm_ws: vec3<f32>,
    @location(1) pos_ws: vec3<f32>,
    @location(2) orig_pos: vec3<f32>,
    @location(3) view_dir: vec3<f32>,
};

// ---------- Vertex Shader ----------
@vertex
fn vs_main(in: VSIn) -> VSOut {
    let p = normalize(in.nrm);
    let t = params.time * params.speed;

    let base_turb   = ridge_fbm(p * params.freq + vec3<f32>(t, t*0.7, -t*0.4), params.octaves);
    let detail_turb = fbm(p * params.freq * 2.0 + vec3<f32>(t*0.3, -t*0.5, t*0.2), params.octaves);
    let cells       = voronoi(p * params.freq * 3.0 + vec3<f32>(-t*0.2, t*0.4, t*0.3));

    let base_distortion   = pow(max(0.0, base_turb), 2.0) * 0.8;
    let detail_distortion = (detail_turb - 0.5) * 0.4;
    let cell_distortion   = (cells - 0.5) * 0.3;

    let total_distortion = params.amp * (base_distortion + detail_distortion + cell_distortion);

    let pos_ws = (1.0 + total_distortion) * in.pos;
    let pos_cs = camera.view_proj * vec4<f32>(pos_ws, 1.0);

    var out: VSOut;
    out.pos_cs   = pos_cs;
    out.nrm_ws   = normalize(in.nrm);
    out.pos_ws   = pos_ws;
    out.orig_pos = in.pos;
    out.view_dir = normalize(camera.camera_pos - pos_ws);
    return out;
}

// ---------- util color ----------
fn kelvin_to_rgb(temp: f32) -> vec3<f32> {
    var temperature = clamp(temp, 1000.0, 40000.0) / 100.0;
    var color = vec3<f32>(1.0);

    if (temperature <= 66.0) {
        color.r = 1.0;
    } else {
        color.r = clamp(329.698727446 * pow(temperature - 60.0, -0.1332047592), 0.0, 255.0) / 255.0;
    }

    if (temperature <= 66.0) {
        color.g = clamp(99.4708025861 * log(temperature) - 161.1195681661, 0.0, 255.0) / 255.0;
    } else {
        color.g = clamp(288.1221695283 * pow(temperature - 60.0, -0.0755148492), 0.0, 255.0) / 255.0;
    }

    if (temperature >= 66.0) {
        color.b = 1.0;
    } else if (temperature <= 19.0) {
        color.b = 0.0;
    } else {
        color.b = clamp(138.5177312231 * log(temperature - 10.0) - 305.0447927307, 0.0, 255.0) / 255.0;
    }
    return color;
}

// Atmósfera fría (más azul, menos lavado)
fn atmospheric_scattering(view_dir: vec3<f32>, normal: vec3<f32>) -> vec3<f32> {
    let fresnel = pow(max(0.0, 1.0 - dot(view_dir, normal)), 2.5);
    return vec3<f32>(0.25, 0.55, 1.0) * fresnel * 3.0;
}

// ---------- Fragment Shader ----------
@fragment
fn fs_main(in: VSOut) -> @location(0) vec4<f32> {
    let t = params.time * params.speed;

    let base_turb   = ridge_fbm(in.nrm_ws * params.freq + vec3<f32>(t, t*0.7, -t*0.4), params.octaves);
    let detail_turb = fbm(in.nrm_ws * params.freq * 2.0 + vec3<f32>(t*0.3, -t*0.5, t*0.2), params.octaves);
    let plasma      = voronoi(in.nrm_ws * params.freq * 3.0 + vec3<f32>(-t*0.2, t*0.4, t*0.3));

    let pulse     = 0.5 + 0.5 * sin(6.28318 * params.cycle_t);
    let pulse_var = 0.5 + 0.3 * sin(6.28318 * params.cycle_t * 1.3);

    let solar_flares   = pow(max(0.0, base_turb * 1.5), 2.5);
    let plasma_effect  = pow(max(0.0, 1.0 - plasma), 2.0);
    let granulation    = pow(max(0.0, detail_turb), 1.8);

    // -------- PALETA FRÍA (reforzada) --------
    let hot_zones    = smoothstep(0.7, 1.0, solar_flares);
    let medium_zones = smoothstep(0.4, 0.7, solar_flares);
    let cool_zones   = smoothstep(0.0, 0.4, solar_flares);

    // Más azules, menos blanco
    let white_hot   = vec3<f32>(0.50, 0.56, 1.00);
    let blue_white  = vec3<f32>(0.55, 0.42, 1.00);
    let cyan_medium = vec3<f32>(0.75, 0.78, 1.00);
    let blue_cool   = vec3<f32>(0.96, 0.84, 1.00);
    let deep_blue   = vec3<f32>(0.93, 0.88, 0.35);

    var base_color = deep_blue;
    base_color = mix(base_color, blue_cool,   cool_zones);
    base_color = mix(base_color, cyan_medium, medium_zones);
    base_color = mix(base_color, blue_white,  hot_zones);
    // Limitar mezcla a blanco para evitar “wash-out”
    base_color = mix(base_color, white_hot,   smoothstep(0.92, 1.0, solar_flares) * 0.6);

    // Plasma más azul
    let plasma_color = mix(
        vec3<f32>(0.15, 0.55, 1.00),
        vec3<f32>(0.80, 0.90, 1.00),
        plasma_effect
    );
    base_color = mix(base_color, plasma_color, plasma_effect * 0.45);

    // Intensidades
    let core_intensity   = 3.2 + 1.8 * pulse;
    let flare_intensity  = 2.8 * solar_flares;
    let plasma_intensity = 2.3 * plasma_effect * pulse_var;
    let grain_intensity  = 1.4 * granulation;

    let total_intensity = clamp(
        core_intensity + flare_intensity + plasma_intensity + grain_intensity,
        0.0, 12.0
    );

    var core_color = base_color * total_intensity;

    // Corona reforzando azules (menos brillo para no blanquear)
    let dist_from_center = length(in.pos_ws);
    let edge_factor  = smoothstep(0.8, 1.1, dist_from_center);
    let corona_glow  = pow(edge_factor, 1.5) * (3.5 + 1.8 * pulse);

    let inner_corona = vec3<f32>(0.82, 0.90, 1.00);
    let mid_corona   = vec3<f32>(0.36, 0.72, 1.00);
    let outer_corona = vec3<f32>(0.10, 0.28, 0.95);

    var corona_color = mix(inner_corona, mid_corona, smoothstep(0.8, 1.0, edge_factor));
    corona_color = mix(corona_color, outer_corona,  smoothstep(1.0, 1.1, edge_factor));
    corona_color = corona_color * corona_glow;

    // Atmósfera fría
    let atmosphere       = atmospheric_scattering(in.view_dir, in.nrm_ws);
    let atmosphere_color = atmosphere * (2.3 + 1.3 * pulse);

    // Manchas frías
    let dark_spots = smoothstep(0.65, 0.85, plasma) * 0.5;
    let spot_color = vec3<f32>(0.025, 0.04, 0.10);
    core_color = mix(core_color, spot_color, dark_spots);

    // Combinación
    var final_color = core_color + corona_color + atmosphere_color;

    // -------- Tone mapping / Color grading --------
    let exposure = 0.42;                 // menos exposición => menos blanco
    let exposed  = final_color * exposure;

    // Reinhard con denominador más bajo (conserva saturación)
    let tone_mapped = exposed / (exposed + vec3<f32>(0.70));

    // Más saturación hacia color
    let luma      = dot(tone_mapped, vec3<f32>(0.2126, 0.7152, 0.0722));
    let saturated = mix(vec3<f32>(luma), tone_mapped, 2.2);

    // Gamma: azul más brillante (gamma < 1 lo aclara)
    var graded = vec3<f32>(
        pow(saturated.r, 1.10),
        pow(saturated.g, 1.00),
        pow(saturated.b, 0.80)
    );

    // Boost final azul / reducción leve R y G
    var final_output = graded * vec3<f32>(0.85, 0.90, 1.30);
    final_output = clamp(final_output, vec3<f32>(0.0), vec3<f32>(1.0));

    return vec4<f32>(final_output, 1.0);
}
