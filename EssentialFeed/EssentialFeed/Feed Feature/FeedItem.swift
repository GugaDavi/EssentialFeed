//
//  Copyright © Essential Developer. All rights reserved.
//

import Foundation

public struct FeedItem: Equatable {
	public let id: UUID
	public let description: String?
	public let location: String?
	public let imageURL: URL
	
	public init(id: UUID, imageURL: URL, description: String? = nil, location: String? = nil) {
		self.id = id
		self.description = description
		self.location = location
		self.imageURL = imageURL
	}
}
