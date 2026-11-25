# whatsapp_clone

Flutter 1-to-1 chat app.

- **Auth:** Firebase Phone Auth (Pakistani numbers, stored as E.164 `+92…`)
- **Data:** Cloud Firestore (`users`, `chats`, `messages`) + Isar local cache
- **Images:** Supabase Storage bucket `chat-images`

Targets Android/iOS. Web is not supported (Isar 3 and `dart:io` file handling).

## Backend setup

### Firebase (project `whatsapp-clone-3e5ea`)
1. Console → Authentication → enable **Phone** sign-in.
2. Console → Project settings → Android app → add your **SHA-1 and SHA-256**
   (`cd android && ./gradlew signingReport`). Phone auth fails without them.
   For testing without SMS, add test numbers under Authentication → Phone.
3. Deploy the security rules:
   ```sh
   npm i -g firebase-tools
   firebase login
   firebase deploy --only firestore
   ```
4. iOS only: run `flutterfire configure` (or add `ios/Runner/GoogleService-Info.plist`)
   and set up APNs for phone auth.

### Supabase
Run `supabase/storage_policies.sql` in the Supabase SQL editor to create the
`chat-images` bucket and its upload/read policies.

## Run / test
```sh
flutter pub get
flutter test
flutter run
```

After changing an Isar model, regenerate code:
`dart run build_runner build --delete-conflicting-outputs`
