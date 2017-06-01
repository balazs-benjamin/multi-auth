//
//  ViewController.swift
//  Auth App
//
//  Created by mobile developer on 2017. 05. 25..
//  Copyright © 2017. Balazs Benjamin. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import FacebookCore
import FacebookLogin
import FBSDKLoginKit

class LoginViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var tfEmail: UITextField!
    @IBOutlet weak var tfPassword: UITextField!
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var btnLogin: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var databaseRef:DatabaseReference?
    
    var isUserExist = false
    
    var credentialFB:AuthCredential?
    
    var fbLinked = false
    var fbID = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        
        if Auth.auth().currentUser != nil {
            self.performSegue(withIdentifier: "main", sender: nil)
        }
        
        // Register observer for the keyboard show/hide
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name:NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name:NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        //Looks for single or multiple taps.
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        
        //Uncomment the line below if you want the tap not not interfere and cancel other interactions.
        //tap.cancelsTouchesInView = false
        
        view.addGestureRecognizer(tap)
        
        btnLogin.isEnabled = false
        tfEmail.delegate = self
        tfPassword.delegate = self
        
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

    // validate the input values
    func checkValidate () -> Bool{
        if !isValidEmail(value: tfEmail.text!) {
            showAlert(viewController:self, strMsg: "Please input valid email address", focusItem: tfEmail)
            return false
        }
        
        if (tfPassword.text?.isEmpty)! {
            showAlert(viewController:self, strMsg: "Please input password", focusItem: tfPassword)
            return false
        }
        return true
    }
    
    // Login with email and password
    @IBAction func onLoginWithEmail(_ sender: Any) {
        if checkValidate() {
            guard let status = Network.reachability?.status else { return }
            if status == .unreachable {
                showAlert(viewController: self, strMsg: "Sorry, unable to login. Please check your internet connection", focusItem: nil)
                return;
            }
            
            btnLogin.isEnabled = false
            activityIndicator.isHidden = false
            Auth.auth().signIn(withEmail: tfEmail.text!, password: tfPassword.text!) { (user, err) in
                if err != nil {
                    showAlert(viewController:self, strMsg: (err?.localizedDescription)!, focusItem: nil)
                    self.btnLogin.isEnabled = true
                    self.activityIndicator.isHidden = true
                } else {
                    let userDefaults = UserDefaults.standard
                    userDefaults.set(user!.uid, forKey: "userid")
                    userDefaults.synchronize()
                    
                    if self.fbLinked {
                        user?.link(with: self.credentialFB!, completion: { (user1, error) in
                            let ref = Database.database().reference().child("users").child(Auth.auth().currentUser!.uid)
                            let values = [
                                "Facebook ID": self.fbID,
                                ] as [String : Any]
                            ref.updateChildValues(values)

                            self.btnLogin.isEnabled = true
                            self.activityIndicator.isHidden = true
                            
                            self.performSegue(withIdentifier: "main", sender: nil)
                        })
                    } else {
                        self.btnLogin.isEnabled = true
                        self.activityIndicator.isHidden = true
                        self.performSegue(withIdentifier: "main", sender: nil)
                    }
                }
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // Login with Facebook
    @IBAction func onLoginWithFacebook(_ sender: Any) {
        guard let status = Network.reachability?.status else { return }
        if status == .unreachable {
            showAlert(viewController: self, strMsg: "Sorry, unable to login. Please check your internet connection", focusItem: nil)
            return;
        }

        self.btnLogin.isEnabled = false
        self.activityIndicator.isHidden = false

        let loginManager = LoginManager()
        loginManager.logIn([ .publicProfile, .email, .userFriends ], viewController: self) { loginResult in
            switch loginResult {
            case .failed(let error):
                showAlert(viewController:self, strMsg: (error.localizedDescription), focusItem: nil)
                self.btnLogin.isEnabled = true
                self.activityIndicator.isHidden = true
                break
            case .cancelled:
                print("User cancelled login.")
                self.btnLogin.isEnabled = true
                self.activityIndicator.isHidden = true
                break
            case .success(let grantedPermissions, let declinedPermissions, let accessToken):
                print("Logged in! \(grantedPermissions)")
                print("Logged in! \(declinedPermissions)")
                self.credentialFB = FacebookAuthProvider.credential(withAccessToken: accessToken.authenticationToken)
                
                self.getFBUserData()
                break
            }
        }
    }
    
    // Feteching Facebook profile when you login with facebook
    func getFBUserData(){
        if((FBSDKAccessToken.current()) != nil){
            FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "id, name, first_name, last_name, picture.type(large), email"]).start(completionHandler: { (connection, result, error) -> Void in
                if (error != nil){
                    showAlert(viewController: self, strMsg: (error?.localizedDescription)!, focusItem: nil)
                    self.btnLogin.isEnabled = true
                    self.activityIndicator.isHidden = true

                    return
                }
                print(result ?? "")
                guard let data = result as? [String:Any] else { return }
                
                self.fbID = data["id"] as? String ?? ""
                let emailID = data["email"] ?? ""
                
                var bUserExist = false
                var bLinkedEmail = false
                self.databaseRef = Database.database().reference().child("users")
                var handle: UInt = 0
                handle = (self.databaseRef?.observe(DataEventType.value, with: { (snapshot) -> Void in
                    // Email choosed
                    print(snapshot.childrenCount) // I got the expected number of items
                    let enumerator = snapshot.children
                    while let rest = enumerator.nextObject() as? DataSnapshot {
                        print(rest.value ?? "")
                        if rest.hasChild("Facebook ID") {
                            if let userDict = rest.value as? [String:AnyObject] {
                                let childEmail = userDict["Facebook ID"] as! String
                                if childEmail == self.fbID {
                                    bUserExist = true
                                    break
                                }
                            }
                        }
                        if rest.hasChild("Email") {
                            if let userDict = rest.value as? [String:AnyObject] {
                                let childEmail = userDict["Email"] as! String
                                if childEmail == emailID as! String {
                                    bLinkedEmail = true
                                    break
                                }
                            }
                        }
                    }
                    
                    if let ref = self.databaseRef {
                        ref.removeAllObservers()
                        ref.removeObserver(withHandle: handle)
                    }
                    
                    if bUserExist {
                        Auth.auth().signIn(with: self.credentialFB!, completion: { (user, err) in
                            let userDefaults = UserDefaults.standard
                            userDefaults.set(user!.uid, forKey: "userid")
                            userDefaults.synchronize()
                            
                            self.btnLogin.isEnabled = true
                            self.activityIndicator.isHidden = true
                            self.performSegue(withIdentifier: "main", sender: nil)
                        })
                    } else {
                        if bLinkedEmail {
                            showAlert(viewController: self, strMsg: "Your primary email is already registered. Please login with the email and password to link your facebook account!", focusItem: self.tfEmail)
                            self.fbLinked = true
                        } else {
                            self.performSegue(withIdentifier: "facebook_smsVerify", sender: nil)
                        }
                    }
                    self.btnLogin.isEnabled = true
                    self.activityIndicator.isHidden = true
                    
                }))!
            })
        } else {
            self.btnLogin.isEnabled = true
            self.activityIndicator.isHidden = true
        }
    }
    
    
    // enable/disable Login button when fill or blank the email & password field
    @IBAction func onUpdateEmail(_ sender: Any) {
        if !tfEmail.text!.isEmpty && !tfPassword.text!.isEmpty {
            btnLogin.isEnabled = true
        } else {
            btnLogin.isEnabled = false
        }
    }
    
    // enable/disable Login button when fill or blank the email & password field
    @IBAction func onUpdatePassword(_ sender: Any) {
        if !tfEmail.text!.isEmpty && !tfPassword.text!.isEmpty {
            btnLogin.isEnabled = true
        } else {
            btnLogin.isEnabled = false
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "facebook_smsVerify" {
            let vc = segue.destination as! PhoneRegisterViewController
            vc.isFacebookVerify = true
            vc.credentialFB = credentialFB
        }
    }
    
    // Removes the firebase observer
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if let ref = databaseRef {
            ref.removeAllObservers()
        }
    }
}
