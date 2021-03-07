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
	
	public enum Error: Swift.Error {
		case connectivity
		case invalidData
	}
	
	public typealias LoadImageCommentsCompletion = (Error?) -> Void
	
	public func loadImageComments(completion: @escaping LoadImageCommentsCompletion) {
		client.get(from: url) { (result) in
			switch result {
			case .success((_, _)):
				completion(Error.invalidData)
				
			case .failure(_):
				completion(Error.connectivity)
			}
		}
	}
}

class LoadImageCommentsFromRemoteUseCaseTests: XCTestCase {
	func test_init_doesNotRequestDataFromURL() {
		// given
		
		// when
		let (_, httpSpy) = makeSUT()
		
		// then
		XCTAssertEqual(httpSpy.requestedURLs, [])
	}
	
	func test_loadImageComments_requestDataFromURL() {
		// given
		let url = anyURL()
		let (sut, httpSpy) = makeSUT(url: url)
		
		// when
		sut.loadImageComments { _ in }
		
		// then
		XCTAssertEqual(httpSpy.requestedURLs, [url])
	}
	
	func test_loadImageCommentsTwice_requestDataFromURLTwice() {
		// given
		let url = anyURL()
		let (sut, httpSpy) = makeSUT(url: url)
		
		// when
		sut.loadImageComments { _ in }
		sut.loadImageComments { _ in }
		
		// then
		XCTAssertEqual(httpSpy.requestedURLs, [url, url])
	}
	
	func test_loadImageComments_deliversConnectivityErrorOnClientError() {
		// given
		let (sut, httpSpy) = makeSUT()
		
		// when, then
		expect(sut, toReceive: .connectivity, when: {
			httpSpy.complete(with: anyNSError())
		})
	}
	
	func test_loadImageComments_deliversInvalidDataErrorOnNon2xxHTTPResponse() {
		// given
		let (sut, httpSpy) = makeSUT()
		
		let non2xxStatusCodes = [100, 300, 400, 500]
		
		non2xxStatusCodes.enumerated().forEach { (index, statusCode) in
			// when, then
			expect(sut, toReceive: .invalidData,
				   when: { httpSpy.complete(withStatusCode: statusCode, data: anyData(), at: index) },
				   at: index
			)
		}
	}
	
	private func makeSUT(
		url: URL = anyURL(),
		file: StaticString = #file,
		line: UInt = #line
	) -> (ImageCommentsLoader, HTTPClientSpy)
	{
		let httpSpy = HTTPClientSpy()
		let sut = ImageCommentsLoader(url: url, client: httpSpy)
		trackForMemoryLeaks(httpSpy, file: file, line: line)
		trackForMemoryLeaks(sut, file: file, line: line)
		return (sut, httpSpy)
	}
	
	private func expect(
		_ sut: ImageCommentsLoader,
		toReceive expectedError: ImageCommentsLoader.Error,
		when action: ()-> Void,
		at index: Int = 0,
		file: StaticString = #file,
		line: UInt = #line
	) {
		
		// when
		var receivedErrors = [ImageCommentsLoader.Error?]()
		sut.loadImageComments { receivedErrors.append($0) }
		action()
		
		// then
		XCTAssertEqual(
			receivedErrors,
			[expectedError],
			"expect to receive \(expectedError), but got \(receivedErrors) instead, at index: \(index)",
			file: file,
			line: line
		)
	}

}
