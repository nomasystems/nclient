//
//  Copyright © Nomasystems S.L.. All rights reserved.
//

import Foundation

/// Possible errors that can occur when making API request with `APIClient` .
public enum APIError: Error {
    /// An error related to the client, such as invalid request parameters or authentication failure.
    /// Http codes from 400 to 499.
    case client

    /// An error related to the server, such as internal server error or unavailable service.
    /// Http codes from 500 to 599.
    case server

    /// An error indicating a general request failure.
    /// Rest of http codes.
    case failed

    /// An error related to data, such as malformed response or unexpected data format.
    case data
}

