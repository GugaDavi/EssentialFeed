//
//  CacheFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Gustavo Guedes on 10/10/24.
//

import XCTest
import EssentialFeed

class CacheFeedUseCaseTests: XCTestCase {
	func test_init_doesNotMessageStoreUponCreation() {
		let store = makeSUT().store
		
		XCTAssertEqual(store.receivedMessagens, [])
	}
	
	func test_save_requestsCacheDeletion() {
		let (sut, store) = makeSUT()
		
		sut.save(uniqueItems().models) { _ in }
		
		XCTAssertEqual(store.receivedMessagens, [.deleteCachedFeed])
	}
	
	func test_save_doesNotRequestCacheInsertionOnDeleteError() {
		let (sut, store) = makeSUT()
		let deletionError = anyNSError()
		
		sut.save(uniqueItems().models) { _ in }
		store.completeDeletion(with: deletionError)
		
		XCTAssertEqual(store.receivedMessagens, [.deleteCachedFeed])
	}
	
	func test_save_requestsNewCacheInsertionWithTimestampOnSuccessfulDeletion() {
		let timestamp = Date()
		let (models: items, local: localItems) = uniqueItems()
		let (sut, store) = makeSUT(currentDate: { timestamp })
		
		sut.save(items) { _ in }
		store.completeDeletionSuccessfully()
		
		XCTAssertEqual(store.receivedMessagens, [.deleteCachedFeed, .insert(localItems, timestamp)])
	}
	
	func test_save_failsOnDeleteError() {
		let (sut, store) = makeSUT()
		let deletionError = anyNSError()
		
		expect(sut, toCompleteWithError: deletionError, when: {
			store.completeDeletion(with: deletionError)
		})
	}
	
	func test_save_failsOnInsertionError() {
		let (sut, store) = makeSUT()
		let insertionError = anyNSError()
		
		expect(sut, toCompleteWithError: insertionError, when: {
			store.completeDeletionSuccessfully()
			store.completeInsertion(with: insertionError)
		})
	}
	
	func test_save_succeedsOnSuccessfulCacheInsertion() {
		let (sut, store) = makeSUT()
		
		expect(sut, toCompleteWithError: nil, when: {
			store.completeDeletionSuccessfully()
			store.completeInsertionSuccessfully()
		})
	}
	
	func test_save_doesNotDeliverDeletionErrorAfterSUTInstanceHasBeenDeallocated() {
		let store = FeedStoreSpy()
		var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
		
		var receivedResults = [LocalFeedLoader.SaveResult]()
		sut?.save(uniqueItems().models) { receivedResults.append($0) }
		
		sut = nil
		store.completeDeletion(with: anyNSError())
		
		XCTAssertTrue(receivedResults.isEmpty)
	}
	
	func test_save_doesNotDeliverInsertionErrorAfterSUTInstanceHasBeenDeallocated() {
		let store = FeedStoreSpy()
		var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
		
		var receivedResults = [LocalFeedLoader.SaveResult]()
		sut?.save(uniqueItems().models) { receivedResults.append($0) }
		
		store.completeDeletionSuccessfully()
		sut = nil
		store.completeInsertion(with: anyNSError())
		
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
	
	private func expect(_ sut: LocalFeedLoader, toCompleteWithError expectedError: NSError?, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
		let exp = expectation(description: "Wait for save completion")
		
		var receivedError: Error?
		sut.save(uniqueItems().models) { error in
			receivedError = error
			exp.fulfill()
		}
		action()
		
		wait(for: [exp], timeout: 1)
		XCTAssertEqual(receivedError as NSError?, expectedError, file: file, line: line)
	}
	
	private func uniqueFeedItem() -> FeedItem {
		return FeedItem(id: UUID(), imageURL: anyURL())
	}
	
	private func uniqueItems() -> (models: [FeedItem], local: [LocalFeedItem]) {
		let models = [uniqueFeedItem(), uniqueFeedItem()]
		let local = models.map { LocalFeedItem(id: $0.id, imageURL: $0.imageURL, description: $0.description, location: $0.location) }
		
		return (models, local)
	}
	
	private func anyURL() -> URL {
		return URL(string: "http://any-url.com")!
	}
	
	private func anyNSError() -> NSError {
		return NSError(domain: "any error", code: 0)
	}
	
	private class FeedStoreSpy: FeedStore {
		var insertions = [(items: [LocalFeedItem], timestamp: Date)]()
		
		enum ReceivedMessage: Equatable {
			case deleteCachedFeed
			case insert([LocalFeedItem], Date)
		}
		
		private(set) var receivedMessagens = [ReceivedMessage]()
		
		private var deletionCompletions = [DeletionCompletion]()
		private var insertionCompletions = [InsertionCompletion]()
		
		func deleteCachedFeed(completion: @escaping DeletionCompletion) {
			deletionCompletions.append(completion)
			receivedMessagens.append(.deleteCachedFeed)
		}
		
		func completeDeletion(with error: Error, at index: Int = 0) {
			deletionCompletions[index](error)
		}
		
		func completeDeletionSuccessfully(at index: Int = 0) {
			deletionCompletions[index](nil)
		}
		
		func completeInsertion(with error: Error, at index: Int = 0) {
			insertionCompletions[index](error)
		}
		
		func insert(_ items: [LocalFeedItem], timestamp: Date, completion: @escaping InsertionCompletion) {
			insertionCompletions.append(completion)
			receivedMessagens.append(.insert(items, timestamp))
		}
		
		func completeInsertionSuccessfully(at index: Int = 0) {
			insertionCompletions[index](nil)
		}
	}
}
