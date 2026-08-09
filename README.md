# Pawly

Pawly is a responsive Flutter app for Malaysian pet parents. One codebase powers Android and the web app, with Supabase providing authentication and the shared data store.

## What is connected

- Email/password sign-up, sign-in, email verification, password reset, and sign-out
- Profile data (name, Malaysian mobile number, city)
- Private pet profiles and daily-care routines
- Public partner catalogue with RM pricing
- Grooming, boarding, and veterinary bookings with partner-published appointment slots
- Atomic slot reservation, so the final appointment cannot be double-booked
- Completed-visit reviews from verified pet parents
- Pay-at-venue booking status, ready for a Malaysian payment-gateway integration
- Role-aware workspaces: pet parents see their own data; a provider-linked account sees only its assigned operational data
- Row Level Security and database functions that prevent clients from confirming/completing their own bookings or double-booking a slot

## Phase 1 scope

Phase 1 follows the proposal's narrow, trust-first launch: pet profiles and care reminders, plus verified grooming, boarding, and veterinary partners, real availability, booking requests, merchant confirmation, and reviews. The SQL schema includes merchant ownership and payment status fields; a live payment checkout should only be added after you select a gateway and provide its merchant credentials.

## Set up Supabase

1. Create a Supabase project.
2. In **SQL Editor**, run [supabase/schema.sql](supabase/schema.sql), then run the SQL files in [supabase/migrations](supabase/migrations) in timestamp order. These create the data model, secure booking flow, role-aware merchant access, profile trigger, and small Klang Valley partner catalogue.
3. In **Authentication -> URL Configuration**, add these redirect URLs:
   - `io.supabase.flutter://login-callback/` for Android password recovery
   - `http://localhost:3000/**` for local web development
   - Your exact deployed website URL, for example `https://pawly.example.com/`
   Set **Site URL** to the exact deployed website URL when it exists; until then use `http://localhost:3000/`.
4. In **Project Settings → API**, copy the Project URL and publishable key if you want to point a local build to a different Supabase project. Never use a service-role key in Flutter.

## Run it

For the Pawly project already linked to this repository, simply run:

```powershell
flutter run
```

To deliberately use another Supabase project during development:

```powershell
flutter run --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLISHABLE_KEY
```

To run the browser version, choose Chrome in Android Studio or use:

```powershell
flutter run -d chrome
```

For email confirmation and password-reset testing on the web, use the fixed local URL you added in Supabase:

```powershell
flutter run -d chrome --web-port 3000
```

Build the production website with:

```powershell
flutter build web --release
```

The static website files are generated in `build/web` and can be deployed to Vercel, Netlify, Firebase Hosting, or Supabase Hosting.

## Important

Pawly’s client-safe project URL and publishable key are included so the team can run the linked project without a long command. They are not secrets; Row Level Security protects the data. `.env.example` is a reminder file only; Flutter does not load it automatically. Never put a `service_role` key in an app, GitHub, or a `.env` file shared with the team.

The Passkeys Web SDK required transitively by `supabase_flutter` is included locally at `web/passkeys_bundle.js`. If you change `web/index.html` or this file, stop the current Chrome run and launch again; hot reload does not reload the HTML document.
