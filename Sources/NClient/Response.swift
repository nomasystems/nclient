//
//  Copyright © Nomasystems S.L.. All rights reserved.
//

import Foundation

public struct Response<Body> {
    public let http: HTTPURLResponse
    public let body: Body
}
