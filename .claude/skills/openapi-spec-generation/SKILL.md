---
name: openapi-spec-generation
description: Generate and maintain OpenAPI 3.1 specifications from code, design-first specs, and validation patterns. Use when creating API documentation, generating SDKs, or ensuring API contract compliance.
globs:
  - "**/openapi.yaml"
  - "**/openapi.yml"
  - "**/openapi.json"
  - "**/swagger.yaml"
  - "**/swagger.json"
  - "**/*.openapi.yaml"
  - "**/api-docs/**"
triggers:
  - "generate openapi spec"
  - "create api documentation"
  - "write swagger spec"
  - "document this api"
  - "openapi from code"
  - "api spec"
---

# OpenAPI Spec Generation

Comprehensive patterns for creating, maintaining, and validating OpenAPI 3.1 specifications for RESTful APIs.

## Quick Start

**Design-First:**
1. Copy the minimal skeleton below → `openapi.yaml`
2. Add your paths and schemas
3. Validate: `spectral lint openapi.yaml`
4. Preview: `redocly preview-docs openapi.yaml`

**Code-First:**
| Stack | Command |
|-------|---------|
| FastAPI | `python -c "import json; from main import app; print(json.dumps(app.openapi(), indent=2))" > openapi.json` |
| Spring Boot | `curl http://localhost:8080/v3/api-docs > openapi.json` |
| tsoa | `npx tsoa spec` |

## When to Use This Skill

- Creating API documentation from scratch
- Generating OpenAPI specs from existing code
- Designing API contracts (design-first approach)
- Validating API implementations against specs
- Generating client SDKs from specs
- Setting up API documentation portals

## Core Concepts

### OpenAPI 3.1 Structure

```yaml
openapi: 3.1.0
info:
  title: API Title
  version: 1.0.0
servers:
  - url: https://api.example.com/v1
paths:
  /resources:
    get: ...
components:
  schemas: ...
  securitySchemes: ...
```

### Design Approaches

| Approach | Description | Best For |
|----------|-------------|----------|
| **Design-First** | Write spec before code | New APIs, contracts, external consumers |
| **Code-First** | Generate spec from code | Existing APIs, rapid iteration |
| **Hybrid** | Annotate code, generate spec | Evolving APIs, keep spec in sync |

### Code-First Tool Comparison

| Language | Tool | Annotation Style | Output |
|----------|------|------------------|--------|
| **Python** | FastAPI + Pydantic | Type hints + `Field()` | Auto at `/openapi.json` |
| **Java/Kotlin** | springdoc-openapi | `@Operation`, `@Schema` | Auto at `/v3/api-docs` |
| **TypeScript** | tsoa | Decorators (`@Get`, `@Response`) | Generated at build time |

## Templates

### Minimal Skeleton (Copy-Paste Starter)

```yaml
openapi: 3.1.0
info:
  title: My API
  version: 1.0.0
  description: API description here

servers:
  - url: https://api.example.com/v1
    description: Production
  - url: http://localhost:8080/v1
    description: Local

paths:
  /resources:
    get:
      operationId: listResources
      summary: List resources
      tags: [Resources]
      parameters:
        - $ref: "#/components/parameters/PageParam"
        - $ref: "#/components/parameters/LimitParam"
      responses:
        "200":
          description: Success
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/ResourceList"
        "401":
          $ref: "#/components/responses/Unauthorized"
      security:
        - bearerAuth: []

    post:
      operationId: createResource
      summary: Create resource
      tags: [Resources]
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: "#/components/schemas/CreateResourceRequest"
      responses:
        "201":
          description: Created
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/Resource"
        "400":
          $ref: "#/components/responses/BadRequest"
      security:
        - bearerAuth: []

components:
  schemas:
    Resource:
      type: object
      required: [id, name, createdAt]
      properties:
        id:
          type: string
          format: uuid
        name:
          type: string
        createdAt:
          type: string
          format: date-time

    CreateResourceRequest:
      type: object
      required: [name]
      properties:
        name:
          type: string
          minLength: 1
          maxLength: 100

    ResourceList:
      type: object
      properties:
        data:
          type: array
          items:
            $ref: "#/components/schemas/Resource"
        pagination:
          $ref: "#/components/schemas/Pagination"

    Pagination:
      type: object
      properties:
        page:
          type: integer
        limit:
          type: integer
        total:
          type: integer

    Error:
      type: object
      required: [code, message]
      properties:
        code:
          type: string
        message:
          type: string

  parameters:
    PageParam:
      name: page
      in: query
      schema:
        type: integer
        default: 1
        minimum: 1

    LimitParam:
      name: limit
      in: query
      schema:
        type: integer
        default: 20
        minimum: 1
        maximum: 100

  responses:
    BadRequest:
      description: Invalid request
      content:
        application/json:
          schema:
            $ref: "#/components/schemas/Error"

    Unauthorized:
      description: Authentication required
      content:
        application/json:
          schema:
            $ref: "#/components/schemas/Error"

  securitySchemes:
    bearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT
```

### Complete API Specification (Full Example)

<details>
<summary>Expand: User Management API with all features</summary>

```yaml
openapi: 3.1.0
info:
  title: User Management API
  description: |
    API for managing users and their profiles.

    ## Authentication
    All endpoints require Bearer token authentication.

    ## Rate Limiting
    - 1000 requests per minute for standard tier
    - 10000 requests per minute for enterprise tier
  version: 2.0.0
  contact:
    name: API Support
    email: api-support@example.com
    url: https://docs.example.com
  license:
    name: MIT
    url: https://opensource.org/licenses/MIT

servers:
  - url: https://api.example.com/v2
    description: Production
  - url: https://staging-api.example.com/v2
    description: Staging
  - url: http://localhost:3000/v2
    description: Local development

tags:
  - name: Users
    description: User management operations
  - name: Profiles
    description: User profile operations
  - name: Admin
    description: Administrative operations

paths:
  /users:
    get:
      operationId: listUsers
      summary: List all users
      description: Returns a paginated list of users with optional filtering.
      tags:
        - Users
      parameters:
        - $ref: "#/components/parameters/PageParam"
        - $ref: "#/components/parameters/LimitParam"
        - name: status
          in: query
          description: Filter by user status
          schema:
            $ref: "#/components/schemas/UserStatus"
        - name: search
          in: query
          description: Search by name or email
          schema:
            type: string
            minLength: 2
            maxLength: 100
      responses:
        "200":
          description: Successful response
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/UserListResponse"
              examples:
                default:
                  $ref: "#/components/examples/UserListExample"
        "400":
          $ref: "#/components/responses/BadRequest"
        "401":
          $ref: "#/components/responses/Unauthorized"
        "429":
          $ref: "#/components/responses/RateLimited"
      security:
        - bearerAuth: []

    post:
      operationId: createUser
      summary: Create a new user
      description: Creates a new user account and sends welcome email.
      tags:
        - Users
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: "#/components/schemas/CreateUserRequest"
            examples:
              standard:
                summary: Standard user
                value:
                  email: user@example.com
                  name: John Doe
                  role: user
              admin:
                summary: Admin user
                value:
                  email: admin@example.com
                  name: Admin User
                  role: admin
      responses:
        "201":
          description: User created successfully
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/User"
          headers:
            Location:
              description: URL of created user
              schema:
                type: string
                format: uri
        "400":
          $ref: "#/components/responses/BadRequest"
        "409":
          description: Email already exists
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/Error"
      security:
        - bearerAuth: []

  /users/{userId}:
    parameters:
      - $ref: "#/components/parameters/UserIdParam"

    get:
      operationId: getUser
      summary: Get user by ID
      tags:
        - Users
      responses:
        "200":
          description: Successful response
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/User"
        "404":
          $ref: "#/components/responses/NotFound"
      security:
        - bearerAuth: []

    patch:
      operationId: updateUser
      summary: Update user
      tags:
        - Users
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: "#/components/schemas/UpdateUserRequest"
      responses:
        "200":
          description: User updated
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/User"
        "400":
          $ref: "#/components/responses/BadRequest"
        "404":
          $ref: "#/components/responses/NotFound"
      security:
        - bearerAuth: []

    delete:
      operationId: deleteUser
      summary: Delete user
      tags:
        - Users
        - Admin
      responses:
        "204":
          description: User deleted
        "404":
          $ref: "#/components/responses/NotFound"
      security:
        - bearerAuth: []
        - apiKey: []

components:
  schemas:
    User:
      type: object
      required:
        - id
        - email
        - name
        - status
        - createdAt
      properties:
        id:
          type: string
          format: uuid
          readOnly: true
          description: Unique user identifier
        email:
          type: string
          format: email
          description: User email address
        name:
          type: string
          minLength: 1
          maxLength: 100
          description: User display name
        status:
          $ref: "#/components/schemas/UserStatus"
        role:
          type: string
          enum: [user, moderator, admin]
          default: user
        avatar:
          type: string
          format: uri
          nullable: true
        metadata:
          type: object
          additionalProperties: true
          description: Custom metadata
        createdAt:
          type: string
          format: date-time
          readOnly: true
        updatedAt:
          type: string
          format: date-time
          readOnly: true

    UserStatus:
      type: string
      enum: [active, inactive, suspended, pending]
      description: User account status

    CreateUserRequest:
      type: object
      required:
        - email
        - name
      properties:
        email:
          type: string
          format: email
        name:
          type: string
          minLength: 1
          maxLength: 100
        role:
          type: string
          enum: [user, moderator, admin]
          default: user
        metadata:
          type: object
          additionalProperties: true

    UpdateUserRequest:
      type: object
      minProperties: 1
      properties:
        name:
          type: string
          minLength: 1
          maxLength: 100
        status:
          $ref: "#/components/schemas/UserStatus"
        role:
          type: string
          enum: [user, moderator, admin]
        metadata:
          type: object
          additionalProperties: true

    UserListResponse:
      type: object
      required:
        - data
        - pagination
      properties:
        data:
          type: array
          items:
            $ref: "#/components/schemas/User"
        pagination:
          $ref: "#/components/schemas/Pagination"

    Pagination:
      type: object
      required:
        - page
        - limit
        - total
        - totalPages
      properties:
        page:
          type: integer
          minimum: 1
        limit:
          type: integer
          minimum: 1
          maximum: 100
        total:
          type: integer
          minimum: 0
        totalPages:
          type: integer
          minimum: 0
        hasNext:
          type: boolean
        hasPrev:
          type: boolean

    Error:
      type: object
      required:
        - code
        - message
      properties:
        code:
          type: string
          description: Error code for programmatic handling
        message:
          type: string
          description: Human-readable error message
        details:
          type: array
          items:
            type: object
            properties:
              field:
                type: string
              message:
                type: string
        requestId:
          type: string
          description: Request ID for support

  parameters:
    UserIdParam:
      name: userId
      in: path
      required: true
      description: User ID
      schema:
        type: string
        format: uuid

    PageParam:
      name: page
      in: query
      description: Page number (1-based)
      schema:
        type: integer
        minimum: 1
        default: 1

    LimitParam:
      name: limit
      in: query
      description: Items per page
      schema:
        type: integer
        minimum: 1
        maximum: 100
        default: 20

  responses:
    BadRequest:
      description: Invalid request
      content:
        application/json:
          schema:
            $ref: "#/components/schemas/Error"
          example:
            code: VALIDATION_ERROR
            message: Invalid request parameters
            details:
              - field: email
                message: Must be a valid email address

    Unauthorized:
      description: Authentication required
      content:
        application/json:
          schema:
            $ref: "#/components/schemas/Error"
          example:
            code: UNAUTHORIZED
            message: Authentication required

    NotFound:
      description: Resource not found
      content:
        application/json:
          schema:
            $ref: "#/components/schemas/Error"
          example:
            code: NOT_FOUND
            message: User not found

    RateLimited:
      description: Too many requests
      content:
        application/json:
          schema:
            $ref: "#/components/schemas/Error"
      headers:
        Retry-After:
          description: Seconds until rate limit resets
          schema:
            type: integer
        X-RateLimit-Limit:
          description: Request limit per window
          schema:
            type: integer
        X-RateLimit-Remaining:
          description: Remaining requests in window
          schema:
            type: integer

  examples:
    UserListExample:
      value:
        data:
          - id: "550e8400-e29b-41d4-a716-446655440000"
            email: "john@example.com"
            name: "John Doe"
            status: "active"
            role: "user"
            createdAt: "2024-01-15T10:30:00Z"
        pagination:
          page: 1
          limit: 20
          total: 1
          totalPages: 1
          hasNext: false
          hasPrev: false

  securitySchemes:
    bearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT
      description: JWT token from /auth/login

    apiKey:
      type: apiKey
      in: header
      name: X-API-Key
      description: API key for service-to-service calls

security:
  - bearerAuth: []
```

</details>

### Code-First: Java/Spring Boot (springdoc-openapi)

```java
// build.gradle.kts
dependencies {
    implementation("org.springdoc:springdoc-openapi-starter-webflux-ui:2.8.0")
}
```

```yaml
# application.yml
springdoc:
  api-docs:
    path: /v3/api-docs
  swagger-ui:
    path: /swagger-ui.html
    tags-sorter: alpha
    operations-sorter: alpha
```

```java
// OpenApiConfig.java
@Configuration
public class OpenApiConfig {
    @Bean
    public OpenAPI customOpenAPI() {
        return new OpenAPI()
            .info(new Info()
                .title("User Management API")
                .version("2.0.0")
                .description("API for managing users and profiles")
                .contact(new Contact()
                    .name("API Support")
                    .email("api-support@example.com")))
            .addSecurityItem(new SecurityRequirement().addList("bearerAuth"))
            .components(new Components()
                .addSecuritySchemes("bearerAuth", new SecurityScheme()
                    .type(SecurityScheme.Type.HTTP)
                    .scheme("bearer")
                    .bearerFormat("JWT")));
    }
}
```

```java
// UserController.java
@RestController
@RequestMapping("/api/v1/users")
@Tag(name = "Users", description = "User management operations")
@SecurityRequirement(name = "bearerAuth")
public class UserController {

    @Operation(
        summary = "List all users",
        description = "Returns paginated list with optional filtering"
    )
    @ApiResponses({
        @ApiResponse(responseCode = "200", description = "Success",
            content = @Content(schema = @Schema(implementation = UserListResponse.class))),
        @ApiResponse(responseCode = "400", description = "Invalid request",
            content = @Content(schema = @Schema(implementation = ErrorResponse.class))),
        @ApiResponse(responseCode = "401", description = "Unauthorized")
    })
    @GetMapping
    public Mono<UserListResponse> listUsers(
        @Parameter(description = "Page number (1-based)")
        @RequestParam(defaultValue = "1") @Min(1) int page,
        
        @Parameter(description = "Items per page")
        @RequestParam(defaultValue = "20") @Min(1) @Max(100) int limit,
        
        @Parameter(description = "Filter by status")
        @RequestParam(required = false) UserStatus status,
        
        @Parameter(description = "Search by name or email")
        @RequestParam(required = false) @Size(min = 2, max = 100) String search
    ) {
        // Implementation
    }

    @Operation(summary = "Create a new user")
    @ApiResponses({
        @ApiResponse(responseCode = "201", description = "User created",
            content = @Content(schema = @Schema(implementation = User.class))),
        @ApiResponse(responseCode = "400", description = "Invalid request"),
        @ApiResponse(responseCode = "409", description = "Email already exists")
    })
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public Mono<User> createUser(
        @Valid @RequestBody CreateUserRequest request
    ) {
        // Implementation
    }

    @Operation(summary = "Get user by ID")
    @ApiResponses({
        @ApiResponse(responseCode = "200", description = "Success"),
        @ApiResponse(responseCode = "404", description = "User not found")
    })
    @GetMapping("/{userId}")
    public Mono<User> getUser(
        @Parameter(description = "User ID", required = true)
        @PathVariable UUID userId
    ) {
        // Implementation
    }

    @Operation(summary = "Update user")
    @PatchMapping("/{userId}")
    public Mono<User> updateUser(
        @PathVariable UUID userId,
        @Valid @RequestBody UpdateUserRequest request
    ) {
        // Implementation
    }

    @Operation(summary = "Delete user")
    @DeleteMapping("/{userId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Tag(name = "Admin")
    public Mono<Void> deleteUser(@PathVariable UUID userId) {
        // Implementation
    }
}
```

```java
// DTOs with schema annotations
@Schema(description = "User entity")
public record User(
    @Schema(description = "Unique identifier", format = "uuid")
    UUID id,
    
    @Schema(description = "Email address", format = "email")
    String email,
    
    @Schema(description = "Display name", minLength = 1, maxLength = 100)
    String name,
    
    @Schema(description = "Account status")
    UserStatus status,
    
    @Schema(description = "User role", defaultValue = "user")
    UserRole role,
    
    @Schema(description = "Created timestamp")
    Instant createdAt
) {}

@Schema(description = "Create user request")
public record CreateUserRequest(
    @Schema(description = "Email address", format = "email", requiredMode = REQUIRED)
    @NotBlank @Email String email,
    
    @Schema(description = "Display name", minLength = 1, maxLength = 100, requiredMode = REQUIRED)
    @NotBlank @Size(min = 1, max = 100) String name,
    
    @Schema(description = "User role", defaultValue = "user")
    UserRole role
) {}
```

### Code-First: Python/FastAPI

<details>
<summary>Expand: FastAPI with automatic OpenAPI generation</summary>

```python
from fastapi import FastAPI, HTTPException, Query, Path
from pydantic import BaseModel, Field, EmailStr
from typing import Optional, List
from datetime import datetime
from uuid import UUID
from enum import Enum

app = FastAPI(
    title="User Management API",
    description="API for managing users and profiles",
    version="2.0.0",
    openapi_tags=[
        {"name": "Users", "description": "User operations"},
        {"name": "Admin", "description": "Admin operations"},
    ],
    servers=[
        {"url": "https://api.example.com/v2", "description": "Production"},
        {"url": "http://localhost:8000", "description": "Development"},
    ],
)

# Enums
class UserStatus(str, Enum):
    active = "active"
    inactive = "inactive"
    suspended = "suspended"

class UserRole(str, Enum):
    user = "user"
    moderator = "moderator"
    admin = "admin"

# Models
class UserCreate(BaseModel):
    email: EmailStr = Field(..., description="User email address")
    name: str = Field(..., min_length=1, max_length=100, description="Display name")
    role: UserRole = Field(default=UserRole.user)

    model_config = {
        "json_schema_extra": {
            "examples": [{"email": "user@example.com", "name": "John Doe", "role": "user"}]
        }
    }

class User(BaseModel):
    id: UUID = Field(..., description="Unique identifier")
    email: EmailStr
    name: str
    status: UserStatus
    role: UserRole
    created_at: datetime = Field(..., alias="createdAt")

    model_config = {"populate_by_name": True}

class UserListResponse(BaseModel):
    data: List[User]
    pagination: dict

class ErrorResponse(BaseModel):
    code: str = Field(..., description="Error code")
    message: str = Field(..., description="Error message")

# Endpoints
@app.get("/users", response_model=UserListResponse, tags=["Users"])
async def list_users(
    page: int = Query(1, ge=1, description="Page number"),
    limit: int = Query(20, ge=1, le=100, description="Items per page"),
    status: Optional[UserStatus] = Query(None, description="Filter by status"),
):
    """List users with pagination and filtering."""
    pass

@app.post("/users", response_model=User, status_code=201, tags=["Users"],
          responses={409: {"model": ErrorResponse, "description": "Email exists"}})
async def create_user(user: UserCreate):
    """Create a new user and send welcome email."""
    pass

@app.get("/users/{user_id}", response_model=User, tags=["Users"],
         responses={404: {"model": ErrorResponse}})
async def get_user(user_id: UUID = Path(..., description="User ID")):
    """Get user by ID."""
    pass

@app.delete("/users/{user_id}", status_code=204, tags=["Users", "Admin"])
async def delete_user(user_id: UUID = Path(..., description="User ID")):
    """Delete user permanently."""
    pass

# Export: python -c "import json; from main import app; print(json.dumps(app.openapi(), indent=2))"
```

</details>

### Code-First: TypeScript/tsoa

<details>
<summary>Expand: tsoa with decorators</summary>

```typescript
import {
  Controller, Get, Post, Patch, Delete, Route, Path, Query, Body,
  Response, SuccessResponse, Tags, Security, Example,
} from "tsoa";

interface User {
  id: string;
  email: string;
  name: string;
  status: "active" | "inactive" | "suspended";
  role: "user" | "moderator" | "admin";
  createdAt: Date;
}

interface CreateUserRequest {
  email: string;
  name: string;
  role?: "user" | "moderator" | "admin";
}

interface ErrorResponse {
  code: string;
  message: string;
}

@Route("users")
@Tags("Users")
export class UsersController extends Controller {
  
  @Get()
  @Security("bearerAuth")
  @Response<ErrorResponse>(401, "Unauthorized")
  public async listUsers(
    @Query() page: number = 1,
    @Query() limit: number = 20,
    @Query() status?: string,
  ): Promise<{ data: User[]; pagination: object }> {
    throw new Error("Not implemented");
  }

  @Post()
  @Security("bearerAuth")
  @SuccessResponse(201, "Created")
  @Response<ErrorResponse>(400, "Invalid request")
  @Response<ErrorResponse>(409, "Email exists")
  public async createUser(@Body() body: CreateUserRequest): Promise<User> {
    this.setStatus(201);
    throw new Error("Not implemented");
  }

  @Get("{userId}")
  @Security("bearerAuth")
  @Response<ErrorResponse>(404, "Not found")
  public async getUser(@Path() userId: string): Promise<User> {
    throw new Error("Not implemented");
  }

  @Delete("{userId}")
  @Tags("Users", "Admin")
  @Security("bearerAuth")
  @SuccessResponse(204, "Deleted")
  public async deleteUser(@Path() userId: string): Promise<void> {
    this.setStatus(204);
  }
}
```

</details>

## Validation & Linting

### Spectral Configuration

```yaml
# .spectral.yaml
extends: ["spectral:oas"]

rules:
  # Require operation IDs (for SDK generation)
  operation-operationId: error
  
  # Require descriptions
  operation-description: warn
  info-description: error
  
  # Security
  operation-security-defined: error
  
  # Response codes
  operation-success-response: error
  
  # Custom: snake_case path params
  path-params-snake-case:
    description: Path parameters should be snake_case
    severity: warn
    given: "$.paths[*].parameters[?(@.in == 'path')].name"
    then:
      function: pattern
      functionOptions:
        match: "^[a-z][a-z0-9_]*$"

  # Custom: camelCase schema properties
  schema-properties-camelCase:
    description: Schema properties should be camelCase
    severity: warn
    given: "$.components.schemas[*].properties[*]~"
    then:
      function: casing
      functionOptions:
        type: camel
```

### Validation Commands

```bash
# Install tools
npm install -g @stoplight/spectral-cli @redocly/cli

# Lint with Spectral
spectral lint openapi.yaml

# Lint with Redocly
redocly lint openapi.yaml

# Bundle multiple files
redocly bundle openapi.yaml -o bundled.yaml

# Preview documentation
redocly preview-docs openapi.yaml
```

## SDK Generation

```bash
# Install OpenAPI Generator
npm install -g @openapitools/openapi-generator-cli

# TypeScript client
openapi-generator-cli generate \
  -i openapi.yaml \
  -g typescript-fetch \
  -o ./generated/ts-client \
  --additional-properties=supportsES6=true,npmName=@myorg/api-client

# Python client
openapi-generator-cli generate \
  -i openapi.yaml \
  -g python \
  -o ./generated/python-client \
  --additional-properties=packageName=api_client

# Java client
openapi-generator-cli generate \
  -i openapi.yaml \
  -g java \
  -o ./generated/java-client \
  --additional-properties=library=webclient,dateLibrary=java8
```

## CI/CD Integration

```yaml
# .github/workflows/api-docs.yml
name: API Docs
on: [push, pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Lint OpenAPI spec
        uses: stoplightio/spectral-action@v0.8.10
        with:
          file_glob: "openapi.yaml"
      
      - name: Build docs
        run: npx @redocly/cli build-docs openapi.yaml -o docs/index.html
      
      - name: Upload docs
        uses: actions/upload-artifact@v4
        with:
          name: api-docs
          path: docs/
```

## Common Mistakes

| Mistake | Problem | Fix |
|---------|---------|-----|
| Missing `operationId` | SDK generators create ugly method names | Add unique operationId to every endpoint |
| No error schemas | Consumers can't handle errors properly | Define Error schema, use for all 4xx/5xx |
| Examples don't match schema | Validation fails, confuses consumers | Use `$ref` for examples, validate with Spectral |
| Inconsistent naming | `user_id` vs `userId` vs `userID` | Pick one style (camelCase), enforce with linter |
| Missing `nullable: true` | Null handling bugs | Be explicit: `nullable: true` (3.0) or `type: ["string", "null"]` (3.1) |
| No pagination on list endpoints | Clients fetch unbounded data | Always paginate, document limits |
| Hardcoded server URLs | Breaks in different environments | Use server variables or multiple server entries |

## Best Practices

### Do's

- **Use `$ref`** — Reuse schemas, parameters, responses
- **Add examples** — Real-world values help consumers
- **Document all errors** — Every possible error code
- **Version your API** — In URL (`/v1/`) or header
- **Use semantic versioning** — For spec changes
- **Validate in CI** — Catch breaking changes early

### Don'ts

- **Don't use generic descriptions** — Be specific
- **Don't skip security** — Define all auth schemes
- **Don't forget nullable** — Be explicit about null
- **Don't mix naming styles** — Consistent throughout
- **Don't hardcode URLs** — Use server variables

## Resources

- [OpenAPI 3.1 Specification](https://spec.openapis.org/oas/v3.1.0)
- [Swagger Editor](https://editor.swagger.io/)
- [Redocly](https://redocly.com/)
- [Spectral](https://stoplight.io/open-source/spectral)
- [OpenAPI Generator](https://openapi-generator.tech/)
- [springdoc-openapi](https://springdoc.org/)