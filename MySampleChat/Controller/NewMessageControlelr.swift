//
//  NewMessageControlelr.swift
//  MySampleChat
//
//  Created by IRISMAC on 28/01/19.
//  Copyright © 2019 IRIS Medical Solutions. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase
   let imageCache = NSCache<AnyObject, AnyObject>()
class NewMessageControlelr: UITableViewController {

    var users = [User]()
    
    var messageController :  ViewController?
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Log out", style: .plain, target: self, action: #selector(handleLogout))
     FetchUser()
        
    }
     @objc func handleLogout(){
        self.dismiss(animated: true, completion: nil)
    }
    func FetchUser(){
        users.removeAll()
        Database.database().reference().child("users").observe(.childAdded, with: { (snapshot) in
            print(snapshot)
            if let dict = snapshot.value as? [String:AnyObject]{
                let name = dict["name"] as? String
                let mail = dict["email"] as? String
                 let URL = dict["myImageURL"] as? String
                self.users.append(User.init(id: snapshot.key, name: name!, email: mail!, profileURL: URL!))
            
            }
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
            
        }, withCancel: nil)
            
        
        
    }
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return users.count
    }
  
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
         let user = users[indexPath.row]
             let cell =  tableView.dequeueReusableCell(withIdentifier: "Cell1")!
        let lbl1 = cell.viewWithTag(100) as! UILabel
         let lbl2 = cell.viewWithTag(101) as! UILabel
         let userImage = cell.viewWithTag(102) as! UIImageView
        userImage.loadImageUsingURLString(urlString: user.profileURL!)
        lbl1.text  = user.name
       lbl2.text = user.email
        return cell
    
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        dismiss(animated: true, completion: nil)
           let user = users[indexPath.row]
        messageController?.ShowChat(user: user)
        
        
    }
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72
    }
    
}


class User {
     var id:String?
    var name:String?
    var email:String?
    var profileURL:String?
    init(id: String, name: String,email: String,profileURL: String) {
        self.id = id
        self.name = name
        self.email = email
        self.profileURL = profileURL
    }
}
class Message {
    var fromId:String?
    var toId:String?
    var text:String?
    var timestamp:NSNumber?
    init(fromId: String, toId: String,text: String,timestamp: NSNumber) {
        self.fromId = fromId
        self.toId = toId
        self.text = text
        self.timestamp = timestamp
    }
    func chatPartnerID() -> String?{
        return  (fromId == Auth.auth().currentUser?.uid) ? toId : fromId
    }
}

