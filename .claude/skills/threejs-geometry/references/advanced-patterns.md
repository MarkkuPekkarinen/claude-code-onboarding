# Geometry Advanced Patterns

## Interleaved Buffers

More efficient memory layout for large meshes — interleaves position and UV data in a single buffer.

```javascript
const interleavedBuffer = new THREE.InterleavedBuffer(
  new Float32Array([
    // pos.x, pos.y, pos.z, uv.u, uv.v (repeated per vertex)
    -1, -1, 0, 0, 0,
     1, -1, 0, 1, 0,
     1,  1, 0, 1, 1,
    -1,  1, 0, 0, 1,
  ]),
  5, // stride (floats per vertex)
);

geometry.setAttribute(
  "position",
  new THREE.InterleavedBufferAttribute(interleavedBuffer, 3, 0), // size 3, offset 0
);
geometry.setAttribute(
  "uv",
  new THREE.InterleavedBufferAttribute(interleavedBuffer, 2, 3), // size 2, offset 3
);
```

## InstancedBufferGeometry

For custom per-instance attributes beyond transform/color.

```javascript
const geometry = new THREE.InstancedBufferGeometry();
geometry.copy(new THREE.BoxGeometry(1, 1, 1));

// Add per-instance attribute
const offsets = new Float32Array(count * 3);
for (let i = 0; i < count; i++) {
  offsets[i * 3]     = Math.random() * 10;
  offsets[i * 3 + 1] = Math.random() * 10;
  offsets[i * 3 + 2] = Math.random() * 10;
}
geometry.setAttribute("offset", new THREE.InstancedBufferAttribute(offsets, 3));

// Use in shader:
// attribute vec3 offset;
// vec3 transformed = position + offset;
```

## Morph Targets

Blend between different mesh shapes for facial animation, squash-and-stretch, etc.

```javascript
// Base geometry
const geometry = new THREE.BoxGeometry(1, 1, 1, 4, 4, 4);

// Create morph target
const morphPositions = geometry.attributes.position.array.slice();
for (let i = 0; i < morphPositions.length; i += 3) {
  morphPositions[i]     *= 2;   // Scale X
  morphPositions[i + 1] *= 0.5; // Squash Y
}

geometry.morphAttributes.position = [
  new THREE.BufferAttribute(new Float32Array(morphPositions), 3),
];

const mesh = new THREE.Mesh(geometry, material);
mesh.morphTargetInfluences[0] = 0.5; // 50% blend
```

### Accessing GLTF Morph Targets

```javascript
// Morph attributes are stored in geometry
console.log("Morph attributes:", Object.keys(mesh.geometry.morphAttributes));

// Name → index mapping
const smileIndex = mesh.morphTargetDictionary["smile"];
mesh.morphTargetInfluences[smileIndex] = 1;

// Animate with keyframe track
const track = new THREE.NumberKeyframeTrack(
  ".morphTargetInfluences[smile]",
  [0, 0.5, 1],
  [0, 1, 0],
);
const clip = new THREE.AnimationClip("smile", 1, [track]);
mixer.clipAction(clip).play();
```

## BufferAttribute Types Reference

```javascript
// Typed array selection guide
new Float32Array(count * itemSize); // Positions, normals, UVs
new Uint16Array(count);             // Indices (up to 65535 vertices)
new Uint32Array(count);             // Indices (larger meshes)
new Uint8Array(count * itemSize);   // Colors (0-255 range)

// Item sizes
// Position: 3 (x, y, z)
// Normal:   3 (x, y, z)
// UV:       2 (u, v)
// Color:    3 (r, g, b) or 4 (r, g, b, a)
// Index:    1
```

## Geometry Utilities

```javascript
import * as BufferGeometryUtils from "three/examples/jsm/utils/BufferGeometryUtils.js";

// Merge geometries (must have same attributes)
const merged = BufferGeometryUtils.mergeGeometries([geo1, geo2, geo3]);

// Merge with groups (for multi-material)
const mergedWithGroups = BufferGeometryUtils.mergeGeometries([geo1, geo2], true);

// Compute tangents (required for normal maps)
BufferGeometryUtils.computeTangents(geometry);

// Interleave attributes for better performance
const interleaved = BufferGeometryUtils.interleaveAttributes([
  geometry.attributes.position,
  geometry.attributes.normal,
  geometry.attributes.uv,
]);
```

## Performance Optimization

1. **Use indexed geometry** — reuse vertices with indices (Uint16Array for <65536 verts)
2. **Merge static meshes** — reduce draw calls with `mergeGeometries`
3. **Use InstancedMesh** — for many identical objects (see main SKILL.md)
4. **Appropriate segment counts** — more segments = smoother but slower

```javascript
// Segment count guidelines
new THREE.SphereGeometry(1, 16, 16); // Performance (game objects)
new THREE.SphereGeometry(1, 32, 32); // Good quality (default)
new THREE.SphereGeometry(1, 64, 64); // High quality (hero objects)

// Dispose when done
geometry.dispose();
```
