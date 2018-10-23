//
//  ForgotPasswordViewController.swift
//  shopping
//
//  Created by Austin Teague on 7/21/18.
//  Copyright © 2018 Austin Teague. All rights reserved.
//

import UIKit
import RealmSwift
import SVProgressHUD
import Hex

class ForgotPasswordViewController: UIViewController {

    @IBOutlet weak var emailField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func resetPasswordButtonPressed(_ sender: Any) {
        SyncUser.requestPasswordReset(forAuthServer: Config.REALM_URL, userEmail: emailField.text!) { (error) in
            if (error != nil) {
                SVProgressHUD.showError(withStatus: error?.localizedDescription)
            } else {
                self.dismiss(animated: true, completion: {
                    self.emailField.text = ""
                })
            }
        }
    }

    @IBAction func backToLoginButtonPress(_ sender: Any) {
        dismiss(animated: true) {
            self.emailField.text = ""
        }
    }
}
