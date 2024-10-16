//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Gustavo Guedes on 02/10/24.
//

import XCTest
import EssentialFeed

final class LoadFeedFromRemoteUseCaseTests: XCTestCase {
	func test_init_doesNotRequestDataFromURL() {
		let (_, client) = makeSUT()
		
		XCTAssertTrue(client.requestedURLs.isEmpty)
	}
	
	func test_load_requestDataFromURL() {
		let url = URL(string: "https://a-given-url.com")!
		let (sut, client) = makeSUT(url: url)
		
		sut.load { _ in }
		
		XCTAssertEqual(client.requestedURLs, [url])
	}
	
	func test_load_requestDataFromURLTwice() {
		let url = URL(string: "https://a-given-url.com")!
		let (sut, client) = makeSUT(url: url)
		
		sut.load { _ in }
		sut.load { _ in }
		
		XCTAssertEqual(client.requestedURLs, [url, url])
	}
	
	func test_load_deliversErrorOnClientError() {
		let (sut, client) = makeSUT()
		
		expect(sut, toCompleteWith: failure(.connectivity), when: {
			let clientError = NSError(domain: "Test", code: 0)
			client.complete(with: clientError)
		})
	}
	
	func test_load_deliversErrorOnNon200HTTPResponse() {
		let (sut, client) = makeSUT()
		
		let samples = [199, 201, 300, 400, 500]
		
		samples.enumerated().forEach { index, code in
			expect(sut, toCompleteWith: failure(.invalidData), when: {
				let json  = makeItemsJSON([])
				client.complete(withStatusCode: code, data: json, at: index)
			})
		}
	}
	
	func test_load_deliveriesErrorOn200HTTPResponseWithInvalidJSON() {
		let (sut, client) = makeSUT()
		
		expect(sut, toCompleteWith: failure(.invalidData), when: {
			let invalidData = Data("invalid json".utf8)
			client.complete(withStatusCode: 200, data: invalidData)
		})
	}
	
	func test_load_deliversNoItemsOn200HTTPResponseWithEmptyJSONList() {
		let (sut, client) = makeSUT()
		
		expect(sut, toCompleteWith: .success([]), when: {
			let emtpyListJson = makeItemsJSON([])
			client.complete(withStatusCode: 200, data: emtpyListJson)
		})
	}
	
	func test_load_deliversItemOn200HTTPResponseWithJSONItems() {
		let (sut, client) = makeSUT()
		
		let (firstItem, firstJson) = makeItem(id: UUID(), imageURL: URL(string: "http://a-url.com")!)
		
		let (secondItem, secondJson) = makeItem(
			id: UUID(),
			imageURL: URL(string: "http://a-url.com")!,
			description: "a description",
			location: "a location"
		)
		
		expect(sut, toCompleteWith: .success([firstItem, secondItem]), when: {
			let json = makeItemsJSON([firstJson, secondJson])
			client.complete(withStatusCode: 200, data: json)
		})
	}
	
	func test_load_doesNotDeliveryResultAfterSUTInstanceHasBeenDeallocated() {
		let url = URL(string: "http://any-url.com")!
		let client = HTTPClientSpy()
		
		var sut: RemoteFeedLoader? = RemoteFeedLoader(url: url, client: client)
		
		var capturedResults = [RemoteFeedLoader.Result]()
		sut?.load { capturedResults.append($0) }
		
		sut = nil
		client.complete(withStatusCode: 200, data: makeItemsJSON([]))
		
		XCTAssertTrue(capturedResults.isEmpty)
	}
	
	//MARK: - Helpers
	
	private func failure(_ error: RemoteFeedLoader.Error) -> RemoteFeedLoader.Result {
		return .failure(error)
	}
	
	private func makeSUT(
		url: URL = URL(string: "https://a-url.com")!,
		file: StaticString = #filePath,
		line: UInt = #line
	) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
		let client = HTTPClientSpy()
		let sut = RemoteFeedLoader(url: url, client: client)
		
		trackForMemoryLeaks(sut, file: file, line: line)
		trackForMemoryLeaks(client, file: file, line: line)
		
		return (sut, client)
	}
	
	private func makeItem(
		id: UUID,
		imageURL: URL,
		description: String? = nil,
		location: String? = nil
	) -> (model: FeedItem, json: [String: Any]) {
		let item = FeedItem(
			id: id,
			imageURL: imageURL,
			description: description,
			location: location
		)
		
		let json = [
			"id": item.id.uuidString,
			"image": item.imageURL.absoluteString,
			"description": item.description,
			"location": item.location
		].reduce(into: [String: Any]()) { acc, e in
			if let value = e.value { acc[e.key] = value }
		}
		
		return (item, json)
	}
	
	private func makeItemsJSON(_ items: [[String: Any]]) -> Data {
		let json = ["items": items]
		return try! JSONSerialization.data(withJSONObject: json)
	}
	
	private func expect(
		_ sut: RemoteFeedLoader,
		toCompleteWith expectedResult: RemoteFeedLoader.Result,
		when action: () -> Void,
		file: StaticString = #filePath,
		line: UInt = #line
	) {
		let exp = expectation(description: "Wait for load completion")
		
		sut.load { receivedResult in
			switch (receivedResult, expectedResult) {
			case let (.success(receivedResult), .success(expectedResult)):
				XCTAssertEqual(receivedResult, expectedResult, file: file, line: line)
			case let (.failure(receivedError as RemoteFeedLoader.Error), .failure(expectedError as RemoteFeedLoader.Error)):
				XCTAssertEqual(receivedError, expectedError, file: file, line: line)
			default:
				XCTFail("Expected result \(expectedResult) get \(receivedResult) instead", file: file, line: line)
			}
			
			exp.fulfill()
		}
		
		action()
		
		wait(for: [exp], timeout: 1.0)
	}
	
	private class HTTPClientSpy: HTTPClient {
		private var messages = [(url: URL, completion: HTTPClientResponse)]()
		
		var requestedURLs: [URL] {
			return messages.map { $0.url }
		}
		
		func get(from url: URL, completion: @escaping HTTPClientResponse) {
			messages.append((url, completion))
		}
		
		func complete(with error: Error, at index: Int = 0) {
			messages[index].completion(.failure(error))
		}
		
		func complete(withStatusCode code: Int, data: Data, at index: Int = 0) {
			let response = HTTPURLResponse(
				url: requestedURLs[index], statusCode: code, httpVersion: nil, headerFields: nil
			)!
			messages[index].completion(.success(data, response))
		}
	}
}
