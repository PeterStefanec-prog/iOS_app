//
//  Map_all_event_controller.swift
//  MlynyHub
//
//  Created by Andrej Kazimir on 21/03/2025.
//

import UIKit
import MapKit
import FirebaseFirestore

class Map_all_event_controller: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var Map_all_events: MKMapView!

    override func viewDidLoad() {
        super.viewDidLoad()

        Map_all_events.delegate = self
        Map_all_events.showsUserLocation = true

        // Načítanie eventov v reálnom čase
        loadEventPins()
    }

    // MARK: - Načítanie eventov
    func loadEventPins() {
        let db = Firestore.firestore()

        // V reálnom čase počúvame zmeny v kolekcii "Events"
        db.collection("Events").addSnapshotListener { snapshot, error in
            if let error = error {
                print("Chyba pri načítaní eventov: \(error.localizedDescription)")
                return
            }

            guard let documents = snapshot?.documents else { return }

            // Najskôr odstránime všetky staré piny
            self.Map_all_events.removeAnnotations(self.Map_all_events.annotations)

            // Prejdeme všetky dokumenty
            for document in documents {
                let data = document.data()
                let title = data["Title"] as? String ?? "Event"

                // Predpokladáme, že "Location" je pole [latitude, longitude]
                if let locationArray = data["Location"] as? [Double], locationArray.count == 2 {
                    let latitude = locationArray[0]
                    let longitude = locationArray[1]

                    // Vytvor MKPointAnnotation
                    let annotation = MKPointAnnotation()
                    annotation.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                    annotation.title = title

                    // Pridaj pin do mapy
                    self.Map_all_events.addAnnotation(annotation)
                }
            }

            // Automatický zoom na všetky piny
            self.Map_all_events.showAnnotations(self.Map_all_events.annotations, animated: true)
        }
    }
}
