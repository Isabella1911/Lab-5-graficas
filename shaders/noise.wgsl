fn hash3(p: vec3f) -> f32 {
    let h = dot(p, vec3f(127.1, 311.7, 74.7));
    return fract(sin(h) * 43758.5453);
}

fn noise3(p: vec3f) -> f32 {
    let i = floor(p);
    let f = fract(p);

    let n000 = hash3(i + vec3f(0.0,0.0,0.0));
    let n100 = hash3(i + vec3f(1.0,0.0,0.0));
    let n010 = hash3(i + vec3f(0.0,1.0,0.0));
    let n110 = hash3(i + vec3f(1.0,1.0,0.0));
    let n001 = hash3(i + vec3f(0.0,0.0,1.0));
    let n101 = hash3(i + vec3f(1.0,0.0,1.0));
    let n011 = hash3(i + vec3f(0.0,1.0,1.0));
    let n111 = hash3(i + vec3f(1.0,1.0,1.0));

    let u = f*f*(3.0 - 2.0*f); // smoothstep

    let nx00 = mix(n000, n100, u.x);
    let nx10 = mix(n010, n110, u.x);
    let nx01 = mix(n001, n101, u.x);
    let nx11 = mix(n011, n111, u.x);

    let nxy0 = mix(nx00, nx10, u.y);
    let nxy1 = mix(nx01, nx11, u.y);

    return mix(nxy0, nxy1, u.z);
}

fn fbm(p: vec3f, octaves: u32) -> f32 {
    var sum = 0.0;
    var amp = 0.5;
    var freq = 1.0;
    for (var i:u32 = 0u; i < octaves; i = i + 1u) {
        sum += amp * noise3(p * freq);
        freq *= 2.0;
        amp *= 0.5;
    }
    return sum;
}