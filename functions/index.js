const {onDocumentUpdated} = require("firebase-functions/v2/firestore");
const {onDocumentCreated} = require("firebase-functions/v2/firestore");

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
            route: "/contract_sign",
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

exports.sendNotificationOnNewChatMessage = onDocumentCreated(
    "Chat/{userId}/{tourId}/{messageId}",
    async (event) => {
      const {userId, tourId} = event.params;
      const messageData = event.data && event.data.data();

      if (!messageData) {
        console.error("Message data is missing.");
        return null;
      }
      const currentUserUid = messageData.UID;
      if (currentUserUid === userId) {
        return null;
      }

      try {
        const userDoc = await admin.firestore()
            .collection("Users").doc(userId).get();
        if (!userDoc.exists) return null;

        const fcmToken = userDoc.data().fcmToken;
        if (!fcmToken) return null;

        const role = userDoc.data().Role;
        let tourDoc;

        if (role === "Driver Cum Guide") {
          const guideDoc = await admin.firestore().
              collection("Guide").doc(tourId).get();
          if (guideDoc.exists) {
            tourDoc = guideDoc;
          } else {
            const carDoc = await admin.firestore().
                collection("Cars").doc(tourId).get();
            if (carDoc.exists) {
              tourDoc = carDoc;
            }
          }
        } else {
          const collection = role === "Guide" ? "Guide" : "Cars";
          tourDoc = await admin.firestore().
              collection(collection).doc(tourId).get();
        }

        if (!tourDoc || !tourDoc.exists) return null;
        const tourName = tourDoc.data().TourName;

        const message = {
          notification: {
            title: `New Message for tour ${tourName}`,
            body: `${messageData.name} sent a message`,
          },
          data: {
            route: "/chat_page",
            userId,
            tourId,
            name: messageData.name,
            fullBody: `${messageData.name} sent a message`,
          },
          token: fcmToken,
        };

        try {
          await admin.messaging().send(message);
        } catch (error) {
          console.error("🔥 Error while sending notification:", error);
        }
      } catch (error) {
        console.error("Error sending chat notification:", error);
      }

      return null;
    },
);

exports.notifyDriversOnNewCarTour = onDocumentCreated(
    "Cars/{tourId}",
    async (event) => {
      const tourData = event.data && event.data.data();
      if (!tourData) return;

      const usersSnapshot = await admin.firestore().collection("Users").get();
      for (const userDoc of usersSnapshot.docs) {
        const userData = userDoc.data();
        const role = userData.Role;
        const fcmToken = userData.fcmToken;
        const userId = userDoc.id;

        if (!fcmToken || !(role === "Driver" ||
            role === "Driver Cum Guide")) continue;

        const activeVehicleId = userData["Active Vehicle"];
        let activeVehicle;
        if (activeVehicleId) {
          const vehicleDoc = await admin.firestore()
              .doc(`Users/${userId}/Vehicles/${activeVehicleId}`)
              .get();
          if (vehicleDoc.exists) activeVehicle = vehicleDoc.data();
        }

        const startDate = new Date(tourData.StartDate);
        const endDate = new Date(tourData.EndDate);
        if (endDate > startDate) continue;

        const matches = activeVehicle &&
          activeVehicle["Vehicle Type"] === tourData.VehicleType &&
          activeVehicle["Seat Number"] === tourData.SeatNumber;

        if (matches) {
          const message = {
            notification: {
              title: "New Tour Available",
              body: `A new Ride tour has been added.`,
            },
            data: {
              route: "/new_tours",
              fullBody: `A new Ride tour has been added.`,
            },
            token: fcmToken,
          };
          await admin.messaging().send(message);
        }
      }
    },
);

exports.notifyGuidesOnNewGuideTour = onDocumentCreated(
    "Guide/{tourId}",
    async (event) => {
      const tourData = event.data && event.data.data();
      if (!tourData) return;

      const usersSnapshot = await admin.firestore().collection("Users").get();
      for (const userDoc of usersSnapshot.docs) {
        const userData = userDoc.data();
        const role = userData.Role;
        const fcmToken = userData.fcmToken;
        if (!fcmToken || !(role === "Guide" ||
            role === "Driver Cum Guide")) continue;

        const startDate = new Date(tourData.StartDate);
        const endDate = new Date(tourData.EndDate);
        if (endDate > startDate) continue;

        const requiredLanguages = tourData.Languages.
            split(",").map((lang) => lang.trim().toLowerCase()) || [];
        const spokenLanguages = userData["Language spoken"].
            split(",").map((lang) => lang.trim().toLowerCase()) || [];
        const languageMatch = requiredLanguages.
            every((lang) => spokenLanguages.includes(lang));
        const matches = userData.Category ===
            tourData.Category && languageMatch;

        if (matches) {
          const message = {
            notification: {
              title: "New Tour Available",
              body: `A new Guide tour has been added.`,
            },
            data: {
              route: "/new_tours",
              fullBody: `A new Guide tour has been added.`,
            },
            token: fcmToken,
          };
          await admin.messaging().send(message);
        }
      }
    },
);
