# Reel Mind

## What the Project Does

The app helps make content planning faster, more personalized, and more genuine by giving users AI-generated ideas they can build on, AI-assisted script support for developing talking points, and a workspace for organizing ideas through draft, script-ready, posted, and archived states. It also includes What to Try Next, which analyzes posted scripts to suggest new hook directions, and Saved Hooks, where users can store future content directions for later.

## Why the Project Is Useful

The problem Reel Mind aims to solve is reducing the amount of time social media creators spend on pre-production planning, especially when coming up with new short-form content ideas. Many creators experience burnout or creative roadblocks when trying to think of video ideas that still fit their personal content style. When creators run out of ideas, it becomes harder to consistently produce and publish content, which can lead to lower viewership, fewer promotional opportunities, and slower audience growth.

Reel Mind uses AI to help creators generate personalized video ideas and talking points based on their content style. Instead of spending excessive time brainstorming from scratch, users can rely on the app to support the idea-generation process while they focus more on filming and producing content. The goal is to make content planning faster, more personalized, and more genuine while helping creators stay consistent without feeling creatively drained.

## How Users Can Get Started

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

For AI features to work, the Firebase project must have Authentication, Cloud Firestore, Firebase Storage, Cloud Functions, and the `ANTHROPIC_API_KEY` secret configured. The callable Firebase Function `callClaude` must also be deployed.

## Where Users Can Get Help

Users can review the project files in this repository, especially:

- [`lib/`](lib/) for the Flutter app code
- [`functions/index.js`](functions/index.js) for the Firebase Claude proxy
- [`firestore.rules`](firestore.rules) for Cloud Firestore access rules

For Firebase-specific setup, use the Firebase Console and Firebase documentation for Authentication, Firestore, Storage, Cloud Functions, and Secret Manager.

## Maintainers and Contributors

Current contributors:

- Allison Nguyen
