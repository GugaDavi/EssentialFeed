//
//  FeedCachePolicy.swift
//  EssentialFeed
//
//  Created by Gustavo Guedes on 15/10/24.
//

import Foundation

final class FeedCachePolicy {
	private init() {}
	
	private static let calendar = Calendar(identifier: .gregorian)
	
	private static let maxAgeCacheInDays: Int = 7
	
	static func validate(_ timestamp: Date, against date: Date) -> Bool {
		guard let maxCacheAge = calendar.date(byAdding: .day, value: maxAgeCacheInDays, to: timestamp) else {
			return false
		}
		
		return date < maxCacheAge
	}
}
