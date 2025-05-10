//
//  SceneDelegate.swift
//  MlynyHub
//
//  Created by Peter Štefanec on 28/02/2025.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import UserNotifications


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

        // Load main storyboard
        let storyboard = UIStoryboard(name: "Main", bundle: nil)

        // Decide which view controller to show
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
        window?.rootViewController = navController
        window?.makeKeyAndVisible()

        // 3) konfigurácia indikátora siete
        setupStatusBubble()

        /// ... predchádzajúci kód ostáva rovnaký ...

        // Observer na lokalnu notif
        NotificationCenter.default.addObserver(
            forName: .didTapEventNotification,
            object: nil,
            queue: .main        // handle na man vlakne
        ) { [weak self] note in
            guard let self = self,
                  let eventID = note.userInfo?["eventID"] as? String else { return }
            
            //  pokus – event uz je v pamati allEventController
            if let nav = self.window?.rootViewController as? UINavigationController,
               let all = nav.viewControllers
                .first(where: { $0 is AllEventsViewController }) as? AllEventsViewController,
               let hit = all.events.first(where: { $0.eventId == eventID }) {
                
                self.pushDetail(for: hit)      // main q
                return
            }
            
            //  alt pokus – firestore cache
            self.fetchEventFromCache(eventID: eventID) { [weak self] entry in
                guard let self = self else { return }
                
                // naspat na hlavne vlakno
                DispatchQueue.main.async {
                    guard let entry = entry else {
                        // alert (
                        let alert = UIAlertController(
                            title: "Offline",
                            message: "Údaje k eventu nie sú uložené v telefóne.",
                            preferredStyle: .alert)
                        alert.addAction(.init(title: "OK", style: .default))
                        self.window?.rootViewController?.present(alert, animated: true)
                        return
                    }
                    self.pushDetail(for: entry)     // UI na main queue
                }
            }
        }

    }

    
    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }
    
    func sceneDidBecomeActive(_ scene: UIScene)  {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }
    
    func sceneWillResignActive(_ scene: UIScene) { }
    
    func sceneWillEnterForeground(_ scene: UIScene) { }
    
    func sceneDidEnterBackground(_ scene: UIScene) { }

    // MARK: - Offline cache helpers

    /// Vytiahne Event_entry čisto z Firestore cache (žiadny network request)
    private func fetchEventFromCache(eventID: String,
                                     completion: @escaping (Event_entry?) -> Void) {

        let docRef = Firestore.firestore()
            .collection("Events")
            .document(eventID)

        // .cache = nedotýka sa siete, vráti len lokálne uložený dokument
        docRef.getDocument(source: .cache) { snap, _ in
            guard let data = snap?.data() else {
                completion(nil)
                return
            }

            // — parsovanie ako v AllEventsViewController —
            let df = DateFormatter()
            df.dateStyle = .medium
            df.timeStyle = .short

            let ts  = data["Date"] as? Timestamp
            let loc = data["Location"] as? [Double] ?? []

            let entry = Event_entry(
                eventId:      eventID,
                Title:        data["Title"]        as? String ?? "Bez názvu",
                Description:  data["Description"]  as? String ?? "",
                max_slots:    data["Participant slots"] as? Int ?? 0,
                filled_slots: data["Filled slots"]     as? Int ?? 0,
                Date:         ts != nil ? df.string(from: ts!.dateValue()) : "",
                Image_url:    data["ImageURL"]     as? String ?? "",
                latitude:     loc.first ?? 0,
                longitude:    loc.dropFirst().first ?? 0
            )
            completion(entry)
        }
    }

    /// Pokúsi sa nájsť obrázok v URLCache (disk alebo RAM)
    private func cachedImage(for urlString: String) -> UIImage? {
        guard let url = URL(string: urlString) else { return nil }
        let request = URLRequest(url: url)
        if let cached = URLCache.shared.cachedResponse(for: request) {
            return UIImage(data: cached.data)
        }
        return nil
    }

    /// Vytvorí a pushne Event_detail_controller
    private func pushDetail(for entry: Event_entry) {

        guard let nav = window?.rootViewController as? UINavigationController else { return }

        let sb = UIStoryboard(name: "Main", bundle: nil)
        let detail = sb.instantiateViewController(
            withIdentifier: "Event_view"
        ) as! Event_detail_controller

        detail.event       = entry
        detail.passedImage = cachedImage(for: entry.Image_url)

        nav.pushViewController(detail, animated: true)
    }

    // MARK: - Setup status bubble (network indicator)
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
