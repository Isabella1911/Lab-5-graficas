# Lab-5-graficas


## Características principales

- **Vertex Shader (`star.wgsl`)**
  - Calcula distorsiones radiales basadas en *ridged FBM*, *voronoi* y *value noise*.
  - Aplica deformaciones dinámicas al mallado para simular actividad estelar.
  - Control de amplitud, frecuencia y velocidad mediante uniformes.

- **Fragment Shader (`star.wgsl`)**
  - Genera color procedural con zonas frías:
    - Núcleo blanco-azulado.
    - Capas intermedias cian-azules.
    - Borde profundo azul.
  - Simula efectos de:
    - **Granulación solar**
    - **Plasma dinámico**
    - **Corona atmosférica** con *fresnel scattering*
    - **Pulsación periódica** controlada por `cycle_t`
  - Incluye tone-mapping, saturación y corrección gamma personalizados.

---

##  Estructura del proyecto
Lab-5-graficas/
├── assets/
│ └── shaders/
│ ├── noise.wgsl # Funciones de ruido y FBM
│ └── star.wgsl # Shader principal (vertex + fragment)
├── src/
│ ├── main.rs # Inicialización WGPU + render loop
│ ├── renderer.rs # Pipeline y carga de shaders
│ ├── mesh.rs # Generación de esfera
│ ├── uniforms.rs # Parámetros y bind groups
│ └── params.rs # Control de uniforms dinámicos
├── Cargo.toml
├── Cargo.lock
└── README.md

## Parámetros configurables

Los uniforms definidos en `Params` permiten modificar el comportamiento del shader:

| Uniform        | Descripción | Rango sugerido |
|----------------|--------------|----------------|
| `time`         | Tiempo global animado | — |
| `freq`         | Frecuencia del ruido | 0.5 – 3.0 |
| `amp`          | Amplitud de distorsión | 0.05 – 0.3 |
| `speed`        | Velocidad de animación | 0.1 – 1.0 |
| `octaves`      | Capas FBM | 3 – 6 |
| `cycle_t`      | Fase de pulsación (sin/cos) | 0.0 – 1.0 |
| `temp_kelvin`  | Temperatura base (para futuras paletas) | 1000 – 40000 |

## Cómo ejecutar
cargo run --release
