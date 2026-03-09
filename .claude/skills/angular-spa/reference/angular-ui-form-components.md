# Angular UI Form Components

Reusable Angular 21+ form components using daisyUI 5.5.5 + TailwindCSS 4.x.
All components use standalone, OnPush, and signal-based APIs.

---

## Section A: Component Selection Framework

**The Golden Rule: Data Type → Input Component → Validation Pattern**

| Data Type | Component | daisyUI Class |
|-----------|-----------|---------------|
| Short text (<100 chars) | `input[type=text/email/password/url]` | `input input-bordered` |
| Long text (>100 chars) | `textarea` | `textarea textarea-bordered` |
| Numeric (integer/decimal) | `input[type=number]` | `input input-bordered` |
| Currency | Composite: prefix `$` + `input[type=number]` | `input input-bordered` with `join` wrapper |
| Date | `input[type=date]` | `input input-bordered` |
| Time | `input[type=time]` | `input input-bordered` |
| Boolean (single toggle) | `input[type=checkbox]` | `checkbox` or `toggle` |
| Single choice, 2–7 options | Radio group | `radio` inside `form-control` |
| Single choice, 8–15 options | `select` | `select select-bordered` |
| Single choice, >15 options | Autocomplete / combobox | `input input-bordered` + dropdown |
| Multiple choice, ≤8 options | Checkbox group | `checkbox` per option |
| Multiple choice, >8 options | `select[multiple]` | `select select-bordered h-auto` |
| File / media upload | `input[type=file]` | `file-input file-input-bordered` |
| Structured (address, phone) | Composite inputs | Multiple `input input-bordered` in grid |
| Credit card | Composite: number + expiry + CVV | `join` wrapper with `input input-bordered` |
| Search | `input[type=search]` | `input input-bordered` with search icon |
| Range / slider | `input[type=range]` | `range range-primary` |
| Color | `input[type=color]` | Native color picker |

**Decision rules:**

- Never use `select` for boolean — use `checkbox` or `toggle` (clearer cognitive model)
- Never use `input[type=number]` for phone numbers — use `input[type=tel]` to preserve leading zeros
- Never use `textarea` for structured data that belongs in separate fields
- Prefer radio groups over selects when the option count is ≤7 and screen space allows (all options visible at a glance reduces errors)

---

## Section B: Validation Timing Strategy

**Recommended: On Blur with Progressive Enhancement**

```
Field pristine (never touched):  No validation shown
User typing (dirty, not blurred): No errors shown
On blur (field loses focus):      Validate and show errors immediately
After first error shown:          Switch to onChange for that field only
On fix:                           Show success state immediately
```

This prevents "angry forms" (showing errors before the user finishes typing) while ensuring fast feedback once the user has left a field.

### Five Modes with Angular Reactive Forms Mapping

| Mode | When to Use | Angular Config |
|------|-------------|----------------|
| **On Submit** | Low-friction short forms (login, search) | `fb.group({...}, { updateOn: 'submit' })` |
| **On Blur** | Standard data-entry forms (recommended default) | `fb.group({...}, { updateOn: 'blur' })` |
| **On Change** | Real-time constraint enforcement (password strength) | `fb.group({...}, { updateOn: 'change' })` |
| **Debounced** | Async validation (username availability check) | `updateOn: 'change'` + `debounceTime(300)` on `valueChanges` |
| **Progressive** | Complex long forms where UX research matters | Start with blur; add `.valueChanges` listener after first error per field |

### Progressive Enhancement Implementation

```typescript
// After the form group is touched (first submit attempt):
// switch individual fields to live validation
setupProgressiveValidation(): void {
  Object.keys(this.form.controls).forEach(key => {
    const ctrl = this.form.get(key)!;
    ctrl.valueChanges.subscribe(() => {
      if (ctrl.touched) ctrl.updateValueAndValidity();
    });
  });
}
```

---

## Section C: Error Message Best Practice

**Formula: What's wrong + Why it matters + How to fix**

| ❌ Vague (forbidden) | ✅ Actionable (required) |
|---------------------|--------------------------|
| "Invalid input" | "Email must include @ symbol (e.g., name@example.com)" |
| "Error" | "Password must be at least 8 characters long" |
| "Field required" | "Please enter your email so we can send your order confirmation" |
| "Too long" | "Message must be 500 characters or fewer (currently 523)" |
| "Invalid date" | "Date must be today or in the future (format: DD/MM/YYYY)" |
| "Passwords don't match" | "Passwords must match — please re-enter your new password" |

**Rules:**
- Always name the field in the message if not rendered directly beneath it
- Always include the constraint value: "at least 8" not "too short"
- For async errors (server-side): show the exact rejection reason if safe to expose, else "This [thing] is already in use — try a different one"
- Never blame the user: "You entered an invalid…" → "This email address doesn't look right…"

---

## Section D: Multi-Step Wizard Pattern

Angular 21 signals-based wizard. Each step is a standalone component; the wizard orchestrates navigation and validates step-by-step.

```typescript
import {
  Component, ChangeDetectionStrategy, signal, computed, inject
} from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';

// Step 1 component
@Component({
  selector: 'app-wizard-step-personal',
  standalone: true,
  imports: [ReactiveFormsModule],
  template: `
    <div class="space-y-4">
      <h3 class="text-lg font-semibold">Personal Information</h3>
      <div [formGroup]="form" class="space-y-4">
        <div class="form-control">
          <label class="label" for="firstName">
            <span class="label-text">First Name <span class="text-error" aria-hidden="true">*</span></span>
          </label>
          <input id="firstName" type="text" formControlName="firstName"
            class="input input-bordered"
            [class.input-error]="hasError('firstName')"
            [attr.aria-invalid]="hasError('firstName')"
            [attr.aria-describedby]="hasError('firstName') ? 'firstName-error' : null"
            aria-required="true" />
          @if (hasError('firstName')) {
            <label class="label">
              <span id="firstName-error" class="label-text-alt text-error" role="alert">
                {{ getError('firstName') }}
              </span>
            </label>
          }
        </div>
        <div class="form-control">
          <label class="label" for="lastName">
            <span class="label-text">Last Name <span class="text-error" aria-hidden="true">*</span></span>
          </label>
          <input id="lastName" type="text" formControlName="lastName"
            class="input input-bordered"
            [class.input-error]="hasError('lastName')"
            [attr.aria-invalid]="hasError('lastName')"
            [attr.aria-describedby]="hasError('lastName') ? 'lastName-error' : null"
            aria-required="true" />
          @if (hasError('lastName')) {
            <label class="label">
              <span id="lastName-error" class="label-text-alt text-error" role="alert">
                {{ getError('lastName') }}
              </span>
            </label>
          }
        </div>
      </div>
    </div>
  `,
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class WizardStepPersonalComponent {
  private readonly fb = inject(FormBuilder);

  readonly form = this.fb.nonNullable.group({
    firstName: ['', [Validators.required, Validators.minLength(2)]],
    lastName: ['', [Validators.required, Validators.minLength(2)]]
  });

  hasError(field: string): boolean {
    const c = this.form.get(field);
    return !!(c?.invalid && c?.touched);
  }

  getError(field: string): string | null {
    const c = this.form.get(field);
    if (!c?.invalid || !c?.touched) return null;
    if (c.errors?.['required']) return `${field === 'firstName' ? 'First name' : 'Last name'} is required`;
    if (c.errors?.['minlength']) return `Must be at least ${c.errors['minlength'].requiredLength} characters`;
    return null;
  }
}

// Step 2 component (contact)
@Component({
  selector: 'app-wizard-step-contact',
  standalone: true,
  imports: [ReactiveFormsModule],
  template: `
    <div class="space-y-4">
      <h3 class="text-lg font-semibold">Contact Details</h3>
      <div [formGroup]="form">
        <div class="form-control">
          <label class="label" for="email">
            <span class="label-text">Email <span class="text-error" aria-hidden="true">*</span></span>
          </label>
          <input id="email" type="email" formControlName="email"
            class="input input-bordered"
            [class.input-error]="hasError('email')"
            [attr.aria-invalid]="hasError('email')"
            [attr.aria-describedby]="hasError('email') ? 'email-error' : null"
            aria-required="true" />
          @if (hasError('email')) {
            <label class="label">
              <span id="email-error" class="label-text-alt text-error" role="alert">
                {{ getError('email') }}
              </span>
            </label>
          }
        </div>
      </div>
    </div>
  `,
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class WizardStepContactComponent {
  private readonly fb = inject(FormBuilder);

  readonly form = this.fb.nonNullable.group({
    email: ['', [Validators.required, Validators.email]]
  });

  hasError(field: string): boolean {
    const c = this.form.get(field);
    return !!(c?.invalid && c?.touched);
  }

  getError(field: string): string | null {
    const c = this.form.get(field);
    if (!c?.invalid || !c?.touched) return null;
    if (c.errors?.['required']) return 'Email is required so we can confirm your submission';
    if (c.errors?.['email']) return 'Email must include @ symbol (e.g., name@example.com)';
    return null;
  }
}

// Step 3 — Review (read-only summary, no form)
@Component({
  selector: 'app-wizard-step-review',
  standalone: true,
  template: `
    <div class="space-y-4">
      <h3 class="text-lg font-semibold">Review Your Information</h3>
      <div class="bg-base-200 rounded-box p-4 space-y-2">
        @for (entry of summaryEntries(); track entry.label) {
          <div class="flex justify-between">
            <span class="text-base-content/60">{{ entry.label }}</span>
            <span class="font-medium">{{ entry.value }}</span>
          </div>
        }
      </div>
    </div>
  `,
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class WizardStepReviewComponent {
  summaryEntries = input<{ label: string; value: string }[]>([]);
}

// Wizard orchestrator
@Component({
  selector: 'app-multi-step-wizard',
  standalone: true,
  imports: [
    WizardStepPersonalComponent,
    WizardStepContactComponent,
    WizardStepReviewComponent
  ],
  template: `
    <div class="card bg-base-100 shadow-xl max-w-2xl mx-auto">
      <div class="card-body space-y-6">

        <!-- daisyUI steps progress bar -->
        <ul class="steps steps-horizontal w-full">
          @for (step of steps(); track $index) {
            <li class="step"
              [class.step-primary]="$index <= currentStep()"
              [attr.data-content]="$index < currentStep() ? '✓' : $index + 1">
              {{ step }}
            </li>
          }
        </ul>

        <!-- Step content -->
        @switch (currentStep()) {
          @case (0) { <app-wizard-step-personal #step0 /> }
          @case (1) { <app-wizard-step-contact #step1 /> }
          @case (2) {
            <app-wizard-step-review [summaryEntries]="summaryData()" />
          }
        }

        <!-- Navigation controls -->
        <div class="flex justify-between pt-4">
          <button type="button" class="btn btn-ghost"
            [class.btn-disabled]="!canGoBack()"
            [attr.aria-disabled]="!canGoBack()"
            (click)="goBack()">
            Back
          </button>

          @if (canSubmit()) {
            <button type="button" class="btn btn-primary"
              [disabled]="submitting()"
              (click)="submit()">
              @if (submitting()) { <span class="loading loading-spinner loading-sm"></span> }
              Submit
            </button>
          } @else {
            <button type="button" class="btn btn-primary"
              (click)="goNext()">
              Next
            </button>
          }
        </div>

      </div>
    </div>
  `,
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class MultiStepWizardComponent {
  // ---- State signals ----
  protected readonly currentStep = signal(0);
  protected readonly steps = signal(['Personal Info', 'Contact', 'Review']);
  protected readonly submitting = signal(false);

  // ---- Derived signals ----
  protected readonly progress = computed(
    () => ((this.currentStep() + 1) / this.steps().length) * 100
  );
  protected readonly canGoBack = computed(() => this.currentStep() > 0);
  protected readonly canSubmit = computed(
    () => this.currentStep() === this.steps().length - 1
  );

  // Collect form values from child step components via ViewChild in real usage.
  // Shown here as a plain signal for illustration.
  protected readonly summaryData = computed<{ label: string; value: string }[]>(
    () => [
      { label: 'First Name', value: '—' },
      { label: 'Last Name', value: '—' },
      { label: 'Email', value: '—' }
    ]
  );

  protected goNext(): void {
    // In practice: validate the current step's FormGroup before advancing.
    // e.g., if (this.stepRef.form.invalid) { this.stepRef.form.markAllAsTouched(); return; }
    if (this.currentStep() < this.steps().length - 1) {
      this.currentStep.update(s => s + 1);
    }
  }

  protected goBack(): void {
    if (this.canGoBack()) this.currentStep.update(s => s - 1);
  }

  protected async submit(): Promise<void> {
    this.submitting.set(true);
    try {
      // API call here — collect values from child step forms
    } finally {
      this.submitting.set(false);
    }
  }
}
```

**Accessing child step form values:** Use `@ViewChild(WizardStepPersonalComponent)` and read `.form.getRawValue()` before advancing. Store collected values in a parent signal and pass to the Review step as `summaryEntries`.

---

## Section E: Accessibility Requirements

Every form element must satisfy all of the following:

| Requirement | Implementation |
|-------------|---------------|
| Every `<input>` / `<textarea>` / `<select>` has a visible label | `<label [for]="id">` or `aria-label` on the element |
| Required fields are announced to screen readers | `aria-required="true"` on the input; visual asterisk with `aria-hidden="true"` |
| Error state is communicated to screen readers | `aria-invalid="true"` on the input when invalid and touched |
| Error messages are linked to their input | `aria-describedby="field-error-id"` on input; `id="field-error-id"` on error `<span>` |
| Error messages are announced immediately | `role="alert"` on the error `<span>` (live region) |
| Focus lands on the first error after failed submit | See focus management pattern below |
| Keyboard-only navigation works end-to-end | Tab order follows visual order; no focus traps except modals |
| Color is not the only indicator of error state | Use `input-error` class (border change) AND error message text, never color alone |

### Focus Management After Failed Submit

```typescript
// In your form component, inject ElementRef or use ViewChildren
import { ElementRef, inject, viewChildren } from '@angular/core';

protected onSubmit(): void {
  if (this.form.invalid) {
    this.form.markAllAsTouched();
    // Focus the first invalid field after change detection runs
    setTimeout(() => {
      const firstInvalidKey = Object.keys(this.form.controls)
        .find(key => this.form.get(key)?.invalid);
      if (firstInvalidKey) {
        const el = this.elementRef.nativeElement
          .querySelector(`[formControlName="${firstInvalidKey}"]`);
        el?.focus();
      }
    }, 0);
    return;
  }
  // proceed
}
```

### Error Announcement Template Pattern

```html
<!-- Always pair aria-invalid + aria-describedby on the input -->
<input
  type="email"
  formControlName="email"
  [attr.aria-invalid]="hasError('email')"
  [attr.aria-describedby]="hasError('email') ? 'email-error' : null"
  aria-required="true"
  class="input input-bordered" />

<!-- role="alert" triggers immediate screen reader announcement -->
@if (hasError('email')) {
  <span id="email-error" class="label-text-alt text-error" role="alert">
    Email must include @ symbol (e.g., name@example.com)
  </span>
}
```

---

## Component Templates

---

## Form Field Component

```typescript
import { Component, ChangeDetectionStrategy, input, computed } from '@angular/core';

@Component({
  selector: 'app-form-field',

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
