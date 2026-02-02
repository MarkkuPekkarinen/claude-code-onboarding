---
name: angular-spa
description: Patterns and templates for Angular 21.x SPA development with standalone components, signals, and lazy routing. Activate when building Angular components, services, routes, or tests.
allowed-tools: Bash, Read, Write, Edit
---

# Angular 21.x SPA Development Skill

## Quick Scaffold — New Angular Project
```bash
npx @angular/cli@latest new my-app \
  --routing --style=scss --standalone --ssr=false
cd my-app
```

## Standalone Component Template
```typescript
import { Component, ChangeDetectionStrategy, signal, inject } from '@angular/core';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-feature',
  standalone: true,
  imports: [CommonModule],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    @if (loading()) {
      <div class="spinner">Loading...</div>
    } @else {
      <div class="feature">
        @for (item of items(); track item.id) {
          <div class="feature__item">{{ item.name }}</div>
        }
      </div>
    }
  `,
  styles: [`
    .feature { display: flex; flex-direction: column; gap: 1rem; }
    .feature__item { padding: 1rem; border: 1px solid #e0e0e0; border-radius: 8px; }
  `]
})
export class FeatureComponent {
  private service = inject(FeatureService);
  items = signal<Item[]>([]);
  loading = signal(true);

  constructor() {
    this.service.getAll().subscribe({
      next: (data) => { this.items.set(data); this.loading.set(false); },
      error: () => this.loading.set(false),
    });
  }
}
```

## Service Template
```typescript
import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';

@Injectable({ providedIn: 'root' })
export class UserService {
  private http = inject(HttpClient);
  private baseUrl = `${environment.apiUrl}/api/v1/users`;

  getAll(): Observable<User[]> {
    return this.http.get<User[]>(this.baseUrl);
  }

  getById(id: string): Observable<User> {
    return this.http.get<User>(`${this.baseUrl}/${id}`);
  }

  create(dto: CreateUserDto): Observable<User> {
    return this.http.post<User>(this.baseUrl, dto);
  }

  update(id: string, dto: UpdateUserDto): Observable<User> {
    return this.http.patch<User>(`${this.baseUrl}/${id}`, dto);
  }

  delete(id: string): Observable<void> {
    return this.http.delete<void>(`${this.baseUrl}/${id}`);
  }
}
```

## Lazy Routes Template
```typescript
// app.routes.ts
import { Routes } from '@angular/router';
import { authGuard } from './core/guards/auth.guard';

export const routes: Routes = [
  { path: '', redirectTo: 'dashboard', pathMatch: 'full' },
  {
    path: 'dashboard',
    loadComponent: () => import('./features/dashboard/dashboard.component')
      .then(m => m.DashboardComponent),
    canActivate: [authGuard],
  },
  {
    path: 'users',
    loadChildren: () => import('./features/users/users.routes')
      .then(m => m.USER_ROUTES),
    canActivate: [authGuard],
  },
  {
    path: 'login',
    loadComponent: () => import('./features/auth/login.component')
      .then(m => m.LoginComponent),
  },
  { path: '**', redirectTo: 'dashboard' },
];
```

## app.config.ts
```typescript
import { ApplicationConfig, provideZoneChangeDetection } from '@angular/core';
import { provideRouter } from '@angular/router';
import { provideHttpClient, withInterceptorsFromDi } from '@angular/common/http';
import { routes } from './app.routes';

export const appConfig: ApplicationConfig = {
  providers: [
    provideZoneChangeDetection({ eventCoalescing: true }),
    provideRouter(routes),
    provideHttpClient(withInterceptorsFromDi()),
  ],
};
```

## Auth Interceptor
```typescript
import { HttpInterceptorFn } from '@angular/common/http';
import { inject } from '@angular/core';
import { AuthService } from '../services/auth.service';

export const authInterceptor: HttpInterceptorFn = (req, next) => {
  const token = inject(AuthService).getToken();
  if (token) {
    req = req.clone({ setHeaders: { Authorization: `Bearer ${token}` } });
  }
  return next(req);
};
```

## Component Test Template
```typescript
describe('UserListComponent', () => {
  let fixture: ComponentFixture<UserListComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [UserListComponent],
      providers: [
        provideHttpClient(),
        provideHttpClientTesting(),
      ],
    }).compileComponents();

    fixture = TestBed.createComponent(UserListComponent);
    fixture.detectChanges();
  });

  it('should display users', () => {
    expect(fixture.nativeElement.querySelectorAll('.user-card').length).toBeGreaterThan(0);
  });
});
```
