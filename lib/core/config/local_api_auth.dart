/// SECURITY: shared Basic credential (`takko:123456`) that the mobile app
/// sends to the "local" API (`check-in/getdate-time`, `check-in/location`).
/// Shipping it in the web bundle makes it public (pentest finding) — those
/// endpoints must move to per-user auth (e.g. the Bearer token) server-side,
/// then drop this constant.
const String kLocalApiBasicAuth = 'Basic dGFra286MTIzNDU2';
