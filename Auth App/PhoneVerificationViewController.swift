//
//  PhoneVerificationViewController.swift
//  Auth App
//
//  Created by mobile developer on 2017. 05. 26..
//  Copyright © 2017. Balazs Benjamin. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import FBSDKLoginKit

class PhoneVerificationViewController: UIViewController {
    
    @IBOutlet weak var tfCode: UITextField!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var btnNext: UIButton!
    
    var strPhoneNumber: String = ""
    var strEmail = ""
    var isFacebookVerify = false
    var credentialFB:AuthCredential?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name:NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name:NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        //Looks for single or multiple taps.
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        
        //Uncomment the line below if you want the tap not not interfere and cancel other interactions.
        //tap.cancelsTouchesInView = false
        
        view.addGestureRecognizer(tap)
        
        activityIndicator.isHidden = true
    }
    
    //Calls this function when the tap is recognized.
    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    func keyboardWillShow(notification:NSNotification){
        //give room at the bottom of the scroll view, so it doesn't cover up anything the user needs to tap
        var userInfo = notification.userInfo!
        var keyboardFrame:CGRect = (userInfo[UIKeyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue
        keyboardFrame = self.view.convert(keyboardFrame, from: nil)
        
        var contentInset:UIEdgeInsets = self.scrollView.contentInset
        contentInset.bottom = keyboardFrame.size.height
        self.scrollView.contentInset = contentInset
    }
    
    func keyboardWillHide(notification:NSNotification){
        var contentInset:UIEdgeInsets = UIEdgeInsets.zero
        contentInset.top = (self.navigationController?.navigationBar.frame.size.height)!
        self.scrollView.contentInset = contentInset
    }
    
    
    // Verify the phone number with PIN Code sent with sms
    @IBAction func onVerify(_ sender: Any) {
        if (tfCode.text?.isEmpty)! {
            showAlert(viewController:self, strMsg: "Please enter the 6-digit code we sent to your phone number \(strPhoneNumber)", focusItem: tfCode)
            return
        }

        if tfCode.text?.characters.count != 6 {
            showAlert(viewController:self, strMsg: "Please Enter the 6-digit code we sent to your phone number \(strPhoneNumber)", focusItem: tfCode)
            return
        }
        
        guard let status = Network.reachability?.status else { return }
        if status == .unreachable {
            showAlert(viewController: self, strMsg: "Sorry, we couldn't complete your request. Please try again in a moment", focusItem: nil)
            return;
        }

        
        let verificationID = UserDefaults.standard.string(forKey: "phone_verification")
        let credential = PhoneAuthProvider.provider().credential(withVerificationID: verificationID!, verificationCode: tfCode.text!)
        
        btnNext.isEnabled = false
        activityIndicator.isHidden = false
        
        Auth.auth().signIn(with: credential) { (user, err) in
            if (err != nil) {
                showAlert(viewController: self, strMsg: (err?.localizedDescription)!, focusItem: self.tfCode)
                self.btnNext.isEnabled = true
                self.activityIndicator.isHidden = true
            
            } else {
                // Successful.
                // User is signed in.
                // This should display the phone number.
                print("Phone number: %@", user?.phoneNumber ?? "");
                // Get the phone number provider.
                let userInfo = user?.providerData[0];
                // The phone number provider UID is the phone number itself.
                print("Phone provider uid: %@", userInfo?.uid ?? "");
                // The phone number providerID is 'phone'
                print("Phone provider ID: %@", userInfo?.providerID ?? "");
                
                let userDefaults = UserDefaults.standard
                userDefaults.set(user!.uid, forKey: "userid")
                userDefaults.synchronize()
                
                if self.isFacebookVerify {
                    let currentUser = Auth.auth().currentUser
                    
                    currentUser?.link(with: self.credentialFB!, completion: { (user, error) in
                        if let error = error {
                            showAlert(viewController:self, strMsg: error.localizedDescription, focusItem: self.tfCode)
                            self.btnNext.isEnabled = true
                            self.activityIndicator.isHidden = true
                            return;
                        }
                        
                        if (FBSDKAccessToken.current()) != nil {
                            FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "id, name, first_name, last_name, picture.type(large), email"]).start(completionHandler: { (connection, result, error) -> Void in
                                if (error != nil){
                                    showAlert(viewController: self, strMsg: (error?.localizedDescription)!, focusItem: nil)
                                    self.btnNext.isEnabled = true
                                    self.activityIndicator.isHidden = true
                                } else {
                                    print(result ?? "")
                                    guard let data = result as? [String:Any] else { return }
                                    
                                    let now = Date()
                                    let dateFormatter = DateFormatter()
                                    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                                    
                                    let fbID = data["id"] ?? ""
                                    let ref = Database.database().reference().child("users").child(user!.uid)
                                    let newUser = [
                                        "Facebook ID": data["id"] ?? "",
                                        "First Name": data["first_name"] ?? "",
                                        "Last Name": data["last_name"] ?? "",
                                        "Email": data["email"] ?? "",
                                        "Phone Number": self.strPhoneNumber,
                                        "picture": "http://graph.facebook.com/\(fbID)/picture?type=large",
                                        "CreatedAt":dateFormatter.string(from: now)
                                        ] as [String : Any]
                                    ref.setValue(newUser)
                                    
                                    let userDefaults = UserDefaults.standard
                                    userDefaults.set(user!.uid, forKey: "userid")
                                    userDefaults.synchronize()
                                    
                                    
                                    self.performSegue(withIdentifier: "toMain", sender: nil)
                                }
                            })
                        } else {
                            self.btnNext.isEnabled = true
                            self.activityIndicator.isHidden = true
                        }
                    })
                } else {
                    
                    self.btnNext.isEnabled = true
                    self.activityIndicator.isHidden = true
                    self.performSegue(withIdentifier: "signup", sender: nil)
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toMain" {
            
        } else {
            let vc:SignupViewController = segue.destination as! SignupViewController
            vc.strEmail = strEmail
            vc.strPhoneNumber = strPhoneNumber
        }
    }
}
