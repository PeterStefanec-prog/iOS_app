//
//  Pick_location_controller.swift
//  MlynyHub
//
//  Created by Andrej Kazimir on 20/03/2025.
//

import UIKit
import MapKit
import CoreLocation

protocol LocationPickerDelegate: AnyObject {
    func didSelectLocation(latitude: Double, longitude: Double, address: String)
}

class Pick_location_controller: UIViewController, MKMapViewDelegate, UISearchBarDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var Map_view: MKMapView!
    @IBOutlet weak var Address_search_bar: UISearchBar!
    @IBOutlet weak var Change_map_label: UIButton!
    
    let locationManager = CLLocationManager()
    //delegate podla toho kto to poslal (Add_event_controller)
    weak var delegate: LocationPickerDelegate?
    
    var selectedLatitude: Double?
    var selectedLongitude: Double?
    var selectedAddress: String?  // 🔥 Nová premenná na adresu

    override func viewDidLoad() {
        super.viewDidLoad()

        Map_view.delegate = self
        Address_search_bar.delegate = self
        locationManager.delegate = self

        Map_view.showsUserLocation = true
        
        //long press robi pin
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(didLongPress(_:)))
        Map_view.addGestureRecognizer(longPressGesture)
        
        //lokacia
        requestLocationPermission()
        //ak dal lokaciu, mapa sa otvori zoomnuta na jeho lokaciu
        if let userLocation = locationManager.location?.coordinate {
            zoomToLocation(coordinate: userLocation)
        } else {
            locationManager.requestLocation()
        }
    }
    
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    @IBAction func useCurrentLocation(_ sender: UIButton) {
        locationManager.requestLocation()
    }
    
    
    //ukazovatel aktualnej polohy
    @objc func locationManager(_ manager: CLLocationManager,
                               didUpdateLocations locations: [CLLocation]) {
        guard let coord = locations.last?.coordinate else { return }
        DispatchQueue.main.async {
            self.getAddressFromCoordinates(coord) { address in
                self.addPin(at: coord, address: address)
            }
        }
    }


    
    @objc func locationManager(_ manager: CLLocationManager,
                               didFailWithError error: Error) {
        print("Chyba pri získavaní polohy: \(error.localizedDescription)")
    }
    
    //long press prida pin a vrati coordinacie
    @objc func didLongPress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            let touchPoint = gesture.location(in: Map_view)
            let coordinate = Map_view.convert(touchPoint, toCoordinateFrom: Map_view)
            
            getAddressFromCoordinates(coordinate) { [weak self] address in
                guard let self = self else { return }
                self.addPin(at: coordinate, address: address)
            }
        }
    }
    //vyhladavanie podla adresy
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        Address_search_bar.resignFirstResponder()
        if let address = Address_search_bar.text {
            geocodeAddress(address)
        }
    }
    //Ziskava z adresy geokod
    func geocodeAddress(_ address: String) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address) { [weak self] placemarks, error in
            guard
                let self = self,
                let location = placemarks?.first?.location
            else { return }

            let coordinate = location.coordinate
            DispatchQueue.main.async {
                self.addPin(at: coordinate, address: address)
                let region = MKCoordinateRegion(center: coordinate,
                                                latitudinalMeters: 500,
                                                longitudinalMeters: 500)
                self.Map_view.setRegion(region, animated: true)
            }
        }
    }

    //získava z geokodu adresu
    func getAddressFromCoordinates(_ coordinate: CLLocationCoordinate2D,
                                   completion: @escaping (String) -> Void) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(CLLocation(latitude: coordinate.latitude,
                                                   longitude: coordinate.longitude)) { placemarks, error in
            let address: String
            if let placemark = placemarks?.first {
                address = [placemark.name,
                           placemark.thoroughfare,
                           placemark.locality,
                           placemark.administrativeArea,
                           placemark.country]
                          .compactMap { $0 }
                          .joined(separator: ", ")
            } else {
                address = "Neznáma adresa"
            }

            DispatchQueue.main.async {
                completion(address)
            }
        }
    }


    func addPin(at coordinate: CLLocationCoordinate2D, address: String) {
        Map_view.removeAnnotations(Map_view.annotations)

        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = address
        Map_view.addAnnotation(annotation)
        //ulozenie suradnic do class premennych
        selectedLatitude = coordinate.latitude
        selectedLongitude = coordinate.longitude
        selectedAddress = address

        //print("Vybraný bod: \(coordinate.latitude), \(coordinate.longitude) - Adresa: \(address)")
    }
    
    @IBAction func Done_button(_ sender: UIButton) {
        //odosielanie data naspat k delegatovi
        if let latitude = selectedLatitude, let longitude = selectedLongitude, let address = selectedAddress {
            delegate?.didSelectLocation(latitude: latitude, longitude: longitude, address: address)
            //print(" Odosielam: \(latitude), \(longitude) - \(address)")
        }
        dismiss(animated: true, completion: nil)
    }
    
    //zmena mapy medzi standardnou a satelitnou
    @IBAction func Change_map_view(_ sender: UIButton) {
        if Map_view.mapType == .standard {
            Map_view.mapType = .satellite
            Change_map_label.setTitle("Standard", for: .normal)
        } else {
            Map_view.mapType = .standard
            Change_map_label.setTitle("Satellite", for: .normal)
        }
    }
    //zoom
    func zoomToLocation(coordinate: CLLocationCoordinate2D) {
        let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 500, longitudinalMeters: 500)
        Map_view.setRegion(region, animated: true)
    }
}
