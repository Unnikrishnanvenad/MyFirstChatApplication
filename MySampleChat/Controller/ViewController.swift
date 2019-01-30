//
//  ViewController.swift
//  MySampleChat
//
//  Created by IRISMAC on 28/01/19.
//  Copyright © 2019 IRIS Medical Solutions. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase

class ViewController: UITableViewController {
    var users = [User]()
    var messages = [Message]()
      var messageDict = [String: Message]()
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Log out", style: .plain, target: self, action: #selector(handleLogout))
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "New", style: .plain, target: self, action: #selector(NewMessage))
        setupNavigationBar()
//        observeMessage()
    }
    func observeuserMessage(){
        messages.removeAll()
      messageDict.removeAll()
            if ((Auth.auth().currentUser?.uid) != nil){
                let msgRef = Database.database().reference().child("user-messages").child((Auth.auth().currentUser?.uid)!)
                msgRef.observe(.childAdded, with: { (snapshot) in
                    let key = snapshot.key
                  let  ref =  Database.database().reference().child("messages").child(key)
                    ref.observeSingleEvent(of: .value, with: { (snapshot) in
                        print(snapshot)
                        if let dict = snapshot.value as? [String:AnyObject]{
                            print(dict)
                            let fromId = dict["fromId"] as? String
                            let toId = dict["toId"] as? String
                            let text = dict["text"] as? String
                            let timestamp = dict["timestamp"] as? NSNumber
                            let dataMessge =   Message(fromId: fromId!, toId: toId!, text: text!, timestamp: timestamp!)
                            if let chatpartnerID = dataMessge.chatPartnerID(){
                                self.messageDict[chatpartnerID] = dataMessge
                            self.messages = Array(self.messageDict.values)
                            //                self.messages.sorted(by: { (lhs, rhs) -> Bool in
                            //                    if let lhsTime = lhs.timestamp?.intValue, let rhsTime = rhs.timestamp?.intValue {
                            //                        return lhs.timestamp < rhs.timestamp
                            //                    }
                            //                })
                            self.messages = self.messages.sorted{(($0.timestamp?.intValue)! > ($1.timestamp?.intValue)!)}
                            DispatchQueue.main.async {
                                self.tableView.reloadData()
                            }
                            }
                        }
                    }, withCancel: nil)
                    
                }, withCancel: nil)
                
                
            }else{
                
        }
        
    }
    func observeMessage(){
        messages.removeAll()
        messageDict.removeAll()
        let ref = Database.database().reference().child("messages")
        ref.observe(.childAdded, with: { (snapshot) in
            if let dict = snapshot.value as? [String:AnyObject]{
                print(dict)
                let fromId = dict["fromId"] as? String
                let toId = dict["toId"] as? String
                let text = dict["text"] as? String
                let timestamp = dict["timestamp"] as? NSNumber
              let dataMessge =   Message(fromId: fromId!, toId: toId!, text: text!, timestamp: timestamp!)
                self.messageDict[toId!] = dataMessge
                self.messages = Array(self.messageDict.values)
//                self.messages.sorted(by: { (lhs, rhs) -> Bool in
//                    if let lhsTime = lhs.timestamp?.intValue, let rhsTime = rhs.timestamp?.intValue {
//                        return lhs.timestamp < rhs.timestamp
//                    }
//                })
               self.messages = self.messages.sorted{(($0.timestamp?.intValue)! > ($1.timestamp?.intValue)!)}
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        }, withCancel: nil)
    }
    func setupNavigationBar(){
        self.users.removeAll()
        if ((Auth.auth().currentUser?.uid) != nil){
            Database.database().reference().child("users").child(Auth.auth().currentUser!.uid).observeSingleEvent(of: .value) { (snapshot) in
                if let dict = snapshot.value as? [String:AnyObject]{
                    print(dict)
                    let name = dict["name"] as? String
                    let mail = dict["email"] as? String
                    let URL = dict["myImageURL"] as? String
                    self.users.append(User.init(id: snapshot.key, name: name!, email: mail!, profileURL: URL!))
                 self.setupNavigationBarWithUser(user: self.users[0])
                }
            }
        }else{
           return
        }
        
    }
    func setupNavigationBarWithUser(user:User){
        messages.removeAll()
        messageDict.removeAll()
        tableView.reloadData()
        observeuserMessage()
        let profileView = UIImageView()
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        let titlesView = UIView()
        let lbl = UILabel()
        lbl.frame = CGRect(x: 40, y: 0, width: 60, height: 40)
        titlesView.frame = CGRect(x: 0, y: 0, width: 100, height: 40)
        titlesView.addSubview(containerView)
        profileView.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        titlesView.backgroundColor = .red
        lbl.text = user.name
        profileView.loadImageUsingURLString(urlString: user.profileURL!)
        containerView.addSubview(profileView)
        containerView.addSubview(lbl)
        self.navigationItem.titleView = titlesView
        titlesView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.NewChat)))
        
    }
       @objc func NewChat(){
        if self.users.count > 0{
             ShowChat(user: self.users[0])
        }
        
    }
    func ShowChat(user:User){
        let secondVC = self.storyboard?.instantiateViewController(withIdentifier: "ChatController") as! ChatController
        secondVC.users = user
        let navigationVC = UINavigationController(rootViewController: secondVC)
        self.present(navigationVC, animated: true, completion: nil)
        
    }
        @objc func NewMessage(){
            let secondVC = self.storyboard?.instantiateViewController(withIdentifier: "NewMessageControlelr") as! NewMessageControlelr
            secondVC.messageController = self
            let navigationVC = UINavigationController(rootViewController: secondVC)
            self.present(navigationVC, animated: true, completion: nil)
            
    }
    @objc func handleLogout(){
        
        
        do {
            try Auth.auth().signOut()
        } catch let Error {
            print(Error)
        }
        
        let secondVC = self.storyboard?.instantiateViewController(withIdentifier: "LogINController") as! LogINController
        secondVC.messageController = self
        let navigationVC = UINavigationController(rootViewController: secondVC)
        self.present(navigationVC, animated: true, completion: nil)
    }
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return messages.count
    }
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var idPartner: String?
        let user = messages[indexPath.row]
        let cell =  tableView.dequeueReusableCell(withIdentifier: "Cell1")!
        let lbl1 = cell.viewWithTag(100) as! UILabel
        let lbl2 = cell.viewWithTag(101) as! UILabel
        let lbl3 = cell.viewWithTag(103) as! UILabel
        let userImage = cell.viewWithTag(102) as! UIImageView
        lbl2.text = user.text
        if let toId = user.chatPartnerID(){
            let ref = Database.database().reference().child("users").child(toId)
            ref.observeSingleEvent(of: .value, with: { (snapshot) in
                print(snapshot)
                if let dict = snapshot.value as? [String:AnyObject]{
                    let name = dict["name"] as? String
                    let mail = dict["email"] as? String
                    let URL = dict["myImageURL"] as? String
                    userImage.loadImageUsingURLString(urlString: URL!)
                    lbl1.text  = name
                }
            }, withCancel: nil)
        }
        if let seconds = user.timestamp?.doubleValue{
                let timedate = NSDate(timeIntervalSince1970: seconds)
            let df = DateFormatter()
            df.dateFormat =  "hh:mm:ss a"
            lbl3.text = df.string(from: timedate as Date)
        }
        return cell
        
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let message =  messages[indexPath.row]
      
        guard let chatPartnerId = message.chatPartnerID() else {
            return
        }
        let ref = Database.database().reference().child("users").child(chatPartnerId)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            print(snapshot)
            if let dict = snapshot.value as? [String:AnyObject]{
                let name = dict["name"] as? String
                let mail = dict["email"] as? String
                let URL = dict["myImageURL"] as? String
                let userData = User.init(id: chatPartnerId, name: name!, email: mail!, profileURL: URL!)
                self.ShowChat(user: userData)
            }
        }, withCancel: nil)
        
    }
    
    
}

extension UIImageView{
    func loadImageUsingURLString(urlString:String){
        self.image = nil
        if let cachedImage = imageCache.object(forKey: urlString as AnyObject) as? UIImage{
            self.image = cachedImage
        }else{
         let urls =  urlString
                let url = URL(string: urls)
                let data = try? Data(contentsOf: url!)
                if data != nil{
                    let downloadImage  = UIImage(data: data!)
                    imageCache.setObject(downloadImage!, forKey: urls as AnyObject)
                    self.image = UIImage(data: data!)
                }
            
        }
    }
}
