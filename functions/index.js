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

exports.sendNewMessageNotification =
  onDocumentUpdated("Chat/{userId}/{tourId}/sender",
      async (event) => {
        if (!event || !event.params) {
          console.error("Context or params is missing!");
          return null;
        }
        const userId = event.params.userId;
        const tourId = event.params.tourId;
        const senderDoc = event.data.after.data();
        const previousSenderDoc = event.data.before.data();
        if (!senderDoc) {
          return null;
        }
        const newMessages = Object.keys(senderDoc)
            .filter((key) => key.startsWith("message") &&
            (!previousSenderDoc || !previousSenderDoc[key]))
            .map((key) => ({key, ...senderDoc[key]}));

        if (newMessages.length === 0) {
          return null;
        }
        const latestMessage = newMessages[newMessages.length - 1];

        try {
          const userDoc = await admin.firestore()
              .collection("Users")
              .doc(userId)
              .get();
          if (!userDoc.exists) {
            return null;
          }
          const fcmToken = userDoc.data().fcmToken;

          if (!fcmToken) {
            return null;
          }

          if (userDoc.data().role == "Guide") {
            const tourDoc = await admin.firestore()
                .collection("Guide")
                .doc(tourId)
                .get();
            if (!tourDoc.exists) {
              return null;
            }
            const tourName = tourDoc.data().tourName;


            const message = {
              notification: {
                title: "New Message",
                body: `${latestMessage.name}
                 just sent you a message for tour ${tourName}`,
              },
              data: {
                userId: userId,
                tourId: tourId,
                route: "chat",
                name: latestMessage.name,
              },
              token: fcmToken,
            };

            const response = await admin.messaging().send(message);
            console.log("Notification sent successfully!", response);
          } else {
            const tourDoc = await admin.firestore()
                .collection("Cars")
                .doc(tourId)
                .get();
            if (!tourDoc.exists) {
              return null;
            }
            const tourName = tourDoc.data().tourName;


            const message = {
              notification: {
                title: "New Message",
                body: `${latestMessage.name}
               just sent you a message for tour ${tourName}`,
              },
              data: {
                userId: userId,
                tourId: tourId,
                route: "chat",
                name: latestMessage.name,
              },
              token: fcmToken,
            };

            const response = await admin.messaging().send(message);
            console.log("Notification sent successfully!", response);
          }
        } catch (error) {
          console.error("Error sending notification:", error);
        }

        return null;
      });
