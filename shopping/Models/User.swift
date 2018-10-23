//
//  User.swift
//  shopping
//
//  Created by Austin Teague on 7/20/18.
//  Copyright © 2018 Austin Teague. All rights reserved.
//

import Foundation
import RealmSwift

class User : Object {
    @objc dynamic var id : String = ""
    @objc dynamic var name : String = ""
    @objc dynamic var email : String = ""
    @objc dynamic var avatar : String? = nil
    @objc dynamic var active: Bool = true
    @objc dynamic var created_at: Date = Date()
    @objc dynamic var deactivated_at: Date? = nil

    override static func primaryKey() -> String? {
        return "id"
    }
}
