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
	private let url: URL
	public init(url: URL, client: HTTPClient) {
		self.url = url
		self.client = client
	}
	
	public func loadImageComments() {
		client.get(from: url) { (_) in
			
		}
	}
}

class LoadImageCommentsFromRemoteUseCaseTests: XCTestCase {
	func test_init_doesNotRequestDataFromURL() {
		// given
		let url = anyURL()
		let httpSpy = HTTPClientSpy()
		
		// when
		let _ = ImageCommentsLoader(url: url, client: httpSpy)
		
		// then
		XCTAssertEqual(httpSpy.requestedURLs, [])
	}
	
	func test_loadImageComments_requestDataFromURL() {
		// given
		let url = anyURL()
		let httpSpy = HTTPClientSpy()
		let sut = ImageCommentsLoader(url: url, client: httpSpy)
		
		// when
		sut.loadImageComments()
		
		// then
		XCTAssertEqual(httpSpy.requestedURLs, [url])
	}
}
