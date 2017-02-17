//
//  BTGestureExtension.swift
//  BTCardViewController
//
//  Created by Sébastien Tardif on 2017-02-17.
//  Copyright © 2017 Tardif.ca. All rights reserved.
//

import UIKit

// MARK: - Array Extension

extension UIGestureRecognizer
{
	public func cancel()
	{
		self.isEnabled = false
		self.isEnabled = true
	}
}

