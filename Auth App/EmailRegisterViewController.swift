//
//  EmailRegisterViewController.swift
//  Auth App
//
//  Created by mobile developer on 2017. 05. 26..
//  Copyright © 2017. Balazs Benjamin. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class EmailRegisterViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var tfEmail: UITextField!
    
    @IBOutlet weak var btnNext: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    var bDuplicated = false // Phone number/Email is duplicated
    
    var databaseRef:DatabaseReference?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
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
    
    @IBAction func onNext(_ sender: Any) {
        guard let status = Network.reachability?.status else { return }
        if status == .unreachable {
            showAlert(viewController: self, strMsg: "Sorry, we couldn't complete your request. Please try again in a moment", focusItem: nil)
            return;
        }
        
        if !isValidEmail(value: tfEmail.text!) {
            showAlert(viewController: self, strMsg: "Please enter a valid email.", focusItem: tfEmail)
            return
        }
        checkDuplicate()
    }
    
    // Check if the email is already associated with another acccount
    func checkDuplicate() {
        
        bDuplicated = false
        databaseRef = Database.database().reference().child("users")
        
        btnNext.isEnabled = false
        activityIndicator.isHidden = false
        
        databaseRef?.observe(DataEventType.value, with: { (snapshot) -> Void in
            // Email choosed
            print(snapshot.childrenCount) // I got the expected number of items
            let enumerator = snapshot.children
            while let rest = enumerator.nextObject() as? DataSnapshot {
                print(rest.value ?? "")
                if rest.hasChild("Email") {
                    if let userDict = rest.value as? [String:AnyObject]{
                        let childEmail = userDict["Email"] as! String
                        if childEmail == self.tfEmail.text! {
                            self.bDuplicated = true
                            break;
                        }
                    }
                }
                
            }
            
            if let ref = self.databaseRef {
                ref.removeAllObservers()
            }

            if self.bDuplicated {
                showAlert(viewController: self, strMsg: "The email address is already associated with another account", focusItem: self.tfEmail)
            } else {
                self.performSegue(withIdentifier: "phoneRegister", sender: nil)
            }
            
            self.btnNext.isEnabled = true
            self.activityIndicator.isHidden = true

        })
        
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let dest:PhoneRegisterViewController = segue.destination as! PhoneRegisterViewController
        dest.strEmail = tfEmail.text!
        dest.isFacebookVerify = false
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if let ref = databaseRef {
            ref.removeAllObservers()
        }
    }
}
