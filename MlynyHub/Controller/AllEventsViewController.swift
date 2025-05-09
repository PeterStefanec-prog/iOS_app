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
    
    // image cache
    private let imageCache = NSCache<NSString, UIImage>()
    
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
        cell.Event_location.text = addressCache[key] ?? "Načítavam…"
            
        
        // ***************  IMAGE  *************
        guard !event.Image_url.isEmpty,
              let url = URL(string: event.Image_url)
        else { return cell }

        let cacheKey = event.Image_url as NSString

        // 1) gete ready request with cache
        var request = URLRequest(url: url)
        request.cachePolicy = .returnCacheDataElseLoad
        request.timeoutInterval = 60

        let task = URLSession.shared.dataTask(with: request) { [weak self, weak tableView] data, response, error in
            guard
              let self = self,
              let data = data,
              let image = UIImage(data: data),
              error == nil
            else { return }

            // 2) save to in-mem cache
            self.imageCache.setObject(image, forKey: cacheKey)

            // 3) save downloaded images to URLCache (disk)
            if let response = response {
              URLCache.shared.storeCachedResponse(
                CachedURLResponse(response: response, data: data),
                for: request
              )
            }

            DispatchQueue.main.async {
              if let currentCell = tableView?
                .cellForRow(at: indexPath) as? Event_cell {
                currentCell.Event_image.image = image
              }
            }
        }
        task.resume()
        
        cell.selectionStyle = .none
        return cell
    }
    
    func fetchEvents() {
        let db = Firestore.firestore()
        db.collection("Events")
          .order(by: "Date", descending: false)
          .addSnapshotListener { [weak self] querySnapshot, error in
            guard let self = self else { return }
            if let error = error {
              print("Chyba pri načítaní eventov: \(error.localizedDescription)")
              return
            }
            guard let documents = querySnapshot?.documents else { return }
            
            // load events into array
            let df = DateFormatter()
            df.dateStyle = .medium
            df.timeStyle = .short
            
            

              self.events = documents.map { doc in
                  let data = doc.data()
                  // Timestamp - String
                  var dateString = ""
                  if let ts = data["Date"] as? Timestamp {
                      dateString = df.string(from: ts.dateValue())
                  }
                  // Location pole - lat, lon
                  let loc = data["Location"] as? [Double] ?? []
                  let latitude  = loc.count > 0 ? loc[0] : 0
                  let longitude = loc.count > 1 ? loc[1] : 0

                  return Event_entry(
                      eventId: doc.documentID,
                      Title: data["Title"] as? String ?? "Bez názvu",
                      Description: data["Description"] as? String ?? "",
                      max_slots: data["Participant slots"] as? Int ?? 0,
                      filled_slots: data["Filled slots"] as? Int ?? 0,
                      Date: dateString,
                      Image_url: data["ImageURL"] as? String ?? "",
                      latitude: latitude,
                      longitude: longitude
                  )
              }

              // 2) One-time reverse-geocode for everu unique suradnice
              let uniqueKeys = Set(self.events.map { "\($0.latitude),\($0.longitude)" })
              for key in uniqueKeys {
                  // reteazec na lan a lon
                  let parts = key.split(separator: ",")
                  guard parts.count == 2,
                        let lat = Double(parts[0]),
                        let lon = Double(parts[1]) else { continue }

                  let loc = CLLocation(latitude: lat, longitude: lon)
                  // 👇 create a brand-new geocoder for *this* request
                  CLGeocoder().reverseGeocodeLocation(loc) { placemarks, error in
                      guard let placemark = placemarks?.first, error == nil else { return }
                              
                      let comps: [String?] = [
                          placemark.thoroughfare,      // ulica
                          placemark.subThoroughfare,   // cislo domu
                          placemark.locality           // mesto
                      ]
                      let address = comps.compactMap { $0 }.joined(separator: ", ")
                      // uloz do cache
                      self.addressCache[key] = address

                      // find every line which use this key and reload it
                      let indexPaths = self.events.enumerated()
                        .filter { "\($0.element.latitude),\($0.element.longitude)" == key }
                        .map { IndexPath(row: $0.offset, section: 0) }

                      DispatchQueue.main.async {
                          self.Event_table_view.reloadRows(at: indexPaths, with: .automatic)
                      }
                  }
              }

              // 3) global reload of data
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
                
                // send event model
                let selectedEvent = events[indexPath.row]
                detailVC.event = selectedEvent

                // get image and send it
                if let cell = Event_table_view.cellForRow(at: indexPath) as? Event_cell {
                    detailVC.passedImage = cell.Event_image.image
                }
                
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
