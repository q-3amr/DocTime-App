const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

// تهيئة Firebase Admin SDK
admin.initializeApp();

exports.sendBookingNotificationOnUpdate = onDocumentUpdated("appointments/{appointmentId}", async (event) => {
    // الحصول على البيانات الجديدة والقديمة للموعد
    const newData = event.data.after.data();
    const oldData = event.data.before.data();

    // التحقق من تغير حالة الموعد (status)
    if (newData.status !== oldData.status) {

        // التحقق من وجود توكن الجهاز الخاص بالمريض (patientFcmToken)
        if (!newData.patientFcmToken) {
            console.log("لا يوجد توكن للمريض، لن يتم إرسال الإشعار");
            return null;
        }

        // إعداد الرسالة (الإشعار التقليدي)
        const message = {
            notification: {
                title: newData.status === 'accepted' ? 'تم قبول موعدك' : 'تحديث بخصوص موعدك',
                body: newData.status === 'accepted'
                    ? 'مبروك! تم قبول طلب الموعد الخاص بك.'
                    : `نعتذر، حالة موعدك الآن هي: ${newData.status}`
            },
            // إعدادات خاصة بالأندرويد لضمان ظهور الإشعار كـ Banner تقليدي
            android: {
                priority: 'high',
                notification: {
                    channelId: 'high_importance_channel',
                    clickAction: 'FLUTTER_NOTIFICATION_CLICK'
                }
            },
            token: newData.patientFcmToken
        };

        try {
            // إرسال الإشعار
            await admin.messaging().send(message);
            console.log("تم إرسال الإشعار التقليدي للمريض بنجاح");
            return null;
        } catch (error) {
            console.error("خطأ أثناء إرسال الإشعار:", error);
            return null;
        }
    }
    return null;
});