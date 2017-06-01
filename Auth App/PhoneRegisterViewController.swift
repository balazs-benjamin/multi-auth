//
//  SignupScreen1.swift
//  Auth App
//
//  Created by mobile developer on 2017. 05. 26..
//  Copyright © 2017. Balazs Benjamin. All rights reserved.
//

import UIKit
import FirebaseAuth
import MICountryPicker
import FirebaseDatabase

extension String {
    var isPhoneNumber: Bool {
        do {
            let detector = try NSDataDetector(types: NSTextCheckingResult.CheckingType.phoneNumber.rawValue)
            let matches = detector.matches(in: self, options: [], range: NSMakeRange(0, self.characters.count))
            if let res = matches.first {
                return res.resultType == .phoneNumber && res.range.location == 0 && res.range.length == self.characters.count
            } else {
                return false
            }
        } catch {
            return false
        }
    }
}

class PhoneRegisterViewController: UIViewController, UITextFieldDelegate, MICountryPickerDelegate {
    let picker = MICountryPicker()
    
    @IBOutlet weak var tfCountryCode:UITextField!
    @IBOutlet weak var tfPhoneNumber: UITextField!
    @IBOutlet weak var phoneView: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var btnNext: UIButton!
    
    var dialCode = "" // My Dial Code
    var bDuplicated = false // Phone number/Email is duplicated
    var phoneNumber = ""
    var strEmail = ""
    
    var isFacebookVerify = false
    var credentialFB:AuthCredential?
    
    var databaseRef:DatabaseReference?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //Looks for single or multiple taps.
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        
        //Uncomment the line below if you want the tap not not interfere and cancel other interactions.
        //tap.cancelsTouchesInView = false
        
        view.addGestureRecognizer(tap)
        
        picker.delegate = self
        picker.showCallingCodes = true
        
        if let countryCode = (Locale.current as NSLocale).object(forKey: .countryCode) as? String {
            print(countryCode)
            let dialCode = getCountryPhonceCode(countryCode)
            tfCountryCode.text = "\(countryCode) \(dialCode)"
            self.dialCode = dialCode
        }
        
        activityIndicator.isHidden = true
    }
    
    //Calls this function when the tap is recognized.
    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    @IBAction func onChooseCountry(_ sender: Any) {
        navigationController?.pushViewController(picker, animated: true)
    }
    
    
    func countryPicker(_ picker: MICountryPicker, didSelectCountryWithName name: String, code: String) {
        print(code)
        picker.dismiss(animated: true) {
            
        }
    }
    
    func countryPicker(_ picker: MICountryPicker, didSelectCountryWithName name: String, code: String, dialCode: String) {
        print(dialCode)
        tfCountryCode.text = ("\(code) \(dialCode)")
        self.dialCode = dialCode
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func onNext(_ sender: Any) {
        guard let status = Network.reachability?.status else { return }
        if status == .unreachable {
            showAlert(viewController: self, strMsg: "Sorry, we couldn't complete your request. Please try again in a moment", focusItem: nil)
            return;
        }

        phoneNumber = dialCode+tfPhoneNumber.text!
        if !phoneNumber.isPhoneNumber {
            showAlert(viewController: self,strMsg: "Phone number is invalid.", focusItem:tfPhoneNumber)
            return
        }

        checkDuplicate()
    }
    
    // Check if the phone number is already associated with another account
    func checkDuplicate() {
        //self.sendCode()
        //return

        btnNext.isEnabled = false
        activityIndicator.isHidden = false

        bDuplicated = false
        databaseRef = Database.database().reference().child("users")
        databaseRef?.observe(DataEventType.value, with: { (snapshot) -> Void in
            // Email choosed
            print(snapshot.childrenCount) // I got the expected number of items
            let enumerator = snapshot.children
            while let rest = enumerator.nextObject() as? DataSnapshot {
                print(rest.value ?? "")
                if rest.hasChild("Phone Number") {
                    if let userDict = rest.value as? [String:AnyObject]{
                        let childPhone = userDict["Phone Number"] as! String
                        if childPhone == self.phoneNumber {
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
                showAlert(viewController: self, strMsg: "The phone number is already associated with another account", focusItem: self.tfPhoneNumber)
                self.btnNext.isEnabled = true
                self.activityIndicator.isHidden = true

            } else {
                self.sendCode()
            }
        })
        
        
    }
    
    // Send verification code to the phone number
    func sendCode() {
        PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber) { (verificationID: String?, error:Error?) in
            self.btnNext.isEnabled = true
            self.activityIndicator.isHidden = true

            if verificationID == nil {
                // Verification code not sent.
                print(error?.localizedDescription ?? "")
                showAlert(viewController: self, strMsg: (error?.localizedDescription)!, focusItem: nil)
            } else {
                // Successful.
                print(verificationID ?? "")
                
                UserDefaults.standard.set(verificationID, forKey: "phone_verification")
                UserDefaults.standard.synchronize()
                
                self.performSegue(withIdentifier: "phone_verify", sender: nil)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let dest:PhoneVerificationViewController = segue.destination as! PhoneVerificationViewController
        dest.strPhoneNumber = phoneNumber
        dest.strEmail = strEmail
        dest.isFacebookVerify = isFacebookVerify
        dest.credentialFB = credentialFB
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if let ref = databaseRef {
            ref.removeAllObservers()
        }
    }
}
