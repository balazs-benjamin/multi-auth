//
//  ProfileViewController.swift
//  Auth App
//
//  Created by mobile developer on 2017. 05. 26..
//  Copyright © 2017. Balazs Benjamin. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage

import FBSDKLoginKit
import FacebookCore
import FacebookLogin
import SDWebImage


extension Date {
    var ticks: UInt64 {
        return UInt64((self.timeIntervalSince1970 + 62_135_596_800) * 10_000_000)
    }
}

class ProfileViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
 
    @IBOutlet weak var btnLinkFacebook: UIButton!
    var currentUser:User?
    @IBOutlet weak var imageView: UIImageView!
    var imagePicker: UIImagePickerController!
    @IBOutlet weak var btnNext: UIButton!
    @IBOutlet weak var btnTakePhoto: UIButton!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    var storageRef : StorageReference = StorageReference()
    
    var isPhotoTaken = false
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        currentUser = Auth.auth().currentUser
        
        activityIndicator.isHidden = true
        
        let ref = Database.database().reference().child("users").child(Auth.auth().currentUser!.uid)
        ref.observe(DataEventType.value, with: { (snapshot) -> Void in
            if snapshot.hasChild("picture") {
                if let userDict = snapshot.value as? [String:AnyObject]{
                    if let picture = userDict["picture"] as? String {
                        self.imageView.sd_setImage(with: URL(string: picture), placeholderImage: UIImage(named: "place_holder"))
                    }
                }
            }

        })
        
        self.navigationItem.setHidesBackButton(true, animated:true)
    }
    
    @IBAction func onTakePhoto(_ sender: Any) {
        imagePicker =  UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func onChooseFromGallery(_ sender: Any) {
        imagePicker =  UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        imagePicker.dismiss(animated: true, completion: nil)
        imageView.image = info[UIImagePickerControllerOriginalImage] as? UIImage
        isPhotoTaken = true
    }
    
    // Store the profile picture and goto main screen
    @IBAction func onNext(_ sender: Any) {
        guard let status = Network.reachability?.status else { return }
        if status == .unreachable {
            showAlert(viewController: self, strMsg: "Sorry, we couldn't complete your request. Please try again in a moment", focusItem: nil)
            return;
        }

        if imageView.image != nil, let uploadData = UIImageJPEGRepresentation(imageView.image!, 0.5) {
            let newMetadata = StorageMetadata()
            newMetadata.cacheControl = "public,max-age=300";
            newMetadata.contentType = "image/jpeg";
            
            let ticks = Date().ticks
            let uid = Auth.auth().currentUser!.uid
            storageRef = Storage.storage().reference().child("ProfilePictures/\(uid)/\(ticks).jpg")
            let uploadTask = storageRef.putData(uploadData, metadata: newMetadata) { snapshot, error in
                if let error = error {
                    print(error)
                }
            }
            
            btnNext.isEnabled = false
            activityIndicator.isHidden = false
            
            // Shows progress bar until saved
            uploadTask.observe(.progress) { snapshot in
                //progressBar1.observedProgress = snapshot.progress
            }
            
            uploadTask.observe(.success) { snapshot in
                if let profileImageURL = snapshot.metadata?.downloadURL()?.absoluteString {
                    let ref = Database.database().reference().child("users").child(Auth.auth().currentUser!.uid)
                    let values = [
                        "picture": profileImageURL,
                        ] as [String : Any]
                    ref.updateChildValues(values)

                }
                
                self.btnNext.isEnabled = true
                self.activityIndicator.isHidden = true

                self.performSegue(withIdentifier: "main", sender: nil)
            }
        }
    }
    
    // Link with Facebook account
    @IBAction func onLink(_ sender: Any) {
        
        guard let status = Network.reachability?.status else { return }
        if status == .unreachable {
            showAlert(viewController: self, strMsg: "Sorry, we couldn't complete your request. Please try again in a moment", focusItem: nil)
            return;
        }

        
        let loginManager = LoginManager()
        loginManager.logIn([ .publicProfile, .email, .userFriends ], viewController: self) { loginResult in
            switch loginResult {
            case .failed(let error):
                print(error)
                break
            case .cancelled:
                print("User cancelled login.")
                break
            case .success(let grantedPermissions, let declinedPermissions, let accessToken):
                print("Logged in! \(grantedPermissions)")
                print("Logged in! \(declinedPermissions)")
                let credential = FacebookAuthProvider.credential(withAccessToken: accessToken.authenticationToken)
                print(self.currentUser?.uid ?? "")
                self.currentUser?.link(with: credential, completion: { (user, error) in
                    if let error = error {
                        showAlert(viewController: self, strMsg: error.localizedDescription, focusItem: nil)
                        return;
                    }
                })
                self.getFBUserData()
                break
            }
        }
    }
    
    
    // Get Facebook ID and profile picture
    // Store facebook photo if user didn't take his profile picture.
    func getFBUserData(){
        if((FBSDKAccessToken.current()) != nil){
            FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "id, name, first_name, last_name, picture.type(large), email"]).start(completionHandler: { (connection, result, error) -> Void in
                if (error == nil){
                    guard let data = result as? [String:Any] else { return }
                    
                    let ref = Database.database().reference().child("users").child(Auth.auth().currentUser!.uid)
                    let userID = data["id"] as! String
                    
                    var values = [
                        "Facebook ID": data["id"] ?? "",
                        //"First Name": data["first_name"] ?? "",
                        //"Last Name": data["last_name"] ?? "",
                        //"Email": data["email"] ?? "",
                        "picture": "http://graph.facebook.com/\(userID)/picture?type=large",
                        ] as [String : Any]
                    if self.isPhotoTaken {
                        values = [
                            "Facebook ID": data["id"] ?? "",
                            ] as [String : Any]
                    }
                    ref.updateChildValues(values)
                }
            })
        }
    }

}
