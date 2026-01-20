//
//  Error.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

public extension Error {
    var isNetworkError: Bool {
        let nsError = self as NSError
        return nsError.domain == NSURLErrorDomain &&
            (nsError.code == NSURLErrorTimedOut ||
                nsError.code == NSURLErrorCannotFindHost ||
                nsError.code == NSURLErrorCannotConnectToHost ||
                nsError.code == NSURLErrorNetworkConnectionLost ||
                nsError.code == NSURLErrorDNSLookupFailed ||
                nsError.code == NSURLErrorNotConnectedToInternet ||
                nsError.code == NSURLErrorInternationalRoamingOff ||
                nsError.code == NSURLErrorCallIsActive ||
                nsError.code == NSURLErrorDataNotAllowed ||
                nsError.code == NSURLErrorRequestBodyStreamExhausted ||
                nsError.code == NSURLErrorBadServerResponse ||
                nsError.code == NSURLErrorBadURL ||
                nsError.code == NSURLErrorCancelled ||
                nsError.code == NSURLErrorCannotCloseFile ||
                nsError.code == NSURLErrorCannotCreateFile ||
                nsError.code == NSURLErrorCannotDecodeContentData ||
                nsError.code == NSURLErrorCannotDecodeRawData ||
                nsError.code == NSURLErrorCannotLoadFromNetwork ||
                nsError.code == NSURLErrorCannotMoveFile ||
                nsError.code == NSURLErrorCannotOpenFile ||
                nsError.code == NSURLErrorCannotParseResponse ||
                nsError.code == NSURLErrorCannotRemoveFile ||
                nsError.code == NSURLErrorCannotWriteToFile ||
                nsError.code == NSURLErrorClientCertificateRejected ||
                nsError.code == NSURLErrorClientCertificateRequired ||
                nsError.code == NSURLErrorDataLengthExceedsMaximum ||
                nsError.code == NSURLErrorDownloadDecodingFailedMidStream ||
                nsError.code == NSURLErrorDownloadDecodingFailedToComplete ||
                nsError.code == NSURLErrorFileDoesNotExist ||
                nsError.code == NSURLErrorFileIsDirectory ||
                nsError.code == NSURLErrorHTTPTooManyRedirects ||
                nsError.code == NSURLErrorNetworkConnectionLost ||
                nsError.code == NSURLErrorNoPermissionsToReadFile ||
                nsError.code == NSURLErrorRedirectToNonExistentLocation ||
                nsError.code == NSURLErrorResourceUnavailable ||
                nsError.code == NSURLErrorServerCertificateHasBadDate ||
                nsError.code == NSURLErrorServerCertificateHasUnknownRoot ||
                nsError.code == NSURLErrorServerCertificateNotYetValid ||
                nsError.code == NSURLErrorServerCertificateUntrusted ||
                nsError.code == NSURLErrorSecureConnectionFailed ||
                nsError.code == NSURLErrorUnsupportedURL ||
                nsError.code == NSURLErrorUserAuthenticationRequired ||
                nsError.code == NSURLErrorUserCancelledAuthentication ||
                nsError.code == NSURLErrorZeroByteResource)
    }
    
    var nsErrorCode: Int { (self as NSError).code }
}
