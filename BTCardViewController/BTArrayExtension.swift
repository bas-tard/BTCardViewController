//
//  BTArrayExtension.swift
//  BTCardViewController
//
//  Created by Sébastien Tardif on 2017-02-16.
//  Copyright © 2017 Tardif.ca. All rights reserved.
//

import Foundation

// MARK: - Array Extension

extension Array where Element: Equatable
{
	/// Removes an element from the array
	///
	/// - Parameter object: The element that was removed, if any
	mutating func remove(object: Element) -> Element?
	{
		if let index = index(of: object) {
			return remove(at: index)
		}

		return nil
	}
}
