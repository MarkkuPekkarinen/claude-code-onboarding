# Advanced Controls & Interaction Patterns

## Camera Controls — Additional Types

### FlyControls

Free-flying camera (no ground constraint).

```javascript
import { FlyControls } from "three/addons/controls/FlyControls.js";

const controls = new FlyControls(camera, renderer.domElement);
controls.movementSpeed = 10;
controls.rollSpeed = Math.PI / 24;
controls.dragToLook = true;

function animate() {
  controls.update(clock.getDelta()); // Requires delta
}
```

### FirstPersonControls

FPS-style with look/move constraints.

```javascript
import { FirstPersonControls } from "three/addons/controls/FirstPersonControls.js";

const controls = new FirstPersonControls(camera, renderer.domElement);
controls.movementSpeed = 10;
controls.lookSpeed = 0.1;
controls.lookVertical = true;
controls.constrainVertical = true;
controls.verticalMin = Math.PI / 4;
controls.verticalMax = (Math.PI * 3) / 4;

function animate() {
  controls.update(clock.getDelta());
}
```

### PointerLockControls

Browser pointer lock for immersive FPS controls.

```javascript
import { PointerLockControls } from "three/addons/controls/PointerLockControls.js";

const controls = new PointerLockControls(camera, document.body);

document.addEventListener("click", () => controls.lock());
controls.addEventListener("lock", () => console.log("Pointer locked"));
controls.addEventListener("unlock", () => console.log("Pointer unlocked"));

const keys = {};
document.addEventListener("keydown", (e) => { keys[e.code] = true; });
document.addEventListener("keyup", (e) => { keys[e.code] = false; });

const velocity = new THREE.Vector3();
const direction = new THREE.Vector3();

function animate() {
  if (controls.isLocked) {
    const forward = Number(keys["KeyW"]) - Number(keys["KeyS"]);
    direction.z = forward;
    direction.normalize();

    velocity.z -= direction.z * 0.1;
    velocity.z *= 0.9; // Friction
    controls.moveForward(-velocity.z);
  }
}
```

### TrackballControls

Unconstrained rotation (rolls past poles).

```javascript
import { TrackballControls } from "three/addons/controls/TrackballControls.js";

const controls = new TrackballControls(camera, renderer.domElement);
controls.rotateSpeed = 2.0;
controls.zoomSpeed = 1.2;
controls.panSpeed = 0.8;
controls.staticMoving = true;

function animate() {
  controls.update();
}
```

### MapControls

Top-down map-style controls (pan + zoom, no orbit).

```javascript
import { MapControls } from "three/addons/controls/MapControls.js";

const controls = new MapControls(camera, renderer.domElement);
controls.enableDamping = true;
controls.dampingFactor = 0.05;
controls.screenSpacePanning = false;
controls.maxPolarAngle = Math.PI / 2;
```

## Box Selection (Rubber-Band)

Select multiple objects with a drag rectangle.

```javascript
import { SelectionBox } from "three/addons/interactive/SelectionBox.js";
import { SelectionHelper } from "three/addons/interactive/SelectionHelper.js";

const selectionBox = new SelectionBox(camera, scene);
const selectionHelper = new SelectionHelper(renderer, "selectBox"); // CSS class

document.addEventListener("pointerdown", (event) => {
  selectionBox.startPoint.set(
    (event.clientX / window.innerWidth) * 2 - 1,
    -(event.clientY / window.innerHeight) * 2 + 1,
    0.5,
  );
});

document.addEventListener("pointermove", (event) => {
  if (selectionHelper.isDown) {
    selectionBox.endPoint.set(
      (event.clientX / window.innerWidth) * 2 - 1,
      -(event.clientY / window.innerHeight) * 2 + 1,
      0.5,
    );
  }
});

document.addEventListener("pointerup", (event) => {
  selectionBox.endPoint.set(
    (event.clientX / window.innerWidth) * 2 - 1,
    -(event.clientY / window.innerHeight) * 2 + 1,
    0.5,
  );
  const selected = selectionBox.select();
  console.log("Selected objects:", selected);
});
```

## World ↔ Screen Coordinate Conversion

### World to Screen (Placing HTML over 3D)

```javascript
function worldToScreen(position, camera) {
  const vector = position.clone();
  vector.project(camera);

  return {
    x: ((vector.x + 1) / 2) * window.innerWidth,
    y: (-(vector.y - 1) / 2) * window.innerHeight,
  };
}

const screenPos = worldToScreen(mesh.position, camera);
element.style.left = screenPos.x + "px";
element.style.top  = screenPos.y + "px";
```

### Screen to World

```javascript
function screenToWorld(screenX, screenY, camera, targetZ = 0) {
  const vector = new THREE.Vector3(
    (screenX / window.innerWidth) * 2 - 1,
    -(screenY / window.innerHeight) * 2 + 1,
    0.5,
  );
  vector.unproject(camera);

  const dir = vector.sub(camera.position).normalize();
  const distance = (targetZ - camera.position.z) / dir.z;
  return camera.position.clone().add(dir.multiplyScalar(distance));
}
```

### Ray-Plane Intersection

```javascript
function getRayPlaneIntersection(mouse, camera, plane) {
  const raycaster = new THREE.Raycaster();
  raycaster.setFromCamera(mouse, camera);

  const intersection = new THREE.Vector3();
  raycaster.ray.intersectPlane(plane, intersection);
  return intersection;
}

const groundPlane = new THREE.Plane(new THREE.Vector3(0, 1, 0), 0);
const worldPos = getRayPlaneIntersection(mouse, camera, groundPlane);
```

## InteractionManager Class Pattern

Encapsulates all interaction logic for a scene.

```javascript
class InteractionManager {
  constructor(camera, renderer, scene) {
    this.camera = camera;
    this.renderer = renderer;
    this.scene = scene;
    this.raycaster = new THREE.Raycaster();
    this.mouse = new THREE.Vector2();
    this.clickables = [];
    this.bindEvents();
  }

  bindEvents() {
    const canvas = this.renderer.domElement;
    canvas.addEventListener("click", (e) => this.onClick(e));
    canvas.addEventListener("mousemove", (e) => this.onMouseMove(e));
    canvas.addEventListener("touchstart", (e) => this.onTouchStart(e));
  }

  updateMouse(event) {
    const rect = this.renderer.domElement.getBoundingClientRect();
    this.mouse.x = ((event.clientX - rect.left) / rect.width) * 2 - 1;
    this.mouse.y = -((event.clientY - rect.top) / rect.height) * 2 + 1;
  }

  getIntersects() {
    this.raycaster.setFromCamera(this.mouse, this.camera);
    return this.raycaster.intersectObjects(this.clickables, true);
  }

  onClick(event) {
    this.updateMouse(event);
    const intersects = this.getIntersects();
    if (intersects.length > 0) {
      const object = intersects[0].object;
      if (object.userData.onClick) object.userData.onClick(intersects[0]);
    }
  }

  addClickable(object, callback) {
    this.clickables.push(object);
    object.userData.onClick = callback;
  }

  dispose() {
    // Remove event listeners
  }
}

const interaction = new InteractionManager(camera, renderer, scene);
interaction.addClickable(mesh, (intersect) => {
  console.log("Clicked at:", intersect.point);
});
```

## Performance Tips

1. **Throttle mousemove** — limit raycasts to 20fps for hover effects
2. **Use layers** — `raycaster.layers.set(N)` to filter targets
3. **Simple collision meshes** — use invisible BoxGeometry for raycasting complex models
4. **Disable controls when not needed** — `controls.enabled = false`

```javascript
// Throttle mousemove
let lastRaycast = 0;
function onMouseMove(event) {
  const now = Date.now();
  if (now - lastRaycast < 50) return; // 20fps max
  lastRaycast = now;
  // ... raycast
}

// Simple collision proxy
const collisionMesh = new THREE.Mesh(
  new THREE.BoxGeometry(1, 1, 1),
  new THREE.MeshBasicMaterial({ visible: false }),
);
collisionMesh.userData.target = complexMesh;
clickables.push(collisionMesh);
```
