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

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // enabling 3rd libraries
        FirebaseApp.configure()
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

