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

class ChatController: UICollectionViewController ,UITextFieldDelegate,UICollectionViewDelegateFlowLayout{
    
    var txtField  =  UITextField()
    var user = [User]()
    var messages = [Message]()
    var messageDict = [String: Message]()
    var users : User?
    var containerViewBottom : NSLayoutConstraint?
    let sampleViewc = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = users?.name
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Log out", style: .plain, target: self, action: #selector(handleLogout))
        
        observeMessages()
        collectionView.register(FreelancerCell.self, forCellWithReuseIdentifier: "Cell")
        collectionView.showsVerticalScrollIndicator = false
        collectionView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 58, right: 0)
        collectionView.scrollIndicatorInsets = UIEdgeInsets(top: 00, left: 0, bottom: 58, right: 0)
        collectionView.backgroundColor = .white
        collectionView.keyboardDismissMode = .interactive
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        setupInputComponent()
        sampleViewc.frame = self.view.frame
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
    }
    @objc func keyboardWillShow(notification: Notification) {
        if   let duration = notification.userInfo![UIResponder.keyboardAnimationDurationUserInfoKey] as? Double{
            if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
                print("notification: Keyboard will show")
              
                    self.view.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - keyboardSize.height)
//                    self.view.frame.origin.y -= keyboardSize.height
                    UIView.animate(withDuration: duration) {
                        self.view.layoutIfNeeded()
                    }
                
                if self.collectionView.numberOfItems(inSection: 0) > 0{
                            let lastItemIndex = self.collectionView.numberOfItems(inSection: 0) - 1
                            let indexPath:IndexPath = IndexPath(item: lastItemIndex, section: 0)
                            self.collectionView.scrollToItem(at: indexPath, at: .bottom, animated: false)
                            }
            }
        }
        
    }
    
    @objc func keyboardWillHide(notification: Notification) {
        if   let duration = notification.userInfo![UIResponder.keyboardAnimationDurationUserInfoKey] as? Double{
          
                self.view.frame = sampleViewc.frame
                UIView.animate(withDuration: duration) {
                    self.view.layoutIfNeeded()
                }
                if self.collectionView.numberOfItems(inSection: 0) > 0{
                    let lastItemIndex = self.collectionView.numberOfItems(inSection: 0) - 1
                    let indexPath:IndexPath = IndexPath(item: lastItemIndex, section: 0)
                    self.collectionView.scrollToItem(at: indexPath, at: .bottom, animated: false)
            
            }
        }
    }
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        collectionView.collectionViewLayout.invalidateLayout()
    }
    func setupInputComponent(){
        let containerView = UIView()
        containerView.backgroundColor = .white
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        collectionView?.backgroundColor = .white
        
        containerView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        containerViewBottom =   containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        containerViewBottom!.isActive = true
        containerView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        containerView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        let sendBtn = UIButton()
        sendBtn.setTitle("Send", for: .normal)
        sendBtn.setTitleColor(.blue, for: .normal)
        sendBtn.translatesAutoresizingMaskIntoConstraints = false
        sendBtn.addTarget(self, action: #selector(BtnSend), for: .touchUpInside)
        containerView.addSubview(sendBtn)
        sendBtn.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
        sendBtn.bottomAnchor.constraint(equalTo: containerView.bottomAnchor).isActive = true
        sendBtn.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
        sendBtn.widthAnchor.constraint(equalToConstant: 80).isActive = true
        txtField.placeholder = "Enter text.."
        txtField.delegate = self
        txtField.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(txtField)
        txtField.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        txtField.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        txtField.rightAnchor.constraint(equalTo: sendBtn.leftAnchor).isActive = true
        txtField.bottomAnchor.constraint(equalTo: containerView.bottomAnchor).isActive = true
        txtField.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
        let seperatorView = UIView()
        seperatorView.backgroundColor = UIColor.lightGray.withAlphaComponent(0.5)
        seperatorView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(seperatorView)
        seperatorView.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        seperatorView.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        seperatorView.widthAnchor.constraint(equalTo: containerView.widthAnchor).isActive = true
        seperatorView.heightAnchor.constraint(equalToConstant: 1).isActive = true
    }
    @objc func handleLogout(){
        navigationController?.popViewController(animated: true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        BtnSend()
        return true
    }
    func observeMessages(){
        messages.removeAll()
        messageDict.removeAll()
        if ((Auth.auth().currentUser?.uid) != nil){
            let msgRef = Database.database().reference().child("user-messages").child((Auth.auth().currentUser?.uid)!).child((users?.id)!)
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
                                self.collectionView.reloadData()
                            }
                        }
                    }
                }, withCancel: nil)
                
            }, withCancel: nil)
        }
    }
    @objc func BtnSend() {
        guard  txtField.text  != "" else {
            return
        }
        let ref = Database.database().reference().child("messages")
        let childRef = ref.childByAutoId()
        let toID = users?.id
        let fromID =  Auth.auth().currentUser?.uid
        let timestamp: NSNumber = (Date().timeIntervalSince1970 as AnyObject as! NSNumber)
        let values = ["text": txtField.text!,"toId":toID! as Any, "fromId": fromID!,"timestamp": timestamp] as [String : Any]
        childRef.updateChildValues(values)
        self.txtField.text = nil
        guard let messageId = childRef.key else { return }
        
        let userMessagesRef = Database.database().reference().child("user-messages").child(fromID!).child(toID!).child(messageId)
        userMessagesRef.setValue(1)
        
        let recipientUserMessagesRef = Database.database().reference().child("user-messages").child(toID!).child(fromID!).child(messageId)
        recipientUserMessagesRef.setValue(1)
        
       
       
        if self.collectionView.numberOfItems(inSection: 0) > 0{
        let lastItemIndex = self.collectionView.numberOfItems(inSection: 0) - 1
        let indexPath:IndexPath = IndexPath(item: lastItemIndex, section: 0)
        self.collectionView.scrollToItem(at: indexPath, at: .bottom, animated: false)
        }
       
        
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    let DEFAULT_USER_IMAGE  =  UIImage(named:"user")!
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! FreelancerCell
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
