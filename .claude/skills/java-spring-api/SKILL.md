---
name: java-spring-api
description: Patterns and templates for Java 21 Spring Boot 3.4 WebFlux REST API development. Activate when creating controllers, services, repositories, DTOs, or tests in a Spring Boot project.
allowed-tools: Bash, Read, Write, Edit
---

# Java 21 + Spring Boot 3.4 WebFlux REST API Skill

## Quick Scaffold — New Spring Boot Project

```bash
# Using Spring Initializr via curl
curl https://start.spring.io/starter.zip \
  -d type=maven-project \
  -d language=java \
  -d javaVersion=21 \
  -d bootVersion=3.5.0 \
  -d dependencies=webflux,r2dbc,postgresql,flyway,validation,actuator,lombok \
  -d groupId=com.company \
  -d artifactId=my-service \
  -d name=my-service \
  -o my-service.zip && unzip my-service.zip -d my-service
```

## pom.xml Essentials
```xml
<project>
    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>3.5.0</version>
    </parent>

    <properties>
        <java.version>21</java.version>
    </properties>

    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-webflux</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-data-r2dbc</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-validation</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-actuator</artifactId>
        </dependency>
        <dependency>
            <groupId>org.postgresql</groupId>
            <artifactId>r2dbc-postgresql</artifactId>
            <scope>runtime</scope>
        </dependency>
        <dependency>
            <groupId>org.postgresql</groupId>
            <artifactId>postgresql</artifactId>
            <scope>runtime</scope>
        </dependency>
        <dependency>
            <groupId>org.flywaydb</groupId>
            <artifactId>flyway-core</artifactId>
        </dependency>
        <dependency>
            <groupId>org.flywaydb</groupId>
            <artifactId>flyway-database-postgresql</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
        <dependency>
            <groupId>io.projectreactor</groupId>
            <artifactId>reactor-test</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>
</project>
```

## File Templates

### DTO (record)
```java
public record CreateUserRequest(
    @NotBlank String email,
    @NotBlank @Size(max = 100) String firstName,
    @NotBlank @Size(max = 100) String lastName
) {}

public record UserResponse(
    UUID id, String email, String firstName, String lastName, Instant createdAt
) {}
```

### R2DBC Entity
```java
@Table("users")
public class UserEntity {
    @Id private UUID id;
    private String email;
    private String firstName;
    private String lastName;
    private Instant createdAt;
    private Instant updatedAt;
    // getters, setters, builder
}
```

### Repository
```java
public interface UserRepository extends ReactiveCrudRepository<UserEntity, UUID> {
    Mono<UserEntity> findByEmail(String email);
    Flux<UserEntity> findByLastName(String lastName);
}
```

### Service
```java
@Service
@RequiredArgsConstructor
public class UserService {
    private final UserRepository userRepository;

    public Mono<UserResponse> findById(UUID id) {
        return userRepository.findById(id)
                .map(this::toResponse)
                .switchIfEmpty(Mono.error(new NotFoundException("User not found")));
    }

    public Mono<UserResponse> create(CreateUserRequest request) {
        var entity = new UserEntity();
        entity.setEmail(request.email());
        entity.setFirstName(request.firstName());
        entity.setLastName(request.lastName());
        entity.setCreatedAt(Instant.now());
        entity.setUpdatedAt(Instant.now());
        return userRepository.save(entity).map(this::toResponse);
    }

    private UserResponse toResponse(UserEntity e) {
        return new UserResponse(e.getId(), e.getEmail(), e.getFirstName(), e.getLastName(), e.getCreatedAt());
    }
}
```

### Controller
```java
@RestController
@RequestMapping("/api/v1/users")
@RequiredArgsConstructor
public class UserController {
    private final UserService userService;

    @GetMapping("/{id}")
    public Mono<ResponseEntity<UserResponse>> getById(@PathVariable UUID id) {
        return userService.findById(id)
                .map(ResponseEntity::ok)
                .switchIfEmpty(Mono.just(ResponseEntity.notFound().build()));
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public Mono<UserResponse> create(@Valid @RequestBody CreateUserRequest request) {
        return userService.create(request);
    }

    @GetMapping
    public Flux<UserResponse> getAll() {
        return userService.findAll();
    }
}
```

### Test
```java
@SpringBootTest
@AutoConfigureWebTestClient
class UserControllerTest {

    @Autowired WebTestClient webTestClient;

    @Test
    void createUser_shouldReturn201() {
        var request = new CreateUserRequest("john@example.com", "John", "Doe");

        webTestClient.post().uri("/api/v1/users")
                .contentType(MediaType.APPLICATION_JSON)
                .bodyValue(request)
                .exchange()
                .expectStatus().isCreated()
                .expectBody()
                .jsonPath("$.email").isEqualTo("john@example.com");
    }
}
```

## application.yml Template
```yaml
spring:
  r2dbc:
    url: r2dbc:postgresql://localhost:5432/mydb
    username: ${DB_USERNAME:postgres}
    password: ${DB_PASSWORD:postgres}
  flyway:
    url: jdbc:postgresql://localhost:5432/mydb
    user: ${DB_USERNAME:postgres}
    password: ${DB_PASSWORD:postgres}
  webflux:
    base-path: /

server:
  port: 8080

management:
  endpoints:
    web:
      exposure:
        include: health,info,metrics
```
