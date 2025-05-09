//
//  MainViewController.swift
//  MlynyHub
//
//  Created by Peter Štefanec on 01/03/2025.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import CoreLocation


class AllEventsViewController: UIViewController {

    @IBOutlet weak var Event_table_view: UITableView!
    
    /// Geocoder a  in-memory cache na adresy
    private let geocoder = CLGeocoder()
    private var addressCache: [String: String] = [:]  // lat a lon bude klucom
    
    //pole eventov na testovanie
    var events: [Event_entry] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Event_table_view.dataSource = self
        Event_table_view.delegate = self
        //dolna lista setup - nesiel cez storyboard :(
        navigationItem.hidesBackButton = true
        Event_table_view.register(UINib(nibName: "Event_cell", bundle: nil), forCellReuseIdentifier: "Reusable_cell")
        fetchEvents()
    }
    
    // Logging out via firebase
    @IBAction func log_out_button_pressed(_ sender: UIBarButtonItem) {
        let firebaseAuth = Auth.auth()
        do {
          try firebaseAuth.signOut()
            // Go to the starting screen after logging out
//            navigationController?.popToRootViewController(animated: true)
            self.performSegue(withIdentifier: "log_out_segue", sender: self)
        } catch let signOutError as NSError {
            showAlert(title: "Error signing out", message: NSError.description())
            print("Error signing out: %@", signOutError)
        }
    }
}

//event_board
extension AllEventsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return events.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Reusable_cell", for: indexPath) as! Event_cell
        let event = events[indexPath.row]
        cell.Event_name.text = event.Title
        
        // cas
        cell.Event_date.text = event.Date
        
        
        // poloha (suradnice)
        // 1) kluc pre cache
        let key = "\(event.latitude),\(event.longitude)"
        
        if let cachedAddress = addressCache[key] {
            // 2a) ak yuz mame v  cache pouzijeme ho
            cell.Event_location.text = cachedAddress
        } else {
            // 2b) Inak spravime reverse geocode
            let location = CLLocation(latitude: event.latitude,
                                      longitude: event.longitude)
            geocoder.reverseGeocodeLocation(location) { [weak self, weak cell] placemarks, error in
                guard let self = self,
                      let placemark = placemarks?.first,
                      error == nil else {
                    DispatchQueue.main.async {
                        cell?.Event_location.text = "Unknown location"
                    }
                    return
                }
                // 3) zlozenie citatelnej adresy
                let parts: [String?] = [
                    placemark.thoroughfare,      // ulica
                    placemark.subThoroughfare,   // cislo
                    placemark.locality,          // mesto
                ]
                let address = parts.compactMap { $0 }.joined(separator: ", ")
                
                // 4) ulozime do cache a aktualizujeme cell
                self.addressCache[key] = address
                DispatchQueue.main.async {
                    cell?.Event_location.text = address
                }
            }
        }
            

        // Načítanie obrázka ak je k dispozícii
        if !event.Image_url.isEmpty {
            cell.Event_image.loadFrom(urlString: event.Image_url)
        } else {
            cell.Event_image.image = nil  // Alebo zobrazenie placeholder
        }
        
        cell.selectionStyle = .none
        return cell
    }
    
    func fetchEvents() {
        let db = Firestore.firestore()
        db.collection("Events").order(by: "Date", descending: false).addSnapshotListener { querySnapshot, error in
            if let error = error {
                print("Chyba pri načítaní eventov: \(error.localizedDescription)")
                return
            }
            self.events.removeAll()
            
            
            let df = DateFormatter()
            df.dateStyle = .medium
            df.timeStyle = .short
            
            
            for document in querySnapshot!.documents {
                let data = document.data()
                
                // 1) Timestamp - Date - String
                var dateString = ""
                if let ts = data["Date"] as? Timestamp {
                    dateString = df.string(from: ts.dateValue())
                }
                
                // 2) rozbalime lat, lon z Location pola
                let loc = data["Location"] as? [Double] ?? []
                let latitude  = loc.count > 0 ? loc[0] : 0
                let longitude = loc.count > 1 ? loc[1] : 0
                
                let title = data["Title"] as? String ?? "Bez názvu"
                let description = data["Description"] as? String ?? ""
                let maxSlots = data["Participant slots"] as? Int ?? 0
                let filledSlots = data["Filled slots"] as? Int ?? 0
                let image_url_storage = data["ImageURL"] as? String ?? ""


                // Create event by including the document id as eventId
                let event = Event_entry(
                    eventId: document.documentID,
                    Title: title,
                    Description: description,
                    max_slots: maxSlots,
                    filled_slots: filledSlots,
                    Date: dateString,
                    Image_url: image_url_storage,
                    latitude: latitude,
                    longitude: longitude
                )
                self.events.append(event)
            }
            print(self.events.count)
            DispatchQueue.main.async {
                self.Event_table_view.reloadData()
            }
        }
    }
    
    // MARK: send actual event to the Evetn_detail_controller
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Go_to_event_detail" {
            // 'sender' should be the indexPath passed from didSelectRowAt
            if let indexPath = sender as? IndexPath,
               let detailVC = segue.destination as? Event_detail_controller {
                
                let selectedEvent = events[indexPath.row]
                
                // Pass the event to the detail controller
                detailVC.event = selectedEvent
                print("Passing event to detail:", selectedEvent.Title)
            }
        }
    }

}

extension AllEventsViewController: UITableViewDelegate {
    // In didSelectRowAt
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("Selected event at row: \(indexPath.row)")
        // Call segue with the indexPath as sender
        performSegue(withIdentifier: "Go_to_event_detail", sender: indexPath)
    }
     
}





