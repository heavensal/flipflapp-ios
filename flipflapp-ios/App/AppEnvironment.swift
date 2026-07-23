import Foundation

struct AppEnvironment {
    let api: APIClient
    let tokenStore: any TokenStoring
}
