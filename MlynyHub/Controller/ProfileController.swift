//
//  ProfileController.swift
//  MlynyHub
//
//  Created by Andrej Kazimir on 09/05/2025.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import PhotosUI
import FirebaseCrashlytics


class ProfileController: UIViewController {
    //outlets
    @IBOutlet weak var FacultyLabel: UILabel!
    @IBOutlet weak var UniversityLabel: UILabel!
    @IBOutlet weak var AboutMeLabel: UILabel!
    @IBOutlet weak var FirstNameLastNameLabel: UILabel!
    @IBOutlet weak var Profile_picture_image: UIImageView!
    @IBOutlet weak var UsernameLabel: UILabel!
    // Stub outlet to match storyboard connection
    @IBOutlet weak var Change_Username_Button: UIButton!

    private let db = Firestore.firestore()
    private var userRef: DocumentReference? {
        guard let uid = Auth.auth().currentUser?.uid else { return nil }
        return db.collection("users").document(uid)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Set default image if none
        Profile_picture_image.image = UIImage(named: "Default_pfp")
        setupProfileImageView()
        loadProfile()
    }
    //to be changed
    private func setupProfileImageView() {
        Profile_picture_image.layer.cornerRadius = Profile_picture_image.frame.width / 2
        Profile_picture_image.clipsToBounds = true
        Profile_picture_image.isUserInteractionEnabled = true
    }
    //loading profile from db
    private func loadProfile() {
        guard let ref = userRef else { return }
        ref.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self, let data = snapshot?.data(), error == nil else { return }
            //changing username…
            self.UsernameLabel.text = data["username"] as? String
            if let name = data["name"] as? String,
               let surname = data["surname"] as? String {
                self.FirstNameLastNameLabel.text = "\(name) \(surname)"
            }
            //changing aboutme…
            let aboutRaw = (data["aboutMe"] as? String)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let aboutVal = (aboutRaw?.isEmpty == false) ? aboutRaw! : "none"
            self.AboutMeLabel.text = "About me: \(aboutVal)"
            //changing uni…
            let uniRaw = (data["university"] as? String)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let uniVal = (uniRaw?.isEmpty == false) ? uniRaw! : "none"
            self.UniversityLabel.text = "University: \(uniVal)"
            //changing faculty…
            let facRaw = (data["faculty"] as? String)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let facVal = (facRaw?.isEmpty == false) ? facRaw! : "none"
            self.FacultyLabel.text = "Faculty: \(facVal)"
            //changing profile picture…
            if let urlString = data["profileImageURL"] as? String,
               let url = URL(string: urlString) {
                var req = URLRequest(url: url,
                                     cachePolicy: .returnCacheDataElseLoad,
                                     timeoutInterval: 60)
                URLSession.shared.dataTask(with: req) { data, response, _ in
                    if let data = data, let img = UIImage(data: data) {
                        if let resp = response {
                            let cached = CachedURLResponse(response: resp, data: data)
                            URLCache.shared.storeCachedResponse(cached, for: req)
                        }
                        DispatchQueue.main.async { self.Profile_picture_image.image = img }
                    } else {
                        DispatchQueue.main.async { self.Profile_picture_image.image = UIImage(named: "Default_pfp") }
                    }
                }.resume()
            } else {
                DispatchQueue.main.async { self.Profile_picture_image.image = UIImage(named: "Default_pfp") }
            }
        }
    }
    //changing profile picture
    @IBAction func ChangeProfilePicturePressed(_ sender: UIButton) {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
    //changing username
    @IBAction func ChangeUsernamePressed(_ sender: Any) {
        promptForField("username", title: "Zmeniť užívateľské meno", placeholder: "Nové užívateľské meno")
    }
    //changing aboutme
    @IBAction func ChangeAboutMePressed(_ sender: Any) {
        promptForField("aboutMe", title: "Zmeniť About Me", placeholder: "O mne...")
    }
    //changing uni
    @IBAction func ChangeUniversityPressed(_ sender: Any) {
        promptForField("university", title: "Zmeniť univerzitu", placeholder: "Univerzita")
    }
    //changing faculty
    @IBAction func ChangeFacultyPressed(_ sender: Any) {
        promptForField("faculty", title: "Zmeniť fakultu", placeholder: "Fakulta")
    }
    //function that reads text, changes db
    private func promptForField(_ key: String, title: String, placeholder: String) {
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alert.addTextField { tf in tf.placeholder = placeholder }
        alert.addAction(UIAlertAction(title: "Zrušiť", style: .cancel))
        alert.addAction(UIAlertAction(title: "Uložiť", style: .default) { _ in
            guard let text = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty,
                  let ref = self.userRef else { return }
            ref.updateData([key: text]) { error in
                if let e = error {
                    // Use existing UIViewController.showAlert extension
                    self.showAlert(title: "Chyba", message: e.localizedDescription)
                } else {
                    DispatchQueue.main.async {
                        switch key {
                        case "username": self.UsernameLabel.text = text
                        case "aboutMe": self.AboutMeLabel.text = "About me: \(text)"
                        case "university": self.UniversityLabel.text = "University: \(text)"
                        case "faculty": self.FacultyLabel.text = "Faculty: \(text)"
                        default: break
                        }
                    }
                }
            }
        })
        present(alert, animated: true)
    }

    //uploading pfp
    private func uploadProfileImage(_ image: UIImage) {
        guard let uid = Auth.auth().currentUser?.uid,
              let data = image.jpegData(compressionQuality: 0.5) else { return }
        let name = "profile_\(uid).jpg"
        let ref = Storage.storage().reference().child("profile_images/\(name)")
        let meta = StorageMetadata()
        meta.contentType = "image/jpeg"
        ref.putData(data, metadata: meta) { _, error in
            if let e = error {
                self.showAlert(title: "Chyba", message: e.localizedDescription)
                return
            }
            ref.downloadURL { url, _ in
                if let url = url, let r = self.userRef {
                    r.updateData(["profileImageURL": url.absoluteString])
                }
            }
        }
    }
    
    
    @IBAction func CrashAppButtonPressed(_ sender: UIButton) {
        //log
        Crashlytics.crashlytics().log("Crash button tapped in ProfileController")
        //logujeme meno
        if let username = UsernameLabel.text {
            Crashlytics.crashlytics().setCustomValue(username, forKey: "current_username")
        }
        //error
        fatalError("Test Crashlytics crash from CrashAppButtonPressed")
    }
}

// MARK: - PHPickerViewControllerDelegate
extension ProfileController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let item = results.first,
              item.itemProvider.canLoadObject(ofClass: UIImage.self) else { return }
        item.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] img, _ in
            guard let self = self, let image = img as? UIImage else { return }
            DispatchQueue.main.async {
                self.Profile_picture_image.image = image
            }
            self.uploadProfileImage(image)
        }
    }
}
