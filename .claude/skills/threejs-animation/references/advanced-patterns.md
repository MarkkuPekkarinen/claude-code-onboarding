# Animation Advanced Patterns

## Procedural Animation — Physics & Math

### Smooth Damping

Smooth follow / lerp that feels physically plausible.

```javascript
const target = new THREE.Vector3();
const current = new THREE.Vector3();
const velocity = new THREE.Vector3();

function smoothDamp(current, target, velocity, smoothTime, deltaTime) {
  const omega = 2 / smoothTime;
  const x = omega * deltaTime;
  const exp = 1 / (1 + x + 0.48 * x * x + 0.235 * x * x * x);
  const change = current.clone().sub(target);
  const temp = velocity
    .clone()
    .add(change.clone().multiplyScalar(omega))
    .multiplyScalar(deltaTime);
  velocity.sub(temp.clone().multiplyScalar(omega)).multiplyScalar(exp);
  return target.clone().add(change.add(temp).multiplyScalar(exp));
}

function animate() {
  current.copy(smoothDamp(current, target, velocity, 0.3, delta));
  mesh.position.copy(current);
}
```

### Spring Physics

```javascript
class Spring {
  constructor(stiffness = 100, damping = 10) {
    this.stiffness = stiffness;
    this.damping = damping;
    this.position = 0;
    this.velocity = 0;
    this.target = 0;
  }

  update(dt) {
    const force = -this.stiffness * (this.position - this.target);
    const dampingForce = -this.damping * this.velocity;
    this.velocity += (force + dampingForce) * dt;
    this.position += this.velocity * dt;
    return this.position;
  }
}

const spring = new Spring(100, 10);
spring.target = 1;

function animate() {
  mesh.position.y = spring.update(delta);
}
```

### Oscillation Patterns

```javascript
function animate() {
  const t = clock.getElapsedTime();

  // Sine wave
  mesh.position.y = Math.sin(t * 2) * 0.5;

  // Bounce (always positive)
  mesh.position.y = Math.abs(Math.sin(t * 3)) * 2;

  // Circular motion
  mesh.position.x = Math.cos(t) * 2;
  mesh.position.z = Math.sin(t) * 2;

  // Figure 8 (Lissajous)
  mesh.position.x = Math.sin(t) * 2;
  mesh.position.z = Math.sin(t * 2) * 1;
}
```

## Animation Utilities

```javascript
// Find clip by name
const clip = THREE.AnimationClip.findByName(clips, "Walk");

// Create subclip (startFrame, endFrame, fps)
const subclip = THREE.AnimationUtils.subclip(clip, "subclip", 0, 30, 30);

// Convert to additive (relative to reference frame)
THREE.AnimationUtils.makeClipAdditive(clip);
THREE.AnimationUtils.makeClipAdditive(clip, 0, referenceClip);

// Clone clip
const clone = clip.clone();

// Get duration
clip.duration;

// Remove redundant keyframes
clip.optimize();
```

## Custom Interpolation

```javascript
// Cubic spline via InterpolateSmooth
const track = new THREE.VectorKeyframeTrack(
  ".position",
  [0, 0.5, 1, 1.5, 2],
  [0,0,0, 1,2,0, 2,0,0, 3,2,0, 4,0,0],
);
track.setInterpolation(THREE.InterpolateSmooth);

// Step (no interpolation — snaps between values)
const visibilityTrack = new THREE.BooleanKeyframeTrack(
  ".visible",
  [0, 0.5, 1],
  [true, false, true],
);
// BooleanKeyframeTrack always uses InterpolateDiscrete
```

## Performance Optimization

```javascript
// Pause off-screen animations
mesh.onBeforeRender = () => { action.paused = false; };
mesh.onAfterRender  = () => {
  if (!isInFrustum(mesh)) action.paused = true;
};

// Cache clips
const clipCache = new Map();
function getClip(name) {
  if (!clipCache.has(name)) clipCache.set(name, loadClip(name));
  return clipCache.get(name);
}

// Optimize clips — removes redundant keyframes
gltf.animations.forEach(clip => clip.optimize());
```

**Performance rules:**
1. Share clips — same `AnimationClip` can be used on multiple mixers
2. Disable mixers for invisible objects
3. LOD for animations — simpler rigs for distant characters
4. Call `clip.optimize()` after loading GLTF animations
