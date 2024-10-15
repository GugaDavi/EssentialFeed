//
//  FeedStore.swift
//  EssentialFeed
//
//  Created by Gustavo Guedes on 14/10/24.
//

import Foundation

public protocol FeedStore {
	typealias DeletionCompletion = (Error?) -> Void
	typealias InsertionCompletion = (Error?) -> Void
	
	func deleteCachedFeed(completion: @escaping DeletionCompletion)
	func insert(_ items: [FeedItem], timestamp: Date, completion: @escaping InsertionCompletion)
}
