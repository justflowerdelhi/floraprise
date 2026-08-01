# Floraprise Mobile Authentication Design
Version: 1.0
Status: Approved
Architecture Version: 1.0
Last Updated: 2026-07-31
Owner: Mobile Platform

## 1. Authentication Goals

- Establish a mobile-first authentication model for the Floraprise Mobile product.
- Use mobile number as the primary login identifier.
- Keep authentication fully independent from ERP.
- Support password-based login now and prepare the architecture for OTP and social login later.
- Ensure the design remains compatible with the frozen architecture constitution and enterprise solution structure.

## 2. User Identity Model

- Primary identity: Mobile Number, unique per account.
- Optional identity: Email Address, not mandatory.
- Display Name: optional friendly name for the account.
- Country Code: stored separately for future international support.
- The account is identified by mobile number first, with email treated as an auxiliary field.
- No separate role table is introduced in this sprint.

## 3. Device Management

- Support multiple devices per user.
- Each device is registered independently.
- Device nickname is optional.
- Device last login time is stored.
- Devices can be revoked individually.
- A force logout from all devices revokes all active refresh tokens for the user.
- Trusted devices are represented by a device status flag that can be used later without changing the core schema.

## 4. Registration Flow

1. Client sends registration request with mobile number, password, optional email, and device metadata.
2. Validation ensures the mobile number is unique and the password meets policy.
3. The system hashes the password.
4. A new MobileUser is created.
5. A MobileDevice record is created or attached to the user.
6. A refresh token is issued for the device/session.
7. The service returns access token, refresh token, and user identity payload.

## 5. Login Flow

1. Client submits mobile number and password.
2. The system validates the user exists and the password is correct.
3. The system verifies the device/session is allowed.
4. A new access token and refresh token are issued.
5. The system persists the refresh token and updates session state.

## 6. JWT Authentication Flow

- Access token lifetime: 15 to 30 minutes, configurable.
- Refresh token lifetime: 30 days, configurable.
- Token rotation is used on refresh.
- Refresh token revocation is supported.
- Refresh token reuse detection is supported.
- JWTs contain subject, issuer, audience, expiration, and device/session context.
- JWT validation includes signature, issuer, audience, expiration, and device binding checks.

## 7. Refresh Token Flow

- Access tokens are short-lived.
- JWTs contain subject, audience, issuer, expiration, and device/session identifiers.
- The API validates JWT signature, issuer, audience, and expiration.
- The API resolves the current user from the token and attaches the identity to the request.

## 8. Logout Flow

1. Client submits refresh token.
2. The system validates the token is present, active, and not expired.
3. The system issues a new access token and optionally rotates the refresh token.
4. The system updates the refresh token record.

## 9. Password Reset Flow

1. Client calls logout with the current refresh token.
2. The system marks the refresh token as revoked.
3. The session is invalidated for that device.
4. Subsequent access tokens are rejected.

## 10. Device Registration Flow

1. Client submits forgot password with mobile number or email.
2. The system checks whether the account exists.
3. A reset token is generated and associated with the user.
4. The reset token is returned to the client through the supported delivery channel.
5. Client submits the reset token and a new password.
6. The system updates the password and revokes all existing refresh tokens.

## 11. Session Management

- The device is registered at login or registration.
- Device metadata includes platform, device ID, OS version, and app version.
- Each device gets its own session and refresh token lifecycle.
- Multiple devices are supported.

## 12. Token Expiration Strategy

- A session is created per successful login and tied to a device.
- Sessions are tracked via refresh tokens and device bindings.
- Logout revokes the active refresh token for the current session.
- Password resets revoke all sessions.

## 13. Password Policy

- Minimum password length: 8 characters.
- Complexity rules: at least one uppercase letter, one lowercase letter, one digit, and one special character.
- Password hashing algorithm: ASP.NET Identity-compatible hashing via an abstraction.
- Password history: future enhancement only; not implemented in this sprint.
- Account lockout after failed attempts: configurable and enabled by default after repeated failures.

## 14. Password Hashing Strategy

- Access token lifetime: configurable, default 15 minutes.
- Refresh token lifetime: configurable, default 30 days.
- Refresh tokens rotate on use.
- Expired tokens are rejected.

## 15. Security Features

- Rate limiting on login attempts.
- Brute-force protection through lockout and throttling.
- Audit logging for registration, login, refresh, logout, and password reset operations.
- Correlation ID included in authentication logs.
- Refresh tokens stored securely and hashed before persistence.
- HTTPS-only cookies are planned for future web clients; not implemented in this sprint.

## 16. Security Considerations

- Passwords are hashed using a slow password hashing mechanism such as PBKDF2, bcrypt, or Argon2.
- Passwords are never stored in plaintext.
- Password history is not implemented in this sprint.

## 17. Future Authentication Roadmap

- OTP Login: planned for future support.
- Google Sign-In: planned for future support.
- Apple Sign-In: planned for future support.
- Microsoft Sign-In: planned for future support.
- Passkeys/WebAuthn: optional long-term roadmap item.

## 18. Future OTP Support

- Never store secrets in source code.
- Use strongly typed configuration for JWT, database, and token settings.
- Use HTTPS in production.
- Protect against brute-force attempts through throttling later.
- Use audit-friendly logging for authentication events.
- Do not expose internal identity implementation details to the domain layer.

## 19. Future Social Login Support

- The authentication layer is designed so OTP can be added as a second login method later.
- The abstraction should support a provider-based approach.
- OTP is not implemented in Sprint 2.

## 20. Mobile-Specific Decisions

- Remember Me behavior: optional long-lived refresh session for trusted devices.
- Offline behavior when a token expires: the app prompts the user to reconnect and re-authenticate.
- Automatic token refresh: supported when a valid refresh token exists.
- Session timeout: access token expiration plus refresh token inactivity window.
- Device change handling: if the current device changes, the system verifies the device registration and issues a new session for the new device.

## 21. Database Schema

Only the following authentication-related tables are included in this sprint:

- MobileUsers
- MobileDevices
- RefreshTokens

### MobileUsers
- Id
- MobileNumber
- Email
- PasswordHash
- IsActive
- CreatedAtUtc
- UpdatedAtUtc
- LastLoginAtUtc

### MobileDevices
- Id
- UserId
- DeviceId
- DeviceName
- Platform
- OperatingSystem
- AppVersion
- CreatedAtUtc
- UpdatedAtUtc

### RefreshTokens
- Id
- UserId
- DeviceId
- TokenHash
- ExpiresAtUtc
- RevokedAtUtc
- ReplacedByTokenHash
- CreatedAtUtc
- UpdatedAtUtc

## 22. Error Handling Strategy

- Stable error codes are defined for external clients and tests.

### Error Codes

- AUTH-1001 Invalid credentials
- AUTH-1002 User not found
- AUTH-1003 Account locked
- AUTH-1004 Refresh token expired
- AUTH-1005 Refresh token revoked
- AUTH-1006 Invalid device
- AUTH-1007 Password expired

## 23. Validation Rules

- Mobile number is required and must be normalized.
- Email is optional but must be valid when provided.
- Password must be strong enough for the policy.
- Refresh tokens must be present and valid.
- Reset tokens must be valid and not expired.

## 24. Sequence Diagrams

### Registration Sequence

```text
Register
↓
Create User
↓
Register Device
↓
Issue JWT
↓
Return Session
```

### Login Sequence

```text
Login
↓
Validate Password
↓
Issue JWT
↓
Store Refresh Token
↓
Return Session
```

## 25. Testing Strategy

- Unit tests for password hashing, token generation, and token validation.
- Integration tests for registration, login, refresh, logout, forgot/reset password, and protected endpoint access.
- Swagger verification for endpoint exposure.
- Health endpoint verification.

## 26. Implementation Scope for Sprint 2

This sprint includes only authentication-related behavior:
- Registration
- Login
- JWT
- Refresh Token
- Logout
- Password Reset
- Device Registration

The following are explicitly out of scope:
- Subscriptions
- Orders
- Delivery
- Customers
- Licensing
- Notifications
- ERP integration

## 27. Sequence Diagrams

### Registration

```text
Client -> API: POST /register
API -> Application: RegisterCommand
Application -> Domain: Create MobileUser
Application -> Infrastructure: Persist MobileUser + Device
Infrastructure -> API: AuthResult
API -> Client: AccessToken + RefreshToken
```

### Login

```text
Client -> API: POST /login
API -> Application: LoginCommand
Application -> Infrastructure: Validate credentials + issue tokens
Infrastructure -> API: AuthResult
API -> Client: AccessToken + RefreshToken
```

### Refresh

```text
Client -> API: POST /refresh
API -> Application: RefreshCommand
Application -> Infrastructure: Validate refresh token
Infrastructure -> API: New tokens
API -> Client: New AccessToken + RefreshToken
```


- Unit tests for password hashing, token generation, and token validation.
- Integration tests for registration, login, refresh, logout, forgot/reset password, and protected endpoint access.
- Swagger verification for endpoint exposure.
- Health endpoint verification.

## 21. Implementation Scope for Sprint 2

This document defines only authentication behavior.
No orders, subscriptions, delivery, ERP integration, or other product domains are included.
