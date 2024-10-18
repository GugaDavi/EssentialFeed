//
//  LoadFeedFromCacheUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Gustavo Guedes on 14/10/24.
//

import XCTest
import EssentialFeed

class LoadFeedFromCacheUseCaseTests: XCTestCase {
	func test_init_doesNotMessageStoreUponCreation() {
		let store = makeSUT().store
		
		XCTAssertEqual(store.receivedMessagens, [])
	}
	
	func test_load_requestsCacheRetrieval() {
		let (sut, store) = makeSUT()
		
		sut.load() { _ in }
		
		XCTAssertEqual(store.receivedMessagens, [.retrieve])
	}
	
	func test_load_failsOnRetrievalError() {
		let (sut, store) = makeSUT()
		let retrievalError = anyNSError()
		
		expect(sut, toCompleteWith: .failure(retrievalError), when: {
			store.completeRetrieval(with: retrievalError)
		})
	}
	
	func test_load_deliversNoImagesOnEmptyCache() {
		let (sut, store) = makeSUT()
		
		expect(sut, toCompleteWith: .success([]), when: {
			store.completeRetrievalWithEmptyCache()
		})
	}
	
	func test_load_deliversCachedImagesOnNonExpiredCache() {
		let feed = uniqueImageFeed()
		let fixedCurrentDate = Date()
		let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
		let nonExpiredTimestamp = fixedCurrentDate.minusFeedCacheMaxAge().adding(seconds: 1)
		
		expect(sut, toCompleteWith: .success(feed.models), when: {
			store.completeRetrieval(with: feed.local, timestamp: nonExpiredTimestamp)
		})
	}
	
	func test_load_deliversNoImagesOnCacheExpiration() {
		let feed = uniqueImageFeed()
		let fixedCurrentDate = Date()
		let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
		let expirationTimestamp = fixedCurrentDate.minusFeedCacheMaxAge()
		
		expect(sut, toCompleteWith: .success([]), when: {
			store.completeRetrieval(with: feed.local, timestamp: expirationTimestamp)
		})
	}
	
	func test_load_deliversNoImagesOnExpiredCache() {
		let feed = uniqueImageFeed()
		let fixedCurrentDate = Date()
		let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
		let expiredTimestamp = fixedCurrentDate.minusFeedCacheMaxAge().adding(seconds: -1)
		
		expect(sut, toCompleteWith: .success([]), when: {
			store.completeRetrieval(with: feed.local, timestamp: expiredTimestamp)
		})
	}
	
	func test_load_hasNoSideEffectsOnRetrievalErro() {
		let (sut, store) = makeSUT()
		
		sut.load { _ in }
		store.completeRetrieval(with: anyNSError())
		
		XCTAssertEqual(store.receivedMessagens, [.retrieve])
	}
	
	func test_load_hasNoSideEffectsOnEmptyCache() {
		let (sut, store) = makeSUT()
		
		sut.load { _ in }
		store.completeRetrievalWithEmptyCache()
		
		XCTAssertEqual(store.receivedMessagens, [.retrieve])
	}
	
	func test_load_hasNoSideEffectsOnNonExpiredCache() {
		let feed = uniqueImageFeed()
		let fixedCurrentDate = Date()
		let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
		let nonExpiredTimestamp = fixedCurrentDate.minusFeedCacheMaxAge().adding(seconds: 1)
		
		sut.load { _ in }
		store.completeRetrieval(with: feed.local, timestamp: nonExpiredTimestamp)
		
		XCTAssertEqual(store.receivedMessagens, [.retrieve])
	}
	
	func test_load_hasNoSideEffectsOnCacheExpiration() {
		let feed = uniqueImageFeed()
		let fixedCurrentDate = Date()
		let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
		let expirationTimestamp = fixedCurrentDate.minusFeedCacheMaxAge()
		
		sut.load { _ in }
		store.completeRetrieval(with: feed.local, timestamp: expirationTimestamp)
		
		XCTAssertEqual(store.receivedMessagens, [.retrieve])
	}
	
	func test_load_hasNoSideEffectsOnExpiredCache() {
		let feed = uniqueImageFeed()
		let fixedCurrentDate = Date()
		let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
		let expiredTimestamp = fixedCurrentDate.minusFeedCacheMaxAge().adding(seconds: -1)
		
		sut.load { _ in }
		store.completeRetrieval(with: feed.local, timestamp: expiredTimestamp)
		
		XCTAssertEqual(store.receivedMessagens, [.retrieve])
	}
	
	func test_load_doesNotDeliverResultAfterSUTInstanceHasBeenDeallocated() {
		let store = FeedStoreSpy()
		var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
		
		var receivedResults = [LocalFeedLoader.LoadResult]()
		sut?.load { receivedResults.append($0) }
		
		sut = nil
		store.completeRetrievalWithEmptyCache()
		
		XCTAssertTrue(receivedResults.isEmpty)
	}
	
	//MARK: - Helpers
	
	private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #filePath, line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
		let store = FeedStoreSpy()
		let sut = LocalFeedLoader(store: store, currentDate: currentDate)
		trackForMemoryLeaks(store, file: file, line: line)
		trackForMemoryLeaks(sut, file: file, line: line)
		return (sut, store)
	}
	
	private func expect(_ sut: LocalFeedLoader, toCompleteWith expectedResult: LocalFeedLoader.LoadResult, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
		
		let exp = expectation(description: "Wait for load completion")
		
		sut.load() { receivedResult in
			switch (receivedResult, expectedResult) {
			case let (.success(receivedImages), .success(expectedImages)):
				XCTAssertEqual(receivedImages, expectedImages, file: file, line: line)
			case let (.failure(receivedError as NSError), .failure(expectedError as NSError)):
				XCTAssertEqual(receivedError, expectedError, file: file, line: line)
			default:
				XCTFail("Expected result \(expectedResult), got \(receivedResult) instead", file: file, line: line)
			}
			exp.fulfill()
		}
		
		action()
		wait(for: [exp], timeout: 1)
	}
}
