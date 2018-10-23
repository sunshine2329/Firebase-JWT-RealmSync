//
//  RegisterViewController.swift
//  shopping
//
//  Created by Austin Teague on 7/21/18.
//  Copyright © 2018 Austin Teague. All rights reserved.
//

import UIKit
import RealmSwift
import FirebaseAuth
import FirebaseFunctions
import Crashlytics
import SVProgressHUD
import Hex

class RegisterViewController: AuthViewController, UITextFieldDelegate {

    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var registerButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        let animationDuration: Double = 0.55
        UIView.animate(withDuration: animationDuration, animations: {
            self.nameField.alpha = 1
        }) { (true) in
            UIView.animate(withDuration: animationDuration, animations: {
                self.emailField.alpha = 1
            }, completion: { (true) in
                UIView.animate(withDuration: animationDuration, animations: {
                    self.passwordField.alpha = 1
                }, completion: { (true) in
                    UIView.animate(withDuration: animationDuration, animations: {
                        self.registerButton.alpha = 1
                    })
                })
            })
        }

        nameField.delegate = self
        emailField.delegate = self
        passwordField.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if let user = SyncUser.current {
            print("\nUser already logged in")
            Crashlytics.sharedInstance().setUserIdentifier(user.identity)
            performSegue(withIdentifier: "goToApp", sender: self)
        }
    }
    
    override func loggedIn() {
        self.performSegue(withIdentifier: "goToOnboarding", sender: self)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if (nameField.isFirstResponder) {
            emailField.becomeFirstResponder()
        } else if (emailField.isFirstResponder) {
            passwordField.becomeFirstResponder()
        } else if (passwordField.isFirstResponder) {
            textField.resignFirstResponder()
            registerUser()
        }
        return true
    }
    
    func registerUser() {
        SVProgressHUD.show()

        // Temporary create user account in both Firebase and Realm
        if let email = emailField.text, let password = passwordField.text {
            Auth.auth().createUser(withEmail: email, password: password) { [weak self] (authUser, error) in
                if let error = error {
                    SVProgressHUD.showError(withStatus: error.localizedDescription)
                    print(error.localizedDescription)
                    Crashlytics.sharedInstance().recordError(error)
                } else if authUser != nil {
                    self?.getJwtToken()
                }
            }
        }
    }

    @IBAction func registerButtonPressed(_ sender: Any) {
        registerUser()
    }
}
