//
//  ChatController.swift
//  MySampleChat
//
//  Created by IRISMAC on 29/01/19.
//  Copyright © 2019 IRIS Medical Solutions. All rights reserved.
//
//
import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase
import SDWebImage

class ChatController: UIViewController,UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout {
   
    @IBOutlet var collectionview: UICollectionView!
    var user = [User]()
    var messages = [Message]()
    var messageDict = [String: Message]()
    var users : User?
    
    @IBOutlet var txtMessage: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = users?.name
  navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Log out", style: .plain, target: self, action: #selector(handleLogout))
     observeMessages()
        collectionview.register(FreelancerCell.self, forCellWithReuseIdentifier: "Cell")
        collectionview.showsVerticalScrollIndicator = false
        
    }
      @objc func handleLogout(){
        self.dismiss(animated: true, completion: nil)
    }
    func observeMessages(){
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
                   
                    if dataMessge.chatPartnerID()  == self.users?.id{
                         self.messages.append(dataMessge)
                        DispatchQueue.main.async {
                            self.collectionview.reloadData()
                        }
                    }
                    
                   
                }
            }, withCancel: nil)
            
        }, withCancel: nil)
        }
    }
    @IBAction func BtnSend(_ sender: Any) {
        let ref = Database.database().reference().child("messages")
        let childRef = ref.childByAutoId()
        let toID = users?.id
        let fromID =  Auth.auth().currentUser?.uid
         let timestamp: NSNumber = (Date().timeIntervalSince1970 as AnyObject as! NSNumber)
        let values = ["text": txtMessage.text!,"toId":toID! as Any, "fromId": fromID!,"timestamp": timestamp] as [String : Any]
        childRef.updateChildValues(values)
      self.txtMessage.text = nil
        guard let messageId = childRef.key else { return }
        
        let userMessagesRef = Database.database().reference().child("user-messages").child(fromID!).child(messageId)
        userMessagesRef.setValue(1)
        
        let recipientUserMessagesRef = Database.database().reference().child("user-messages").child(toID!).child(messageId)
        recipientUserMessagesRef.setValue(1)
        
        
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    let DEFAULT_USER_IMAGE  =  UIImage(named:"user")!
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionview.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! FreelancerCell
        let data = messages[indexPath.row]
        let urlImage  = URL(string: (users?.profileURL)!)
         cell.profileImageview.sd_setShowActivityIndicatorView(true)
         cell.profileImageview.sd_setIndicatorStyle(.whiteLarge)
        
        cell.profileImageview.sd_setImage(with: urlImage , placeholderImage: DEFAULT_USER_IMAGE)
        if data.fromId ==  Auth.auth().currentUser?.uid{
              cell.textView.backgroundColor = .blue
            cell.profileImageview.isHidden = true
        }else{
             cell.textView.backgroundColor = .gray
            cell.rightAnchors?.isActive = false
            cell.leftAnchors?.isActive = true
        }
      
        
      cell.textView.text = data.text
        cell.widthConstrain?.constant = EstimatedHeight(text: data.text!).width + 30
    
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var height:CGFloat = 80
          let data = messages[indexPath.row]
        if let text = data.text{
            height = EstimatedHeight(text: text).height + 20
        }
        
        return CGSize(width: view.frame.width, height: height)
    }
    private func EstimatedHeight(text:String) -> CGRect{
        let size = CGSize(width: 200, height: 1000)
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        return NSString(string: text).boundingRect(with: size, options: options, attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 18)], context: nil)
    }

}
class FreelancerCell: UICollectionViewCell {
    let textView: UITextView = {
        let textView = UITextView()
        textView.layer.cornerRadius = 18
        textView.textColor = .white
        textView.font = UIFont.boldSystemFont(ofSize: 18)
        textView.textAlignment = .center
        textView.clipsToBounds = true
         textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()
    let profileImageview: UIImageView = {
        let profileImageview = UIImageView()
        profileImageview.layer.cornerRadius = 18
        profileImageview.clipsToBounds = true
        profileImageview.translatesAutoresizingMaskIntoConstraints = false
        return profileImageview
    }()
    var widthConstrain : NSLayoutConstraint?
       var rightAnchors : NSLayoutConstraint?
    var leftAnchors : NSLayoutConstraint?
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(textView)
         addSubview(profileImageview)
        profileImageview.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 8).isActive = true
        profileImageview.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        profileImageview.heightAnchor.constraint(equalToConstant: 32).isActive = true
        profileImageview.widthAnchor.constraint(equalToConstant: 32).isActive = true
        
        rightAnchors =  textView.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -20)
        rightAnchors!.isActive = true
        leftAnchors =  textView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 50)
//        leftAnchors!.isActive = true
        textView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        textView.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
        widthConstrain =  textView.widthAnchor.constraint(equalToConstant: 200)
        widthConstrain?.isActive = true
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
