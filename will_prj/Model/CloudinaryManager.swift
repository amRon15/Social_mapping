//
//  CloudinaryManager.swift
//  will_prj
//
//  Created by 邱允聰 on 29/12/2024.
//

import Foundation
import Cloudinary
import SwiftUI

class CloudinaryManager{
    private let config = CLDConfiguration(cloudName: "do8pmrsqi", apiKey: "988174913548525", apiSecret: "sStjTCQuMNgXJA345RzA4pvjVgI", secure: true)
    static let shared = CloudinaryManager()
    private var cloudinary: CLDCloudinary?
    
    init(){
        setUp()
    }
    
    private func setUp(){
        cloudinary = CLDCloudinary(configuration: config)        
    }
    
    func uploadImage(data: Data, userId: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let cloudinary = CloudinaryManager.shared.cloudinary else {
            completion(.failure(NSError(domain: "CloudinaryNotConfigured", code: -1, userInfo: nil)))
            return
        }
        
        let uploader = cloudinary.createUploader()
        let params = CLDUploadRequestParams().setPublicId(userId)
        
        uploader.upload(data: data, uploadPreset: "ml_default", params: params, completionHandler: {result, err in
            DispatchQueue.main.async{
                if let err = err{
                    completion(.failure(err))
                } else if let url = result?.secureUrl{
                    print("Image uploaded successfully with URL: \(url)")
                    completion(.success(url))
                } else{
                    completion(.failure(NSError(domain: "UploadFailed", code: -1, userInfo: nil)))
                }
            }
        })
    }
    
    func fetchImage(publicId: String, completion: @escaping (Image?) -> Void) {
        guard let cloudinary = CloudinaryManager.shared.cloudinary else {
            completion(nil)
            return
        }

        let url = cloudinary.createUrl().generate(publicId)
        
        guard let urlString = url, let url = URL(string: urlString) else {
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil, let uiImage = UIImage(data: data) else {
                completion(nil)
                return
            }

            DispatchQueue.main.async {
                completion(Image(uiImage: uiImage))
            }
        }.resume()
    }
}
