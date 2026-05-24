// ─── FOR RAHMAH ───────────────────────────────────────────────────────────────
// This is the Cloud Function that listens to any change in the "appointments"
// collection and sends a push notification to the patient's device when the
// doctor changes the appointment status (e.g. accepted / rejected).
//
// HOW IT WORKS:
//   1. Doctor changes appointment status in the app.
//   2. Firestore document updates → this function fires automatically.
//   3. We check if status actually changed (to avoid duplicate notifications).
//   4. We grab the patient's FCM token (saved at booking time) and send the push.
//
// WHAT WAS FIXED FROM YOUR ORIGINAL:
//   - Added { region: "us-central1" } so the function deploys to the correct
//     region that matches your Firestore setup. Without this, Firebase picks a
//     default that might not match and cause latency issues.
//   - Switched logs from Arabic to English so they appear correctly in the
//     Firebase Console (it doesn't always handle Arabic well in logs).
//   - Added a log for the "status did not change" case so debugging is easier.
// ─────────────────────────────────────────────────────────────────────────────

const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

// Initialize Firebase Admin SDK
admin.initializeApp();

// ─── FOR RAHMAH ───────────────────────────────────────────────────────────────
// The { document, region } object is the fix here.
// "us-central1" is the default Firebase region — make sure your Firebase
// project's Firestore is also on this region (check Firebase Console > Firestore).
// If it's on a different region, change this string to match.
// ─────────────────────────────────────────────────────────────────────────────
exports.sendBookingNotificationOnUpdate = onDocumentUpdated(
  { document: "appointments/{appointmentId}", region: "us-central1" },
  async (event) => {
    // Get the new and old appointment data
    const newData = event.data.after.data();
    const oldData = event.data.before.data();

    // ─── FOR RAHMAH ─────────────────────────────────────────────────────────
    // We only want to send a notification when the STATUS field specifically
    // changes. Without this check, any field update (e.g. adding feedback)
    // would trigger a notification — which is wrong.
    // ────────────────────────────────────────────────────────────────────────
    if (newData.status === oldData.status) {
      console.log("Status did not change — no notification needed.");
      return null;
    }

    // Check that the patient's device token exists
    if (!newData.patientFcmToken) {
      console.log("No patient FCM token found — skipping notification.");
      return null;
    }

    // ─── FOR RAHMAH ─────────────────────────────────────────────────────────
    // We handle two statuses explicitly: "accepted" and "rejected".
    // For any other status change (e.g. "cancelled"), we send a generic message.
    // You can expand this switch-case later to handle more statuses with
    // custom messages for each one.
    // ────────────────────────────────────────────────────────────────────────
    let notificationTitle;
    let notificationBody;

    if (newData.status === "accepted") {
      notificationTitle = "Appointment Accepted";
      notificationBody = "Great news! Your appointment request has been accepted.";
    } else if (newData.status === "rejected") {
      notificationTitle = "Appointment Rejected";
      notificationBody = "Unfortunately, your appointment request was not accepted.";
    } else {
      notificationTitle = "Appointment Update";
      notificationBody = `Your appointment status has been updated to: ${newData.status}`;
    }

    // Build the notification message object
    const message = {
      notification: {
        title: notificationTitle,
        body: notificationBody,
      },
      // ─── FOR RAHMAH ───────────────────────────────────────────────────────
      // The "data" payload is sent alongside the notification.
      // The Flutter app reads this in onMessageOpenedApp (in main.dart) to know
      // which appointment was affected and navigate to the right screen.
      // ────────────────────────────────────────────────────────────────────────
      data: {
        appointmentId: event.params.appointmentId,
        status: newData.status,
        type: "appointment_status_update",
      },
      android: {
        priority: "high",
        notification: {
          channelId: "high_importance_channel",
        },
      },
      token: newData.patientFcmToken,
    };

    try {
      const response = await admin.messaging().send(message);
      console.log("Notification sent successfully. Message ID:", response);
      return null;
    } catch (error) {
      console.error("Error sending notification:", error);
      return null;
    }
  }
);