# Post-Processing Effects Catalog

## Film Grain

```javascript
import { FilmPass } from "three/addons/postprocessing/FilmPass.js";

const filmPass = new FilmPass(
  0.35,  // noise intensity
  0.5,   // scanline intensity
  648,   // scanline count
  false, // grayscale
);
composer.addPass(filmPass);
```

## Vignette

```javascript
import { ShaderPass } from "three/addons/postprocessing/ShaderPass.js";
import { VignetteShader } from "three/addons/shaders/VignetteShader.js";

const vignettePass = new ShaderPass(VignetteShader);
vignettePass.uniforms["offset"].value = 1.0;   // Vignette size
vignettePass.uniforms["darkness"].value = 1.0; // Intensity
composer.addPass(vignettePass);
```

## Color Correction

```javascript
import { ColorCorrectionShader } from "three/addons/shaders/ColorCorrectionShader.js";

const colorPass = new ShaderPass(ColorCorrectionShader);
colorPass.uniforms["powRGB"].value = new THREE.Vector3(1.2, 1.2, 1.2); // Gamma
colorPass.uniforms["mulRGB"].value = new THREE.Vector3(1.0, 1.0, 1.0); // Multiply
composer.addPass(colorPass);
```

## Gamma Correction

```javascript
import { GammaCorrectionShader } from "three/addons/shaders/GammaCorrectionShader.js";

composer.addPass(new ShaderPass(GammaCorrectionShader));
```

## Pixelation

```javascript
import { RenderPixelatedPass } from "three/addons/postprocessing/RenderPixelatedPass.js";

const pixelPass = new RenderPixelatedPass(6, scene, camera); // 6 = pixel size
composer.addPass(pixelPass);
```

## Glitch Effect

```javascript
import { GlitchPass } from "three/addons/postprocessing/GlitchPass.js";

const glitchPass = new GlitchPass();
glitchPass.goWild = false; // true = continuous glitching
composer.addPass(glitchPass);
```

## Halftone

```javascript
import { HalftonePass } from "three/addons/postprocessing/HalftonePass.js";

const halftonePass = new HalftonePass(window.innerWidth, window.innerHeight, {
  shape: 1,              // 1 = dot, 2 = ellipse, 3 = line, 4 = square
  radius: 4,
  rotateR: Math.PI / 12,
  rotateB: (Math.PI / 12) * 2,
  rotateG: (Math.PI / 12) * 3,
  scatter: 0,
  blending: 1,
  blendingMode: 1,
  greyscale: false,
});
composer.addPass(halftonePass);
```

## Custom Shader Examples

### Invert Colors

```javascript
const InvertShader = {
  uniforms: { tDiffuse: { value: null } },
  vertexShader: `
    varying vec2 vUv;
    void main() {
      vUv = uv;
      gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
    }
  `,
  fragmentShader: `
    uniform sampler2D tDiffuse;
    varying vec2 vUv;
    void main() {
      vec4 color = texture2D(tDiffuse, vUv);
      gl_FragColor = vec4(1.0 - color.rgb, color.a);
    }
  `,
};
```

### Chromatic Aberration

```javascript
const ChromaticAberrationShader = {
  uniforms: {
    tDiffuse: { value: null },
    amount: { value: 0.005 },
  },
  vertexShader: `
    varying vec2 vUv;
    void main() {
      vUv = uv;
      gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
    }
  `,
  fragmentShader: `
    uniform sampler2D tDiffuse;
    uniform float amount;
    varying vec2 vUv;
    void main() {
      vec2 dir = vUv - 0.5;
      float dist = length(dir);
      float r = texture2D(tDiffuse, vUv - dir * amount * dist).r;
      float g = texture2D(tDiffuse, vUv).g;
      float b = texture2D(tDiffuse, vUv + dir * amount * dist).b;
      gl_FragColor = vec4(r, g, b, 1.0);
    }
  `,
};
```

## Multi-Pass Rendering (Multiple Scenes)

```javascript
const bgComposer = new EffectComposer(renderer);
bgComposer.addPass(new RenderPass(bgScene, camera));

const fgComposer = new EffectComposer(renderer);
fgComposer.addPass(new RenderPass(fgScene, camera));
fgComposer.addPass(bloomPass);

function animate() {
  renderer.autoClear = false;
  renderer.clear();
  bgComposer.render();
  renderer.clearDepth();
  fgComposer.render();
}
```

## Render to Texture

```javascript
const renderTarget = new THREE.WebGLRenderTarget(512, 512);

renderer.setRenderTarget(renderTarget);
renderer.render(scene, camera);
renderer.setRenderTarget(null);

otherMaterial.map = renderTarget.texture;
```

## WebGPU Post-Processing (Three.js r150+)

Node-based system — experimental.

```javascript
import { postProcessing, pass, bloom } from "three/addons/nodes/Nodes.js";

const scenePass = pass(scene, camera);
const bloomNode = bloom(scenePass, 0.5, 0.4, 0.85);

const postProcessing = new THREE.PostProcessing(renderer);
postProcessing.outputNode = bloomNode;

function animate() {
  postProcessing.render();
}
```

## Handle Resize

```javascript
function onWindowResize() {
  const width = window.innerWidth;
  const height = window.innerHeight;
  const pixelRatio = renderer.getPixelRatio();

  camera.aspect = width / height;
  camera.updateProjectionMatrix();

  renderer.setSize(width, height);
  composer.setSize(width, height);

  // Update pass-specific resolutions
  if (fxaaPass) {
    fxaaPass.material.uniforms["resolution"].value.set(
      1 / (width * pixelRatio),
      1 / (height * pixelRatio),
    );
  }

  if (bloomPass) {
    bloomPass.resolution.set(width, height);
  }
}

window.addEventListener("resize", onWindowResize);
```

## Performance Tips

1. **Limit passes** — each pass is a full-screen render
2. **Lower resolution** — use smaller render targets for blur passes
3. **Disable unused effects** — `bloomPass.enabled = false`
4. **Use FXAA over MSAA** — less expensive
5. **Skip expensive effects on mobile**

```javascript
const isMobile = /iPhone|iPad|Android/i.test(navigator.userAgent);
if (!isMobile) composer.addPass(expensivePass);

// Reduce bloom resolution
new UnrealBloomPass(
  new THREE.Vector2(window.innerWidth / 2, window.innerHeight / 2),
  strength, radius, threshold,
);
```
