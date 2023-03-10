//
//  Copyright © Nomasystems S.L.. All rights reserved.
//

import Foundation

struct Response<Body> {
    let http: HTTPURLResponse
    let body: Body
}
