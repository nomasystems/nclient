//
//  Copyright © Nomasystems S.L.. All rights reserved.
//

import Foundation

/// A namespace for handling HTTP-related functionality.
public enum HTTP {
    /// Represents an HTTP method.
    public enum Method: String {
        case GET
        case DELETE
        case POST
        case PUT
    }

    /// Represents the name of an HTTP header.
    struct HeaderName: RawRepresentable {
        let rawValue: String
    }

    /// Supported MIME types
    public struct MIMEType: RawRepresentable {
        public let rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }
    }
}

extension HTTP.HeaderName {
    init(_ rawValue: RawValue) {
        self.rawValue = rawValue
    }
}

extension HTTP.HeaderName {
    /// The "Accept" header name.
    static let accept = HTTP.HeaderName("Accept")

    /// The "Content-Type" header name.
    static let contentType = HTTP.HeaderName("Content-Type")
}

public extension HTTP.MIMEType {
    /// JSON data.
    static let json = HTTP.MIMEType(rawValue: "application/json")

    /// URL-encoded form data.
    static let formUrlEncoded = HTTP.MIMEType(rawValue: "application/x-www-form-urlencoded")

    /// MP4
    static let mp4 = HTTP.MIMEType(rawValue: "audio/mp4")
}

extension URLRequest {
    mutating func setHeader(_ name: HTTP.HeaderName, value: String) {
        setValue(value, forHTTPHeaderField: name.rawValue)
    }
}

extension URL {
    public struct PathComponents {
        private(set) var stringValue: String = ""

        mutating func append<S: LosslessStringConvertible>(_ component: S) {
            if !stringValue.isEmpty, stringValue.last != "/" {
                stringValue.append("/")
            }
            stringValue.append(String(describing: component))
        }

        mutating func append<T: RawRepresentable>(_ component: T) where T.RawValue: LosslessStringConvertible {
            append(component.rawValue)
        }
    }
}

public extension URLComponents {
    init(path: String, queryItems: [URLQueryItem] = []) {
        self.init()
        self.path = path
        // Avoid setting queryItems to [] as that appends a trailing ? to the url
        self.queryItems = queryItems.isEmpty ? nil : queryItems
    }

    mutating func appendPathComponents(_ pathComponents: URL.PathComponents) {
        if !path.isEmpty, path.last != "/" {
            path.append("/")
        }
        path.append(pathComponents.stringValue)
    }
}
