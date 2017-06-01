//
//  MainViewController.swift
//  Auth App
//
//  Created by mobile developer on 2017. 05. 26..
//  Copyright © 2017. Balazs Benjamin. All rights reserved.
//

import UIKit
import FirebaseAuth
import SDWebImage

import FBSDKLoginKit

class MainViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var friendsArray:NSArray?
    
    @IBOutlet weak var tableView: UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        getFBFriends()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        self.navigationItem.setHidesBackButton(true, animated:true)
    }

    func showAlert(strMsg:String, focusItem:UITextField?) {
        let alert = UIAlertController(title: "", message: strMsg, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler:{(action) in
            if focusItem != nil {
                focusItem?.becomeFirstResponder()
            }
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func onLogout(_ sender: Any) {
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
            
            let loginManager = FBSDKLoginManager()
            loginManager.logOut()
            
            let userDefaults = UserDefaults.standard
            userDefaults.removeObject(forKey: "userid")
            userDefaults.synchronize()
            
            
            self.navigationController?.popToRootViewController(animated: true)
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
            showAlert(strMsg: signOutError.localizedDescription, focusItem: nil)
        }
    }
    
    
    func getFBFriends(){
        if((FBSDKAccessToken.current()) != nil){
            FBSDKGraphRequest(graphPath: "/me/friends", parameters: ["fields": "id, name, first_name, last_name, picture.type(large), email"]).start(completionHandler: { (connection, result, error) -> Void in
                if (error == nil){
                    //everything works print the user data
                    print(result ?? "")
                    
                    let resultdict = result as! NSDictionary
                    print("Result Dict: \(resultdict)")
                    let data : NSArray = resultdict.object(forKey: "data") as! NSArray
                    
                    for i in 0 ..< data.count
                    {
                        let valueDict : NSDictionary = data[i] as! NSDictionary
                        let id = valueDict.object(forKey: "id") as! String
                        print("the id value is \(id)")
                    }
                }
            })
        }
    }
    
    // MARK: UITableView
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    
    // cell height
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "CellFriend", for: indexPath ) 

        //var imageView = cell.viewWithTag(100) as! UIImageView
        //var nameLabel = cell.viewWithTag(101) as! UILabel
        
        
        // connect objects with our information from arrays
        return cell
    }
    
}

