# Spring Boot Enterprise Patterns

Production-ready enterprise patterns for Java 21 + Spring Boot 3.5.x WebFlux.

## Exception Hierarchy

### Base Exception

```java
package com.company.service.exception;

import java.util.Collections;
import java.util.List;
import java.util.Map;
import org.springframework.http.HttpStatus;

public abstract class ApplicationException extends RuntimeException {

    private final HttpStatus httpStatus;
    private final String errorCode;
    private final List<String> errors;
    private final Map<String, Object> details;

    protected ApplicationException(HttpStatus httpStatus, String errorCode, String message) {
        this(httpStatus, errorCode, message, null, List.of(), Map.of());
    }

    protected ApplicationException(HttpStatus httpStatus, String errorCode, String message, Throwable cause) {
        this(httpStatus, errorCode, message, cause, List.of(), Map.of());
    }

    protected ApplicationException(HttpStatus httpStatus, String errorCode, String message, List<String> errors) {
        this(httpStatus, errorCode, message, null, errors, Map.of());
    }

    protected ApplicationException(HttpStatus httpStatus, String errorCode, String message,
                                   Throwable cause, List<String> errors, Map<String, Object> details) {
        super(message, cause);
        this.httpStatus = httpStatus;
        this.errorCode = errorCode;
        this.errors = errors != null ? Collections.unmodifiableList(errors) : List.of();
        this.details = details != null ? Collections.unmodifiableMap(details) : Map.of();
    }

    public HttpStatus getHttpStatus() { return httpStatus; }
    public String getErrorCode() { return errorCode; }
    public List<String> getErrors() { return errors; }
    public Map<String, Object> getDetails() { return details; }
}
```

### Concrete Exceptions

```java
// 400 Bad Request — validation failures
public class InvalidInputException extends ApplicationException {
    public InvalidInputException(String message) {
        super(HttpStatus.BAD_REQUEST, "VALIDATION_ERROR", message);
    }
    public InvalidInputException(String message, List<String> errors) {
        super(HttpStatus.BAD_REQUEST, "VALIDATION_ERROR", message, errors);
    }
}

// 404 Not Found
public class ResourceNotFoundException extends ApplicationException {
    public ResourceNotFoundException(String message) {
        super(HttpStatus.NOT_FOUND, "RESOURCE_NOT_FOUND", message);
    }
}

// 409 Conflict — business rule violations
public class BusinessRuleException extends ApplicationException {
    public BusinessRuleException(String message) {
        super(HttpStatus.CONFLICT, "BUSINESS_RULE_VIOLATION", message);
    }
    public BusinessRuleException(HttpStatus status, String errorCode, String message) {
        super(status, errorCode, message);
    }
}

// 500/502/503 — external service failures
public class ServiceIntegrationException extends ApplicationException {
    public ServiceIntegrationException(String message, Throwable cause) {
        super(HttpStatus.INTERNAL_SERVER_ERROR, "INTEGRATION_ERROR", message, cause);
    }
    public ServiceIntegrationException(HttpStatus status, String errorCode, String message, Throwable cause) {
        super(status, errorCode, message, cause);
    }
}
```

### Error Response DTOs

```java
// Client errors (4xx)
public record ClientErrorResponse(
    @Schema(description = "General error description", example = "Validation failed")
    String message,

    @Schema(description = "Specific error details", example = "[\"email is required\"]", nullable = true)
    List<String> errors,

    @Schema(description = "Application error code", example = "VALIDATION_ERROR")
    String errorCode,

    @Schema(description = "ISO-8601 timestamp", example = "2025-05-19T13:30:00Z")
    String timestamp
) {}

// Server errors (5xx)
public record ServerErrorResponse(
    @Schema(description = "Error type", example = "InternalServerError")
    String error,

    @Schema(description = "Error description", example = "Unexpected error occurred")
    String message,

    @Schema(description = "ISO-8601 timestamp", example = "2025-05-19T13:30:00Z")
    String timestamp,

    @Schema(description = "Trace ID for log correlation", example = "abc123xy")
    String traceId
) {}
```

### Global Error Handler (WebFlux)

```java
@Component
@Order(-2)
public class GlobalErrorWebExceptionHandler extends AbstractErrorWebExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(GlobalErrorWebExceptionHandler.class);

    public GlobalErrorWebExceptionHandler(ErrorAttributes errorAttributes,
                                          ApplicationContext applicationContext,
                                          ServerCodecConfigurer serverCodecConfigurer) {
        super(errorAttributes, new WebProperties().getResources(), applicationContext);
        super.setMessageWriters(serverCodecConfigurer.getWriters());
        super.setMessageReaders(serverCodecConfigurer.getReaders());
    }

    @Override
    protected RouterFunction<ServerResponse> getRoutingFunction(ErrorAttributes errorAttributes) {
        return RouterFunctions.route(RequestPredicates.all(), this::renderErrorResponse);
    }

    private Mono<ServerResponse> renderErrorResponse(ServerRequest request) {
        Throwable error = getError(request);
        String traceId = UUID.randomUUID().toString().substring(0, 8);
        String timestamp = Instant.now().toString();

        log.error("[{}] {} {} — {}", traceId, request.methodName(), request.path(), error.getMessage(), error);

        return switch (error) {
            case ApplicationException appEx when appEx.getHttpStatus().is4xxClientError() ->
                ServerResponse.status(appEx.getHttpStatus())
                    .contentType(MediaType.APPLICATION_JSON)
                    .bodyValue(new ClientErrorResponse(
                        appEx.getMessage(), appEx.getErrors(), appEx.getErrorCode(), timestamp));

            case ApplicationException appEx ->
                ServerResponse.status(appEx.getHttpStatus())
                    .contentType(MediaType.APPLICATION_JSON)
                    .bodyValue(new ServerErrorResponse(
                        appEx.getErrorCode(), appEx.getMessage(), timestamp, traceId));

            case WebExchangeBindException validationEx -> {
                List<String> errors = validationEx.getBindingResult().getAllErrors().stream()
                    .map(DefaultMessageSourceResolvable::getDefaultMessage).toList();
                yield ServerResponse.status(HttpStatus.BAD_REQUEST)
                    .contentType(MediaType.APPLICATION_JSON)
                    .bodyValue(new ClientErrorResponse(
                        "Validation failed", errors, "VALIDATION_FAILED", timestamp));
            }

            default ->
                ServerResponse.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .contentType(MediaType.APPLICATION_JSON)
                    .bodyValue(new ServerErrorResponse(
                        "InternalServerError", "Unexpected error. Trace: " + traceId, timestamp, traceId));
        };
    }
}
```

## Security Configuration

### OAuth2 JWT Resource Server

```java
@Configuration
@EnableWebFluxSecurity
@EnableReactiveMethodSecurity
public class SecurityConfig {

    @Bean
    public SecurityWebFilterChain securityWebFilterChain(ServerHttpSecurity http) {
        return http
            .csrf(ServerHttpSecurity.CsrfSpec::disable)
            .cors(cors -> cors.configurationSource(corsSource()))
            .httpBasic(ServerHttpSecurity.HttpBasicSpec::disable)
            .formLogin(ServerHttpSecurity.FormLoginSpec::disable)
            .oauth2ResourceServer(oauth2 -> oauth2.jwt(Customizer.withDefaults()))
            .headers(headers -> {
                headers.frameOptions(opts -> opts.mode(XFrameOptionsServerHttpHeadersWriter.Mode.DENY));
                headers.contentSecurityPolicy(csp -> csp.policyDirectives("default-src 'self'; frame-ancestors 'none';"));
            })
            .authorizeExchange(exchanges -> exchanges
                .pathMatchers("/management/**", "/swagger-ui.html", "/swagger-ui/**", "/v3/api-docs/**").permitAll()
                .pathMatchers("/api/v1/**").authenticated()
                .anyExchange().authenticated()
            )
            .build();
    }
}

// Method-level authorization — requires @EnableReactiveMethodSecurity above
@Service
@RequiredArgsConstructor
public class OrderService {
    @PreAuthorize("hasRole('ADMIN')")
    public Mono<Void> deleteOrder(UUID id) { /* ... */ }

    @PreAuthorize("hasRole('USER') or hasRole('ADMIN')")
    public Mono<Order> getOrder(UUID id) { /* ... */ }
}
```

### CORS Configuration

```java
@Configuration
public class CorsConfig {

    private CorsConfigurationSource corsSource() {
        CorsConfiguration config = new CorsConfiguration();
        config.setAllowedOrigins(List.of("${CORS_ORIGINS:http://localhost:4200}"));
        config.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE", "OPTIONS"));
        config.setAllowedHeaders(List.of("Authorization", "Content-Type", "Accept"));
        config.setAllowCredentials(true);
        config.setMaxAge(3600L);
        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", config);
        return source;
    }
}
```

## Resilience4j Configuration

### application.yml

```yaml
resilience4j:
  circuitbreaker:
    configs:
      default:
        sliding-window-type: COUNT_BASED
        sliding-window-size: 100
        minimum-number-of-calls: 20
        failure-rate-threshold: 50
        slow-call-rate-threshold: 100
        slow-call-duration-threshold: 5s
        wait-duration-in-open-state: 30s
        permitted-number-of-calls-in-half-open-state: 10
        automatic-transition-from-open-to-half-open-enabled: true
        register-health-indicator: true
  retry:
    configs:
      default:
        max-attempts: 3
        wait-duration: 500ms
        enable-exponential-backoff: true
        exponential-backoff-multiplier: 2
        exponential-max-wait-duration: 5s
        retry-exceptions:
          - java.io.IOException
          - java.util.concurrent.TimeoutException
          - org.springframework.web.reactive.function.client.WebClientRequestException
        ignore-exceptions:
          - com.company.service.exception.InvalidInputException
          - com.company.service.exception.BusinessRuleException
  ratelimiter:
    configs:
      default:
        limit-for-period: 100
        limit-refresh-period: 1s
        timeout-duration: 1s
  timelimiter:
    configs:
      default:
        timeout-duration: 3s
        cancel-running-future: true
  bulkhead:
    configs:
      default:
        max-concurrent-calls: 25
        max-wait-duration: 0ms
```

### Maven Dependency

```xml
<dependency>
    <groupId>io.github.resilience4j</groupId>
    <artifactId>resilience4j-spring-boot3</artifactId>
</dependency>
<dependency>
    <groupId>io.github.resilience4j</groupId>
    <artifactId>resilience4j-reactor</artifactId>
</dependency>
```

## WebClient Connection Pool

```java
@Configuration
public class WebClientConfig {

    @Bean
    public WebClient.Builder webClientBuilder(
            @Value("${webclient.pool.max-connections:100}") int maxConnections,
            @Value("${webclient.pool.acquire-timeout-millis:5000}") int acquireTimeout,
            @Value("${webclient.pool.response-timeout-millis:10000}") int responseTimeout) {

        ConnectionProvider provider = ConnectionProvider.builder("app-pool")
            .maxConnections(maxConnections)
            .pendingAcquireTimeout(Duration.ofMillis(acquireTimeout))
            .build();

        HttpClient httpClient = HttpClient.create(provider)
            .option(ChannelOption.CONNECT_TIMEOUT_MILLIS, 5000)
            .responseTimeout(Duration.ofMillis(responseTimeout))
            .doOnConnected(conn -> conn
                .addHandlerLast(new ReadTimeoutHandler(responseTimeout, TimeUnit.MILLISECONDS))
                .addHandlerLast(new WriteTimeoutHandler(responseTimeout, TimeUnit.MILLISECONDS)));

        return WebClient.builder()
            .clientConnector(new ReactorClientHttpConnector(httpClient));
    }
}
```

### application.yml

```yaml
webclient:
  pool:
    max-connections: 100
    acquire-timeout-millis: 5000
    response-timeout-millis: 10000
```

## Reactive Health Indicators

```java
@Component("applicationHealth")
@ConditionalOnProperty(name = "health.application.enabled", havingValue = "true", matchIfMissing = true)
public class ApplicationHealthIndicator implements ReactiveHealthIndicator {

    @Override
    public Mono<Health> health() {
        return Mono.just(Health.up()
                .withDetail("name", "application")
                .withDetail("timestamp", Instant.now().toString())
                .build())
            .onErrorResume(ex -> Mono.just(Health.down(ex)
                .withDetail("error", ex.getMessage())
                .build()));
    }
}
```

### Actuator Configuration

```yaml
management:
  endpoints:
    web:
      exposure:
        include: health, info, prometheus, metrics, loggers
      base-path: /management
    enabled-by-default: false
  endpoint:
    health:
      enabled: true
      show-details: always
      probes:
        enabled: true
      group:
        liveness:
          include: ping
        readiness:
          include: "*"
    info:
      enabled: true
    prometheus:
      enabled: true
    metrics:
      enabled: true
    loggers:
      enabled: true
  metrics:
    tags:
      application: ${spring.application.name}
    distribution:
      percentiles-histogram:
        http.server.requests: true
```

## R2DBC Connection Pool

```yaml
spring:
  r2dbc:
    pool:
      enabled: true
      initial-size: 5
      max-size: 20
      max-idle-time: 30m
      max-life-time: 1h
      max-acquire-time: 2s
      max-create-connection-time: 5s
      validation-query: SELECT 1
```

## Swagger / OpenAPI Configuration

```java
@Configuration
public class SwaggerConfig {

    @Bean
    public OpenAPI customOpenAPI() {
        return new OpenAPI()
            .addSecurityItem(new SecurityRequirement().addList("BearerAuth"))
            .components(new Components()
                .addSecuritySchemes("BearerAuth", new SecurityScheme()
                    .name("BearerAuth")
                    .type(SecurityScheme.Type.HTTP)
                    .scheme("bearer")
                    .bearerFormat("JWT")));
    }
}
```

### Maven Dependency

```xml
<dependency>
    <groupId>org.springdoc</groupId>
    <artifactId>springdoc-openapi-starter-webflux-ui</artifactId>
    <version>2.8.6</version>
</dependency>
```

### application.yml

```yaml
springdoc:
  api-docs:
    path: /v3/api-docs
  swagger-ui:
    path: /swagger-ui.html
    display-request-duration: true
    operations-sorter: alpha
```
