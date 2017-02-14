//
//  BTViewExtensions.swift
//  BTCardViewController
//
//  Created by Sébastien Tardif on 2017-02-16.
//  Copyright © 2017 Tardif.ca. All rights reserved.
//

import UIKit
import ObjectiveC

private var KEY_BOUNDS_WITH_MARGINS = "BTViewExtension.boundsWithMargins"

/// Prefixes to used when setting up constraints in order to easily identify constraints.
///
/// - leading: A leading constraints within the superview.
/// - trailing: A trailing constraints within the superview.
/// - spacing: A leading or trailing constraint with a sibling.
/// - centerX: An horizontal centering constraint within the superview
/// - centerY: A vertical centering constraint within the superview
/// - width: A width constraint for the view itself.
/// - height: A height constraint for the view itself.
public enum BTConstraintAttributePrefix : String
{
	case leading = "leading-"
	case trailing = "trailing-"
	case spacing = "spacing-"
	case centerX = "centerX-"
	case centerY = "centerY-"
	case width = "width-"
	case height = "height-"
}

// MARK: - Extension to add a rect to use for viewController(at: offset) that would
// take margins into consideration
public extension UIView
{
	/// Returns the view's contraints that apply to a particular subview.
	///
	/// - Parameter subview: The subview whose constraints are requested.
	/// - Returns: An array of constraints that apply to subview.
	func constraints(for subview: UIView?) -> [NSLayoutConstraint]
	{
		var constraints : [NSLayoutConstraint] = []

		for constraint in self.constraints {
			if (constraint.firstItem as? UIView == subview
				|| constraint.secondItem as? UIView == subview
				) {
				constraints.append(constraint)
			}
		}

		return constraints
	}

	/// Bounds of the view including the margins or spacing to the left or the right of the view.
	private(set) public var boundsWithMargins : CGRect?
	{
		set
		{
			objc_setAssociatedObject(
				self,
				&KEY_BOUNDS_WITH_MARGINS,
				newValue,
				.OBJC_ASSOCIATION_RETAIN_NONATOMIC
			)
		}
		get
		{
			var rect = objc_getAssociatedObject(self, &KEY_BOUNDS_WITH_MARGINS) as? CGRect
			if (rect == nil) {
				rect = self.computeBoundsWithMargins()
			}

			return rect;
		}
	}

	/// Indicates that the boundsWithMargins should be recalculated the next time they are needed
	public func recomputeBoundsWithMarginsWhenNeeded()
	{
		self.boundsWithMargins = nil
	}

	/// Computes the bounds of the view containing horizontal margins
	///
	/// - Returns: The expanded bounds
	private func computeBoundsWithMargins() -> CGRect?
	{
		if (self.superview == nil) {
			return nil
		}

		var bounds = self.bounds

		// Get the view's constraints within its supervew
		var constraints = self.superview!.constraints(for: self)

		// Add the view's own constraints for itself
		constraints.append(contentsOf: self.constraints(for: self))

		// Iterate all those constrains to check for horizontal margins
		for constraint in constraints {

			// Constraint has no identifier, just iggore
			if (constraint.identifier == nil) {
				continue
			}

			if (constraint.identifier!.hasPrefix(BTConstraintAttributePrefix.leading.rawValue)) {

				bounds.origin.x -= constraint.constant
				bounds.size.width += constraint.constant

			} else if (constraint.identifier!.hasPrefix(BTConstraintAttributePrefix.spacing.rawValue)) {

				if (constraint.firstAttribute == .leading
					&& constraint.firstItem as? UIView == self
					) {

					bounds.origin.x -= constraint.constant / 2
					bounds.size.width += constraint.constant / 2

				} else if (constraint.secondAttribute == .trailing
					|| constraint.secondItem as? UIView == self
					) {

					bounds.size.width += constraint.constant / 2

				}

			} else if (constraint.identifier!.hasPrefix(BTConstraintAttributePrefix.trailing.rawValue)) {

				bounds.size.width += constraint.constant

			}
		}

		self.boundsWithMargins = bounds
		return bounds
	}
}
