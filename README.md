# NClient

Minimal Swift API client based on async/await.

Setup and start to run a client in just few steps with NClient:
* Initialize the `APIClient` by specifying the client server `baseUrl`.
* Implement the data model and conform the `Endpoint` to define the network requests.
* Execute these requests and decode them responses using the `performEndpointRequest` method.

The `APIClient` uses an underlying `URLSession` for handling network requests. The design of this component follows the principle of "less is more", avoiding unnecessary abstractions beyond the native APIs.

## Usage

Let's provide a usage example so you can see how simple and straightforward is to develop a client using the NClient package. For this demo we are going to setup a client to fetch github user data. The related endpoint is: `https://api.github.com/user/{id}`.

As we say earlier, start initializing the `APIClient`:

```swift
import NClient

let githubBaseUrl = URL(string: "https://api.github.com")!
let client = APIClient(baseUrl: githubBaseUrl)
```

Implement the data model. The expected body response in this case:

```swift
struct User: Decodable {
    let id: Int
    let login: String
    // Rest of properties
}
```

Define the fetch user endpoint by conforming `Endpoint`:
```swift
struct FetchUserEndpoint: Endpoint {
    struct Parameters {
        let id: Int
    }

    typealias ResponseBody = User

    func url(parameters: Parameters) -> URLComponents {
        .init(path: "/user/\(parameters.id)")
    }
}
```

Call `performEndpointRequest` to execute the request and get the data needed:
```swift
func fetchUser(by id: Int) async throws -> User {
    try await client.performEndpointRequest(
        endpoint: FetchUserEndpoint(),
        parameters: .init(id: id),
        requestBody: .empty
    ).body
}
```

And that's it!

## Release History

* 1.1
    * Initial Version
