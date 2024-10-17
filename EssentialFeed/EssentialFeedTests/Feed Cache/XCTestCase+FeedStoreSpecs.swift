//
//  XCTestCase+FeedStoreSpecs.swift
//  EssentialFeedTests
//
//  Created by Gustavo Guedes on 17/10/24.
//

import XCTest
import EssentialFeed

extension FeedStoreSpecs where Self: XCTestCase {
	func expect(_ sut: FeedStore, toRetrieveTwice expectedResult: RetrievalcachedFeedResult, file: StaticString = #filePath, line: UInt = #line) {
		expect(sut, toRetrieve: expectedResult, file: file, line: line)
		expect(sut, toRetrieve: expectedResult, file: file, line: line)
	}
	
	func expect(_ sut: FeedStore, toRetrieve expectedResult: RetrievalcachedFeedResult, file: StaticString = #filePath, line: UInt = #line) {
		let exp = expectation(description: "Wait for cache retrieval")
		
		sut.retrieve { retrievedResult in
			switch (expectedResult, retrievedResult) {
			case (.empty, .empty), (.failure, .failure):
				break
			case let (.found(expectedFeed, expectedTimestamp), .found(retrievedFeed, retrievedTimestamp)):
				XCTAssertEqual(expectedFeed, retrievedFeed)
				XCTAssertEqual(expectedTimestamp, retrievedTimestamp)
			default:
				XCTFail("Expected to retreive \(expectedResult), got \(retrievedResult) instead")
			}
			
			exp.fulfill()
		}
		
		wait(for: [exp], timeout: 1)
	}
	
	@discardableResult
	func deleteCache(from sut: FeedStore) -> Error? {
		let exp = expectation(description: "Wait for cache deletion")
		var deletionError: Error? = nil
		sut.deleteCachedFeed { error in
			deletionError = error
			exp.fulfill()
		}
		wait(for: [exp], timeout: 1)
		return deletionError
	}
	
	@discardableResult
	func insert(_ cache: (feed: [LocalFeedImage], timestamp: Date), to sut: FeedStore) -> Error? {
		let exp = expectation(description: "Wait for cache insertion")
		
		var receivedError: Error? = nil
		sut.insert(cache.feed, timestamp: cache.timestamp) { insertionError in
			receivedError = insertionError
			exp.fulfill()
		}
		
		wait(for: [exp], timeout: 1)
		return receivedError
	}
}
