const {onDocumentUpdated} = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
const {initializeApp} = require("firebase-admin/app");

initializeApp();


exports.sendNotificationOnFieldChange = onDocumentUpdated("Users/{userId}",
    async (event) => {
      const beforeData = event.data.before.data();
      const afterData = event.data.after.data();

      const firstStageApplicationForm = "Application Form Verified";
      const secondStageApplicationForm = "Personal & Car Details Form Verified";

      if (beforeData[firstStageApplicationForm] === false &&
          afterData[firstStageApplicationForm] === true) {
        const userToken = afterData.fcmToken;
        const message = {
          notification: {
            title: "Hey There",
            body:
              `Your application form approved.`,
          },
          token: userToken,
          data: {
            route: "/personal_data_form",
            fullBody:
              "Your application form approved. Please follow the next steps.",
          },
        };

        try {
          await admin.messaging().send(message);
          console.log("Notification sent successfully");
        } catch (error) {
          console.error("Error sending notification:", error);
        }
      } else if (beforeData[secondStageApplicationForm] === false &&
          afterData[secondStageApplicationForm] === true) {
        const userToken = afterData.fcmToken;
        const message = {
          notification: {
            title: "Congratulations",
            body:
              `Your application form approved.`,
          },
          token: userToken,
          data: {
            route: "/personal_data_form",
            fullBody:
              "Please follow up next steps to sign a contract.",
          },
        };

        try {
          await admin.messaging().send(message);
          console.log("Notification sent successfully");
        } catch (error) {
          console.error("Error sending notification:", error);
        }
      }
    },
);
