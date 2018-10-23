//
//  AuthViewController.swift
//  shopping
//
//  Created by Mobdev125 on 10/3/18.
//  Copyright © 2018 Austin Teague. All rights reserved.
//

import UIKit
import SVProgressHUD
import RealmSwift
import FirebaseAuth
import FirebaseFunctions
import Crashlytics

class AuthViewController: UIViewController {
    
    var name: String?
    var email: String?
    var errorMsg: String!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    func getJwtToken() {
        Functions.functions().httpsCallable("myAuthFunction").call(completion: { (result, error) in
            if let error = error {
                SVProgressHUD.showError(withStatus: error.localizedDescription)
                print(error.localizedDescription)
                Crashlytics.sharedInstance().recordError(error)
            }
            else if let token = (result?.data as? [String: Any])?["token"] as? String {
                let creds = SyncCredentials.jwt(token)
                SyncUser.logIn(with: creds, server: Config.AUTH_URL) { [weak self](user, error) in
                    if let user = user {
                        let realm = try! Realm(configuration: SyncConfiguration.automatic())
                        do {
                            if let name = self?.name, let email = self?.email {
                                let newUser = User()
                                newUser.id = user.identity!
                                newUser.name = name
                                newUser.email = email
                                
                                try realm.write {
                                    realm.add(newUser)
                                }
                            }
                            Crashlytics.sharedInstance().setUserIdentifier(user.identity!)
                            self?.loggedIn()
                            SVProgressHUD.dismiss()
                        } catch {
                            Crashlytics.sharedInstance().recordError(error)
                            print(error.localizedDescription)
                        }
                    } else if let error = error {
                        if let errorMsg = self?.errorMsg {
                            SVProgressHUD.showError(withStatus: errorMsg)
                            SVProgressHUD.dismiss(withDelay: 1.0)
                        }
                        else {
                            SVProgressHUD.dismiss()
                        }
                        Crashlytics.sharedInstance().recordError(error)
                        print(error.localizedDescription)
                    }
                }
            }
            else {
                let error = NSError(domain: "JWT Token Error", code: 200, userInfo: ["error" : "Can't get jwt token"])
                SVProgressHUD.showError(withStatus: error.localizedDescription)
                print(error.localizedDescription)
                Crashlytics.sharedInstance().recordError(error)
            }
        })
    }

    func loggedIn() {
        fatalError("loggedIn() has not been implemented")
    }
}
