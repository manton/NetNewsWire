//
//  FeedParser.swift
//  RSParser
//
//  Created by Brent Simmons on 6/20/17.
//  Copyright © 2017 Ranchero Software, LLC. All rights reserved.
//

import Foundation

// FeedParser handles the various syndication feed types.
// It might be a good idea to do a plugin-style architecture here instead —
// but feed formats don’t appear all that often, so it’s probably not necessary.

public struct FeedParser {

	static let minNumberOfBytesRequired = 128

	public static func feedType(_ parserData: ParserData) -> FeedType {

		// Can call with partial data — while still downloading, for instance.
		// If there’s not enough data, return .unknown. Ask again when there’s more data.
		// If it’s definitely not a feed, return .notAFeed.
		//
		// This should be fast enough to call on the main thread.

		if parserData.data.count < minNumberOfBytesRequired {
			return .unknown
		}

		let nsdata = parserData.data as NSData
		if nsdata.isProbablyJSONFeed() {
			return .jsonFeed
		}
		if nsdata.isProbablyRSSInJSON() {
			return .rssInJSON
		}

		if nsdata.isProbablyHTML() {
			return .notAFeed
		}

		if nsdata.isProbablyRSS() {
			return .rss
		}
		if nsdata.isProbablyAtom() {
			return .atom
		}

		return .notAFeed
	}

	public static func parseFeed(_ parserData: ParserData) throws -> ParsedFeed? {

		// All the concrete parsers return a ParsedFeed struct.
		// Related: ParsedItem, ParsedAuthor, ParsedHub, ParsedAttachment.
		//
		// This is probably fast enough to call on the main thread —
		// but it’s probably a good idea to use a background queue if
		// you might be doing a lot of parsing. (Such as in a feed reader.)

		do {
			let type = feedType(parserData)

			switch type {

			case .jsonFeed:
				return try JSONFeedParser.parse(parserData)

			case .rssInJSON:
				return try RSSInJSONParser.parse(parserData)

			case .rss:
				return RSSParser.parse(parserData)

			case .atom:
				return AtomParser.parse(parserData)

			case .unknown, .notAFeed:
				return nil
			}
		}
		catch { throw error }
	}
}