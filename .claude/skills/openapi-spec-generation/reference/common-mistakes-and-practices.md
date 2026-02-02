# Common Mistakes and Best Practices

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Missing `operationId` | Add unique operationId to every endpoint -- SDK generators need it |
| No error schemas | Define an Error schema and use it for all 4xx/5xx responses |
| Examples don't match schema | Use `$ref` for examples and validate with Spectral |
| Inconsistent naming (`user_id` vs `userId`) | Pick one style (camelCase), enforce with linter |
| Missing `nullable: true` | Be explicit: `nullable: true` (3.0) or `type: ["string", "null"]` (3.1) |
| No pagination on list endpoints | Always paginate and document limits |
| Hardcoded server URLs | Use server variables or multiple server entries |

## Best Practices

**Do:**
- Use `$ref` to reuse schemas, parameters, and responses
- Add real-world examples to every endpoint
- Document all error codes and responses
- Version the API in the URL (`/v1/`) or header
- Validate the spec in CI on every PR
- Use semantic versioning for spec changes

**Avoid:**
- Generic descriptions -- be specific about what each field and endpoint does
- Skipping security definitions -- define all auth schemes
- Mixing naming styles -- stay consistent throughout the spec
- Hardcoding URLs -- use server variables for environment flexibility
