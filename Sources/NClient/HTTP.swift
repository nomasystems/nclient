//
//  Copyright © Nomasystems S.L.. All rights reserved.
//

import Foundation

enum HTTP {
    enum Method: String {
        case GET
        case DELETE
        case POST
        case PUT
    }

    struct HeaderName: RawRepresentable {
        let rawValue: String
    }
}

extension HTTP {
    enum MIMEType {
        static let json = "application/json"
        static let formUrlEncoded = "application/x-www-form-urlencoded"
    }
}

extension HTTP.HeaderName {
    init(_ rawValue: RawValue) {
        self.rawValue = rawValue
    }
}

extension HTTP.HeaderName {
    static let accept = HTTP.HeaderName("Accept")
    static let contentType = HTTP.HeaderName("Content-Type")
}

extension URLRequest {
    mutating func setHeader(_ name: HTTP.HeaderName, value: String) {
        setValue(value, forHTTPHeaderField: name.rawValue)
    }
}
