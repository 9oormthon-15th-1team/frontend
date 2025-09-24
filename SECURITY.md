# Security Guidelines

## 🔒 Files NEVER to Commit

### Environment & Configuration Files
- `.env*` files (except `.env.example`)
- `config.json`, `secrets.json`
- `credentials.json`
- `api_keys.dart`, `secrets.dart`

### Firebase & Google Services
- `google-services.json` (Android)
- `GoogleService-Info.plist` (iOS)
- `firebase_options.dart`

### Signing & Certificates
- `*.keystore`, `*.jks` (Android signing keys)
- `*.key`, `*.pem`, `*.p12`
- `key.properties`
- `signing.properties`

### Authentication Files
- `auth.json`
- `service-account.json`
- `private-key.json`

## 🛡️ Best Practices

### 1. Environment Variables
- Use `.env.example` to document required environment variables
- Never hardcode API keys or secrets in source code
- Use `flutter_dotenv` package for environment management

### 2. Code Reviews
- Always check for hardcoded secrets before merging
- Use tools like `git-secrets` or `truffleHog` to scan for secrets
- Enable pre-commit hooks to prevent accidental commits

### 3. Local Development
- Keep all sensitive data in `.env` files locally
- Use different API keys for development, staging, and production
- Regularly rotate API keys and secrets

### 4. CI/CD Security
- Use secure environment variables in CI/CD pipelines
- Never log sensitive information
- Use separate Firebase projects for different environments

## 🚨 If You Accidentally Committed Secrets

1. **Immediately** change/revoke the compromised secrets
2. Remove the secrets from Git history:
   ```bash
   git filter-branch --force --index-filter \
   'git rm --cached --ignore-unmatch path/to/sensitive/file' \
   --prune-empty --tag-name-filter cat -- --all
   ```
3. Force push to remove from remote repository
4. Notify team members to re-clone the repository

## 📋 Security Checklist

- [ ] `.env` files are in `.gitignore`
- [ ] No API keys in source code
- [ ] Firebase config files are ignored
- [ ] Signing keys are not committed
- [ ] Pre-commit hooks are enabled
- [ ] Team is aware of security practices
- [ ] Regular security audits are conducted

Remember: **When in doubt, don't commit it!**