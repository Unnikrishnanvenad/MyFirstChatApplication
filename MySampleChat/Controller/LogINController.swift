//
//  LogINController.swift
//  MySampleChat
//
//  Created by IRISMAC on 28/01/19.
//  Copyright © 2019 IRIS Medical Solutions. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase

class LogINController: UIViewController {
    @IBOutlet var txtName: UITextField!
    @IBOutlet var txtEmail: UITextField!
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var txtLogInPassword: UITextField!
    @IBOutlet var txtLoginEmail: UITextField!
    @IBOutlet var viewForLogIN: UIView!
    @IBOutlet var txtPassword: UITextField!
    @IBOutlet var viewForRegister: UIView!
    @IBOutlet var btnLogin: UIButton!
    @IBOutlet var segment: UISegmentedControl!
    
    var messageController : ViewController?
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    func Register(){
        guard let email = txtEmail.text, let passwd =  txtPassword.text else {
            print("Error")
            return
        }
        Auth.auth().createUser(withEmail: email, password: passwd) { (user , error) in
            if let error = error {
                print(error.localizedDescription)
            }
            else if let user = user {
                print("Sign Up Successfully. \(user)")
            }
            if ((Auth.auth().currentUser?.uid) != nil){
                let imageName = NSUUID().uuidString
                let storageRef = Storage.storage().reference().child("\(imageName).png")
                if let img = self.imageView.image{
                    if let data:Data = img.jpeg(.lowest)  {
                        storageRef.putData(data, metadata: nil, completion: { (metaData, error) in
                        if error != nil{
                            print(error)
                            return
                        }
                        print(metaData)
                        storageRef.downloadURL { (url, error) in
                            guard let downloadURL = url else {
                                return
                            }
                            print(url)
                            let sdownloadURL : String =  downloadURL.absoluteString
                            let userID = Auth.auth().currentUser!.uid
                            let values = ["name":self.txtName.text!,"email":self.txtEmail.text!,"myImageURL":sdownloadURL]
                            self.RegisterDataWithFirebase(userID:userID, Values: values as [String : AnyObject])
                            print(downloadURL)
                        }
                    })
                }
            }
            }else{
             return
            }
        }
        
    }
    func RegisterDataWithFirebase(userID:String,Values:[String:AnyObject]){
      
         var users = [User]()
        let userID = Auth.auth().currentUser!.uid
        let ref = Database.database().reference(fromURL: "https://mysamplechat-394c3.firebaseio.com/")
        let userRefernce = ref.child("users").child(userID)
        userRefernce.updateChildValues(Values) { (Error, Reference) in
            if Error != nil{
                print(Error)
                return
            }
            if let dict = Values as? [String:AnyObject]{
                let name = dict["name"] as? String
                let mail = dict["email"] as? String
                let URL = dict["myImageURL"] as? String
                users.append(User.init(id: Reference.key!, name: name!, email: mail!, profileURL: URL!))
               self.messageController?.setupNavigationBarWithUser(user: users[0])
            }
           
            
            self.dismiss(animated: true, completion: nil)
            
        }
        
    }
    func LogIn(){
        guard let email = txtLoginEmail.text, let passwd =  txtLogInPassword.text else {
            print("Error")
            return
        }
        Auth.auth().signIn(withEmail: email, password: passwd) { (user, error) in
            if error != nil{
                print(error)
                return
            }
             self.messageController?.setupNavigationBar()
              self.dismiss(animated: true, completion: nil)
        }
        
    }
    @IBAction func btnRegisterAction(_ sender: Any) {
        if segment.selectedSegmentIndex == 0{
            LogIn()
        }else{
            Register()
        }
        
    }
    
    @IBAction func LoginOrRegisterSegmentAction(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            viewForLogIN.isHidden = false
            viewForRegister.isHidden = true
            btnLogin.setTitle("LogIn", for: .normal)
        case 1:
            viewForLogIN.isHidden = true
            viewForRegister.isHidden = false
             btnLogin.setTitle("Register", for: .normal)
        default:
            print("Test")
        }
    }
    @IBAction func btnImagePicker(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        present(picker, animated: true, completion: nil)
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        print("Cancel")
           picker.dismiss(animated: true, completion: nil)
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        var selectedImage: UIImage?
        if let editedImage = info[.editedImage] as? UIImage {
            selectedImage = editedImage
            self.imageView.image = selectedImage!
            picker.dismiss(animated: true, completion: nil)
        } else if let originalImage = info[.originalImage] as? UIImage {
            selectedImage = originalImage
            self.imageView.image = selectedImage!
            picker.dismiss(animated: true, completion: nil)
        }
        
    }
    
    
    
}

extension UIImage {
    enum JPEGQuality: CGFloat {
        case lowest  = 0
        case low     = 0.25
        case medium  = 0.5
        case high    = 0.75
        case highest = 1
    }
    
    /// Returns the data for the specified image in JPEG format.
    /// If the image object’s underlying image data has been purged, calling this function forces that data to be reloaded into memory.
    /// - returns: A data object containing the JPEG data, or nil if there was a problem generating the data. This function may return nil if the image has no data or if the underlying CGImageRef contains data in an unsupported bitmap format.
    func jpeg(_ jpegQuality: JPEGQuality) -> Data? {
        return jpegData(compressionQuality: jpegQuality.rawValue)
    }
}
