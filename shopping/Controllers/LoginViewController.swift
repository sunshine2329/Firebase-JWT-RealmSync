//
//  LoginViewController.swift
//  shopping
//
//  Created by Austin Teague on 7/21/18.
//  Copyright © 2018 Austin Teague. All rights reserved.
//

import UIKit
import RealmSwift
import FirebaseAuth
import Crashlytics
import SVProgressHUD
import Hex

class LoginViewController: AuthViewController, UITextFieldDelegate {

    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        emailField.delegate = self
        passwordField.delegate = self
    }
    
    override func loggedIn() {
        self.performSegue(withIdentifier: "goToApp", sender: self)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if (emailField.isFirstResponder) {
            passwordField.becomeFirstResponder()
        } else if (passwordField.isFirstResponder) {
            textField.resignFirstResponder()
            loginUser()
        }
        return true
    }

    func loginUser() {
        SVProgressHUD.show()
        self.errorMsg = "Unable to log in. Please check your email and password before trying again."
        if let email = emailField.text, let password = passwordField.text {
            Auth.auth().signIn(withEmail: email, password: password) { [weak self] (authUser, error) in
                if let error = error {
                    SVProgressHUD.showError(withStatus: error.localizedDescription)
                    Crashlytics.sharedInstance().recordError(error)
                    print(error.localizedDescription)
                } else if authUser != nil {
                    self?.getJwtToken()
                }
            }
        }
    }

    @IBAction func loginButtonPressed(_ sender: Any) {
        loginUser()
    }

    @IBAction func createAccountButtonPress(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
