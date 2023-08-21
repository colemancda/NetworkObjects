import XCTest
@testable import NetworkObjects

final class NetworkObjectsTests: XCTestCase {
    
    func testURL() throws {
        let server = URL(string: "https://api.swift-app.com")!
        let id = UUID(uuidString: "8ACA7D6F-8346-4317-9692-B61AA35747E2")!
        
        XCTAssertEqual(NetworkObjectsURI<Person>.fetch(id).url(for: server).absoluteString, "https://api.swift-app.com/person/8ACA7D6F-8346-4317-9692-B61AA35747E2")
        XCTAssertEqual(NetworkObjectsURI<Person>.edit(id).url(for: server).absoluteString, "https://api.swift-app.com/person/8ACA7D6F-8346-4317-9692-B61AA35747E2")
        XCTAssertEqual(NetworkObjectsURI<Person>.delete(id).url(for: server).absoluteString, "https://api.swift-app.com/person/8ACA7D6F-8346-4317-9692-B61AA35747E2")
        XCTAssertEqual(NetworkObjectsURI<Person>.create.url(for: server).absoluteString, "https://api.swift-app.com/person")
    }
}
