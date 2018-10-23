//
//  AccountSettingsViewController.swift
//  shopping
//
//  Created by Austin Teague on 7/19/18.
//  Copyright © 2018 Austin Teague. All rights reserved.
//

import UIKit
import RealmSwift
import FirebaseAuth
import FirebaseStorage
import Crashlytics
import Alamofire
import AlamofireImage
import SVProgressHUD
import Hex
import CropViewController

class AccountSettingsViewController: UIViewController {

    let realm = try! Realm(configuration: SyncConfiguration.automatic())
    var user: Results<User>?
    var userSubscription: SyncSubscription<User>!
    var userSubscriptionToken: NotificationToken?
    
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var userEmailLabel: UILabel!
    @IBOutlet weak var userAvatar: UIImageView!
    var imagePicker : UIImagePickerController!

    override func viewDidLoad() {
        super.viewDidLoad()

        user = realm.objects(User.self).filter("id == %@", SyncUser.current?.identity ?? "")
        if let user = user {
            userSubscription = user.subscribe()
            userSubscriptionToken = userSubscription.observe(\.state, options: .initial) { state in
                if state == .complete {
                    self.setupUser()
                }
            }
        }

        let imageTap = UITapGestureRecognizer(target: self, action: #selector(openImagePicker))
        userAvatar.isUserInteractionEnabled = true
        userAvatar.addGestureRecognizer(imageTap)
        userAvatar.clipsToBounds = true
        userAvatar.layer.cornerRadius = 50.0
        imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
    }

    deinit {
        userSubscriptionToken?.invalidate()
    }

    func setupUser() {
        if let currentUser = user?.first {
            userNameLabel.text = currentUser.name
            userEmailLabel.text = currentUser.email
            if let imageURL = currentUser.avatar {
                ImageService.getImage(withURL: URL(string: imageURL)!) { (avatar) in
                    if let avatar = avatar {
                        self.userAvatar.image = avatar
                    } else {
                        print("\n\nUnable to attach user avatar...")
                        self.userAvatar.image = #imageLiteral(resourceName: "logo")
                    }
                }
            } else {
                userAvatar.image = #imageLiteral(resourceName: "logo")
            }
        }
    }

    @objc func openImagePicker(_ sender: Any) {
        self.present(imagePicker, animated: true, completion: nil)
    }

    func uploadAvatar(avatar: UIImage, completion: @escaping ((_ url : String?) -> ())) {
        guard let uid = SyncUser.current?.identity else { return }
        let storageRef = Storage.storage().reference().child("avatars/\(uid)")
        guard let imageData = avatar.jpegData(compressionQuality: 0.75) else { return }
        let metaData = StorageMetadata()
        metaData.contentType = "image/jpg"
    
        storageRef.putData(imageData, metadata: metaData) { (meta, error) in
            if error == nil, meta != nil {
                if let meta = meta {
                    let url = "gs://" + meta.bucket + "/" + meta.path!
                    completion(url)
                } else {
                    completion(nil)
                }
            } else {
                completion(nil)
            }
        }
    }

    @IBAction func editButtonPressed(_ sender: Any) {
        var textField = UITextField()
        let alert = UIAlertController(title: "Your Name:", message: "", preferredStyle: .alert)
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let action = UIAlertAction(title: "Update", style: .default) { (action) in
            self.userNameLabel.text = textField.text!
            do {
                try self.realm.write {
                    self.user?.first?.name = textField.text!
                }
            } catch {
                Crashlytics.sharedInstance().recordError(error)
                print(error.localizedDescription)
            }
        }
        
        alert.addTextField { (alertTextField) in
            alertTextField.placeholder = "Name"
            if let user = self.user?.first {
                alertTextField.text = user.name
            }
            textField = alertTextField
        }
        
        alert.addAction(cancel)
        alert.addAction(action)
        
        present(alert, animated: true, completion: nil)
    }

    @IBAction func logoutButtonPressed(_ sender: Any) {
        let alertController = UIAlertController(title: "Are you sure?", message: "", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Yes, Logout", style: .destructive, handler: {
            alert -> Void in
            SVProgressHUD.show()
            SyncUser.current?.logOut()
            self.presentingViewController?.dismiss(animated: true, completion: {
                SVProgressHUD.dismiss()
            })
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
}

extension AccountSettingsViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true) {
            if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                let cropVc = CropViewController(image: image)
                cropVc.delegate = self
                cropVc.aspectRatioPreset = CropViewControllerAspectRatioPreset.presetSquare
                cropVc.aspectRatioLockEnabled = true
                cropVc.aspectRatioPickerButtonHidden = true
                self.present(cropVc, animated: true, completion: nil)
            }
        }
    }
}

extension AccountSettingsViewController: CropViewControllerDelegate {
    func cropViewController(_ cropViewController: CropViewController, didCropToImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
        let imageSize : CGSize = CGSize(width: 300, height: 300)
        let updatedAvatar = self.resizeImage(image: image, targetSize: imageSize)
        uploadAvatar(avatar: updatedAvatar) { (data) in
            if data != nil, let user = self.user?.first {
                do {
                    try self.realm.write {
                        user.avatar = data
                    }
                    self.userAvatar.image = image
                } catch {
                    Crashlytics.sharedInstance().recordError(error)
                    print(error.localizedDescription)
                }
            }
        }
        cropViewController.dismiss(animated: true, completion: nil)
    }
}

extension UIViewController {
  func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
    let size = image.size

    let widthRatio  = targetSize.width  / size.width
    let heightRatio = targetSize.height / size.height

    // Figure out what our orientation is, and use that to form the rectangle
    var newSize: CGSize
    if(widthRatio > heightRatio) {
      newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
    } else {
      newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
    }

    // This is the rect that we've calculated out and this is what is actually used below
    let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)

    // Actually do the resizing to the rect using the ImageContext stuff
    UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
    image.draw(in: rect)
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    return newImage!
  }
}
