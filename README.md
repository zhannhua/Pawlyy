# Pawly

Pawly is a responsive Flutter app for Malaysian pet parents. One codebase powers Android and the web app, with Supabase providing authentication and the shared data store.

## What is connected

- Email/password sign-up, sign-in, email verification, password reset, and sign-out
- Profile data (name, Malaysian mobile number, city)
- Private pet profiles and daily-care routines
- Public partner catalogue with RM pricing
- Grooming and boarding bookings with partner-published appointment slots
- Atomic slot reservation, so the final appointment cannot be double-booked
- Completed-visit reviews from verified pet parents
- Pay-at-venue booking status, ready for a Malaysian payment-gateway integration
- Row Level Security so a signed-in user can only access their own profile, pets, routines, and bookings

## Phase 1 scope

Phase 1 follows the proposal's narrow, trust-first launch: pet profiles and care reminders, plus verified grooming and boarding partners, real availability, booking requests, and reviews. The SQL schema includes merchant ownership and payment status fields; a live payment checkout should only be added after you select a gateway and provide its merchant credentials.

## Set up Supabase

1. Create a Supabase project.
2. In **SQL Editor**, run [supabase/schema.sql](supabase/schema.sql). This creates the data model, RLS policies, profile trigger, and a small Klang Valley partner catalogue.
3. In **Authentication -> URL Configuration**, add these redirect URLs:
   - `io.supabase.flutter://login-callback/` for Android password recovery
   - Your local web URL, for example `http://localhost:3000`
   - Your deployed website URL, for example `https://pawly.example.com`
4. In **Project Settings → API**, copy the Project URL and publishable/anon key. Do not put them in Git.

## Run it

```powershell
flutter run --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLISHABLE_KEY
```

To run the browser version, choose Chrome in Android Studio or use:

```powershell
flutter run -d chrome --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLISHABLE_KEY
```

Build the production website with:

```powershell
flutter build web --release --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLISHABLE_KEY
```

The static website files are generated in `build/web` and can be deployed to Vercel, Netlify, Firebase Hosting, or Supabase Hosting.

## Important

The app shows a safe setup screen until the two `--dart-define` values are supplied. `.env.example` is a reminder file only; Flutter does not load it automatically.

The Passkeys Web SDK required transitively by `supabase_flutter` is included locally at `web/passkeys_bundle.js`. If you change `web/index.html` or this file, stop the current Chrome run and launch again; hot reload does not reload the HTML document.
