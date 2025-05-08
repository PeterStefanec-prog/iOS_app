//
//  SceneDelegate.swift
//  MlynyHub
//
//  Created by Peter Štefanec on 28/02/2025.
//

import UIKit
import FirebaseAuth

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    
    // 1) indikator view
    // ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
    // — bublina + label
    private let statusBubble: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.layer.cornerRadius = 10
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.15
        v.layer.shadowOffset = .init(width: 0, height: 2)
        v.layer.shadowRadius = 4
        // Na začiatku hidden
        v.alpha = 0
        return v
    }()
    
    private let statusLabel: UILabel = {
        let lbl = UILabel()
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.font = .systemFont(ofSize: 11, weight: .medium)
        lbl.textColor = .white
        lbl.textAlignment = .center
        return lbl
    }()
    // ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let windowScene = (scene as? UIWindowScene) else { return }

                // Create a new UIWindow
                window = UIWindow(windowScene: windowScene)

                // Load  main storyboard
                let storyboard = UIStoryboard(name: "Main", bundle: nil)

                // Decide which view controller to show - also results in which view to show
                let rootVC: UIViewController
                if Auth.auth().currentUser != nil {
                    // User is logged in
                    rootVC = storyboard.instantiateViewController(withIdentifier: "MainViewController")
                } else {
                    // User is not logged in
                    rootVC = storyboard.instantiateViewController(withIdentifier: "LoginViewController")
                }

                // Embed the chosen root VC in a navigation controller
                let navController = UINavigationController(rootViewController: rootVC)

                // Set the navigation controller as the window's root - important because of navigation bar - it manages a stack of controllers so it'll know that the back button does
                window?.rootViewController = navController
                window?.makeKeyAndVisible()
        
                // 3) konfiguracia indikátora
                setupStatusBubble()
            }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }

    
    private func setupStatusBubble() {
            guard let window = window else { return }
            
            // 1) pridáme bublinu
            window.addSubview(statusBubble)
            statusBubble.addSubview(statusLabel)

            NSLayoutConstraint.activate([
                statusBubble.centerXAnchor.constraint(equalTo: window.centerXAnchor),
                statusBubble.topAnchor.constraint(equalTo: window.safeAreaLayoutGuide.topAnchor, constant: 1),
                statusBubble.widthAnchor.constraint(equalToConstant: 70),
                statusBubble.heightAnchor.constraint(equalToConstant: 25),

                statusLabel.leadingAnchor.constraint(equalTo: statusBubble.leadingAnchor, constant: 8),
                statusLabel.trailingAnchor.constraint(equalTo: statusBubble.trailingAnchor, constant: -8),
                statusLabel.centerYAnchor.constraint(equalTo: statusBubble.centerYAnchor)
            ])

            // 2) prihlásime sa na notifikácie, ešte pred startom monitoru
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(networkStatusChanged(_:)),
                name: NetworkMonitor.statusChangedNotification,
                object: nil
            )

            // 3) až teraz spustíme monitor – handler nám pošle initial + každú ďalšiu zmenu
            NetworkMonitor.shared.start()
        }

        @objc private func networkStatusChanged(_ notification: Notification) {
            let isOnline = (notification.object as? Bool) ?? false
            DispatchQueue.main.async {
                // najprv aktualizujeme farbu + text
                self.updateBubble(isOnline: isOnline)
                // potom jemne prechodom zobrazime bublinu (ak bola hidden)
                UIView.animate(withDuration: 0.25) {
                    self.statusBubble.alpha = 1
                }
            }
        }

        private func updateBubble(isOnline: Bool) {
            let onlineColor  = UIColor(red: 0.20, green: 0.78, blue: 0.56, alpha: 1)
            let offlineColor = UIColor(red: 0.56, green: 0.56, blue: 0.58, alpha: 1)
            statusBubble.backgroundColor = isOnline ? onlineColor : offlineColor
            statusLabel.text = isOnline ? "Online" : "Offline"
        }

        deinit {
            NotificationCenter.default.removeObserver(self)
        }
    }
