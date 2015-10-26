import XCTest
import RequestKit

class StringAdditionsTests: XCTestCase {
    func testStringByAppendingURLPath() {
        let subject = "https://something.com"
        XCTAssertEqual(subject.stringByAppendingURLPath("/login/oauth"), "https://something.com/login/oauth")
        XCTAssertEqual(subject.stringByAppendingURLPath("login/oauth"), "https://something.com/login/oauth")
    }

    func testURLEncodedString() {
        let subject = "something with a space:<3"
        XCTAssertEqual(subject.urlEncodedString(), "something%20with%20a%20space%3A%3C3")
    }
}
