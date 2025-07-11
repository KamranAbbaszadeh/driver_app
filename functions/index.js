// Firebase Cloud Functions for handling real-time notifications
// and user account management.
// Includes notification triggers on Firestore document changes,
// chat messages, tour assignments,
// and secure deletion of user accounts with associated data cleanup.
const admin = require("firebase-admin");
const functions = require("firebase-functions");
const {initializeApp} = require("firebase-admin/app");
const {onDocumentCreated, onDocumentUpdated, onDocumentWritten} =
  require("firebase-functions/v2/firestore");

initializeApp();

// Sends a notification when specific user form fields are updated in Firestore.
// Handles approval and decline events for application
// and personal/car details forms, and registration completion.
exports.sendNotificationOnFieldChange = onDocumentUpdated("Users/{userId}",
    async (event) => {
      const beforeData = event.data.before.data();
      const afterData = event.data.after.data();

      const firstStageApplicationForm = "Application Form Verified";
      const secondStageApplicationForm = "Personal & Car Details Form Verified";

      if (beforeData[firstStageApplicationForm] === false &&
          afterData[firstStageApplicationForm] === true) {
        const userToken = afterData.fcmToken;
        if (!userToken || typeof userToken !== "string") {
          console.error("❌ Invalid or missing FCM token:", userToken);
          return;
        }
        const message = {
          notification: {
            title: "Hey There",
            body:
              `Your application form has been approved.`,
          },
          apns: {
            payload: {
              aps: {
                "content-available": 1,
                "sound": "default",
              },
            },
            headers: {
              "apns-priority": "10",
              "apns-topic": "com.onemoretour",
            },
          },
          android: {
            priority: "high",
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
          apns: {
            payload: {
              aps: {
                "content-available": 1,
                "sound": "default",
              },
            },
            headers: {
              "apns-priority": "10",
              "apns-topic": "com.onemoretour",
            },
          },
          android: {
            priority: "high",
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
      } else if (beforeData["Application Form Decline"] === false &&
             afterData["Application Form Decline"] === true) {
        const userToken = afterData.fcmToken;
        const message = {
          notification: {
            title: "Application Declined",
            body: "Unfortunately, your application form was declined.",
          },
          apns: {
            payload: {
              aps: {
                "content-available": 1,
                "sound": "default",
              },
            },
            headers: {
              "apns-priority": "10",
              "apns-topic": "com.onemoretour",
            },
          },
          android: {
            priority: "high",
          },
          token: userToken,
          data: {
            route: "/application_status",
            fullBody: "Your application form has been declined."+
              "Please contact support or resubmit your application form.",
          },
        };

        try {
          await admin.messaging().send(message);
          console.log("Decline notification sent successfully");
        } catch (error) {
          console.error("Error sending decline notification:", error);
        }
      } else if (beforeData["Personal & Car Details Decline"] === false &&
                afterData["Personal & Car Details Decline"] === true) {
        const userToken = afterData.fcmToken;
        const message = {
          notification: {
            title: "Details Declined",
            body: "Your personal and car details were declined.",
          },
          apns: {
            payload: {
              aps: {
                "content-available": 1,
                "sound": "default",
              },
            },
            headers: {
              "apns-priority": "10",
              "apns-topic": "com.onemoretour",
            },
          },
          android: {
            priority: "high",
          },
          token: userToken,
          data: {
            route: "/personalinfo_status",
            fullBody: "Your personal and car details were declined."+
              "Please resubmit the required information.",
          },
        };

        try {
          await admin.messaging().send(message);
          console.log("Decline notification sent successfully");
        } catch (error) {
          console.error("Error sending decline notification:", error);
        }
      } else if (beforeData["Registration Completed"] === false &&
                 afterData["Registration Completed"] === true) {
        const userToken = afterData.fcmToken;
        const message = {
          notification: {
            title: "Registration Completed",
            body: "Congratulations! Your registration is now complete.",
          },
          apns: {
            payload: {
              aps: {
                "content-available": 1,
                "sound": "default",
              },
            },
            headers: {
              "apns-priority": "10",
              "apns-topic": "com.onemoretour",
            },
          },
          android: {
            priority: "high",
          },
          token: userToken,
          data: {
            route: "/home",
            fullBody: "Your registration has been successfully completed."+
              "Welcome aboard!",
          },
        };

        try {
          await admin.messaging().send(message);
          console.log("Registration completion notification sent successfully");
        } catch (error) {
          console.error("Error sending registration completion notification:",
              error);
        }
      }
    },
);

// Sends a notification to a user when a new chat message is created.
// Only notifies if the message sender is not the message receiver.
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
          apns: {
            payload: {
              aps: {
                "content-available": 1,
                "sound": "default",
              },
            },
            headers: {
              "apns-priority": "10",
              "apns-topic": "com.onemoretour",
            },
          },
          android: {
            priority: "high",
          },
          data: {
            route: "/chat_page",
            userId: String(userId),
            tourId: String(tourId),
            name: String(messageData.name),
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

// Sends notifications to drivers when a new car tour is created
// matching their vehicle and profile criteria.
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
        if (!vehicleDoc.exists) continue;
        const vehicleData = vehicleDoc.data();
        const allowedVehicles = vehicleData["Allowed Vehicle"] || [];
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
                apns: {
                  payload: {
                    aps: {
                      "content-available": 1,
                      "sound": "default",
                    },
                  },
                  headers: {
                    "apns-priority": "10",
                    "apns-topic": "com.onemoretour",
                  },
                },
                android: {
                  priority: "high",
                },
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

// Sends notifications to guides when a new guide tour is created
// matching their languages and categories.
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
            apns: {
              payload: {
                aps: {
                  "content-available": 1,
                  "sound": "default",
                },
              },
              headers: {
                "apns-priority": "10",
                "apns-topic": "com.onemoretour",
              },
            },
            android: {
              priority: "high",
            },
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

// Notifies drivers when a previously assigned tour becomes available again
// due to driver removal.
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
        const allowedVehicles = vehicleDoc.data()["Allowed Vehicle"] || [];

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
              apns: {
                payload: {
                  aps: {
                    "content-available": 1,
                    "sound": "default",
                  },
                },
                headers: {
                  "apns-priority": "10",
                  "apns-topic": "com.onemoretour",
                },
              },
              android: {
                priority: "high",
              },
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

// Notifies guides when a previously assigned guide tour becomes available again
// due to guide removal.
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
              apns: {
                payload: {
                  aps: {
                    "content-available": 1,
                    "sound": "default",
                  },
                },
                headers: {
                  "apns-priority": "10",
                  "apns-topic": "com.onemoretour",
                },
              },
              android: {
                priority: "high",
              },
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


// HTTP endpoint securely deleting user accounts and cleaning up all
// associated user data
// from Firestore and Firebase Storage.
// Requires bearer token authentication for authorization.
exports.deleteUserAccount = functions.https.onRequest(async (req, res) => {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return res.status(401).send({error: "Unauthorized: No token provided."});
  }

  const idToken = authHeader.split("Bearer ")[1];
  let uid;
  try {
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    uid = decodedToken.uid;
  } catch (error) {
    return res.status(401).send({error: "Unauthorized: Invalid token."});
  }

  try {
    const firestore = admin.firestore();
    const storage = admin.storage().bucket();

    const userDocRef = firestore.collection("Users").doc(uid);
    const subcollections = await userDocRef.listCollections();
    for (const sub of subcollections) {
      const subDocs = await sub.listDocuments();
      for (const doc of subDocs) {
        await doc.delete();
      }
    }
    await userDocRef.delete();

    const [files] = await storage.getFiles({prefix: `Users/${uid}/`});
    const deleteOps = files.map((file) => file.delete());
    await Promise.all(deleteOps);

    await admin.auth().deleteUser(uid);

    res.send({success: true});
  } catch (error) {
    console.error("Failed to fully delete user:", error);
    res.status(500).send({error: "Failed to fully delete user."});
  }
});

// Sends a notification to the assigned user when the Routes field changes
// in Cars or Guide documents.
exports.sendNotificationOnRouteChange =
onDocumentWritten("Cars/{docId}", async (event) => {
  await handleRouteChange(event, "Cars");
});

exports.sendNotificationOnGuideRouteChange =
onDocumentWritten("Guide/{docId}", async (event) => {
  await handleRouteChange(event, "Guide");
});


/**
 * Detects changes to non-boolean fields in the Routes map of Cars
 * or Guide documents.
 * Sends an FCM notification to the assigned Driver
 * or Guide if any relevant changes occur.
 *
 * @param {firestore.Event} event - Firestore document write event
 * @param {string} collectionName - Either "Cars" or "Guide",
 * indicating the collection being monitored
 */
async function handleRouteChange(event, collectionName) {
  const beforeData = event.data.before.data();
  const afterData = event.data.after.data();

  if (!beforeData || !afterData) return;

  const beforeRoutes = beforeData.Routes || {};
  const afterRoutes = afterData.Routes || {};

  // Create shallow copies without boolean fields
  const filterBooleanFields = (routes) => {
    const result = {};
    for (const key in routes) {
      if (!routes[key] || typeof routes[key] !== "object") continue;
      const cleaned = {};
      for (const field in routes[key]) {
        if (typeof routes[key][field] !== "boolean") {
          cleaned[field] = routes[key][field];
        }
      }
      result[key] = cleaned;
    }
    return result;
  };

  const cleanedBeforeRoutes = filterBooleanFields(beforeRoutes);
  const cleanedAfterRoutes = filterBooleanFields(afterRoutes);

  if (JSON.stringify(cleanedBeforeRoutes) ===
      JSON.stringify(cleanedAfterRoutes)) return;

  const assignedUserUID = afterData[collectionName ===
      "Cars" ? "Driver" : "Guide"];
  if (!assignedUserUID) return;

  const userDoc = await admin.firestore().collection("Users")
      .doc(assignedUserUID).get();
  if (!userDoc.exists) return;

  const userToken = userDoc.data().fcmToken;
  if (!userToken) return;

  const tourName = afterData.TourName || "Tour";

  const message = {
    notification: {
      title: `${tourName} updated.`,
      body: `The routes details for ${tourName} have been updated.`,
    },
    token: userToken,
    apns: {
      payload: {
        aps: {
          "content-available": 1,
          "sound": "default",
        },
      },
      headers: {
        "apns-priority": "10",
        "apns-topic": "com.onemoretour",
      },
    },
    android: {
      priority: "high",
    },
    data: {
      route: "/tour_details",
      fullBody: `Tour routes for ${tourName} have been updated.
        Please check the latest route info.`,
    },
  };

  try {
    await admin.messaging().send(message);
    console.log(`Route update notification sent for 
        ${collectionName}/${event.params.docId}`);
  } catch (error) {
    console.error("Error sending route update notification:", error);
  }
}
