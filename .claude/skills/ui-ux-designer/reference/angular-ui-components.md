# Angular UI Component Patterns

Reusable Angular 21+ components using daisyUI 5.5.5 + TailwindCSS 4.x.
All components use standalone, OnPush, and signal-based APIs.

## Card Component

```typescript
import {
  Component, ChangeDetectionStrategy, signal, computed,
  input, output
} from '@angular/core';

@Component({
  selector: 'app-example-card',
  standalone: true,
  template: `
    <article class="card bg-base-100 shadow-xl">
      <div class="card-body">
        <h2 class="card-title">{{ title() }}</h2>
        @if (loading()) {
          <div class="space-y-2">
            <div class="skeleton h-4 w-full"></div>
            <div class="skeleton h-4 w-3/4"></div>
          </div>
        } @else {
          <p class="text-base-content/70">{{ content() }}</p>
        }
        <div class="card-actions justify-end mt-4">
          <button type="button" class="btn btn-primary"
            [class.btn-disabled]="loading()"
            [attr.aria-busy]="loading()"
            (click)="handleAction()">
            @if (loading()) {
              <span class="loading loading-spinner loading-sm"></span>
            }
            {{ actionLabel() }}
          </button>
        </div>
      </div>
    </article>
  `,
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class ExampleCardComponent {
  title = input.required<string>();
  content = input<string>('');
  actionLabel = input<string>('Submit');
  loading = input<boolean>(false);
  action = output<void>();

  protected handleAction(): void {
    if (!this.loading()) this.action.emit();
  }
}
```

## Form Field Component

```typescript
import { Component, ChangeDetectionStrategy, input, computed } from '@angular/core';

@Component({
  selector: 'app-form-field',
  standalone: true,
  template: `
    <div class="form-control w-full">
      <label class="label" [for]="inputId()">
        <span class="label-text">
          {{ label() }}
          @if (required()) {
            <span class="text-error ml-1" aria-hidden="true">*</span>
          }
        </span>
        @if (labelAlt()) {
          <span class="label-text-alt">{{ labelAlt() }}</span>
        }
      </label>
      <ng-content></ng-content>
      @if (errorMessage()) {
        <label class="label">
          <span class="label-text-alt text-error" role="alert">{{ errorMessage() }}</span>
        </label>
      }
      @if (hint() && !errorMessage()) {
        <label class="label">
          <span class="label-text-alt text-base-content/60">{{ hint() }}</span>
        </label>
      }
    </div>
  `,
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class FormFieldComponent {
  label = input.required<string>();
  hint = input<string>('');
  labelAlt = input<string>('');
  required = input<boolean>(false);
  errorMessage = input<string | null>(null);

  protected readonly inputId = computed(() =>
    `field-${this.label().toLowerCase().replace(/\s+/g, '-')}-${Math.random().toString(36).slice(2, 9)}`
  );
}
```

## Form with Validation

```typescript
import {
  Component, ChangeDetectionStrategy, signal, inject
} from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { FormFieldComponent } from './form-field.component';

@Component({
  selector: 'app-contact-form',
  standalone: true,
  imports: [ReactiveFormsModule, FormFieldComponent],
  template: `
    <form [formGroup]="form" (ngSubmit)="onSubmit()" class="space-y-4">
      <app-form-field label="Full Name" [required]="true" [errorMessage]="getError('name')">
        <input type="text" formControlName="name"
          class="input input-bordered w-full" [class.input-error]="hasError('name')" />
      </app-form-field>

      <app-form-field label="Email" [required]="true" [errorMessage]="getError('email')">
        <input type="email" formControlName="email"
          class="input input-bordered w-full" [class.input-error]="hasError('email')" />
      </app-form-field>

      <app-form-field label="Message" [required]="true" [errorMessage]="getError('message')" labelAlt="Max 500 chars">
        <textarea formControlName="message"
          class="textarea textarea-bordered w-full h-32" [class.textarea-error]="hasError('message')"></textarea>
      </app-form-field>

      <div class="flex justify-end gap-2 pt-4">
        <button type="button" class="btn btn-ghost" (click)="form.reset()">Clear</button>
        <button type="submit" class="btn btn-primary" [disabled]="!form.valid || submitting()">
          @if (submitting()) { <span class="loading loading-spinner loading-sm"></span> }
          Send
        </button>
      </div>
    </form>
  `,
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class ContactFormComponent {
  private readonly fb = inject(FormBuilder);
  protected readonly submitting = signal(false);

  protected readonly form = this.fb.nonNullable.group({
    name: ['', [Validators.required, Validators.minLength(2)]],
    email: ['', [Validators.required, Validators.email]],
    message: ['', [Validators.required, Validators.minLength(10), Validators.maxLength(500)]]
  });

  protected hasError(field: string): boolean {
    const c = this.form.get(field);
    return !!(c?.invalid && c?.touched);
  }

  protected getError(field: string): string | null {
    const c = this.form.get(field);
    if (!c?.invalid || !c?.touched) return null;
    if (c.errors?.['required']) return `${field.charAt(0).toUpperCase() + field.slice(1)} is required`;
    if (c.errors?.['email']) return 'Please enter a valid email';
    if (c.errors?.['minlength']) return `Minimum ${c.errors['minlength'].requiredLength} characters`;
    if (c.errors?.['maxlength']) return `Maximum ${c.errors['maxlength'].requiredLength} characters`;
    return 'Invalid value';
  }

  protected async onSubmit(): Promise<void> {
    if (this.form.invalid) { this.form.markAllAsTouched(); return; }
    this.submitting.set(true);
    try {
      // API call here
      this.form.reset();
    } finally {
      this.submitting.set(false);
    }
  }
}
```

## Empty State

```typescript
import { Component, ChangeDetectionStrategy, input, output } from '@angular/core';

@Component({
  selector: 'app-empty-state',
  standalone: true,
  template: `
    <div class="hero min-h-[300px] bg-base-200 rounded-box">
      <div class="hero-content text-center">
        <div class="max-w-md">
          <div class="text-6xl mb-4" aria-hidden="true">{{ icon() }}</div>
          <h2 class="text-2xl font-bold">{{ title() }}</h2>
          <p class="py-4 text-base-content/60">{{ description() }}</p>
          @if (actionLabel()) {
            <button type="button" class="btn btn-primary" (click)="action.emit()">
              {{ actionLabel() }}
            </button>
          }
        </div>
      </div>
    </div>
  `,
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class EmptyStateComponent {
  icon = input<string>('');
  title = input.required<string>();
  description = input.required<string>();
  actionLabel = input<string>('');
  action = output<void>();
}
```

## Skeleton Loader

```typescript
import { Component, ChangeDetectionStrategy, input } from '@angular/core';

@Component({
  selector: 'app-skeleton',
  standalone: true,
  template: `
    <div class="animate-pulse" role="status" aria-label="Loading content">
      @for (row of rowsArray(); track $index) {
        <div class="flex items-start gap-4 mb-4">
          @if (showAvatar()) {
            <div class="skeleton w-12 h-12 rounded-full shrink-0"></div>
          }
          <div class="flex-1 space-y-3">
            <div class="skeleton h-4 w-3/4"></div>
            <div class="skeleton h-4 w-1/2"></div>
          </div>
        </div>
      }
      <span class="sr-only">Loading...</span>
    </div>
  `,
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class SkeletonComponent {
  rows = input<number>(3);
  showAvatar = input<boolean>(true);
  protected rowsArray = () => Array.from({ length: this.rows() });
}
```

## Responsive Navigation

```typescript
import {
  Component, ChangeDetectionStrategy, signal, input
} from '@angular/core';
import { RouterLink, RouterLinkActive } from '@angular/router';

interface NavItem { label: string; path: string; icon?: string; }

@Component({
  selector: 'app-responsive-nav',
  standalone: true,
  imports: [RouterLink, RouterLinkActive],
  template: `
    <div class="drawer lg:drawer-open">
      <input id="nav-drawer" type="checkbox" class="drawer-toggle"
        [checked]="drawerOpen()" (change)="toggleDrawer($event)" />
      <div class="drawer-content flex flex-col min-h-screen">
        <header class="navbar bg-base-100 border-b border-base-300 lg:hidden sticky top-0 z-30">
          <div class="flex-none">
            <label for="nav-drawer" class="btn btn-square btn-ghost" aria-label="Open navigation">
              <svg class="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16"/>
              </svg>
            </label>
          </div>
          <div class="flex-1"><span class="text-xl font-bold px-2">{{ title() }}</span></div>
        </header>
        <main class="flex-1 p-4 lg:p-6"><ng-content></ng-content></main>
      </div>
      <aside class="drawer-side z-40">
        <label for="nav-drawer" class="drawer-overlay" aria-label="Close navigation"></label>
        <div class="bg-base-200 min-h-full w-64 flex flex-col">
          <div class="p-4 border-b border-base-300">
            <h1 class="text-xl font-bold">{{ title() }}</h1>
          </div>
          <nav class="flex-1 p-4">
            <ul class="menu gap-1">
              @for (item of navItems(); track item.path) {
                <li>
                  <a [routerLink]="item.path" routerLinkActive="active"
                    [routerLinkActiveOptions]="{ exact: item.path === '/' }"
                    (click)="drawerOpen.set(false)">
                    @if (item.icon) { <span>{{ item.icon }}</span> }
                    {{ item.label }}
                  </a>
                </li>
              }
            </ul>
          </nav>
        </div>
      </aside>
    </div>
  `,
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class ResponsiveNavComponent {
  title = input<string>('App');
  navItems = input<NavItem[]>([]);
  protected readonly drawerOpen = signal(false);

  protected toggleDrawer(event: Event): void {
    this.drawerOpen.set((event.target as HTMLInputElement).checked);
  }
}
```

## Data Table

```typescript
import {
  Component, ChangeDetectionStrategy, input, signal, computed, output
} from '@angular/core';
import { EmptyStateComponent } from './empty-state.component';

export interface TableColumn<T> {
  key: keyof T & string;
  label: string;
  sortable?: boolean;
  width?: string;
  align?: 'left' | 'center' | 'right';
}

@Component({
  selector: 'app-data-table',
  standalone: true,
  imports: [EmptyStateComponent],
  template: `
    <div class="overflow-x-auto rounded-box border border-base-300">
      <table class="table table-zebra">
        <thead class="bg-base-200">
          <tr>
            @for (col of columns(); track col.key) {
              <th [class.cursor-pointer]="col.sortable" [style.width]="col.width"
                [style.text-align]="col.align || 'left'"
                (click)="col.sortable && sort(col.key)"
                [attr.aria-sort]="sortKey() === col.key ? (sortDir() === 'asc' ? 'ascending' : 'descending') : 'none'">
                <div class="flex items-center gap-2">
                  <span>{{ col.label }}</span>
                  @if (col.sortable) {
                    <span class="text-base-content/40 text-sm">
                      {{ sortKey() === col.key ? (sortDir() === 'asc' ? '↑' : '↓') : '↕' }}
                    </span>
                  }
                </div>
              </th>
            }
          </tr>
        </thead>
        <tbody>
          @for (row of sortedData(); track $index) {
            <tr class="hover:bg-base-200/50 transition-colors"
              [class.cursor-pointer]="rowClickable()"
              (click)="rowClickable() && rowClick.emit(row)">
              @for (col of columns(); track col.key) {
                <td [style.text-align]="col.align || 'left'">{{ row[col.key] }}</td>
              }
            </tr>
          } @empty {
            <tr>
              <td [attr.colspan]="columns().length" class="p-0">
                <app-empty-state [title]="emptyTitle()" [description]="emptyDescription()" />
              </td>
            </tr>
          }
        </tbody>
      </table>
    </div>
  `,
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class DataTableComponent<T extends Record<string, unknown>> {
  columns = input.required<TableColumn<T>[]>();
  data = input.required<T[]>();
  rowClickable = input<boolean>(false);
  rowClick = output<T>();
  emptyTitle = input<string>('No data');
  emptyDescription = input<string>('No records found');

  protected readonly sortKey = signal<string | null>(null);
  protected readonly sortDir = signal<'asc' | 'desc'>('asc');

  protected readonly sortedData = computed(() => {
    const key = this.sortKey();
    const result = [...this.data()];
    if (!key) return result;
    const mod = this.sortDir() === 'asc' ? 1 : -1;
    return result.sort((a, b) => {
      if (a[key] == null) return mod;
      if (b[key] == null) return -mod;
      return a[key] < b[key] ? -mod : a[key] > b[key] ? mod : 0;
    });
  });

  protected sort(key: string): void {
    if (this.sortKey() === key) {
      this.sortDir.update(d => d === 'asc' ? 'desc' : 'asc');
    } else {
      this.sortKey.set(key);
      this.sortDir.set('asc');
    }
  }
}
```

## Toast Service & Component

```typescript
// toast.service.ts
import { Injectable, signal } from '@angular/core';

export type ToastType = 'info' | 'success' | 'warning' | 'error';
export interface Toast { id: string; type: ToastType; message: string; title?: string; }

@Injectable({ providedIn: 'root' })
export class ToastService {
  private readonly _toasts = signal<Toast[]>([]);
  readonly toasts = this._toasts.asReadonly();

  show(type: ToastType, message: string, opts: { title?: string; duration?: number } = {}): string {
    const id = crypto.randomUUID();
    const duration = opts.duration ?? (type === 'error' ? 0 : 5000);
    this._toasts.update(t => [...t, { id, type, message, title: opts.title }]);
    if (duration > 0) setTimeout(() => this.dismiss(id), duration);
    return id;
  }

  dismiss(id: string): void { this._toasts.update(t => t.filter(x => x.id !== id)); }

  info(msg: string, title?: string) { return this.show('info', msg, { title }); }
  success(msg: string, title?: string) { return this.show('success', msg, { title }); }
  warning(msg: string, title?: string) { return this.show('warning', msg, { title }); }
  error(msg: string, title?: string) { return this.show('error', msg, { title, duration: 0 }); }
}
```

```typescript
// toast-container.component.ts
import { Component, ChangeDetectionStrategy, inject } from '@angular/core';
import { ToastService } from './toast.service';

@Component({
  selector: 'app-toast-container',
  standalone: true,
  template: `
    <div class="toast toast-end toast-bottom z-50">
      @for (toast of toastService.toasts(); track toast.id) {
        <div class="alert shadow-lg"
          [class.alert-info]="toast.type === 'info'"
          [class.alert-success]="toast.type === 'success'"
          [class.alert-warning]="toast.type === 'warning'"
          [class.alert-error]="toast.type === 'error'"
          role="alert" [attr.aria-live]="toast.type === 'error' ? 'assertive' : 'polite'">
          <div class="flex-1">
            @if (toast.title) { <h3 class="font-bold">{{ toast.title }}</h3> }
            <p class="text-sm">{{ toast.message }}</p>
          </div>
          <button type="button" class="btn btn-ghost btn-sm btn-circle"
            (click)="toastService.dismiss(toast.id)" aria-label="Dismiss">x</button>
        </div>
      }
    </div>
  `,
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class ToastContainerComponent {
  protected readonly toastService = inject(ToastService);
}
```

## Theme Toggle Component

```typescript
import {
  Component, ChangeDetectionStrategy, signal, inject, PLATFORM_ID, afterNextRender
} from '@angular/core';
import { isPlatformBrowser } from '@angular/common';

@Component({
  selector: 'app-theme-toggle',
  standalone: true,
  template: `
    <label class="swap swap-rotate">
      <input type="checkbox" class="theme-controller" value="dark"
        [checked]="isDark()" (change)="onToggle($event)" aria-label="Toggle dark mode" />
      <svg class="swap-off h-8 w-8 fill-current" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" aria-hidden="true">
        <path d="M5.64,17l-.71.71a1,1,0,0,0,0,1.41,1,1,0,0,0,1.41,0l.71-.71A1,1,0,0,0,5.64,17ZM5,12a1,1,0,0,0-1-1H3a1,1,0,0,0,0,2H4A1,1,0,0,0,5,12Zm7-7a1,1,0,0,0,1-1V3a1,1,0,0,0-2,0V4A1,1,0,0,0,12,5ZM5.64,7.05a1,1,0,0,0,.7.29,1,1,0,0,0,.71-.29,1,1,0,0,0,0-1.41l-.71-.71A1,1,0,0,0,4.93,6.34Zm12,.29a1,1,0,0,0,.7-.29l.71-.71a1,1,0,1,0-1.41-1.41L17,5.64a1,1,0,0,0,0,1.41A1,1,0,0,0,17.66,7.34ZM21,11H20a1,1,0,0,0,0,2h1a1,1,0,0,0,0-2Zm-9,8a1,1,0,0,0-1,1v1a1,1,0,0,0,2,0V20A1,1,0,0,0,12,19ZM18.36,17A1,1,0,0,0,17,18.36l.71.71a1,1,0,0,0,1.41,0,1,1,0,0,0,0-1.41ZM12,6.5A5.5,5.5,0,1,0,17.5,12,5.51,5.51,0,0,0,12,6.5Zm0,9A3.5,3.5,0,1,1,15.5,12,3.5,3.5,0,0,1,12,15.5Z"/>
      </svg>
      <svg class="swap-on h-8 w-8 fill-current" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" aria-hidden="true">
        <path d="M21.64,13a1,1,0,0,0-1.05-.14,8.05,8.05,0,0,1-3.37.73A8.15,8.15,0,0,1,9.08,5.49a8.59,8.59,0,0,1,.25-2A1,1,0,0,0,8,2.36,10.14,10.14,0,1,0,22,14.05,1,1,0,0,0,21.64,13Zm-9.5,6.69A8.14,8.14,0,0,1,7.08,5.22v.27A10.15,10.15,0,0,0,17.22,15.63a9.79,9.79,0,0,0,2.1-.22A8.11,8.11,0,0,1,12.14,19.73Z"/>
      </svg>
    </label>
  `,
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class ThemeToggleComponent {
  private readonly platformId = inject(PLATFORM_ID);
  protected readonly isDark = signal(false);

  constructor() {
    afterNextRender(() => {
      if (isPlatformBrowser(this.platformId)) {
        const saved = localStorage.getItem('theme');
        const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
        this.isDark.set(saved ? saved === 'dark' : prefersDark);
      }
    });
  }

  protected onToggle(event: Event): void {
    const checked = (event.target as HTMLInputElement).checked;
    this.isDark.set(checked);
    if (isPlatformBrowser(this.platformId)) {
      localStorage.setItem('theme', checked ? 'dark' : 'light');
    }
  }
}
```

## Theme Service

```typescript
import { Injectable, signal, computed, inject, PLATFORM_ID, effect } from '@angular/core';
import { DOCUMENT, isPlatformBrowser } from '@angular/common';

export const DAISY_THEMES = [
  { name: 'light', label: 'Light', isDark: false },
  { name: 'dark', label: 'Dark', isDark: true },
  { name: 'corporate', label: 'Corporate', isDark: false },
  { name: 'business', label: 'Business', isDark: true },
  // Add more as needed from daisyUI's 35 themes
] as const;

export type ThemeName = typeof DAISY_THEMES[number]['name'];

@Injectable({ providedIn: 'root' })
export class ThemeService {
  private readonly document = inject(DOCUMENT);
  private readonly platformId = inject(PLATFORM_ID);

  readonly themes = DAISY_THEMES;
  private readonly _current = signal<ThemeName>('light');
  readonly currentTheme = this._current.asReadonly();
  readonly isDarkMode = computed(() => this.themes.find(t => t.name === this._current())?.isDark ?? false);

  constructor() {
    if (isPlatformBrowser(this.platformId)) {
      const saved = localStorage.getItem('theme') as ThemeName;
      if (saved && this.themes.some(t => t.name === saved)) {
        this._current.set(saved);
      } else {
        const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
        this._current.set(prefersDark ? 'dark' : 'light');
      }
    }
    effect(() => {
      const theme = this._current();
      this.document.documentElement.setAttribute('data-theme', theme);
      const isDark = this.themes.find(t => t.name === theme)?.isDark ?? false;
      this.document.documentElement.style.colorScheme = isDark ? 'dark' : 'light';
    });
  }

  setTheme(theme: ThemeName): void {
    this._current.set(theme);
    if (isPlatformBrowser(this.platformId)) localStorage.setItem('theme', theme);
  }

  toggleDarkMode(): void {
    this.setTheme(this.isDarkMode() ? 'light' : 'dark');
  }
}
```

## Confirm Dialog Service & Component

```typescript
// confirm-dialog.service.ts
import { Injectable, signal, computed } from '@angular/core';

export interface ConfirmDialogOptions {
  title: string;
  message: string;
  confirmLabel?: string;
  cancelLabel?: string;
  variant?: 'danger' | 'warning' | 'info';
}

@Injectable({ providedIn: 'root' })
export class ConfirmDialogService {
  private readonly _state = signal<{
    isOpen: boolean; title: string; message: string;
    confirmLabel: string; cancelLabel: string;
    variant: string; resolve: ((v: boolean) => void) | null;
  }>({ isOpen: false, title: '', message: '', confirmLabel: 'Confirm', cancelLabel: 'Cancel', variant: 'info', resolve: null });

  readonly state = this._state.asReadonly();
  readonly isOpen = computed(() => this._state().isOpen);

  confirm(opts: ConfirmDialogOptions): Promise<boolean> {
    return new Promise(resolve => {
      this._state.set({
        isOpen: true, title: opts.title, message: opts.message,
        confirmLabel: opts.confirmLabel ?? 'Confirm',
        cancelLabel: opts.cancelLabel ?? 'Cancel',
        variant: opts.variant ?? 'info', resolve
      });
    });
  }

  handleConfirm(): void { this._state().resolve?.(true); this.close(); }
  handleCancel(): void { this._state().resolve?.(false); this.close(); }
  private close(): void { this._state.update(s => ({ ...s, isOpen: false, resolve: null })); }
}
```

```typescript
// confirm-dialog.component.ts
import { Component, ChangeDetectionStrategy, inject, effect, viewChild, ElementRef } from '@angular/core';
import { ConfirmDialogService } from './confirm-dialog.service';

@Component({
  selector: 'app-confirm-dialog',
  standalone: true,
  template: `
    <dialog #dialogEl class="modal" (close)="service.handleCancel()">
      <div class="modal-box">
        <h3 class="font-bold text-lg">{{ service.state().title }}</h3>
        <p class="py-4">{{ service.state().message }}</p>
        <div class="modal-action">
          <button type="button" class="btn btn-ghost" (click)="service.handleCancel()">
            {{ service.state().cancelLabel }}
          </button>
          <button type="button" class="btn"
            [class.btn-error]="service.state().variant === 'danger'"
            [class.btn-warning]="service.state().variant === 'warning'"
            [class.btn-info]="service.state().variant === 'info'"
            (click)="service.handleConfirm()">
            {{ service.state().confirmLabel }}
          </button>
        </div>
      </div>
      <form method="dialog" class="modal-backdrop"><button>close</button></form>
    </dialog>
  `,
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class ConfirmDialogComponent {
  protected readonly service = inject(ConfirmDialogService);
  private readonly dialogEl = viewChild<ElementRef<HTMLDialogElement>>('dialogEl');

  constructor() {
    effect(() => {
      const dialog = this.dialogEl()?.nativeElement;
      if (!dialog) return;
      this.service.isOpen() ? dialog.showModal() : dialog.close();
    });
  }
}
```

## Error Boundary

```typescript
import { Component, ChangeDetectionStrategy, input, signal, output } from '@angular/core';

@Component({
  selector: 'app-error-boundary',
  standalone: true,
  template: `
    @if (hasError()) {
      <div class="alert alert-error shadow-lg">
        <div class="flex-1">
          <h3 class="font-bold">{{ errorTitle() }}</h3>
          <p class="text-sm">{{ errorMessage() }}</p>
        </div>
        <button type="button" class="btn btn-sm btn-ghost" (click)="handleRetry()">Try Again</button>
      </div>
    } @else {
      <ng-content></ng-content>
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class ErrorBoundaryComponent {
  errorTitle = input<string>('Something went wrong');
  protected readonly hasError = signal(false);
  protected readonly errorMessage = signal('');
  retryAction = output<void>();

  setError(message: string): void { this.hasError.set(true); this.errorMessage.set(message); }
  clearError(): void { this.hasError.set(false); this.errorMessage.set(''); }

  protected handleRetry(): void { this.clearError(); this.retryAction.emit(); }
}
```

## Infinite Scroll Directive

```typescript
import { Directive, ElementRef, inject, input, output, afterNextRender, OnDestroy } from '@angular/core';

@Directive({ selector: '[appInfiniteScroll]', standalone: true })
export class InfiniteScrollDirective implements OnDestroy {
  private readonly el = inject(ElementRef);
  threshold = input<number>(100);
  disabled = input<boolean>(false);
  loadMore = output<void>();
  private observer?: IntersectionObserver;
  private sentinel?: HTMLElement;

  constructor() {
    afterNextRender(() => {
      this.sentinel = document.createElement('div');
      this.sentinel.style.height = '1px';
      this.sentinel.setAttribute('aria-hidden', 'true');
      this.el.nativeElement.appendChild(this.sentinel);
      this.observer = new IntersectionObserver(
        entries => { if (entries[0].isIntersecting && !this.disabled()) this.loadMore.emit(); },
        { rootMargin: `${this.threshold()}px`, threshold: 0 }
      );
      this.observer.observe(this.sentinel);
    });
  }

  ngOnDestroy(): void { this.observer?.disconnect(); this.sentinel?.remove(); }
}
```

## Expandable Section

```typescript
import { Component, ChangeDetectionStrategy, input, signal } from '@angular/core';

@Component({
  selector: 'app-expandable-section',
  standalone: true,
  template: `
    <div class="collapse collapse-arrow bg-base-200 rounded-box">
      <input type="checkbox" [checked]="isExpanded()" (change)="isExpanded.update(v => !v)"
        [attr.aria-expanded]="isExpanded()" />
      <div class="collapse-title text-lg font-medium">
        {{ title() }}
        @if (badge()) { <span class="badge badge-sm ml-2">{{ badge() }}</span> }
      </div>
      <div class="collapse-content"><div class="pt-2"><ng-content></ng-content></div></div>
    </div>
  `,
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class ExpandableSectionComponent {
  title = input.required<string>();
  badge = input<string>('');
  defaultExpanded = input<boolean>(false);
  protected readonly isExpanded = signal(false);
}
```
