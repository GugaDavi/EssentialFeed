//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Gustavo Guedes on 02/10/24.
//

import XCTest

protocol HTTPClient {
	func get(from url: URL)
}

class RemoteFeedLoader {
	let client: HTTPClient
	let url: URL
	
	init(url: URL, client: HTTPClient) {
		self.client = client
		self.url = url
	}
	
	func load() {
		client.get(from: url)
	}
}

final class RemoteFeedLoaderTests: XCTestCase {
	func test_init_doesNotRequestDataFromURL() {
		let (_, client) = makeSUT()
		
		XCTAssertNil(client.requestedURL)
	}
	
	func test_load_requestDataFromURL() {
		let url = URL(string: "https://a-given-url.com")!
		let (sut, client) = makeSUT(url: url)
		
		sut.load()
		
		XCTAssertEqual(client.requestedURL, url)
	}
	
	//MARK: - Helpers
	
	private func makeSUT(url: URL = URL(string: "https://a-url.com")!) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
		let client = HTTPClientSpy()
		return (sut: RemoteFeedLoader(url: url, client: client), client: client)
	}
	
	private class HTTPClientSpy: HTTPClient {
		var requestedURL: URL?
		
		func get(from url: URL) {
			requestedURL = url
		}
	}
}
