# Security Features References

These references come from the Serinus `llms.txt` index and document the built-in security-oriented hooks and request limits.

## Source Pages

- `https://serinus.app/security/cors.md`
- `https://serinus.app/security/csrf.md`
- `https://serinus.app/security/rate_limiting.md`
- `https://serinus.app/security/body_size.md`

## Key Points

- CORS is enabled with `app.use(CorsHook())`, optionally restricted with `allowedOrigins`.
- CSRF protection is enabled with `app.use(CsrfHook())` and validates modifying requests while skipping safe methods by default.
- `CsrfHook` supports configuration for ignored methods, header name, session key, cookie name, and custom invalid-token handling.
- Rate limiting is enabled with `app.use(RateLimiterHook(maxRequests: ..., duration: ...))`.
- Body-size limiting is configured at application creation time with the `bodySizeLimit` option, not as middleware.
- When the request body exceeds the configured size, the documented behavior is a `413 Payload Too Large` response.

## Example Patterns From Docs

```dart
final app = await serinus.createApplication(
  entrypoint: AppModule(),
  bodySizeLimit: 1.mb,
);

app.use(CorsHook(allowedOrigins: ['https://example.com']));
app.use(CsrfHook());
app.use(RateLimiterHook(maxRequests: 100, duration: Duration(minutes: 1)));

await app.serve();
```
