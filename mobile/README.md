# Rechef

AI-powered recipe discovery and cooking assistant that helps users go from discovering recipes on social media to actually cooking them.

## Features

- **Recipe Discovery**: Extract recipes from social media links, images, or shared content
- **Pantry Management**: Track ingredients with manual entry, photo scanning, or recipe imports
- **Smart Grocery Lists**: Generate shopping lists that exclude items already in your pantry
- **One-Tap Checkout**: Seamlessly checkout with Instacart using deep links

## Tech Stack

- **Frontend**: Flutter with Riverpod for state management
- **Backend**: Express API for business logic and integrations
- **Database & Auth**: Firebase (Authentication)
- **Storage**: Supabase Storage (for recipe data)

## Setup

1. **Install dependencies:**

   ```bash
   flutter pub get
   ```

2. **Configure environment variables:**
   - Copy `.env.example` to `.env`
   - Configure API endpoints:
     - `API_BASE_URL`: Your Express API URL
     - `API_DEV_URL`: Local development API URL (optional)

3. **Configure Firebase:**
   - Set up Firebase project and add your app
   - Download `google-services.json` for Android and `GoogleService-Info.plist` for iOS
   - Place them in `android/app/` and `ios/Runner/` respectively
   - Enable Google and Apple sign-in in Firebase Console → Authentication → Sign-in method

4. **Run the app:**

   ```bash
   flutter run
   ```

## Project Structure

```dart
lib/
├── app/
│   ├── auth/           # Authentication feature
│   │   ├── data/        # Auth repository
│   │   ├── presentation/# Sign-in screens
│   │   └── providers/   # Riverpod providers
│   ├── pantry/         # Pantry management (TODO)
│   ├── recipes/         # Recipe management (TODO)
│   └── grocery/        # Grocery list (TODO)
└── core/
    ├── config/          # App configuration
    └── theme/           # App theming
```

## Architecture

The app follows a feature-based architecture:

- Each feature owns its data layer, domain models, presentation layer, and Riverpod providers
- Uses `AsyncNotifier`/`Notifier` providers for state management
- Keeps UI logic thin and delegates to providers

## Development

This is a mobile-first iOS application built with Flutter. The backend consists of an Express API for business logic and integrations, with Firebase handling authentication and Supabase handling database and storage.
