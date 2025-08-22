# Firebase Environment Variables Setup Guide

## Critical Security Implementation

Due to exposed Firebase API keys in the repository, we've implemented environment variable-based configuration.

## Required Environment Variables

Add these to your system environment or CI/CD pipeline:

### Development
```bash
export FIREBASE_WEB_API_KEY="your-new-web-api-key"
export FIREBASE_WEB_APP_ID="your-web-app-id"
export FIREBASE_WEB_MESSAGING_SENDER_ID="your-messaging-sender-id"
export FIREBASE_WEB_PROJECT_ID="your-project-id"
export FIREBASE_WEB_AUTH_DOMAIN="your-auth-domain"
export FIREBASE_WEB_STORAGE_BUCKET="your-storage-bucket"
export FIREBASE_WEB_MEASUREMENT_ID="your-measurement-id"

export FIREBASE_ANDROID_API_KEY="your-new-android-api-key"
export FIREBASE_ANDROID_APP_ID="your-android-app-id"
export FIREBASE_ANDROID_MESSAGING_SENDER_ID="your-messaging-sender-id"
export FIREBASE_ANDROID_PROJECT_ID="your-project-id"
export FIREBASE_ANDROID_STORAGE_BUCKET="your-storage-bucket"

export FIREBASE_IOS_API_KEY="your-ios-api-key"
export FIREBASE_IOS_APP_ID="your-ios-app-id"
export FIREBASE_IOS_MESSAGING_SENDER_ID="your-messaging-sender-id"
export FIREBASE_IOS_PROJECT_ID="your-project-id"
export FIREBASE_IOS_STORAGE_BUCKET="your-storage-bucket"
export FIREBASE_IOS_IOS_BUNDLE_ID="your-bundle-id"

export FIREBASE_MACOS_API_KEY="your-macos-api-key"
export FIREBASE_MACOS_APP_ID="your-macos-app-id"
export FIREBASE_MACOS_MESSAGING_SENDER_ID="your-messaging-sender-id"
export FIREBASE_MACOS_PROJECT_ID="your-project-id"
export FIREBASE_MACOS_STORAGE_BUCKET="your-storage-bucket"
export FIREBASE_MACOS_IOS_BUNDLE_ID="your-macos-bundle-id"
```

### Production (CI/CD)
Set these as encrypted secrets in your deployment pipeline.

## Build Commands

### Development
```bash
flutter run --dart-define=FIREBASE_WEB_API_KEY=$FIREBASE_WEB_API_KEY \
            --dart-define=FIREBASE_WEB_APP_ID=$FIREBASE_WEB_APP_ID \
            # ... add all other variables
```

### Production Build
```bash
flutter build apk --dart-define=FIREBASE_WEB_API_KEY=$FIREBASE_WEB_API_KEY \
                  --dart-define=FIREBASE_WEB_APP_ID=$FIREBASE_WEB_APP_ID \
                  # ... add all other variables
```

## Security Checklist

- [ ] Rotate all exposed Firebase API keys in Firebase Console
- [ ] Update environment variables with new keys
- [ ] Add firebase_options.dart to .gitignore
- [ ] Clean git history to remove exposed keys
- [ ] Update CI/CD with encrypted environment variables
- [ ] Test app with new configuration
- [ ] Monitor Firebase usage for suspicious activity

## Notes

- Never commit firebase_options.dart with real API keys
- Use firebase_options_secure.dart template for production
- Environment variables take precedence over default values
- Default values in secure template are placeholders only
