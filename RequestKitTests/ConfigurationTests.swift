import XCTest
import RequestKit

class ConfigurationTests: XCTestCase {
    func testDefaultImplementation() {
        let config = TestConfiguration("1234", url: "https://github.com")
        XCTAssertEqual(config.apiEndpoint, "https://github.com")
        XCTAssertEqual(config.accessToken, "1234")
        XCTAssertEqual(config.accessTokenFieldName, "access_token")
        XCTAssertEqual(config.authorizationHeader, nil)
    }

    func testCustomImplementation() {
        let config = TestCustomConfiguration("1234", url: "https://github.com")
        XCTAssertEqual(config.apiEndpoint, "https://github.com")
        XCTAssertEqual(config.accessToken, "1234")
        XCTAssertEqual(config.accessTokenFieldName, "custom_field")
        XCTAssertEqual(config.authorizationHeader, nil)
    }
    
    func testAuthorizationHeaderConfiguration() {
        let config = TestAuthorizationHeaderConfiguration("1234", url: "https://github.com")
        XCTAssertEqual(config.apiEndpoint, "https://github.com")
        XCTAssertEqual(config.accessToken, "1234")
        XCTAssertEqual(config.accessTokenFieldName, "access_token")
        XCTAssertEqual(config.authorizationHeader, "BEARER")
    }
}

class TestConfiguration: Configuration {
    var apiEndpoint: String
    var accessToken: String?

    init(_ token: String, url: String) {
        apiEndpoint = url
        accessToken = token
    }
}

class TestCustomConfiguration: Configuration {
    var apiEndpoint: String
    var accessToken: String?

    init(_ token: String, url: String) {
        apiEndpoint = url
        accessToken = token
    }

    var accessTokenFieldName: String {
        return "custom_field"
    }
}

class TestAuthorizationHeaderConfiguration: Configuration {
    var apiEndpoint: String
    var accessToken: String?
    
    init(_ token: String, url: String) {
        apiEndpoint = url
        accessToken = token
    }

    var authorizationHeader: String? {
        return "BEARER"
    }
}
