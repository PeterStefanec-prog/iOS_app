//
//  Event_detail_controller.swift
//  MlynyHub
//
//  Created by Peter Štefanec on 11/04/2025.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import CoreLocation
import FirebaseStorage
import UserNotifications
import FirebaseAnalytics


class Event_detail_controller: UIViewController {
    
    // This property is set from AllEventsViewController via segue.
    // It should include an eventId property for Firestore operations.
    var event: Event_entry?
    var passedImage: UIImage?
    
    private let geocoder = CLGeocoder()
    
    // Outlets for UI elements on the Event detail screen
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var slotsLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var eventImageView: UIImageView!
    @IBOutlet weak var eventLocation: UILabel!
    @IBOutlet weak var Change_Date_Button: UIButton!
    @IBOutlet weak var Change_date_pencil: UIImageView!
    
    
    // Button will change text based on user status: "Delete Event" (if admin),
    // "Join Event" (if not a participant) or "Leave Event" (if already joined)
    @IBOutlet weak var actionButton: UIButton!
    
    // Variables to track admin status and whether the user is a participant
    private var isAdmin = false
    private var isParticipant = false
    private var participants: [String] = [] // Array of UIDs for the users who have joined
    private var isEventFull = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Ensure that the event data is available
        guard let event = event else {
            print("No event data was provided.")
            return
        }
        
        // Set the static UI from local event data
        titleLabel.text = event.Title
        eventLocation.text = String(event.latitude) + ", " + String(event.longitude)    // - normal location name
        descriptionLabel.text = event.Description
        dateLabel.text = event.Date
        // Display the slot count (registered/total) from the locally stored event values.
        slotsLabel.text = "\(event.filled_slots)/\(event.max_slots)"
        
        // Load and display the event photo if available from AllEventsViewController
        if let image = passedImage {
            eventImageView.image = image
        } else if !event.Image_url.isEmpty {
            loadImage(urlString: event.Image_url)
        }

        
        actionButton.layer.cornerRadius = 10
        actionButton.isHidden = true // hidden while we identify the state of event - full ..
        
        //skryje ceruzky
        Change_date_pencil.isHidden = true
        Change_date_pencil.isUserInteractionEnabled = false
        Change_Date_Button.isHidden = true
        Change_Date_Button.isUserInteractionEnabled = false
        
        // 1) keby daco
        eventLocation.text = "Načítavam adresu…"
        // 2) Spusti reverse geocoding
        reverseGeocode(latitude: event.latitude, longitude: event.longitude)
        
        // Fetch the latest details from Firestore (Admin, participants, filled slots, etc.)
        fetchEventDetailsFromFirestore(eventId: event.eventId)
    }
    
    
    // MARK: - Fetch Updated Event Details from Firestore
    // Gets the up-to-date event document to update admin and participant info.
    private func fetchEventDetailsFromFirestore(eventId: String) {
        // get event from database
        let db = Firestore.firestore()
        let eventRef = db.collection("Events").document(eventId)
        
        // vyber zdroj podľa siete: online = .default, offline = .cache
        let source: FirestoreSource = NetworkMonitor.shared.isConnected ? .default : .cache
        
        eventRef.getDocument(source: source) { [weak self] snapshot, error in
            guard let self = self else { return }
            if let error = error {
                self.showAlert(title: "Upozornenie", message: "Nie ste pripojeny na internet. Udaje nemusia byt aktualne.")
                print("Error fetching event document: \(error.localizedDescription)")
                return
            }
            
            guard let data = snapshot?.data() else {
                print("No event data found in Firestore.")
                return
            }
            
            // 1. Check if the current user is the admin of the event.
            if let adminRef = data["Admin"] as? DocumentReference,
               let currentUser = Auth.auth().currentUser {
                let expectedAdminPath = "users/\(currentUser.uid)"
                self.isAdmin = (adminRef.path == expectedAdminPath)
            }
            
            self.updateDateEditingUI()
            
            // 2. Update the slot info using real Firestore values.
            let filledSlots = data["Filled slots"] as? Int ?? 0
            let maxSlots = data["Participant slots"] as? Int ?? 0
            self.slotsLabel.text = "\(filledSlots)/\(maxSlots)"
            self.isEventFull = (filledSlots >= maxSlots) // set when the event is full
            
            // 3. Update the list of participants from Firestore.
            if let participantsArr = data["Participants"] as? [String] {
                self.participants = participantsArr
            }
            
            // 4. Determine if the current user is already a participant.
            if let currentUser = Auth.auth().currentUser {
                self.isParticipant = self.participants.contains(currentUser.uid)
            }
            
            // 5. Update the action button based on user status.
            self.configureActionButton()
        }
    }
    
    // MARK: - Configure Action Button Text
    // Sets the button title depending on whether the user is admin or has joined.
    private func configureActionButton() {
        // is the event full and the user is not admin and not even participant? Do not show the button, there is nothing you can do with event.
        if isEventFull && !isParticipant && !isAdmin {
            actionButton.isHidden = true
            return
        } else {
            // For non-admin, if the user has joined then offer option to leave; otherwise, join.
            actionButton.isHidden = false
        }
        
        if isAdmin {
            // If the current user is admin then they can delete the event.
            actionButton.setTitle("Delete Event", for: .normal)
            actionButton.backgroundColor = .systemRed
        } else {
            // For non-admin, if the user has joined then offer option to leave; otherwise, join.
            if isParticipant {
                actionButton.setTitle("Odhlasit sa", for: .normal)
                actionButton.backgroundColor = .systemBlue
                
            } else {
                actionButton.setTitle("Zucastnim sa", for: .normal)
                actionButton.backgroundColor = .systemGreen
            }
        }
    }
    
    // MARK: Kontrola siete pred tyjm ako sa spusti hocijaka akcia
    private func ensureOnline() -> Bool {
        if !NetworkMonitor.shared.isConnected {
            showAlert(title: "Offline", message: "Momentálne nie ste pripojení na internet. Skúste to prosím neskôr.")
            return false
        }
        return true
    }
    
    // MARK: - Action Button Press Handler
    @IBAction func actionButtonTapped(_ sender: UIButton) {
        // 1) if offline - show alert and return from function
        guard ensureOnline() else { return }
        
        if isAdmin {
            // If admin, pressing the button deletes the event.
            confirmDeleteEvent()
        } else {
            // If not admin, then join or leave the event based on current participation.
            if isParticipant {
                leaveEvent()
            } else {
                joinEvent()
            }
        }
    }
    
    // MARK: - Delete Event (for Admin)
    /// Confirmation
    private func confirmDeleteEvent() {
        let alert = UIAlertController(title: "Vymazať event", message: "Určite chcete vymazať event?", preferredStyle: .alert)
        
        // yes -  deleteEvent()
        let yesAction = UIAlertAction(title: "Áno", style: .destructive) { [weak self] _ in
            self?.deleteEvent()
        }
        
        // no
        let noAction = UIAlertAction(title: "Nie", style: .cancel, handler: nil)
        
        alert.addAction(yesAction)
        alert.addAction(noAction)
        
        present(alert, animated: true, completion: nil)
    }

    
    // Deletes the event document from Firestore. - cascade
    private func deleteEvent() {
        guard let event = event else { return }
        let db       = Firestore.firestore()
        let eventRef = db.collection("Events").document(event.eventId)
        let storage  = Storage.storage()

        // 1) image reference z download URL
        let imageRef = storage.reference(forURL: event.Image_url)

        // 2) delete phoot
        imageRef.delete { [weak self] storageError in
            if let err = storageError {
                print("Error deleting image:", err.localizedDescription)
                // continue anyways
            }

            // 3) delete firestore document
            eventRef.delete { error in
                if let error = error {
                    print("Error deleting event doc:", error.localizedDescription)
                    self?.showAlert(title: "Chyba", message: "Nepodarilo sa vymazať event.")
                    return
                }
                Analytics.logEvent("delete_event", parameters: [
                      "event_id": event.eventId as NSObject
                    ])
                print("Event and image deleted successfully.")
                DispatchQueue.main.async {
                    // After deletion, navigate back to the previous screen.
                    self?.navigationController?.popViewController(animated: true)
                    self?.showAlert(title: "Úspech", message: "Event bol úspešne vymazaný.")
                }
            }
        }
    }
    
    // MARK: - Join Event (for non-admin)
    /// Updates Firestore to add the current user to the participants list.
    private func joinEvent() {
        guard let event = event, let currentUser = Auth.auth().currentUser else { return }
        let db = Firestore.firestore()
        let eventRef = db.collection("Events").document(event.eventId)
        
        // Increase the filled slots count and add the current user's uid to the Participants array.
        eventRef.updateData([
            "Filled slots": FieldValue.increment(Int64(1)),
            "Participants": FieldValue.arrayUnion([currentUser.uid])
        ]) { [weak self] error in
            guard let self = self else { return }

            if let error = error {
                print("Error joining event: \(error.localizedDescription)")
                return
            }
            Analytics.logEvent("join_event", parameters: [
              "event_id": event.eventId as NSObject
            ])
            self.showAlert(title: "Uspech", message: "Uspesne ste sa prihlasili na event")
            
            // Notifikácia 15 min pred začiatkom
            eventRef.getDocument { snap, _ in
                guard let ts = snap?.data()?["Date"] as? Timestamp else { return }
                self.scheduleReminder(forEventID: event.eventId,
                                      title: event.Title,
                                      at: ts.dateValue())
            }
            self.fetchEventDetailsFromFirestore(eventId: event.eventId)
        }
    }
    
    // MARK: - Leave Event (for non-admin)
    /// Updates Firestore to remove the current user from the participants list.
    private func leaveEvent() {
        guard let event = event, let currentUser = Auth.auth().currentUser else { return }
        let db = Firestore.firestore()
        let eventRef = db.collection("Events").document(event.eventId)
        
        // Decrease the filled slots count and remove the current user's uid from the Participants array.
        eventRef.updateData([
            "Filled slots": FieldValue.increment(Int64(-1)),
            "Participants": FieldValue.arrayRemove([currentUser.uid])
        ]) { [weak self] error in
            if let error = error {
                print("Error leaving event: \(error.localizedDescription)")
                return
            }
            Analytics.logEvent("leave_event", parameters: [
              "event_id": event.eventId as NSObject
            ])
            self?.showAlert(title: "Uspesne odhlaseny.", message: "Urcite sa ale prihlaste na iny event ktory vam vyhovuje.")
            print("Successfully left the event.")
            // Re-fetch updated details so the UI gets refreshed.
            self?.fetchEventDetailsFromFirestore(eventId: event.eventId)
        }
    }
    
    
    // ZOBRAZOVANIE LOKACIE
    private func reverseGeocode(latitude: Double, longitude: Double) {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            guard let self = self else { return }
            if let p = placemarks?.first {
                let parts: [String?] = [
                    p.thoroughfare,
                    p.subThoroughfare,
                    p.locality
                ]
                self.eventLocation.text = parts.compactMap { $0 }.joined(separator: ", ")
            } else {
                self.eventLocation.text = "Neznáma poloha"
            }
        }
    }

    // MARK: - Lokálna notifikácia
    private func scheduleReminder(forEventID id: String, title: String, at startDate: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Čoskoro začína event"
        content.body  = "Event „\(title)“ začne o 15 minút."
        content.categoryIdentifier = "EVENT_REMINDER"
        content.userInfo = ["eventID": id]

        let triggerDate = Calendar.current.date(byAdding: .minute, value: -15, to: startDate)!
        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)

        let req = UNNotificationRequest(identifier: "reminder_\(id)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req) { error in
            if let err = error { print("Chyba pri plánovaní notifikácie:", err) }
        }
    }

    // MARK: - Image loading (online + offline cache)
    private func loadImage(urlString: String) {
        guard let url = URL(string: urlString) else { return }

        var request = URLRequest(url: url)
        request.timeoutInterval = 60
        request.cachePolicy = NetworkMonitor.shared.isConnected
            ? .returnCacheDataElseLoad   // online – skús cache, inak stiahni
            : .returnCacheDataDontLoad   // offline – iba cache

        // Ak už obrázok máme v URLCache → rovno ho zobraz
        if let cached = URLCache.shared.cachedResponse(for: request),
           let img = UIImage(data: cached.data) {
            eventImageView.image = img
            return
        }
        // V offline režime tu končíme (nemáme čo sťahovať)
        guard NetworkMonitor.shared.isConnected else { return }

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self,
                  let data = data,
                  let img = UIImage(data: data),
                  error == nil else { return }

            // Ulož do URLCache
            if let response = response {
                URLCache.shared.storeCachedResponse(
                    CachedURLResponse(response: response, data: data), for: request)
            }
            DispatchQueue.main.async {
                self.eventImageView.image = img
            }
        }.resume()
    }
    
    
    @IBAction func ChangeDateButton(_ sender: UIButton) {
        // check
        print("→ tapped, isAdmin=\(isAdmin)")

        guard ensureOnline(), isAdmin, let event = event else { return }

        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .dateAndTime
        if #available(iOS 14.0, *) {
            datePicker.preferredDatePickerStyle = .wheels
        }

        let alert = UIAlertController(title: "Zmeniť dátum",
                                      message: "\n\n\n\n\n\n",
                                      preferredStyle: .actionSheet)
        alert.view.addSubview(datePicker)
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            datePicker.leadingAnchor.constraint(equalTo: alert.view.leadingAnchor, constant: 8),
            datePicker.trailingAnchor.constraint(equalTo: alert.view.trailingAnchor, constant: -8),
            datePicker.topAnchor.constraint(equalTo: alert.view.topAnchor, constant: 40),
            datePicker.heightAnchor.constraint(equalToConstant: 150)
        ])

        alert.addAction(.init(title: "Zrušiť", style: .cancel))
        alert.addAction(.init(title: "OK", style: .default) { _ in
            // 1) získame nový dátum z datePickeru
            let newDate = datePicker.date

            // 2) formátujeme ho do labelu
            let formatter = DateFormatter()
            formatter.dateFormat = "dd.MM.yyyy HH:mm"
            self.dateLabel.text = formatter.string(from: newDate)

            // 3) prevedieme na Firebase Timestamp a updatneme dokument
            let timestamp = Timestamp(date: newDate)
            Firestore.firestore()
                .collection("Events")
                .document(event.eventId)
                .updateData(["Date": timestamp]) { error in
                    if let error = error {
                        self.showAlert(
                            title: "Chyba",
                            message: "Nepodarilo sa zmeniť dátum: \(error.localizedDescription)"
                        )
                    } else {
                        self.showAlert(
                            title: "Úspech",
                            message: "Dátum bol úspešne zmenený."
                        )
                    }
            }
        })


        // **!!! Pridaj toto, aby sa actionSheet nestrhol na iPade:**
        if let pop = alert.popoverPresentationController {
            pop.sourceView = Change_Date_Button
            pop.sourceRect = Change_Date_Button.bounds
        }

        present(alert, animated: true)
    }


    
    private func updateDateEditingUI() {
        Change_date_pencil.isHidden = !isAdmin
        Change_date_pencil.isUserInteractionEnabled = isAdmin
        Change_Date_Button.isHidden = !isAdmin
        Change_Date_Button.isUserInteractionEnabled = isAdmin
    }
}





// MARK: - Asynchronous Image Loading
extension UIImageView {
    /// Asynchronously downloads and sets an image from  URL string - Storage firebase
    func loadFrom(urlString: String) {
        guard let url = URL(string: urlString) else { return }
        DispatchQueue.global().async { [weak self] in
            if let data = try? Data(contentsOf: url),
               let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self?.image = image
                }
            }
        }
    }
}
