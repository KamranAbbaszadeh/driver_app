const {onDocumentUpdated} = require("firebase-functions/v2/firestore");
const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {getFirestore} = require("firebase-admin/firestore");
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

exports.notifyMatchingUsers = onDocumentCreated(
    "Cars/{carId}",
    async (event) => {
      const newCar = event.data.data();

      try {
        const db = getFirestore();
        const usersSnapshot = await db.collection("Users").get();
        const tokensToNotify = [];

        usersSnapshot.forEach((doc) => {
          const user = doc.data();
          const startDate = newCar["StartDate"];
          const tourEndDate = user["Tour End Date"];

          const isMatch =
            user["Vehicle type"] === newCar["Vehicle type"] &&
            user["Seat Number"] >= newCar["NumberofGuests"] &&
            startDate && tourEndDate &&
            (startDate.toDate() >
                tourEndDate.toDate());

          if (isMatch && user["fcmToken"]) {
            tokensToNotify.push(user["fcmToken"]);
          }
          console.log("Checking user:", user);
          console.log("Is Match criteria:");
          console.log(`Vehicle Type Match: ${user["Vehicle type"] ===
            newCar["Vehicle type"]}  ${user["Vehicle type"]}
             ${newCar["Vehicle type"]}`);
          console.log(`Seat Number Match: ${user["Seat Number"] >=
            newCar["NumberofGuests"]} ${user["Seat Number"]}
              ${newCar["NumberofGuests"]}`);
          console.log(`Tour End Date Valid: ${
            startDate.toDate() >
                tourEndDate.toDate()} 
                ${startDate.toDate()}
                  ${tourEndDate.toDate()}`);
        });

        if (tokensToNotify.length > 0) {
          const message = {
            notification: {
              title: "New Tour Available",
              body: `A new tour is waiting for you!`,
            },
            tokens: tokensToNotify,
            data: {
              route: "/orders",
              fullBody:
                `A new tour ${newCar["TourName"]} matches your preferences!`,
            },

          };

          await admin.messaging().sendEachForMulticast(message);

          console.log("Notifications sent to matching users.");
        } else {
          console.log("No matching users found.");
        }
      } catch (error) {
        console.error("Error sending notifications:", error);
      }
    },
);
