//
//  Config.swift
//  shopping
//
//  Created by Austin Teague on 7/30/18.
//  Copyright © 2018 Austin Teague. All rights reserved.
//

import Foundation

struct Config {
    static let MY_INSTANCE_ADDRESS = "practical-rubber-salad.us1.cloud.realm.io"

    static let AUTH_URL  = URL(string: "https://\(MY_INSTANCE_ADDRESS)")!
    static let REALM_URL = URL(string: "realms://\(MY_INSTANCE_ADDRESS)/data")!
}
