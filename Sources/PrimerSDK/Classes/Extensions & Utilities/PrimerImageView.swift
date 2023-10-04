//
//  UIImageView+Extensions.swift
//  PrimerSDK
//
//  Copyright © 2022 Primer API ltd. All rights reserved.
//



import UIKit

internal class PrimerImageView: UIImageView {}

extension PrimerImageView {
    
    convenience init(from url: URL, contentMode mode: ContentMode = .scaleAspectFit) {
        self.init()
        self.contentMode = mode
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard
                let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                let data = data, error == nil,
                let image = UIImage(data: data)
                else { return }
            DispatchQueue.main.async() { [weak self] in
                self?.image = image
            }
        }.resume()
    }
    
    convenience init?(from link: String, contentMode mode: ContentMode = .scaleAspectFit) {
        guard let url = URL(string: link) else { return nil }
        self.init(from: url, contentMode: mode)
    }
    
}


