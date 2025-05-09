//
//  MyEventsViewController.swift
//  MlynyHub
//
//  Created by Peter Štefanec on 09/05/2025.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class MyEventsViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    var events: [Event_entry] = []
    
    // imageCache
    private let imageCache = NSCache<NSString, UIImage>()
    
    // so it will be updated instantly after I participate in event or create new one
    override func viewWillAppear(_ animated: Bool) {
      super.viewWillAppear(animated)
      fetchMyEvents()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate   = self
        tableView.register(
            UINib(nibName: "Event_cell", bundle: nil),
            forCellReuseIdentifier: "Reusable_cell"
        )
        fetchMyEvents()
    }
    
    func fetchMyEvents() {
        guard let user = Auth.auth().currentUser else { return }
        let db      = Firestore.firestore()
        let userRef = db.collection("users").document(user.uid)
        
        // participant query
        let partQ  = db.collection("Events")
            .whereField("Participants", arrayContains: user.uid)
        
        // admi quert
        let adminQ = db.collection("Events")
            .whereField("Admin", isEqualTo: userRef)
        
        let group = DispatchGroup()
        var docsSet = Set<String>()
        var loadedEvents: [Event_entry] = []
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle  = .short
        
        func handleSnapshot(_ snapshot: QuerySnapshot?) {
            snapshot?.documents.forEach { doc in
                guard !docsSet.contains(doc.documentID) else { return }
                docsSet.insert(doc.documentID)
                
                let data = doc.data()
                // MARK: – parsovanie presne ako v AllEventsViewController
                var dateString = ""
                if let ts = data["Date"] as? Timestamp {
                    dateString = df.string(from: ts.dateValue())
                }
                let loc = data["Location"] as? [Double] ?? []
                let latitude  = loc.count > 0 ? loc[0] : 0
                let longitude = loc.count > 1 ? loc[1] : 0
                
                let entry = Event_entry(
                    eventId:      doc.documentID,
                    Title:        data["Title"] as? String ?? "Bez názvu",
                    Description:  data["Description"] as? String ?? "",
                    max_slots:    data["Participant slots"] as? Int ?? 0,
                    filled_slots: data["Filled slots"] as? Int ?? 0,
                    Date:         dateString,
                    Image_url:    data["ImageURL"] as? String ?? "",
                    latitude:     latitude,
                    longitude:    longitude
                )
                loadedEvents.append(entry)
            }
        }
        
        // participant query
        group.enter()
        partQ.getDocuments { snap, _ in
            handleSnapshot(snap)
            group.leave()
        }
        
        // admin query
        group.enter()
        adminQ.getDocuments { snap, _ in
            handleSnapshot(snap)
            group.leave()
        }
        
        // once both done, update UI
        group.notify(queue: .main) {
            self.events = loadedEvents.sorted { $0.Date < $1.Date }
            self.tableView.reloadData()
        }
    }
}

// MARK: – DataSource + Delegate
extension MyEventsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tv: UITableView, numberOfRowsInSection section: Int) -> Int {
        return events.count
    }
    
    func tableView(_ tv: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tv.dequeueReusableCell(
            withIdentifier: "Reusable_cell",
            for: indexPath
        ) as! Event_cell
        let event = events[indexPath.row]
        
        // title + date
        cell.Event_name.text = event.Title
        cell.Event_date.text = event.Date
        
        // image loading (copy from AllEventsViewController)
        cell.Event_image.image = nil
        if !event.Image_url.isEmpty, let url = URL(string: event.Image_url) {
            let key = event.Image_url as NSString
            if let img = imageCache.object(forKey: key) {
                cell.Event_image.image = img
            } else {
                var req = URLRequest(url: url)
                req.cachePolicy = .returnCacheDataElseLoad
                URLSession.shared.dataTask(with: req) { [weak self, weak tv] data, _, _ in
                    guard let data = data, let img = UIImage(data: data) else { return }
                    self?.imageCache.setObject(img, forKey: key)
                    DispatchQueue.main.async {
                        if let visibleCell = tv?.cellForRow(at: indexPath) as? Event_cell {
                            visibleCell.Event_image.image = img
                        }
                    }
                }.resume()
            }
        }
        
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tv: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "Go_to_event_detail", sender: indexPath)
    }
}

// MARK: – Segue
extension MyEventsViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard
            segue.identifier == "Go_to_event_detail",
            let ip     = sender as? IndexPath,
            let detail = segue.destination as? Event_detail_controller
        else { return }
        
        let e = events[ip.row]
        detail.event = e
        if let cell = tableView.cellForRow(at: ip) as? Event_cell {
            detail.passedImage = cell.Event_image.image
        }
    }
}
