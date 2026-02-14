# Rechef: Technical Documentation

## Architecture Overview

Rechef is composed of three services:

```
Mobile App (Flutter)  <-->  Backend API (Express/Node.js)  <-->  PostgreSQL
                                      |
                                      v
                              External Services
                        (OpenAI, Instacart, Firebase)

Web App (Next.js)  <-->  Backend API
```

- **Mobile App**: Flutter (Dart), targeting iOS and Android
- **Backend API**: Node.js with TypeScript, running Express 5
- **Database**: PostgreSQL with Drizzle ORM
- **Web App**: Next.js for shared recipe link pages

## Mobile App

### Tech Stack

| Technology | Purpose |
|---|---|
| Flutter SDK ^3.9.2 | Cross-platform UI framework |
| Riverpod 3.1.0 | State management |
| GoRouter 17.0.1 | Declarative routing and deep linking |
| Firebase Auth | Authentication (Google, Apple) |
| RevenueCat SDK | Subscription and paywall management |
| Speech-to-Text | Voice input for AI cooking assistant |
| Flutter Local Notifications | Cooking reminders and timers |
| Share Handler | iOS Share Extension for recipe import |
| Flutter Chat UI | AI assistant chat interface |

### Architecture

The app follows **Clean Architecture** with a **feature-based folder structure**:

```
lib/
  app/
    recipes/          # Recipe import, list, detail, cooking mode
    pantry/           # Pantry management
    grocery/          # Grocery lists and Instacart checkout
    cookbooks/        # Cookbook organization
    meal_plan/        # Meal planning
    onboarding/       # User onboarding flow
    settings/         # App settings and subscription management
  core/               # Shared utilities, theme, networking
  main.dart           # App entry point, RevenueCat initialization
```

Each feature follows a consistent pattern:
- **Presentation layer**: Screens, widgets, and UI logic
- **Providers**: Riverpod providers for state management
- **Data layer**: Repository classes and API communication
- **Models**: Data classes for domain entities

### Key Screens and Features

- **Recipe Import**: Accepts URLs (YouTube, TikTok, Instagram, websites) or photos. Sends content to the backend for AI extraction.
- **Recipe Detail**: Displays ingredients (with pantry matching), step-by-step instructions, nutrition facts, and sharing options.
- **Cooking Mode**: Full-screen, step-by-step view with built-in timers and an AI assistant. Supports voice input for hands-free use.
- **Pantry**: Track ingredients at home. Automatically cross-references with recipe ingredients.
- **Grocery List**: Aggregated shopping list from recipes. One-tap Instacart checkout.
- **Cookbooks**: Custom and smart collections (Shared With Me, Pantry Picks).

## Backend API

### Tech Stack

| Technology | Purpose |
|---|---|
| Node.js + TypeScript | Runtime and language |
| Express 5.2.1 | HTTP framework |
| PostgreSQL | Primary database |
| Drizzle ORM 0.45.1 | Type-safe database queries and migrations |
| OpenAI SDK (@ai-sdk/openai) | AI recipe extraction and chat |
| FFmpeg (fluent-ffmpeg) | Video frame extraction |
| Cheerio | HTML parsing for web recipes |
| Winston 3.19.0 | Structured logging |

### Database Schema

Key tables:

| Table | Purpose |
|---|---|
| `users` | User accounts linked to Firebase UID |
| `user_onboarding` | Onboarding preferences and data |
| `recipes` | Stored recipes with structured data |
| `recipe_nutrition` | AI-generated nutritional information |
| `saved_content` | Imported content metadata (URLs, sources) |
| `content_jobs` | Background job tracking for async processing |
| `user_pantry` | User pantry items with categories |
| `grocery_lists` | Shopping lists |
| `grocery_list_items` | Individual items in grocery lists |
| `chat_messages` | AI cooking assistant conversation history |
| `shared_recipes` | Shared recipe links and metadata |
| `shared_recipe_saves` | Tracking who saved a shared recipe |
| `share_events` | Analytics events for shared recipes |
| `cookbooks` | Recipe collections |
| `cookbook_recipes` | Many-to-many: recipes in cookbooks |

### AI Pipeline

Recipe extraction uses a multi-step AI pipeline:

1. **Content Detection**: Identify the source type (YouTube, TikTok, Instagram, website, image).
2. **Content Extraction**:
   - **YouTube**: Extract transcript via `youtube-transcript` package, download video for frame analysis.
   - **TikTok**: Download video via `@tobyg74/tiktok-api-dl`, extract frames.
   - **Instagram**: Parse media and caption content.
   - **Websites**: Parse HTML with Cheerio, check for schema.org Recipe markup first, fall back to AI extraction.
   - **Images**: Direct image-to-recipe via AI vision.
3. **Video Frame Analysis**: FFmpeg extracts key frames from videos. GPT-5.2 with vision analyzes frames to identify food-relevant content (ingredients, cooking steps, finished dishes).
4. **Recipe Generation**: GPT-5.2 processes all extracted content (transcripts, frames, text) and generates a structured recipe with name, description, ingredients (with quantities and units), step-by-step instructions, prep/cook time, and servings.
5. **Background Processing**: Recipe generation runs asynchronously via a job queue. The mobile app polls for completion. A processing slot system manages FFmpeg resource usage.

### AI Cooking Assistant

The cooking assistant uses **GPT-4o-mini** via streaming Server-Sent Events (SSE):

- Context-aware: receives the current recipe, current step, and conversation history
- Supports text and voice input (speech-to-text on the client)
- Supports image input (users can photograph their progress for feedback)
- Responses stream in real-time for a responsive chat experience

### Instacart Integration

Rechef integrates with the **Instacart Connect API** (`https://connect.dev.instacart.tools`):

1. User taps "Buy on Instacart" from their grocery list
2. Backend creates an Instacart shopping list with line items (ingredient name, quantity, unit)
3. Instacart returns a checkout URL
4. User completes purchase in Instacart's flow
5. Deep link returns the user to Rechef after checkout

## Web App

A **Next.js 16** application serves shared recipe pages:

- Server-side rendered for SEO and fast load times
- Displays recipe details (ingredients, steps, nutrition) in a clean web view
- Includes a call-to-action to download the Rechef app
- Styled with Tailwind CSS 4

## RevenueCat Implementation

### Setup

RevenueCat is initialized on app launch in `main.dart`:

```dart
await Purchases.configure(
  PurchasesConfiguration('<revenuecat_api_key>')
    ..appUserID = firebaseUser.uid
);
```

The RevenueCat customer ID is set to the user's Firebase UID, ensuring subscription state is tied to the authenticated user.

### Products and Entitlements

| Item | Value |
|---|---|
| Offering ID | `pro` |
| Entitlement | `Rechef Pro` |
| Products | `pro_monthly`, `pro_yearly` |

### Subscription Flow

1. **Free tier**: Users get 5 recipe imports per calendar month. Import count is tracked server-side.
2. **Paywall trigger**: When a free user exceeds 5 imports, the RevenueCat paywall is presented using `purchases_ui_flutter`.
3. **Entitlement check**: The app checks for the `Rechef Pro` entitlement via RevenueCat's `CustomerInfo` to gate premium features (unlimited imports, AI assistant, nutrition facts).
4. **Subscription management**: Users can manage their subscription through RevenueCat's Customer Center, accessible from the app's settings screen.

### Subscription State Model

The app maintains a `SubscriptionStatus` model:

```dart
class SubscriptionStatus {
  final bool isActive;
  final CustomerInfo customerInfo;
  final EntitlementInfo? activeEntitlement;
  final DateTime? expirationDate;
  final bool willRenew;
}
```

This is provided via a Riverpod provider and used throughout the app to conditionally render premium features and enforce usage limits.

## Deployment

- **Mobile App**: Distributed via TestFlight (iOS)
- **Backend API**: Hosted on a Node.js server with PostgreSQL
- **Web App**: Deployed on Vercel
- **Authentication**: Firebase Auth (Google, Apple sign-in)
- **Subscription Infrastructure**: RevenueCat (App Store Connect integration)
