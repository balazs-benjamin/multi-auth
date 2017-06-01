//
//  ResetPasswordViewController.swift
//  Auth App
//
//  Created by mobile developer on 2017. 05. 29..
//  Copyright © 2017. Balazs Benjamin. All rights reserved.
//


import UIKit
import FirebaseAuth
import FirebaseDatabase

class ResetPasswordViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var tfEmail: UITextField!
    
    @IBOutlet weak var btnReset: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    var databaseRef:DatabaseReference?
    
    var isUserExist = false
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Looks for single or multiple taps.
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        
        //Uncomment the line below if you want the tap not not interfere and cancel other interactions.
        //tap.cancelsTouchesInView = false
        
        view.addGestureRecognizer(tap)
        
        btnReset.isEnabled = false
        tfEmail.delegate = self
        
        activityIndicator.isHidden = true
    }
    
    //Calls this function when the tap is recognized.
    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    func checkValidate () -> Bool{
        if !isValidEmail(value: tfEmail.text!) {
            showAlert(viewController:self, strMsg: "Please input valid email address", focusItem: tfEmail)
            return false
        }
        
        return true
    }
    
    // Send Reset Password link
    @IBAction func onResetPasswordWithEmail(_ sender: Any) {
        if checkValidate() {
            Auth.auth().sendPasswordReset(withEmail: self.tfEmail.text!) { error in
                if error == nil {
                    showAlert(viewController: self, strMsg: "Account Found, A Password reset link has been sent to your email address!", focusItem: nil)
                } else {
                    showAlert(viewController: self, strMsg: (error?.localizedDescription)!, focusItem: nil)
                }
                self.btnReset.isEnabled = true
                self.activityIndicator.isHidden = true
            }

        }
    }
    // enable/disable Reset button when fill or blank the email & password field
    @IBAction func onEmailChanged(_ sender: Any) {
        if !tfEmail.text!.isEmpty  {
            btnReset.isEnabled = true
        } else {
            btnReset.isEnabled = false
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if let ref = databaseRef {
            ref.removeAllObservers()
        }
    }
}
