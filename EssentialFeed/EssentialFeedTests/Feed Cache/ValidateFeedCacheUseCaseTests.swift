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
	
	func test_validateCache_doesNotDeleteCacheOnLessThanSevenDaysOldCache() {
		let feed = uniqueImageFeed()
		let fixedCurrentDate = Date()
		let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
		let lessThanSevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7).adding(seconds: 1)
		
		sut.validateCache()
		store.completeRetrieval(with: feed.local, timestamp: lessThanSevenDaysOldTimestamp)
		
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
