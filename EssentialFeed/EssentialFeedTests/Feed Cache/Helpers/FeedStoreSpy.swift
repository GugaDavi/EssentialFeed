//
//  FeedStoreSpy.swift
//  EssentialFeedTests
//
//  Created by Gustavo Guedes on 14/10/24.
//

import Foundation
import EssentialFeed

class FeedStoreSpy: FeedStore {
	var insertions = [(feed: [LocalFeedImage], timestamp: Date)]()
	
	enum ReceivedMessage: Equatable {
		case deleteCachedFeed
		case insert([LocalFeedImage], Date)
		case retrieve
	}
	
	private(set) var receivedMessagens = [ReceivedMessage]()
	
	private var deletionCompletions = [DeletionCompletion]()
	private var insertionCompletions = [InsertionCompletion]()
	private var retrievalCompletions = [RetrievalCompletion]()
	
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
	
	func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
		insertionCompletions.append(completion)
		receivedMessagens.append(.insert(feed, timestamp))
	}
	
	func completeInsertionSuccessfully(at index: Int = 0) {
		insertionCompletions[index](nil)
	}
	
	func retrieve(completion: @escaping RetrievalCompletion) {
		retrievalCompletions.append(completion)
		receivedMessagens.append(.retrieve)
	}
	
	func completeRetrieval(with error: Error, at index: Int = 0) {
		retrievalCompletions[index](.failure(error))
	}
	
	func completeRetrievalWithEmptyCache(at index: Int = 0) {
		retrievalCompletions[index](.empty)
	}
	
	func completeRetrieval(with feed: [LocalFeedImage], timestamp: Date, at index: Int = 0) {
		retrievalCompletions[index](.found(feed: feed, timestamp: timestamp))
	}
}
