# Reel Mind

Reel Mind is a Flutter mobile app for short-form video creators who want help turning inspiration into usable content ideas. Users can save captions, topics, creator influences, and reference videos, then generate new video ideas and script bullets with Claude through a secure Firebase backend.

This project was built as a CS 4750 school project and currently targets Android and iOS with Firebase-backed authentication, storage, and idea management.

## Features

- Email/password authentication with Firebase Auth
- Creator signal import flow for captions, topics, creators, and reference videos
- AI-generated video ideas based on saved creator signals
- Script workspace with autosave, tags, production statuses, and AI assist
- Firestore-backed idea pipeline with draft, script-ready, posted, and archived states
- Onboarding/tutorial overlays across key screens
- Profile and settings screens for managing creator workflow and account data

## Tech Stack

- Flutter and Dart
- Firebase Auth
- Cloud Firestore
- Firebase Storage
- Firebase Cloud Functions
- Anthropic Claude via a Firebase Function proxy

## Architecture

The mobile app does not call Anthropic directly. Claude requests are sent from Flutter to the callable Firebase Function `callClaude`, which then calls Anthropic using a server-side secret stored in Firebase Secret Manager.

This keeps the Anthropic API key out of the client app and allows the backend to enforce:

- authenticated access
- server-side rate limiting
- input validation and sanitization
- centralized prompt logic

## Project Structure

```text
lib/
  models/          Data models such as ideas
  screens/         Main app screens and flows
  services/        Firebase, Claude, preferences, and rate limiting
  utils/           Input validation and shared helpers
  widgets/         Reusable UI components

functions/
  index.js         Firebase callable function for Claude generation

assets/
  branding/        Logos and visual assets
```

## Prerequisites

- Flutter 3.35+
- Dart 3.9+
- Xcode for iOS builds
- Android Studio / Android SDK for Android builds
- Firebase project configured for:
  - Auth
  - Firestore
  - Storage
  - Cloud Functions

For Claude generation to work, the Firebase Function must also be deployed and the Anthropic secret must be set in Firebase Secret Manager.

Set the function secret:

```bash
firebase functions:secrets:set ANTHROPIC_API_KEY
```

Deploy functions:

```bash
firebase deploy --only functions
```

## Getting Started

Install dependencies:

```bash
flutter pub get
```

Run the app:

```bash
flutter run
```

Run checks:

```bash
flutter analyze
flutter test
```

## Android Release Build

Release signing is configured through:

- [key.properties](/Users/allynguyen/Documents/SchoolWork/4750/reel_mind_folder/reel_mind/android/key.properties)
- a local keystore file referenced by `storeFile`

Build a Play Store bundle:

```bash
flutter build appbundle
```

Expected output:

[app-release.aab](/Users/allynguyen/Documents/SchoolWork/4750/reel_mind_folder/reel_mind/build/app/outputs/bundle/release/app-release.aab)

## Current Version

The app version is currently set to `1.0.1+3` in [pubspec.yaml](/Users/allynguyen/Documents/SchoolWork/4750/reel_mind_folder/reel_mind/pubspec.yaml).

## Security Notes

- The Anthropic API key is not stored in Flutter assets or client code.
- Claude requests are proxied through Firebase Cloud Functions.
- User inputs are validated and sanitized before storage and generation.
- Local and server-side rate limiting are both used for sensitive actions.
