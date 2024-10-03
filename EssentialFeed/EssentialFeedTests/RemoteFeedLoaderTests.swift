//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Gustavo Guedes on 02/10/24.
//

import XCTest

class HTTPClient {
	var requestURL: URL?
}

class RemoteFeedLoader {}

final class RemoteFeedLoaderTests: XCTestCase {
	func test_init_doesNotRequestDataFromURL() {
		let client = HTTPClient()
		let sut = RemoteFeedLoader()
		
		XCTAssertNil(client.requestURL)
	}

}
