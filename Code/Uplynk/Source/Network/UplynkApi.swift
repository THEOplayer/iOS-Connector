//
//  UplynkApi.swift
//
//  Created by Raffi on 09/09/2024.
//  Copyright © 2024 THEOplayer. All rights reserved.
//

import Foundation

class UplynkApi {
    static func requestPreplay(srcURL: String, completion: @escaping (_ preplayResponse: PreplayResponse?) -> Void) {
        HttpsConnection.request(type: .get, urlString: srcURL) { content, error in
            guard let preplayResponseStr: String = content else {
                completion(nil)
                return
            }

            let decoder: JSONDecoder = .init()
            guard let preplayResponse: PreplayResponse = try? decoder.decode(PreplayResponse.self, from: Data(preplayResponseStr.utf8)) else {
                completion(nil)
                return
            }

            completion(preplayResponse)
        }
    }
}
