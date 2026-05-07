# Signal Forms — Angular 21+ (Preferred for New Apps)

Signal Forms is Angular's modern form API built on Signals. For Angular 21+, **prefer Signal Forms over reactive forms** for all new apps. Reactive forms (`FormBuilder`, `FormControl`) remain supported but are considered legacy.

## When to use Signal Forms vs Reactive Forms

| Scenario | Use |
|---|---|
| New Angular 21+ app | Signal Forms |
| Existing app with `FormBuilder` | Keep reactive forms (migration not required) |
| Complex dynamic form arrays | Signal Forms or reactive (both work) |
| Simple static form | Signal Forms |

## Basic Signal Form

```typescript
import { Component } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { signalForm, signalInput, Validators } from '@angular/forms/signal';

@Component({
  selector: 'app-login-form',
  standalone: true,
  imports: [FormsModule],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <form (ngSubmit)="submit()">
      <div class="form-control">
        <label class="label">
          <span class="label-text">Email</span>
        </label>
        <input
          type="email"
          class="input input-bordered"
          [class.input-error]="form.controls.email.invalid() && form.controls.email.touched()"
          [(ngModel)]="form.controls.email.value"
          placeholder="you@example.com"
        />
        @if (form.controls.email.invalid() && form.controls.email.touched()) {
          <span class="label-text-alt text-error">
            {{ form.controls.email.errors()?.['required'] ? 'Email is required' : 'Invalid email' }}
          </span>
        }
      </div>

      <div class="form-control">
        <label class="label">
          <span class="label-text">Password</span>
        </label>
        <input
          type="password"
          class="input input-bordered"
          [class.input-error]="form.controls.password.invalid() && form.controls.password.touched()"
          [(ngModel)]="form.controls.password.value"
        />
      </div>

      <button
        type="submit"
        class="btn btn-primary"
        [disabled]="form.invalid()"
      >
        Log in
      </button>
    </form>
  `,
})
export class LoginFormComponent {
  form = signalForm({
    email: signalInput('', {
      validators: [Validators.required, Validators.email],
    }),
    password: signalInput('', {
      validators: [Validators.required, Validators.minLength(8)],
    }),
  });

  submit() {
    if (this.form.valid()) {
      const { email, password } = this.form.value();
      // proceed with login
    }
  }
}
```

## Signal Form API — Key Properties

All properties are signals — read them with `()`:

```typescript
// Form-level
form.valid()        // boolean — all controls valid
form.invalid()      // boolean
form.dirty()        // boolean — any control has been changed
form.touched()      // boolean — any control has been focused+blurred
form.value()        // { email: string, password: string } — typed snapshot

// Control-level
form.controls.email.value()    // string — current value
form.controls.email.valid()    // boolean
form.controls.email.invalid()  // boolean
form.controls.email.dirty()    // boolean
form.controls.email.touched()  // boolean
form.controls.email.errors()   // ValidationErrors | null
```

## Derived validation with computed()

```typescript
export class PasswordChangeComponent {
  form = signalForm({
    current: signalInput('', { validators: [Validators.required] }),
    next: signalInput('', { validators: [Validators.required, Validators.minLength(8)] }),
    confirm: signalInput('', { validators: [Validators.required] }),
  });

  // Derived cross-field validation — no custom validator needed
  passwordMismatch = computed(() =>
    this.form.controls.next.value() !== this.form.controls.confirm.value()
  );

  canSubmit = computed(() =>
    this.form.valid() && !this.passwordMismatch()
  );
}
```

## Dynamic form array with Signal Forms

```typescript
export class TagsFormComponent {
  tags = signal<string[]>(['']);

  addTag() {
    this.tags.update(t => [...t, '']);
  }

  removeTag(index: number) {
    this.tags.update(t => t.filter((_, i) => i !== index));
  }

  updateTag(index: number, value: string) {
    this.tags.update(t => t.map((tag, i) => i === index ? value : tag));
  }
}
```

## Migration from Reactive Forms

```typescript
// ❌ Reactive Forms (legacy)
form = this.fb.group({
  email: ['', [Validators.required, Validators.email]],
  password: ['', [Validators.required, Validators.minLength(8)]],
});

// Accessing values
this.form.get('email')?.value
this.form.get('email')?.invalid && this.form.get('email')?.touched

// ✅ Signal Forms (Angular 21+)
form = signalForm({
  email: signalInput('', { validators: [Validators.required, Validators.email] }),
  password: signalInput('', { validators: [Validators.required, Validators.minLength(8)] }),
});

// Accessing values — all signals
this.form.controls.email.value()
this.form.controls.email.invalid() && this.form.controls.email.touched()
```

## Testing Signal Forms

```typescript
describe('LoginFormComponent', () => {
  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [LoginFormComponent],
    }).compileComponents();
  });

  it('should disable submit when form is invalid', () => {
    const fixture = TestBed.createComponent(LoginFormComponent);
    fixture.detectChanges();

    const btn = fixture.nativeElement.querySelector('button[type="submit"]');
    expect(btn.disabled).toBe(true);
  });

  it('should enable submit when form is valid', () => {
    const fixture = TestBed.createComponent(LoginFormComponent);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    component.form.controls.email.value.set('user@example.com');
    component.form.controls.password.value.set('securepass123');
    fixture.detectChanges();

    const btn = fixture.nativeElement.querySelector('button[type="submit"]');
    expect(btn.disabled).toBe(false);
  });
});
```

> **Note:** Signal Forms API (`signalForm`, `signalInput`) is available in Angular 21+. If your environment doesn't have these imports yet, verify your Angular version with `ng version`. If on Angular 21 but API is missing, it may require enabling with `withSignalForms()` in app.config.ts — check official Angular docs.
