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
            eventImageView.loadFrom(urlString: event.Image_url)     // assynchronously - defined later below
        }

        
        actionButton.layer.cornerRadius = 10
        actionButton.isHidden = true // hidden while we identify the state of event - full ..
        
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
        
        eventRef.getDocument { [weak self] snapshot, error in
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

    
    /// Deletes the event document from Firestore.
    private func deleteEvent() {
        guard let event = event else { return }
        let db = Firestore.firestore()
        let eventRef = db.collection("Events").document(event.eventId)
        eventRef.delete { [weak self] error in
            if let error = error {
                print("Error deleting event: \(error.localizedDescription)")
                return
            }
//            self?.showAlert(title: "Uspech", message: "Even uspesne vymazany.")
            print("Event successfully deleted.")
            // After deletion, navigate back to the previous screen.
            self?.navigationController?.popViewController(animated: true)

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
            if let error = error {
                print("Error joining event: \(error.localizedDescription)")
                return
            }
            self?.showAlert(title: "Uspech", message: "Uspesne ste sa prihlasili na event")
            print("Successfully joined the event.")
            // Re-fetch updated details so the UI gets refreshed.
            self?.fetchEventDetailsFromFirestore(eventId: event.eventId)
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
            self?.showAlert(title: "Uspesne odhlaseny.", message: "Urcite sa ale prihlaste na iny event ktory vam vyhovuje.")
            print("Successfully left the event.")
            // Re-fetch updated details so the UI gets refreshed.
            self?.fetchEventDetailsFromFirestore(eventId: event.eventId)
        }
    }
    
    
    // ZOBRAZOVANIE LOKACIE
    private func reverseGeocode(latitude: Double, longitude: Double) {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self,
                  let placemark = placemarks?.first,
                  error == nil else {
                DispatchQueue.main.async {
                    self?.eventLocation.text = "Neznáma poloha"
                }
                return
            }
            let parts: [String?] = [
                placemark.thoroughfare,      // ulica
                placemark.subThoroughfare,   // cislo domu
                placemark.locality,          // mesto
            ]
            let address = parts.compactMap { $0 }.joined(separator: ", ")
            DispatchQueue.main.async {
                self.eventLocation.text = address
            }
        }
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
