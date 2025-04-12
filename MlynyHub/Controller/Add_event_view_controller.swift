//
//  Add_event_view_controller.swift
//  MlynyHub
//
//  Created by Andrej Kazimir on 19/03/2025.
//

import UIKit
import FirebaseFirestore
import FirebaseStorage
import MapKit
import FirebaseAuth

class Add_event_view_controller: UIViewController {

    @IBOutlet weak var Participant_slots_input: UILabel!
    @IBOutlet weak var Event_title_input: UITextField!
    @IBOutlet weak var Description_title_input: UITextField!
    @IBOutlet weak var Event_participants_stepper: UIStepper!
    @IBOutlet weak var Event_date_input: UIDatePicker!
    
    // outlet pre image pri vytvarani eventu
    @IBOutlet weak var eventImageView: UIImageView!
    
    var selectedLatitude: Double?
    var selectedLongitude: Double?
    
    // selected image in variable
    var selectedImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //restrikcie pre pocet ucastnikov
        Event_participants_stepper.minimumValue = 2
        Event_participants_stepper.maximumValue = 100
        Event_participants_stepper.stepValue = 1
        Event_participants_stepper.value = 5
    }
    
    //pocet sa meni
    @IBAction func Stepper_value_changed(_ sender: UIStepper) {
        Participant_slots_input.text = "\(Int(sender.value))"
    }
    
    // MARK: - User clicked on select image
    @IBAction func select_image(_ sender: UIButton) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary  // or .camera
        present(imagePicker, animated: true, completion: nil)
    }
    
    // MARK: - Create Event Action
    @IBAction func Create_event_button(_ sender: UIButton) {
        // guard - if condition is not true then it instantly executes else { } block
        guard let title = Event_title_input.text, !title.isEmpty,
              let description = Description_title_input.text, !description.isEmpty,
              let participantSlotsText = Participant_slots_input.text, !participantSlotsText.isEmpty,
              let participantSlots = Int(participantSlotsText),
              let longitude = selectedLongitude,
              let latitude = selectedLatitude,
              let image = selectedImage
        else {
            showAlert(title: "Chýbajúce vlastnosti eventu",
                      message: "Doplň vlastnosti eventu. Musí obsahovať názov, popis, počet účastníkov, dátum, miesto a fotografiu!")
            return
        }
        
        // is user logged in?? Save him in variable currentUser
        guard let currentUser = Auth.auth().currentUser else {
            showAlert(title: "Chyba", message: "Používateľ nie je prihlásený. Prihláste sa a skúste to znova.")
            return
        }
        
        // date saved
        let eventDate = Event_date_input.date
        
        // Debug prints
        print("Title: \(title)")
        print("Description: \(description)")
        print("Participants: \(participantSlots)")
        print("Date: \(eventDate)")
        
        // uploading image - if image uploaded and returned imageURL -> upload event in completion handler
        uploadImage(image) { [weak self] imageUrl in
            self?.uploadEvent(
                title: title,
                description: description,
                participantSlots: participantSlots,
                eventDate: eventDate,
                latitude: latitude,
                longitude: longitude,
                imageUrl: imageUrl,
                adminUser: currentUser
            )
        }
    }
    
    // Function to upload event data to Firestore after uploaded image to Storage properly - called after upload image succesfully
    private func uploadEvent(title: String,
                             description: String,
                             participantSlots: Int,
                             eventDate: Date,
                             latitude: Double,
                             longitude: Double,
                             imageUrl: String?,
                             adminUser: User) {
        let db = Firestore.firestore()
        
        // Create a reference by UID to the admin's document in the Users firebase collection
        let adminRef = db.collection("users").document(adminUser.uid)
        
        var eventData: [String: Any] = [
            "Title": title,
            "Description": description,
            "Participant slots": participantSlots,
            "Filled slots": 0,
            "Date": Timestamp(date: eventDate),
            "Location": [latitude, longitude],
            "Admin": adminRef
        ]
        
        if let image_Url = imageUrl {
            eventData["ImageURL"] = image_Url
        }
        
        // upload event to the database
        db.collection("Events").addDocument(data: eventData) { [weak self] error in
            if let error = error {
                print("Error adding document: \(error.localizedDescription)")
                self?.showAlert(title: "Chyba", message: "Nepodarilo sa vytvoriť event. Skús to znova.")
            } else {
                print("Event successfully added!")
                self?.showAlert(title: "Úspech", message: "Event bol úspešne vytvorený!")
                self?.resetForm()
            }
        }

    }
    
    // Function to upload an image to Firebase Storage
    private func uploadImage(_ image: UIImage, completion: @escaping (_ imageUrl: String?) -> Void) {
        // convert image
        guard let imageData = image.jpegData(compressionQuality: 0.6) else {
            print("Error compressing image.")
            completion(nil)
            return
        }
        
        // unique name - generates 128 bit identificator - that is why UUID does not need to be verified by storage - but shit may happen - later
        let imageName = UUID().uuidString
        
        let storageRef = Storage.storage().reference().child("event_images/\(imageName).jpg") // where to store data?
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg" // just for storage to know that it is jpeg
        
        storageRef.putData(imageData, metadata: metadata) { (_, error) in
            if let error = error {
                print("Error uploading image: \(error.localizedDescription)")
                self.showAlert(title: "Chyba", message: "Obrazok sa nepodarilo nahrat.")
                completion(nil) // for completion handler
                return
            }
            storageRef.downloadURL { url, error in
                if let error = error {
                    print("Error getting download URL: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                guard let downloadURL = url else {
                    completion(nil)
                    return
                }
                // return url to completion handler
                completion(downloadURL.absoluteString)
            }
        }
    }
    
    // MARK: - Opens map to choose location
    @IBAction func Open_map(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let locationVC = storyboard.instantiateViewController(withIdentifier: "Choose_map_location") as? Pick_location_controller {
            locationVC.delegate = self
            present(locationVC, animated: true)
        }
    }
    
    
    // MARK: - Reset function - reset forms in UI
    private func resetForm() {
        Event_title_input.text = ""
        Description_title_input.text = ""
        Event_participants_stepper.value = 5
        Participant_slots_input.text = "5"
        Event_date_input.date = Date()
        eventImageView.image = nil
        selectedImage = nil
        selectedLatitude = nil
        selectedLongitude = nil
    }
    
}

// MARK: - Start of extensions


// MARK: - UIImagePickerControllerDelegate, UINavigationControllerDelegate
extension Add_event_view_controller: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    // this function is called after user select the image
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        
        if let image = info[.originalImage] as? UIImage {
            selectedImage = image
            eventImageView.image = image
            print("Image selected")
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

// MARK: - LocationPickerDelegate
extension Add_event_view_controller: LocationPickerDelegate {
    func didSelectLocation(latitude: Double, longitude: Double, address: String) {
        self.selectedLatitude = latitude
        self.selectedLongitude = longitude
        print("Vybraná lokácia: \(latitude), \(longitude) - Adresa: \(address)")
    }
}
