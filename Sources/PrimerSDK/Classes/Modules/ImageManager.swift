//
//  ImageManager.swift
//  PrimerSDK
//
//  Created by Evangelos on 15/7/22.
//

#if canImport(UIKit)

import UIKit

internal class ImageFile: File {
    
    var image: UIImage? {
        if let data = self.data,
           let image = UIImage(data: data, scale: 1.0) {
            return image
        }
        
        if let paymentMethodLogoFileName = PrimerPaymentMethod.getBundledImageFileName(for: self.fileName, assetType: .logo),
           let image = UIImage(named: paymentMethodLogoFileName, in: Bundle.primerResources, compatibleWith: nil) {
            return image
        } else if let image = UIImage(named: self.fileName, in: Bundle.primerResources, compatibleWith: nil) {
            return image
        }
        
        return nil
    }
}

internal class ImageManager {
    
    func getImages(for imageFiles: [ImageFile]) -> Promise<[ImageFile]> {
        return Promise { seal in
            let promises = imageFiles.compactMap({ self.getImage(file: $0) })
            
            firstly {
                when(resolved: promises)
            }
            .done { responses in
                var imageFiles: [ImageFile] = []
                var errors: [Error] = []
                
                for response in responses {
                    switch response {
                    case .success(let imageFile):
                        imageFiles.append(imageFile)
                    case .failure(let err):
                        errors.append(err)
                    }
                }
                
                if !errors.isEmpty, errors.count == responses.count {
                    let err = InternalError.underlyingErrors(errors: errors, userInfo: nil, diagnosticsId: nil)
                    ErrorHandler.handle(error: err)
                    throw err
                } else {
                    seal.fulfill(imageFiles)
                }
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }
    
    func getImage(file: ImageFile) -> Promise<ImageFile> {
        return Promise { seal in
            if file.image != nil {
                seal.fulfill(file)
                
            } else {
                let downloader = Downloader()
                firstly {
                    downloader.download(file: file)
                }
                .done { file in
                    if let imageFile = file as? ImageFile,
                       let imageData = imageFile.data,
                       let image = UIImage(data: imageData) {
                        seal.fulfill(imageFile)
                    } else {
                        let err = InternalError.failedToDecode(message: "image", userInfo: nil, diagnosticsId: nil)
                        ErrorHandler.handle(error: err)
                        throw err
                    }
                }
                .catch { err in
                    seal.reject(err)
                }
            }
        }
    }
}

#endif

