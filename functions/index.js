const admin = require("firebase-admin");

// Initialize Firebase Admin SDK
admin.initializeApp();

// Note: All notifications (booking, accept, reject, chat messages) are handled
// directly inside the Flutter app codebase to prevent duplicate notifications.
// If you need to add custom backend Cloud Functions in the future, you can write them here.