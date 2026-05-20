# Advanced Textures

## DataTexture

Create a texture from raw pixel data.

```javascript
const size = 256;
const data = new Uint8Array(size * size * 4);

for (let i = 0; i < size; i++) {
  for (let j = 0; j < size; j++) {
    const index = (i * size + j) * 4;
    data[index]     = i;   // R
    data[index + 1] = j;   // G
    data[index + 2] = 128; // B
    data[index + 3] = 255; // A
  }
}

const texture = new THREE.DataTexture(data, size, size);
texture.needsUpdate = true;
```

## CanvasTexture

Render from a 2D canvas — useful for dynamic labels, HUD elements.

```javascript
const canvas = document.createElement("canvas");
canvas.width = 256;
canvas.height = 256;
const ctx = canvas.getContext("2d");

ctx.fillStyle = "red";
ctx.fillRect(0, 0, 256, 256);
ctx.fillStyle = "white";
ctx.font = "48px Arial";
ctx.fillText("Hello", 50, 150);

const texture = new THREE.CanvasTexture(canvas);

// Update when canvas changes
texture.needsUpdate = true;
```

## VideoTexture

```javascript
const video = document.createElement("video");
video.src = "video.mp4";
video.loop = true;
video.muted = true;
video.play();

const texture = new THREE.VideoTexture(video);
texture.colorSpace = THREE.SRGBColorSpace;
// No need to set needsUpdate — auto-updates each frame
```

## Compressed Textures (KTX2/Basis)

```javascript
import { KTX2Loader } from "three/examples/jsm/loaders/KTX2Loader.js";

const ktx2Loader = new KTX2Loader();
ktx2Loader.setTranscoderPath("path/to/basis/");
ktx2Loader.detectSupport(renderer);

ktx2Loader.load("texture.ktx2", (texture) => {
  material.map = texture;
});
```

## Render Targets

Render a scene to a texture for post-processing or screen-in-screen effects.

```javascript
// Basic render target
const renderTarget = new THREE.WebGLRenderTarget(512, 512, {
  minFilter: THREE.LinearFilter,
  magFilter: THREE.LinearFilter,
  format: THREE.RGBAFormat,
});

renderer.setRenderTarget(renderTarget);
renderer.render(scene, camera);
renderer.setRenderTarget(null); // Back to screen

material.map = renderTarget.texture;

// Depth texture
const renderTarget = new THREE.WebGLRenderTarget(512, 512);
renderTarget.depthTexture = new THREE.DepthTexture(512, 512, THREE.UnsignedShortType);

// MSAA
const msaaTarget = new THREE.WebGLRenderTarget(512, 512, { samples: 4 });
```

## CubeCamera (Dynamic Reflections)

Update this every frame only when necessary — it's expensive (renders scene 6 times).

```javascript
const cubeRenderTarget = new THREE.WebGLCubeRenderTarget(256, {
  generateMipmaps: true,
  minFilter: THREE.LinearMipmapLinearFilter,
});

const cubeCamera = new THREE.CubeCamera(0.1, 1000, cubeRenderTarget);
scene.add(cubeCamera);

reflectiveMaterial.envMap = cubeRenderTarget.texture;

function animate() {
  reflectiveObject.visible = false;
  cubeCamera.position.copy(reflectiveObject.position);
  cubeCamera.update(renderer, scene);
  reflectiveObject.visible = true;
}
```

## UV Mapping

### Accessing and Modifying UVs

```javascript
const uvs = geometry.attributes.uv;

const u = uvs.getX(vertexIndex);
const v = uvs.getY(vertexIndex);

uvs.setXY(vertexIndex, newU, newV);
uvs.needsUpdate = true;
```

### Second UV Channel (for AO maps)

```javascript
geometry.setAttribute("uv2", geometry.attributes.uv);

// Or create custom second UV
const uv2 = new Float32Array(vertexCount * 2);
// ... fill uv2 data
geometry.setAttribute("uv2", new THREE.BufferAttribute(uv2, 2));
```

### UV Transform in Shader

```javascript
const material = new THREE.ShaderMaterial({
  uniforms: {
    map: { value: texture },
    uvOffset: { value: new THREE.Vector2(0, 0) },
    uvScale: { value: new THREE.Vector2(1, 1) },
  },
  vertexShader: `
    varying vec2 vUv;
    uniform vec2 uvOffset;
    uniform vec2 uvScale;
    void main() {
      vUv = uv * uvScale + uvOffset;
      gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
    }
  `,
  fragmentShader: `
    varying vec2 vUv;
    uniform sampler2D map;
    void main() {
      gl_FragColor = texture2D(map, vUv);
    }
  `,
});
```

## Texture Atlas

Pack multiple sprites into one texture to reduce draw calls.

```javascript
const atlas = loader.load("atlas.png");
atlas.wrapS = THREE.ClampToEdgeWrapping;
atlas.wrapT = THREE.ClampToEdgeWrapping;

function selectSprite(row, col, gridSize = 2) {
  atlas.offset.set(col / gridSize, 1 - (row + 1) / gridSize);
  atlas.repeat.set(1 / gridSize, 1 / gridSize);
}

selectSprite(0, 0); // Select top-left sprite
```

## Procedural Textures

### Noise Texture

```javascript
function generateNoiseTexture(size = 256) {
  const data = new Uint8Array(size * size * 4);
  for (let i = 0; i < size * size; i++) {
    const value = Math.random() * 255;
    data[i * 4] = value;
    data[i * 4 + 1] = value;
    data[i * 4 + 2] = value;
    data[i * 4 + 3] = 255;
  }
  const texture = new THREE.DataTexture(data, size, size);
  texture.needsUpdate = true;
  return texture;
}
```

### Gradient Texture

```javascript
function generateGradientTexture(color1, color2, size = 256) {
  const canvas = document.createElement("canvas");
  canvas.width = size;
  canvas.height = 1;
  const ctx = canvas.getContext("2d");
  const gradient = ctx.createLinearGradient(0, 0, size, 0);
  gradient.addColorStop(0, color1);
  gradient.addColorStop(1, color2);
  ctx.fillStyle = gradient;
  ctx.fillRect(0, 0, size, 1);
  return new THREE.CanvasTexture(canvas);
}
```

## Texture Memory Management

### Dispose All Maps from a Material

```javascript
function disposeMaterial(material) {
  const maps = [
    "map", "normalMap", "roughnessMap", "metalnessMap", "aoMap",
    "emissiveMap", "displacementMap", "alphaMap", "envMap",
    "lightMap", "bumpMap", "specularMap",
  ];
  maps.forEach((mapName) => {
    if (material[mapName]) material[mapName].dispose();
  });
  material.dispose();
}
```

### Texture Pool

```javascript
class TexturePool {
  constructor() {
    this.textures = new Map();
    this.loader = new THREE.TextureLoader();
  }

  async get(url) {
    if (this.textures.has(url)) return this.textures.get(url);
    const texture = await new Promise((resolve, reject) => {
      this.loader.load(url, resolve, undefined, reject);
    });
    this.textures.set(url, texture);
    return texture;
  }

  dispose(url) {
    const texture = this.textures.get(url);
    if (texture) {
      texture.dispose();
      this.textures.delete(url);
    }
  }

  disposeAll() {
    this.textures.forEach((t) => t.dispose());
    this.textures.clear();
  }
}
```
