const admin = require("firebase-admin");
const {initializeApp} = require("firebase-admin/app");
const {onDocumentCreated, onDocumentUpdated} =
  require("firebase-functions/v2/firestore");

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
              `Your application form has been approved.`,
          },
          token: userToken,
          data: {
            route: "/personal_data_form",
            fullBody:
            "Your application form has been approved. "+
              "Please proceed to the next steps.",
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
              `Your application form has been approved.`,
          },
          token: userToken,
          data: {
            route: "/contract_sign",
            fullBody:
              "Please proceed to the next step to sign the contract.",
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
            title: `New message for the tour ${tourName}`,
            body: `${messageData.name} has sent a message`,
          },
          data: {
            route: "/chat_page",
            userId,
            tourId,
            name: messageData.name,
            fullBody: `${messageData.name} has sent a message`,
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

exports.notifyOnNewTour =
  onDocumentCreated("Cars/{carId}", async (event) => {
    const carData = event.data.data();
    const vehicle = carData.Vehicle;
    const numberOfGuests = carData.NumberofGuests;
    const driverField = carData.Driver;

    const usersSnap = await admin.firestore().collection("Users").get();

    for (const userDoc of usersSnap.docs) {
      const user = userDoc.data();
      const role = user.Role;
      const token = user.fcmToken;

      if (!token) continue;

      const activeVehicle = user["Active Vehicle"];
      if (activeVehicle) {
        const vehicleDoc = await admin.firestore()
            .collection("Users")
            .doc(userDoc.id)
            .collection("Vehicles")
            .doc(activeVehicle)
            .get();
        const allowedVehicles = vehicleDoc.data()["Allowed Vehicle"];

        if (vehicleDoc.exists) {
          if ((role === "Driver" || role === "Driver Cum Guide") &&
              driverField === "" &&
              allowedVehicles.includes(vehicle) &&
              vehicleDoc.data()["Seat Number"] >= numberOfGuests) {
            try {
              await admin.messaging().send({
                notification: {
                  title: "New Tour Available",
                  body: "A new tour matches your vehicle. Please review.",
                },
                token,
                data: {
                  route: "/tour_list",
                  fullBody: "A new tour has been created"+
                   "matching your vehicle profile.",
                },
              });
            } catch (error) {
              console.error("🔥 Error while sending notification:", error);
            }
          }
        }
      }
    }
  });

exports.notifyOnNewGuideTour =
  onDocumentCreated("Guide/{guideTourId}", async (event) => {
    const guideData = event.data.data();
    const category = guideData.Category;
    const languagesRequired = guideData.Languages;

    const guideField = guideData.Guide;

    const usersSnap = await admin.firestore().collection("Users").get();

    for (const userDoc of usersSnap.docs) {
      const user = userDoc.data();
      const role = user.Role;
      const token = user.fcmToken;

      if (!token) continue;

      const userLanguages = (user["Language spoken"] || "").
          split(",").map((l) => l.trim());
      const userCategories = user["Allowed category"] || [];


      if ((role === "Guide" || role === "Driver Cum Guide") &&
        !guideField &&
        userCategories.includes(category) &&
        userLanguages.includes(languagesRequired)) {
        try {
          await admin.messaging().send({
            notification: {
              title: "Guide Needed",
              body: "A new guide tour matches your profile.",
            },
            token,
            data: {
              route: "/tour_list",
              fullBody: "A guide tour has been added"+
              "that fits your qualifications.",
            },
          });
        } catch (error) {
          console.error("🔥 Error while sending notification:", error);
        }
      }
    }
  });

exports.notifyOnDriverRemoved =
  onDocumentUpdated("Cars/{carId}", async (event) => {
    const beforeData = event.data.before.data();
    const afterData = event.data.after.data();

    if (beforeData.Driver && !afterData.Driver) {
      const vehicle = afterData.Vehicle;
      const numberOfGuests = afterData.NumberofGuests;

      const usersSnap = await admin.firestore().collection("Users").get();

      for (const userDoc of usersSnap.docs) {
        const user = userDoc.data();
        const token = user.fcmToken;

        if (!token) continue;

        const activeVehicle = user["Active Vehicle"];
        if (!activeVehicle) continue;

        const vehicleDoc = await admin.firestore()
            .collection("Users")
            .doc(userDoc.id)
            .collection("Vehicles")
            .doc(activeVehicle)
            .get();
        if (!vehicleDoc.exists) continue;
        const previousUID = beforeData.Driver;
        const allowedVehicles = vehicleDoc.data()["Allowed Vehicle"];

        if ((user.Role === "Driver" || user.Role === "Driver Cum Guide") &&
          previousUID !== userDoc.id &&
          allowedVehicles.includes(vehicle) &&
          vehicleDoc.data()["Seat Number"] >= numberOfGuests) {
          try {
            await admin.messaging().send({
              notification: {
                title: "Tour Reopened",
                body: "A tour is available again for your vehicle.",
              },
              token,
              data: {
                route: "/tour_list",
                fullBody: "A tour became available again"+
                  "that fits your vehicle.",
              },
            });
          } catch (error) {
            console.error("🔥 Error while sending notification:", error);
          }
        } else {
          console.error("🔥 Error while sending notification:",
              user.Role, allowedVehicles, vehicleDoc.data()["Seat Number"]);
        }
      }
    }
  });

exports.notifyOnGuideRemoved =
  onDocumentUpdated("Guide/{guideTourId}", async (event) => {
    const beforeData = event.data.before.data();
    const afterData = event.data.after.data();

    if (beforeData.Guide && !afterData.Guide) {
      const category = afterData.Category;
      const languagesRequired = afterData.Languages;

      const usersSnap = await admin.firestore().collection("Users").get();

      for (const userDoc of usersSnap.docs) {
        const user = userDoc.data();
        const token = user.fcmToken;

        if (!token) continue;

        const userCategories = user["Allowed category"] || [];

        const userLanguages = (user["Language spoken"] || "").
            split(",").map((l) => l.trim());

        const previousUID = beforeData.Guide;

        if ((user.Role === "Guide" || user.Role === "Driver Cum Guide") &&
          previousUID !== userDoc.id &&
          userCategories.includes(category) &&
          userLanguages.includes(languagesRequired)) {
          try {
            await admin.messaging().send({
              notification: {
                title: "Guide Needed Again",
                body: "A guide is needed for a reopened tour.",
              },
              token,
              data: {
                route: "/tour_list",
                fullBody: "A guide tour became available"+
              "again that matches your profile.",
              },
            });
          } catch (error) {
            console.error("🔥 Error while sending notification:", error);
          }
        } else {
          console.error("🔥 Error while sending notification:",
              user.Role, userCategories,
              userLanguages.includes(languagesRequired));
        }
      }
    }
  });
