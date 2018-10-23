//
//  ImageService.swift
//  shopping
//
//  Created by Austin Teague on 9/24/18.
//  Copyright © 2018 Austin Teague. All rights reserved.
//
import UIKit
import FirebaseStorage
import Crashlytics
import Alamofire
import AlamofireImage

class ImageService {
    static let cache = NSCache<NSString, UIImage>()

    static func downloadImage(withURL url: URL, completion: @escaping (_ image: UIImage?)->()) {
        var downloadedImage: UIImage?

        if url.absoluteString.hasPrefix("gs://") {
            let storageRef = Storage.storage().reference(forURL: url.absoluteString)
            storageRef.getData(maxSize: (1 * 1024 * 1024)) { (data, error) in
                if let error = error {
                    Crashlytics.sharedInstance().recordError(error)
                    print(error.localizedDescription)
                    completion(downloadedImage)
                } else {
                    if let data = data {
                        downloadedImage = UIImage(data: data)
                        DispatchQueue(label: "serial").sync {
                            cache.setObject(downloadedImage!, forKey: url.absoluteString as NSString)
                        }
                        completion(downloadedImage)
                    }
                }
            }
        } else {
            Alamofire.request(url).responseImage { response in
                if let image : UIImage = response.result.value {
                    downloadedImage = image
                    DispatchQueue(label: "serial").sync {
                        cache.setObject(downloadedImage!, forKey: url.absoluteString as NSString)
                    }
                    completion(downloadedImage)
                }
            }
        }
    }

    static func getImage(withURL url: URL, completion: @escaping (_ image: UIImage?)->()) {
        if let image = cache.object(forKey: url.absoluteString as NSString) {
            print("loading cached image")
            completion(image)
        } else {
            downloadImage(withURL: url, completion: completion)
        }
    }

}
