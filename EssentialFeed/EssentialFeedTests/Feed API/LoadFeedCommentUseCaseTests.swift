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
			let emptyItemsJSON = makeItemsJSON([])
			httpSpy.complete(withStatusCode: 200, data: emptyItemsJSON)
		})
	}
	
	func test_loadImageComments_deliversItemsOn200HTTPResponseWithItemJSON() {
		// given
		let (sut, httpSpy) = makeSUT()
		let item0 = makeItem(id: UUID(), message: "a message", createAt: anyRoundDate(), username: "a username")
		let item1 = makeItem(id: UUID(), message: "another message", createAt: anyRoundDate(), username: "another username")
		
		// when, then
		expect(sut, toReceive: [.success([item0.model, item1.model])], when: {
			let json = makeItemsJSON([item0.json, item1.json])
			httpSpy.complete(withStatusCode: 200, data: json)
		})
	}
	
	func test_loadImageComments_doesNotDeliverResultAfterSUTHasBeenDeallocated() {
		// given
		let httpSpy = HTTPClientSpy()
		var sut: RemoteImageCommentsLoader? = RemoteImageCommentsLoader(url: anyURL(), client: httpSpy)
		
		// when
		var receivedResult: RemoteImageCommentsLoader.LoadImageCommentsResult?
		sut?.loadImageComments { receivedResult = $0 }
		sut = nil
		httpSpy.complete(withStatusCode: 200, data: makeItemsJSON([]))
		
		// then
		XCTAssertNil(receivedResult)
	}
	
	func test_cancelLoadImageComments_cancelsClientURLRequest() {
		// given
		let url = anyURL()
		let (sut, httpSpy) = makeSUT(url: url)
		
		// when
		sut.loadImageComments { _ in }
		
		XCTAssertTrue(httpSpy.cancelledURLs.isEmpty, "expect no cancelled URL request until `cancelLoadImageComments` message is sent to sut")
		
		sut.cancelLoadImageComments()
		
		// then
		XCTAssertEqual(httpSpy.cancelledURLs, [url], "expect cancelled URL request after `cancelLoadImageComments` message is sent to sut")
	}
	
	func test_loadImageComments_doesNotDeliverResultAfterSUTcancelLoadImageComments() {
		// given
		let (sut, httpSpy) = makeSUT()
		let item = makeItem(id: UUID(), message: "a message", createAt: anyRoundDate(), username: "a username")
		let json = makeItemsJSON([item.json])
		
		// when, then
		expect(sut, toReceive: [], when: {
			sut.cancelLoadImageComments()
			httpSpy.complete(withStatusCode: 200, data: json)
		})
	}
	
	private func makeSUT(
		url: URL = anyURL(),
		file: StaticString = #file,
		line: UInt = #line
	) -> (RemoteImageCommentsLoader, HTTPClientSpy)
	{
		let httpSpy = HTTPClientSpy()
		let sut = RemoteImageCommentsLoader(url: url, client: httpSpy)
		trackForMemoryLeaks(httpSpy, file: file, line: line)
		trackForMemoryLeaks(sut, file: file, line: line)
		return (sut, httpSpy)
	}
	
	private func expect(
		_ sut: RemoteImageCommentsLoader,
		toReceive expectedResults: [RemoteImageCommentsLoader.LoadImageCommentsResult],
		when action: ()-> Void,
		at index: Int = 0,
		file: StaticString = #file,
		line: UInt = #line
	) {
		
		// when
		var receivedResults = [RemoteImageCommentsLoader.LoadImageCommentsResult]()
		sut.loadImageComments { receivedResults.append($0) }
		action()
		
		// then
		XCTAssertEqual(
			expectedResults.count,
			receivedResults.count,
			"expected to received \(expectedResults.count) results, but got \(receivedResults.count) results instead",
			file: file, line: line)
		
		zip(receivedResults, expectedResults).forEach { resultPair in
			switch resultPair {
			case let (.success(receivedItems), .success(expectedItems)):
				XCTAssertEqual(receivedItems, expectedItems, file: file, line: line)
			
			case let (.failure(receivedError as NSError), .failure(expectedError as NSError)):
				XCTAssertEqual(receivedError, expectedError, file: file, line: line)
			
			default:
				XCTFail("expect to receive \(resultPair.1), but got \(resultPair.0) instead, at index: \(index)", file: file, line: line)
			}
				
		}
	}
	
	private func makeItemsJSON(_ items: [[String: Any]]) -> Data {
		let json = ["items": items]
		return try! JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
	}
	
	private func makeItem(
		id: UUID,
		message: String,
		createAt date: Date,
		username: String
	) -> (model: ImageComment, json: [String: Any])
	{
		let item = ImageComment(
			id: id,
			message: message,
			createAt: date,
			author: username
		)
		
		let json: [String: Any] = [
			"id": id.uuidString,
			"message": message,
			"create_at": ISO8601DateFormatter().string(from: date),
			"author": ["username": username]
		]
		
		return (item, json)
	}
	
	private func anyRoundDate() -> Date {
		let date = Date()
		let diff = Calendar.current.component(.nanosecond, from: date)
		let roundDate = Calendar.current.date(byAdding: .nanosecond, value: -diff, to: date)
		return roundDate!
	}
}
