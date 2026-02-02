# Validation and Linting

Spectral rules, Redocly configuration, and validation commands for enforcing API spec quality.

## Tool Installation

```bash
# Install Spectral and Redocly CLI
npm install -g @stoplight/spectral-cli @redocly/cli
```

## Spectral Configuration

Create `.spectral.yaml` in the project root:

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

## Validation Commands

```bash
# Lint with Spectral
spectral lint openapi.yaml

# Lint with Redocly
redocly lint openapi.yaml

# Bundle multiple files into one
redocly bundle openapi.yaml -o bundled.yaml

# Preview documentation locally
redocly preview-docs openapi.yaml
```

## Key Rules Explained

| Rule | Severity | Purpose |
|------|----------|---------|
| `operation-operationId` | error | Every endpoint needs a unique operationId for SDK generation |
| `operation-description` | warn | Endpoints should have descriptions for documentation |
| `info-description` | error | API info block must include a description |
| `operation-security-defined` | error | All referenced security schemes must be defined |
| `operation-success-response` | error | Every operation must define at least one success response |
| `path-params-snake-case` | warn | Path parameters follow snake_case convention |
| `schema-properties-camelCase` | warn | Schema properties follow camelCase convention |

## Extending Spectral Rules

Add custom rules to catch project-specific issues:

```yaml
# Additional custom rules
rules:
  # Require pagination on list endpoints
  list-endpoints-paginated:
    description: GET endpoints returning arrays should have pagination parameters
    severity: warn
    given: "$.paths[*].get.responses['200'].content['application/json'].schema"
    then:
      function: schema
      functionOptions:
        schema:
          type: object
          required: ["properties"]

  # Require error response on mutating operations
  mutating-ops-error-response:
    description: POST/PUT/PATCH/DELETE should define 4xx responses
    severity: warn
    given: "$.paths[*][post,put,patch,delete].responses"
    then:
      function: schema
      functionOptions:
        schema:
          type: object
          minProperties: 2
```

## Redocly Configuration

Create `redocly.yaml` for additional linting and documentation settings:

```yaml
# redocly.yaml
extends:
  - recommended

rules:
  no-unused-components: error
  operation-operationId-unique: error
  no-ambiguous-paths: error

theme:
  openapi:
    generateCodeSamples:
      languages:
        - lang: curl
        - lang: Python
        - lang: JavaScript
```
