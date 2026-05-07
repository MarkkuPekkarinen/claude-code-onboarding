# Angular Signals — Deep Reference

Extended signal patterns extracted from `../SKILL.md`.

---

## Signal Queries (viewChild / viewChildren / contentChild)

```typescript
import {
  Component,
  viewChild,
  viewChildren,
  contentChild,
  ElementRef,
} from "@angular/core";

@Component({
  selector: "app-container",
  standalone: true,
  template: `
    <input #searchInput />
    <app-item *ngFor="let item of items()" />
  `,
})
export class ContainerComponent {
  // Signal-based queries — no @ViewChild decorator
  searchInput = viewChild<ElementRef>("searchInput");
  items = viewChildren(ItemComponent);
  projectedContent = contentChild(HeaderDirective);

  focusSearch() {
    this.searchInput()?.nativeElement.focus();
  }
}
```

**Required variant** — throws if not found (use when element is always present):

```typescript
searchInput = viewChild.required<ElementRef>("searchInput");
```

**contentChild** — queries projected content from parent:

```typescript
export class PanelComponent {
  header = contentChild(PanelHeaderComponent);
  // Returns Signal<PanelHeaderComponent | undefined>
}
```

---

## linkedSignal — Full Examples

### Basic linkedSignal

```typescript
import { signal, linkedSignal } from '@angular/core';

const items = signal(['a', 'b', 'c']);

// selectedItem resets to items()[0] whenever items() changes
const selectedItem = linkedSignal(() => items()[0]);

// Can be written to independently
selectedItem.set('b'); // 'b'

// When source changes, selectedItem resets to new default
items.set(['x', 'y', 'z']);
selectedItem(); // 'x' — reset by source change
```

### Advanced linkedSignal with previous value

```typescript
import { signal, linkedSignal } from '@angular/core';

const options = signal(['Option A', 'Option B', 'Option C']);

// Keep current selection if it still exists in new options; otherwise reset to first
const selected = linkedSignal<string, string>({
  source: options,
  computation: (newOptions, previous) => {
    if (previous && newOptions.includes(previous.value)) {
      return previous.value; // Preserve selection
    }
    return newOptions[0]; // Reset to first
  },
});

// Test it
selected.set('Option B');
options.set(['Option B', 'Option C', 'Option D']); // 'Option B' preserved
options.set(['Option X', 'Option Y']);              // 'Option X' — reset
```

### Practical: Pagination reset on filter change

```typescript
@Injectable({ providedIn: 'root' })
export class SearchService {
  readonly filter = signal('');

  // Page resets to 0 whenever filter changes
  readonly page = linkedSignal(() => {
    this.filter(); // Declare dependency
    return 0;
  });

  readonly results = resource({
    request: () => ({ filter: this.filter(), page: this.page() }),
    loader: ({ request }) => fetchResults(request),
  });
}
```

---

## resource() — Full API

### Basic resource() with HttpClient

```typescript
import { Component, signal, resource } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { inject } from '@angular/core';
import { firstValueFrom } from 'rxjs';
import { ChangeDetectionStrategy } from '@angular/core';

@Component({
  selector: 'app-user-profile',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    @if (userResource.isLoading()) {
      <div class="skeleton h-8 w-full"></div>
    } @else if (userResource.error()) {
      <div class="alert alert-error">Failed to load user</div>
    } @else {
      <h2>{{ userResource.value()?.name }}</h2>
    }
  `,
})
export class UserProfileComponent {
  private http = inject(HttpClient);
  userId = input.required<string>();

  // Automatically refetches when userId() changes
  userResource = resource({
    request: () => ({ id: this.userId() }),
    loader: ({ request }) =>
      firstValueFrom(this.http.get<User>(`/api/users/${request.id}`)),
  });
}
```

### resource() with AbortSignal

```typescript
// loader receives AbortSignal — use with fetch() directly for cancellation
userResource = resource({
  request: () => this.userId(),
  loader: async ({ request: id, abortSignal }) => {
    const response = await fetch(`/api/users/${id}`, { signal: abortSignal });
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    return response.json() as Promise<User>;
  },
});
```

### resource() Status Signals

```typescript
// All status properties are signals — read in template or computed()
userResource.isLoading() // boolean
userResource.error()     // unknown (the thrown error) or undefined
userResource.value()     // T | undefined
userResource.status()    // 'idle' | 'loading' | 'reloading' | 'resolved' | 'error' | 'local'

// Trigger manual reload
userResource.reload();

// Set value locally (optimistic update)
userResource.set(updatedUser);
```

### httpResource() — HTTP Shorthand

```typescript
import { httpResource } from '@angular/common/http';

// Shorthand for HTTP GET — no firstValueFrom needed
userResource = httpResource<User>(() => `/api/users/${this.userId()}`);

// With options (method, headers, body)
userResource = httpResource<User>({
  url: () => `/api/users/${this.userId()}`,
  method: 'GET',
  headers: { 'X-Api-Key': 'my-key' },
});
```

---

## Signals Decision Cheat Sheet

| Use Case | Tool |
|---|---|
| Local component state | `signal()` |
| Derived read-only value | `computed()` |
| Writable signal that resets on source change | `linkedSignal()` |
| Async data tied to signals | `resource()` / `httpResource()` |
| HTTP side effects (POST/PUT/DELETE) | `HttpClient` + RxJS |
| Complex async flows | `HttpClient` + RxJS |
| Query DOM elements / child components | `viewChild()` / `viewChildren()` |
| Query projected content | `contentChild()` / `contentChildren()` |
