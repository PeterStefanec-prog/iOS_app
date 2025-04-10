//
//  MainViewController.swift
//  MlynyHub
//
//  Created by Peter Štefanec on 01/03/2025.
//


import UIKit
import FirebaseAuth
import FirebaseFirestore

class AllEventsViewController: UIViewController {

    @IBOutlet weak var Event_table_view: UITableView!
    
    
    //pole eventov na testovanie
    var events :[Event_entry] = []
    
    
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
extension AllEventsViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return events.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Reusable_cell", for: indexPath) as! Event_cell
        let event = events[indexPath.row]
        cell.Event_name.text = event.Title

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
            // Zachová len prvý prvok (logo), ale odstráni všetky eventy
            //let logo_event = Event_entry(Title: "Lobogo", Description: "", max_slots: 0, filled_slots: 0, Date: "")
            for document in querySnapshot!.documents {
                let data = document.data()
                let title = data["Title"] as? String ?? "Bez názvu"
                let description = data["Description"] as? String ?? ""
                let maxSlots = data["Participant slots"] as? Int ?? 0
                let filledSlots = data["Filled slots"] as? Int ?? 0
                let dateTimestamp = data["Date"] as? Timestamp
                let dateString = dateTimestamp?.dateValue().description ?? ""
                let image_url_storage = data["ImageURL"] as? String ?? ""

                let event = Event_entry(Title: title, Description: description, max_slots: maxSlots, filled_slots: filledSlots, Date: dateString, Image_url: image_url_storage)
                self.events.append(event)
            }
            print (self.events.count)
            // Aktualizuj tabuľku
            DispatchQueue.main.async {
                self.Event_table_view.reloadData()
            }
        }
    }




    
}
extension AllEventsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print (indexPath.row)
    }
}


extension UIImageView {
    func loadFrom(urlString: String) {
        guard let url = URL(string: urlString) else { return }
        DispatchQueue.global().async { [weak self] in
            if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self?.image = image
                }
            }
        }
    }
}
