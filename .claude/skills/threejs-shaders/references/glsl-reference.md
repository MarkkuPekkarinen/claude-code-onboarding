# GLSL Reference & Advanced Patterns

## GLSL Built-in Functions

### Math Functions

```glsl
// Basic
abs(x), sign(x), floor(x), ceil(x), fract(x)
mod(x, y), min(x, y), max(x, y), clamp(x, min, max)
mix(a, b, t), step(edge, x), smoothstep(edge0, edge1, x)

// Trigonometry
sin(x), cos(x), tan(x)
asin(x), acos(x), atan(y, x), atan(x)
radians(degrees), degrees(radians)

// Exponential
pow(x, y), exp(x), log(x), exp2(x), log2(x)
sqrt(x), inversesqrt(x)
```

### Vector Functions

```glsl
// Length and distance
length(v), distance(p0, p1), dot(x, y), cross(x, y)

// Normalization
normalize(v)

// Reflection and refraction
reflect(I, N), refract(I, N, eta)

// Component-wise comparison
lessThan(x, y), lessThanEqual(x, y)
greaterThan(x, y), greaterThanEqual(x, y)
equal(x, y), notEqual(x, y)
any(bvec), all(bvec)
```

### Texture Functions

```glsl
// GLSL 1.0 (default Three.js) — use texture2D/textureCube
texture2D(sampler, coord)
texture2D(sampler, coord, bias)
textureCube(sampler, coord)

// GLSL 3.0 (glslVersion: THREE.GLSL3) — use texture()
// texture(sampler, coord) replaces texture2D/textureCube
// Also use: out vec4 fragColor instead of gl_FragColor

// Texture size (GLSL 1.30+)
textureSize(sampler, lod)
```

## Shader Includes (Three.js Chunks)

Reuse Three.js's built-in shader code fragments.

```javascript
import { ShaderChunk } from "three";

const fragmentShader = `
  ${ShaderChunk.common}
  ${ShaderChunk.packing}

  uniform sampler2D depthTexture;
  varying vec2 vUv;

  void main() {
    float depth = texture2D(depthTexture, vUv).r;
    float linearDepth = perspectiveDepthToViewZ(depth, 0.1, 1000.0);
    gl_FragColor = vec4(vec3(-linearDepth / 100.0), 1.0);
  }
`;
```

### Common onBeforeCompile Injection Points

```javascript
// Vertex shader
"#include <begin_vertex>"      // After position is calculated
"#include <project_vertex>"    // After gl_Position
"#include <beginnormal_vertex>" // Normal calculation start

// Fragment shader
"#include <color_fragment>"    // After diffuse color
"#include <output_fragment>"   // Final output
"#include <fog_fragment>"      // After fog applied
```

## External Shader Files

```javascript
// With Vite / webpack — import .glsl as string
import vertexShader from "./shaders/vertex.glsl";
import fragmentShader from "./shaders/fragment.glsl";

const material = new THREE.ShaderMaterial({ vertexShader, fragmentShader });
```

## Instanced Shaders

```javascript
const offsets = new Float32Array(instanceCount * 3);
// Fill offsets...
geometry.setAttribute("offset", new THREE.InstancedBufferAttribute(offsets, 3));

const material = new THREE.ShaderMaterial({
  vertexShader: `
    attribute vec3 offset;
    void main() {
      vec3 pos = position + offset;
      gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);
    }
  `,
  fragmentShader: `
    void main() {
      gl_FragColor = vec4(1.0, 0.0, 0.0, 1.0);
    }
  `,
});
```

## Debugging Shaders

```javascript
// Log compiled source (includes Three.js injections)
material.onBeforeCompile = (shader) => {
  console.log("Vertex Shader:", shader.vertexShader);
  console.log("Fragment Shader:", shader.fragmentShader);
};

// Enable WebGL error checking
renderer.debug.checkShaderErrors = true;
```

```glsl
// Visual debugging in fragment shader
void main() {
  gl_FragColor = vec4(vUv, 0.0, 1.0);            // Debug UVs (red-green gradient)
  gl_FragColor = vec4(vNormal * 0.5 + 0.5, 1.0); // Debug normals (RGB = XYZ)
  gl_FragColor = vec4(vPosition * 0.1 + 0.5, 1.0); // Debug world position
}
```

## ShaderMaterial — Full Property List

```javascript
const material = new THREE.ShaderMaterial({
  uniforms: { /* ... */ },
  vertexShader: "/* ... */",
  fragmentShader: "/* ... */",

  transparent: true,
  opacity: 1.0,
  side: THREE.DoubleSide,
  depthTest: true,
  depthWrite: true,

  blending: THREE.NormalBlending,
  // AdditiveBlending, SubtractiveBlending, MultiplyBlending

  wireframe: false,
  wireframeLinewidth: 1, // >1 has no effect on most platforms (WebGL limitation)

  extensions: {
    derivatives: true,       // fwidth, dFdx, dFdy
    fragDepth: true,         // gl_FragDepth
    drawBuffers: true,       // Multiple render targets
    shaderTextureLOD: true,  // texture2DLod
  },

  glslVersion: THREE.GLSL3, // WebGL2 features
});
```

## Performance Tips

1. **Minimize uniforms** — group related values into vec3/vec4
2. **Avoid conditionals** — use `mix`/`step` instead of `if/else`
3. **Precalculate in JS** — move per-frame constants out of GLSL
4. **Lookup tables via textures** — for complex mathematical functions
5. **Limit overdraw** — avoid transparent objects when possible

```glsl
// Instead of:
if (value > 0.5) { color = colorA; } else { color = colorB; }

// Use (GPU-friendly, no branch divergence):
color = mix(colorB, colorA, step(0.5, value));
```
