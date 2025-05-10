//
//  AppDelegate.swift
//  MlynyHub
//
//  Created by Peter Štefanec on 28/02/2025.
//

import UIKit
import FirebaseAuth
import Firebase
import IQKeyboardManagerSwift
import UserNotifications
import FirebaseAnalytics
import FirebaseCrashlytics

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // enabling 3rd libraries
        FirebaseApp.configure()
        // 2) Crashlytics – zapnúť zber (v produkcii je zapnuté defaultne)
            Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)
        // 3) Analytics – pošle “app_open” event
            Analytics.logEvent(AnalyticsEventAppOpen, parameters: nil)
        IQKeyboardManager.shared.isEnabled = true
        IQKeyboardManager.shared.resignOnTouchOutside = true
        
        
        // based on firebase - is user logged in or not?
        window = UIWindow(frame: UIScreen.main.bounds)
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                
                let rootViewController: UIViewController
                if Auth.auth().currentUser != nil {
                    rootViewController = storyboard.instantiateViewController(withIdentifier: "MainViewController")
                } else {
                    rootViewController = storyboard.instantiateViewController(withIdentifier: "LoginViewController")
                }
                
                window?.rootViewController = rootViewController
                window?.makeKeyAndVisible()
        
        
        
        // ––– Firestore offline persistence (default: true, ale nezabúď zmeniť, ak si to niekde vypol)
        let settings = FirestoreSettings()
        settings.cacheSettings = PersistentCacheSettings()
        Firestore.firestore().settings = settings

        // ––– URLCache na disk (pre fotky)
        let memCap = 50 * 1024 * 1024    // 50 MB in-memory
        let diskCap = 200 * 1024 * 1024  // 200 MB on-disk
        URLCache.shared = URLCache(
          memoryCapacity: memCap,
          diskCapacity: diskCap,
          diskPath: "url_cache"
        )

        // MARK: –▶ Lokálne notifikácie – žiadosť o povolenie
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let err = error {
                print("Chyba pri žiadosti o povolenie notifikácií: \(err)")
            }
        }
        
        // MARK: –▶ Definícia akcie a kategórie
        let openAction = UNNotificationAction(identifier: "OPEN_EVENT",title: "Zobraziť event",options: [.foreground])
        
        let eventCategory = UNNotificationCategory(identifier: "EVENT_REMINDER",actions: [openAction],intentIdentifiers: [],options: [])
        
        center.setNotificationCategories([eventCategory])

        // MARK: –▶ Nastav AppDelegate ako UNUserNotificationCenterDelegate
        center.delegate = self
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    



}

// MARK: –▶ UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let userInfo = response.notification.request.content.userInfo
    if let eventID = userInfo["eventID"] as? String {
      // Posli notification, aby SceneDelegate / root VC mohli navigovať
      NotificationCenter.default.post(
        name: .didTapEventNotification,
        object: nil,
        userInfo: ["eventID": eventID]
      )
    }
    completionHandler()
  }
}

// MARK: –▶ Notification.Name helper
extension Notification.Name {
  static let didTapEventNotification = Notification.Name("didTapEventNotification")
}
