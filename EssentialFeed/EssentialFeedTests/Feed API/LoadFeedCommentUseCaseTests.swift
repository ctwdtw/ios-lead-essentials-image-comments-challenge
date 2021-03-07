//
//  LoadImageCommentsFromRemoteUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Paul Lee on 2021/3/7.
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import XCTest
import EssentialFeed

public class ImageCommentsLoader {
	private let client: HTTPClient
	public init(client: HTTPClient) {
		self.client = client
	}
}

class LoadImageCommentsFromRemoteUseCaseTests: XCTestCase {
	func test_init_doesNotRequestDataFromURL() {
		let httpSpy = HTTPClientSpy()
		let _ = ImageCommentsLoader(client: httpSpy)
		
		XCTAssertEqual(httpSpy.requestedURLs, [])
	}
	
}
