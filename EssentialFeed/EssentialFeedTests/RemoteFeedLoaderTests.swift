//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Gustavo Guedes on 02/10/24.
//

import XCTest

class HTTPClient {
	static let shared = HTTPClient()
	
	private init() {}
	
	var requestURL: URL?
}

class RemoteFeedLoader {
	func load() {
		HTTPClient.shared.requestURL = URL(string: "https://a-url.com")
	}
}

final class RemoteFeedLoaderTests: XCTestCase {
	func test_init_doesNotRequestDataFromURL() {
		let client = HTTPClient.shared
		let sut = RemoteFeedLoader()
		
		XCTAssertNil(client.requestURL)
	}

	func test_load_requestDataFromURL() {
		let client = HTTPClient.shared
		let sut = RemoteFeedLoader()
		
		sut.load()
		
		XCTAssertNotNil(client.requestURL)
	}
}
