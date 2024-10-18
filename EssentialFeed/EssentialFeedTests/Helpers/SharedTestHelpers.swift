//
//  SharedTestHelpers.swift
//  EssentialFeedTests
//
//  Created by Gustavo Guedes on 15/10/24.
//

import Foundation

func anyNSError() -> NSError {
	return NSError(domain: "any error", code: 0)
}

func anyURL() -> URL {
	return URL(string: "http://any-url.com")!
}
