//
//  UplynkDRMIntegration.swift
//
//
//  Created by Raveendran, Aravind on 17/2/2025.
//

import Foundation
import OSLog
import THEOplayerSDK

class UplynkDRMIntegration: ContentProtectionIntegration {
    static let integrationID = "UplynkDRM"
    let UPLYNK_CONTENT_ID_PARAMETER_NAME = "b";
    
    var skdUrl: String?
    
    func onExtractFairplayContentId(skdUrl: String, callback: ExtractContentIdCallback) {
        os_log(.debug,log: .drmIntegration, "onExtractFairplayContentId %@", skdUrl)

        self.skdUrl = skdUrl
        let urlComponents = URLComponents(string: skdUrl)!
        let skd = urlComponents.queryItems!.first(where: { $0.name == UPLYNK_CONTENT_ID_PARAMETER_NAME })!.value!
        os_log(.debug,log: .drmIntegration, "onExtractFairplayContentId %@", skd)
        callback.respond(contentID: skd.data(using: .utf8))
    }

    func onCertificateRequest(request: CertificateRequest, callback: CertificateRequestCallback) {
        os_log(.debug,log: .drmIntegration, "onCertificateRequest %@", request.url)
        request.url = request.url
        callback.request(request: request)
    }

    func onCertificateResponse(response: CertificateResponse, callback: CertificateResponseCallback) {
        if let data = try? JSONEncoder().encode(response) {
            let responseString = String(data: data, encoding: .utf8)!
            os_log(.debug,log: .drmIntegration, "onCertificateResponse %@", responseString)
        }
        callback.respond(certificate: response.body)
    }

    func onLicenseRequest(request: LicenseRequest, callback: LicenseRequestCallback) {
        os_log(.debug,log: .drmIntegration, "onLicenseRequest %@", request.url)
        guard let skdUrl = self.skdUrl else {
            return
        }
        let laURL = skdUrl.replacingOccurrences(of: "skd://", with: "https://")
        request.url = laURL
        var dict = [String: String]()
        dict.updateValue(request.body!.base64EncodedString(), forKey: "spc")
        
        do {
            request.body = try JSONEncoder().encode(dict)
            callback.request(request: request)
        } catch {
            callback.error(error: error)
        }
    }

    func onLicenseResponse(response: LicenseResponse, callback: LicenseResponseCallback) {
        if let data = try? JSONEncoder().encode(response) {
            let responseString = String(data: data, encoding: .utf8)!
            os_log(.debug,log: .drmIntegration, "onLicenseResponse %@", responseString)
        }
        
        do {
            let dto = try JSONDecoder().decode(UplynkDRMLicenseResponseDTO.self, from: response.body)
            guard let data = Data(base64Encoded: dto.ckc) else {
                callback.error(error: UplynkError(
                    url: "",
                    description: "ckc response could not be decoded properly",
                    code: .UPLYNK_ERROR_DRM_LICENSE_ACQUISTION_FAILED))
                return
            }
            response.body = data
            callback.respond(license: response.body)
        } catch {
            callback.error(error: error)
        }
    }
}

class UplynkDRMIntegrationFactory: ContentProtectionIntegrationFactory {
    func build(configuration: DRMConfiguration) -> ContentProtectionIntegration {
        return UplynkDRMIntegration()
    }
}

private struct UplynkDRMLicenseResponseDTO: Codable {
    var ckc: String
}
