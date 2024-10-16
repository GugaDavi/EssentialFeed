//
//  LocalFeedImage.swift
//  EssentialFeed
//
//  Created by Gustavo Guedes on 14/10/24.
//

import Foundation

public struct LocalFeedImage: Equatable, Codable {
	public let id: UUID
	public let description: String?
	public let location: String?
	public let url: URL
	
	public init(id: UUID, url: URL, description: String? = nil, location: String? = nil) {
		self.id = id
		self.description = description
		self.location = location
		self.url = url
	}
}
