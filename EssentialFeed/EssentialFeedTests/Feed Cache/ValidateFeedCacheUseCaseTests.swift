//
//  ValidateFeedCacheUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Gustavo Guedes on 15/10/24.
//

import XCTest
import EssentialFeed

final class ValidateFeedCacheUseCaseTests: XCTestCase {
	func test_init_doesNotMessageStoreUponCreation() {
		let store = makeSUT().store
		
		XCTAssertEqual(store.receivedMessagens, [])
	}
	
	func test_validateCache_deletesCacheOnRetrievalErro() {
		let (sut, store) = makeSUT()
		
		sut.validateCache()
		store.completeRetrieval(with: anyNSError())
		
		XCTAssertEqual(store.receivedMessagens, [.retrieve, .deleteCachedFeed])
	}
	
	func test_validateCache_doesNotDeleteCacheOnEmptyCache() {
		let (sut, store) = makeSUT()
		
		sut.validateCache()
		store.completeRetrievalWithEmptyCache()
		
		XCTAssertEqual(store.receivedMessagens, [.retrieve])
	}
	
	func test_validateCache_doesNotDeleteNonExpiredCache() {
		let feed = uniqueImageFeed()
		let fixedCurrentDate = Date()
		let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
		let nonExpiredTimestamp = fixedCurrentDate.minusFeedCacheMaxAge().adding(seconds: 1)
		
		sut.validateCache()
		store.completeRetrieval(with: feed.local, timestamp: nonExpiredTimestamp)
		
		XCTAssertEqual(store.receivedMessagens, [.retrieve])
	}

	func test_validateCache_deletesCacheExpiration() {
		let feed = uniqueImageFeed()
		let fixedCurrentDate = Date()
		let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
		let expirationTimestamp = fixedCurrentDate.minusFeedCacheMaxAge()
		
		sut.validateCache()
		store.completeRetrieval(with: feed.local, timestamp: expirationTimestamp)
		
		XCTAssertEqual(store.receivedMessagens, [.retrieve, .deleteCachedFeed])
	}
	
	func test_validateCache_deletesExpiredCache() {
		let feed = uniqueImageFeed()
		let fixedCurrentDate = Date()
		let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
		let expiredTimestamp = fixedCurrentDate.minusFeedCacheMaxAge().adding(seconds: -1)
		
		sut.validateCache()
		store.completeRetrieval(with: feed.local, timestamp: expiredTimestamp)
		
		XCTAssertEqual(store.receivedMessagens, [.retrieve, .deleteCachedFeed])
	}
	
	func test_validateCache_doesNotDeleteInvalidCacheAfterSUTInstanceHasBeenDeallocated() {
		let store = FeedStoreSpy()
		var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
		
		sut?.validateCache()
		
		sut = nil
		store.completeRetrieval(with: anyNSError())
		
		XCTAssertEqual(store.receivedMessagens, [.retrieve])
	}
	
	//MARK: - Helpers
	
	private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #filePath, line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
		let store = FeedStoreSpy()
		let sut = LocalFeedLoader(store: store, currentDate: currentDate)
		trackForMemoryLeaks(store, file: file, line: line)
		trackForMemoryLeaks(sut, file: file, line: line)
		return (sut, store)
	}
}
