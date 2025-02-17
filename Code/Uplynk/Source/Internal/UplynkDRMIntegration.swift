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
        let responseString = String(data: try! JSONEncoder().encode(response), encoding: .utf8)!
        os_log(.debug,log: .drmIntegration, "onCertificateResponse %@", responseString)
        callback.respond(certificate: response.body)
    }

    func onLicenseRequest(request: LicenseRequest, callback: LicenseRequestCallback) {
        os_log(.debug,log: .drmIntegration, "onLicenseRequest %@", request.url)
        let laURL = self.skdUrl!.replacingOccurrences(of: "skd://", with: "https://")
        request.url = laURL
        var dict = [String: String]()
        dict.updateValue(request.body!.base64EncodedString(), forKey: "spc")

        request.body = try! JSONEncoder().encode(dict)
        callback.request(request: request)
    }

    func onLicenseResponse(response: LicenseResponse, callback: LicenseResponseCallback) {
        let responseString = String(data: try! JSONEncoder().encode(response), encoding: .utf8)!
        os_log(.debug,log: .drmIntegration, "onLicenseResponse %@", responseString)

        let dto = try! JSONDecoder().decode(UplynkDRMLicenseResponseDTO.self, from: response.body)
        response.body = Data(base64Encoded: dto.ckc)!
        
        callback.respond(license: response.body)
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
