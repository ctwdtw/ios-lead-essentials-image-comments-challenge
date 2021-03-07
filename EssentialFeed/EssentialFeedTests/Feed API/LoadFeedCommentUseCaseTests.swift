//
//  LoadImageCommentsFromRemoteUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Paul Lee on 2021/3/7.
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import XCTest
import EssentialFeed

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
		expect(sut, toReceive: [.failure(.connectivity)], when: {
			httpSpy.complete(with: anyNSError())
		})
	}
	
	func test_loadImageComments_deliversInvalidDataErrorOnNon2xxHTTPResponse() {
		// given
		let (sut, httpSpy) = makeSUT()
		
		let non2xxStatusCodes = [100, 300, 400, 500]
		
		non2xxStatusCodes.enumerated().forEach { (index, statusCode) in
			// when, then
			expect(sut, toReceive: [.failure(.invalidData)],
				   when: { httpSpy.complete(withStatusCode: statusCode, data: anyData(), at: index) },
				   at: index
			)
		}
	}
	
	func test_loadImageComments_deliversInvalidDataErrorOn200HTTPResponseWithInvalidJSON() {
		// given
		let (sut, httpSpy) = makeSUT()
		
		// when, then
		expect(sut, toReceive: [.failure(.invalidData)], when: {
			let invalidJSON = "invalidJSON".data(using: .utf8)!
			httpSpy.complete(withStatusCode: 200, data: invalidJSON)
		})
	}
	
	func test_loadImageComments_deliversEmptyItemsOn200HTTPResonseWithEmptyItemJSON() {
		// given
		let (sut, httpSpy) = makeSUT()
		
		// when, then
		expect(sut, toReceive: [.success([])], when: {
			let jsonRawString = """
					{ "items": [] }
				"""
			let emptyItemJSON = jsonRawString.data(using: .utf8)!
			
			httpSpy.complete(withStatusCode: 200, data: emptyItemJSON)
		})
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
		toReceive expectedResults: [ImageCommentsLoader.LoadImageCommentsResult],
		when action: ()-> Void,
		at index: Int = 0,
		file: StaticString = #file,
		line: UInt = #line
	) {
		
		// when
		var receivedResults = [ImageCommentsLoader.LoadImageCommentsResult]()
		sut.loadImageComments { receivedResults.append($0) }
		action()
		
		// then
		XCTAssertEqual(
			receivedResults.count,
			expectedResults.count,
			"expected to received \(expectedResults.count) results, but got \(receivedResults.count) instead",
			file: file, line: line)
		
		zip(receivedResults, expectedResults).forEach { resultPair in
			switch resultPair {
			case let (.success(receivedItems), .success(expectedItems)):
				XCTAssertEqual(receivedItems, expectedItems, file: file, line: line)
			
			case let (.failure(receivedError), .failure(expectedError)):
				XCTAssertEqual(receivedError, expectedError, file: file, line: line)
			
			default:
				XCTFail("expect to receive \(resultPair.1), but got \(resultPair.0) instead, at index: \(index)", file: file, line: line)
			}
				
		}
	}

}
