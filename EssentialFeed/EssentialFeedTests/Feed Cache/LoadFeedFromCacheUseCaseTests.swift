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
	
	func test_load_deliversCachedImagesOnLessThenSevenDaysOldCache() {
		let feed = uniqueImageFeed()
		let fixedCurrentDate = Date()
		let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
		let lessThanSevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7).adding(seconds: 1)
		
		expect(sut, toCompleteWith: .success(feed.models), when: {
			store.completeRetrieval(with: feed.local, timestamp: lessThanSevenDaysOldTimestamp)
		})
	}
	
	func test_load_deliversNoImagesOnSevenDaysOldCache() {
		let feed = uniqueImageFeed()
		let fixedCurrentDate = Date()
		let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
		let lessThanSevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7)
		
		expect(sut, toCompleteWith: .success([]), when: {
			store.completeRetrieval(with: feed.local, timestamp: lessThanSevenDaysOldTimestamp)
		})
	}
	
	func test_load_deliversCachedImagesOnMoreThenSevenDaysOldCache() {
		let feed = uniqueImageFeed()
		let fixedCurrentDate = Date()
		let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
		let moreThanSevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7).adding(seconds: -1)
		
		expect(sut, toCompleteWith: .success([]), when: {
			store.completeRetrieval(with: feed.local, timestamp: moreThanSevenDaysOldTimestamp)
		})
	}
	
	func test_load_deletesCacheOnRetrievalErro() {
		let (sut, store) = makeSUT()
		
		sut.load { _ in }
		store.completeRetrieval(with: anyNSError())
		
		XCTAssertEqual(store.receivedMessagens, [.retrieve, .deleteCachedFeed])
	}
	
	func test_load_doesNotDeleteCacheOnEmptyCache() {
		let (sut, store) = makeSUT()
		
		sut.load { _ in }
		store.completeRetrievalWithEmptyCache()
		
		XCTAssertEqual(store.receivedMessagens, [.retrieve])
	}
	
	func test_load_doesNotDeleteCacheOnLessThanSevenDaysOldCache() {
		let feed = uniqueImageFeed()
		let fixedCurrentDate = Date()
		let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
		let lessThanSevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7).adding(seconds: 1)
		
		sut.load { _ in }
		store.completeRetrieval(with: feed.local, timestamp: lessThanSevenDaysOldTimestamp)
		
		XCTAssertEqual(store.receivedMessagens, [.retrieve])
	}
	
	func test_load_deletesCacheOnSevenDaysOldCache() {
		let feed = uniqueImageFeed()
		let fixedCurrentDate = Date()
		let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
		let sevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7)
		
		sut.load { _ in }
		store.completeRetrieval(with: feed.local, timestamp: sevenDaysOldTimestamp)
		
		XCTAssertEqual(store.receivedMessagens, [.retrieve, .deleteCachedFeed])
	}
	
	func test_load_deletesCacheOnMoreThanSevenDaysOldCache() {
		let feed = uniqueImageFeed()
		let fixedCurrentDate = Date()
		let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
		let moreThanSevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7).adding(seconds: -1)
		
		sut.load { _ in }
		store.completeRetrieval(with: feed.local, timestamp: moreThanSevenDaysOldTimestamp)
		
		XCTAssertEqual(store.receivedMessagens, [.retrieve, .deleteCachedFeed])
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
	
	private func anyNSError() -> NSError {
		return NSError(domain: "any error", code: 0)
	}
	
	private func uniqueFeedImage() -> FeedImage {
		return FeedImage(id: UUID(), url: anyURL())
	}
	
	private func anyURL() -> URL {
		return URL(string: "http://any-url.com")!
	}
	
	private func uniqueImageFeed() -> (models: [FeedImage], local: [LocalFeedImage]) {
		let models = [uniqueFeedImage(), uniqueFeedImage()]
		let local = models.map { LocalFeedImage(id: $0.id, url: $0.url, description: $0.description, location: $0.location) }
		
		return (models, local)
	}
}

private extension Date {
	func adding(days: Int) -> Date {
		return Calendar(identifier: .gregorian).date(byAdding: .day, value: days, to: self)!
	}
	
	func adding(seconds: TimeInterval) -> Date {
		return self + seconds
	}
}
