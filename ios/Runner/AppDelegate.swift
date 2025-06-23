import Flutter
import UIKit
import GoogleMaps
import flutter_local_notifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
      FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { registrar in
          GeneratedPluginRegistrant.register(with: registrar)
      }
      GMSServices.provideAPIKey("AIzaSyB6JYD0lrlzp85gUDB1LMU6CVkNi6EdR6Y")
    GeneratedPluginRegistrant.register(with: self)
      
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

import UserNotifications

extension AppDelegate {
  // This method will be called when the app receives a notification in the foreground
  override func userNotificationCenter(_ center: UNUserNotificationCenter,
                              willPresent notification: UNNotification,
                              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    completionHandler([.alert, .badge, .sound]) // Show alert, badge, and play sound
  }
}
