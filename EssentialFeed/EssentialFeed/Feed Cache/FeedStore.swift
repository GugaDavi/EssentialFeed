//
//  FeedStore.swift
//  EssentialFeed
//
//  Created by Gustavo Guedes on 14/10/24.
//

import Foundation

public enum RetrievalcachedFeedResult {
	case empty
	case found(feed: [LocalFeedImage], timestamp: Date)
	case failure(Error)
}

public protocol FeedStore {
	typealias DeletionCompletion = (Error?) -> Void
	typealias InsertionCompletion = (Error?) -> Void
	typealias RetrievalCompletion = (RetrievalcachedFeedResult) -> Void
	
	func deleteCachedFeed(completion: @escaping DeletionCompletion)
	func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion)
	func retrieve(completion: @escaping RetrievalCompletion)
}

