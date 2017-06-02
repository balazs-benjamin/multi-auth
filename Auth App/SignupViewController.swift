//
//  SignupViewController.swift
//  FirebaseAuth
//
//  Created by mobile developer on 2017. 05. 25..
//  Copyright © 2017. Balazs Benjamin. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class SignupViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var tfFirstName: UITextField!
    @IBOutlet weak var tfLastName: UITextField!
    @IBOutlet weak var tfPassword: UITextField!
    @IBOutlet weak var tfConfirmPassword: UITextField!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var btnNext: UIButton!
    
    var strEmail:String = ""
    var strPhoneNumber:String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
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
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Create account with the email & password + phone number
    @IBAction func onSignup(_ sender: Any) {
        if validateInputValues() {
            guard let status = Network.reachability?.status else { return }
            if status == .unreachable {
                showAlert(viewController: self, strMsg: "Sorry, we couldn't complete your request. Please try again in a moment", focusItem: nil)
                return;
            }

            
            let firebaseAuth = Auth.auth()
            do {
                try firebaseAuth.signOut()
            } catch let signOutError as NSError {
                print ("Error signing out: %@", signOutError)
            }
            
            self.btnNext.isEnabled = false
            self.activityIndicator.isHidden = false
            Auth.auth().createUser(withEmail: strEmail, password: tfPassword.text!) { (user, error) in
                self.btnNext.isEnabled = true
                self.activityIndicator.isHidden = true
                if let err:Error = error {
                    showAlert(viewController:self, strMsg: err.localizedDescription, focusItem: nil)
                    return
                }
                
                let changeRequest = user!.createProfileChangeRequest()
                changeRequest.displayName = self.tfFirstName.text! + " " + self.tfLastName.text!
                changeRequest.commitChanges { error in
                    if error != nil {
                        // An error happened.
                    } else {
                        // Profile updated.
                    }
                }
                
                let now = Date()
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                
                let ref = Database.database().reference().child("users").child(user!.uid)
                let newUser = [
                    "First Name":self.tfFirstName.text!,
                    "Last Name":self.tfLastName.text!,
                    "Email":self.strEmail,
                    "Phone Number": self.strPhoneNumber,
                    "CreatedAt":dateFormatter.string(from: now)
                    ] as [String : Any]
                ref.setValue(newUser)
                
                let userDefaults = UserDefaults.standard
                userDefaults.set(user!.uid, forKey: "userid")
                userDefaults.set(self.tfFirstName.text! + " " + self.tfLastName.text!, forKey: "user_name")
                userDefaults.synchronize()
                
                self.performSegue(withIdentifier: "create_profile", sender: nil)
            }
 
        }
    }
    
    //Validate the input values
    func validateInputValues() -> Bool{
        if (tfFirstName.text?.isEmpty)! {
            showAlert(viewController:self, strMsg: "Please input your first name.", focusItem:tfFirstName)
            return false
        }

        if (tfLastName.text?.isEmpty)! {
            showAlert(viewController:self, strMsg: "Please input your last name.", focusItem:tfLastName)
            return false
        }

        if tfPassword.text != tfConfirmPassword.text {
            showAlert(viewController:self, strMsg: "Password and confirmation password do not match.", focusItem:tfPassword)
            return false
        }
        
        if !isValidPassword(value: tfPassword.text!) {
            showAlert(viewController:self, strMsg: "Password does not meet complexity requirements.", focusItem:tfPassword)
            return false
        }
        
        return true
    }
    
}
