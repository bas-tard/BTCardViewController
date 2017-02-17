//
//  BTCardViewController.swift
//  BTCardViewController
//
//  Created by Sébastien Tardif on 2017-02-13.
//  Copyright © 2017 Tardif.ca. All rights reserved.
//

import UIKit
import ObjectiveC

// MARK: BTCardViewController Class

@objc public class BTCardViewController
	: UIViewController
	, UIScrollViewDelegate
{
// MARK: Interface Builder Outlets

	/// Scroll view from the storyboard (CAN NOT BE NIL!)
	@IBOutlet private (set) open var scrollView : UIScrollView!

	/// Single content view in scroll view from the storyboard (CAN NOT BE NIL!)
	@IBOutlet private (set) open var contentView : UIView!

	/// Background Image that scrolls with the content (based on image width)
	@IBOutlet var backgroundImageView : UIImageView!
	@IBOutlet var backgroundImageLeading : NSLayoutConstraint!

	var animationDuration : TimeInterval
	{
		get
		{
			return UIApplication.shared.statusBarOrientationAnimationDuration
		}
	}

// MARK: Initialization

	public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?)
	{
		_spacing = 8
		_backgroundImage = nil
		_viewControllers = []
		_selectedIndex = 0
		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
	}

	public required init?(coder aDecoder: NSCoder)
	{
		_spacing = 8
		_backgroundImage = nil
		_viewControllers = []
		_selectedIndex = 0
		super.init(coder: aDecoder)
	}


// MARK: View Life Cycle

	override open func viewDidLoad()
	{
		super.viewDidLoad()

		// Get the image from the background image view (from the storyboard),
		// if we have none set-up from setBackgroundImage
		if (self.backgroundImage == nil) {
			_backgroundImage = self.backgroundImageView.image
		} else {
			self.backgroundImageView.image = self.backgroundImage
		}
		self.setupBackgroundImageView()

		// Set-up ourselves as our scroll-view delegate
		self.scrollView.delegate = self

		// Load the views if needed
		self.refresh(animated: false)

		// Adjust the scroll position
		self.scrollTo(self.selectedIndex, animated: false)
	}

// MARK: Data Source

	private var _dataSource : BTCardViewControllerDataSource?

	/// The object that acts as the data source of the card view controller.
	open var dataSource: BTCardViewControllerDataSource?
	{
		set
		{
			self.setDataSource(newValue, animated: false)
		}

		get {
			return _dataSource
		}
	}

	open func setDataSource(_ newValue: BTCardViewControllerDataSource?, animated: Bool)
	{
		_dataSource = newValue

		if (self.isViewLoaded) {
			self.refresh(animated: animated)
		}
	}


// MARK: Delegate

	/// The object that acts as the delegate of the card view controller.
	open var delegate: BTCardViewControllerDelegate?


	open func refresh(animated: Bool)
	{
		var vcs : [UIViewController] = []

		if (self.dataSource != nil) {
			let dataSource = self.dataSource!
			let count = dataSource.numberOfCards(in: self)

			for index in 0..<count {
				let vc = dataSource.cardViewController(self, index: index)
				vcs.append(vc)
			}
		}

		self.setViewControllers(vcs, animated: animated)
	}


// MARK: Background Image

	private var _backgroundImage: UIImage?

	/// An image used as the background of the card view controller. If it is wider than
	/// the view, it  scrolls proportionately.
	@IBInspectable open var backgroundImage: UIImage?
	{
		set
		{
			_backgroundImage = newValue
			if (self.isViewLoaded) {
				self.backgroundImageView.image = self.backgroundImage
				self.setupBackgroundImageView()
			}
		}
		get {
			return _backgroundImage
		}
	}

	internal func setupBackgroundImageView()
	{
		if (!self.isViewLoaded) {
			return
		}

		_backgroundImageWide = nil // in order to recompute
		self.adjustBackgroundImageView()
	}

	internal func adjustBackgroundImageView()
	{
		if (!self.isViewLoaded) {
			return
		}

		let percent = self.scrollView.contentOffset.x / self.contentView.frame.width
		let constant = self.backgroundImageWide && self.backgroundImage != nil
			? self.backgroundImage!.size.width * percent
			: 0
		self.backgroundImageLeading.constant = 0 - constant

		self.view.setNeedsLayout()
		self.view.layoutIfNeeded()
	}

	private var _backgroundImageWide: Bool?
	internal var backgroundImageWide: Bool
	{
		get
		{
			if (_backgroundImageWide == nil && self.isViewLoaded && self.backgroundImage != nil) {
				_backgroundImageWide = self.backgroundImage!.size.width > self.scrollView.frame.width
			}

			return _backgroundImageWide != nil
				? _backgroundImageWide!
				: false
		}
	}


// MARK: Spacing

	private var _spacing : CGFloat

	/// The space between cards in the card view controller.
	@IBInspectable open var spacing: CGFloat
	{
		set
		{
			setSpacing(newValue, animated: false)
		}
		get {
			return _spacing
		}
	}

	/// Changes the spacing between cards.
	///
	/// - Parameters:
	///   - spacing: The space between cards in the card view controller.
	///   - animated: true to animate the transition; false to make the transition immediate.
	open func setSpacing(_ newValue: CGFloat, animated: Bool)
	{
		_spacing = newValue

		if (self.isViewLoaded) {
			updateConstraintsAndLayout(animated: animated)
		}
	}


// MARK: Selected Index

	private var _selectedIndex : Int!
	open var selectedIndex : Int!
	{
		set
		{
			self.setSelectedIndex(newValue, animated: false)
		}

		get
		{
			return _selectedIndex
		}
	}

	open func setSelectedIndex(_ newValue: Int!, animated: Bool)
	{
		if (newValue < 0 || newValue >= self.viewControllers.count) {
			return
		}

		_selectedIndex = newValue

		if (self.isViewLoaded) {
			self.scrollTo(newValue, animated: animated)
		}
	}

	internal func scrollTo(_ index: Int!, animated: Bool)
	{
		if (index < 0 || index >= self.viewControllers.count) {
			return
		}

		if let offset = self.offsetForViewControllerAtIndex(at: index) {
			self.scrollView.setContentOffset(offset, animated: animated)
		}
	}


// MARK: Layout and Constraints Support

	open override func updateViewConstraints()
	{
		super.updateViewConstraints()

		// Remove any constraints of the contentView that relate to its internal views
		for constraint in self.contentView.constraints {
			let firstView = constraint.firstItem as! UIView
			let secondView = constraint.secondItem as! UIView
			if (self.contentView.subviews.contains(firstView)
				|| self.contentView.subviews.contains(secondView)
			) {
				self.contentView.removeConstraint(constraint)
			}
		}

		// Set-up the contraints for the view controllers
		for viewController in self.viewControllers {
			let index = viewControllers.index(of: viewController)!
			let currentView = viewController.view!
			let previousView = index > 0
				? viewControllers[index - 1].view
				: nil

			// Set-up the new constraints
			setupConstraints(
				currentView,
				previousView: previousView,
				at: index,
				count: viewControllers.count,
				setupSizeConstraints: false
			)
		}
	}

	private func setupConstraints(
		_ currentView : UIView!,
		previousView : UIView?,
		at index : Int!,
		count : Int!,
		setupSizeConstraints : Bool)
	{
		if (!self.isViewLoaded) {
			return
		}

		// Set-up the width and height constraint (on currentView)
		if (setupSizeConstraints) {
			let constraintWidth = NSLayoutConstraint(
				item: currentView,
				attribute: .width,
				relatedBy: .equal,
				toItem: nil,
				attribute: .width,
				multiplier: 1.0,
				constant: currentView.frame.width
			)
			constraintWidth.identifier = "\(BTConstraintAttributePrefix.width.rawValue)\(index!)"

			let constraintHeight = NSLayoutConstraint(
				item: currentView,
				attribute: .height,
				relatedBy: .equal,
				toItem: nil,
				attribute: .height,
				multiplier: 1.0,
				constant: currentView.frame.height
			)
			constraintHeight.identifier = "\(BTConstraintAttributePrefix.height.rawValue)\(index!)"

			currentView.addConstraints([ constraintWidth, constraintHeight ])
			NSLayoutConstraint.activate(currentView.constraints)
		}

		var constraints : [NSLayoutConstraint] = []

		// Align all views to the vertical center of the content view. Adjust for the nav and status bar
		let barHeights = self.scrollView.contentInset.top
			+ self.scrollView.contentInset.bottom
		let constraintCenter = NSLayoutConstraint(
			item: currentView,
			attribute: .centerY,
			relatedBy: .equal,
			toItem:self.contentView,
			attribute: .centerY,
			multiplier: 1.0,
			constant:barHeights / 2.0
		)
		constraintCenter.identifier = "\(BTConstraintAttributePrefix.centerY.rawValue)\(index!)"
		constraints.append(constraintCenter)

		// Align the FIRST view with the leading edge of the content view.
		if (previousView == nil) {
			let margin = (self.scrollView.bounds.width - currentView.frame.width) / 2.0
			let constraintLeading = NSLayoutConstraint(
				item: currentView,
				attribute: .leading,
				relatedBy: .equal,
				toItem:self.contentView,
				attribute: .leading,
				multiplier: 1.0,
				constant:margin
			)
			constraintLeading.identifier = "\(BTConstraintAttributePrefix.leading.rawValue)\(index!)"
			constraints.append(constraintLeading)
		}

		// Align all OTHER views (index>0) with their previous item's trailing edge using
		// the spacing value
		else if (previousView != nil) {
			let constraintSpacing = NSLayoutConstraint(
				item: currentView,
				attribute: .leading,
				relatedBy: .equal,
				toItem:previousView,
				attribute: .trailing,
				multiplier: 1.0,
				constant:self.spacing
			)
			constraintSpacing.identifier = "\(BTConstraintAttributePrefix.spacing.rawValue)\(index!)"
			constraints.append(constraintSpacing)
		}


		// The LAST view (which could be the first, hence NO ELSE!) is aligned to the trailing edge
		// of the content view
		if (index == (count - 1)) {
			let margin = (self.scrollView.bounds.width - currentView.frame.width) / 2.0
			let constraintTrailing = NSLayoutConstraint(
				item: self.contentView,
				attribute: .trailing,
				relatedBy: .equal,
				toItem:currentView,
				attribute: .trailing,
				multiplier: 1.0,
				constant:margin
			)
			constraintTrailing.identifier = "\(BTConstraintAttributePrefix.trailing.rawValue)\(index!)"
			constraints.append(constraintTrailing)
		}

		// Apply the constraints if needed
		if (constraints.count > 0) {
			self.contentView.addConstraints(constraints)
			NSLayoutConstraint.activate(constraints)
		}

		currentView.setNeedsLayout()
	}

	internal func updateConstraintsAndLayout(animated: Bool)
	{
		if (!self.isViewLoaded) {
			return
		}

		// Run any pending layouts that are needed
		self.view.layoutIfNeeded()

		// We can not update the constraints
		self.view.setNeedsUpdateConstraints()
		self.view.updateConstraintsIfNeeded()

		if (animated) {
			UIView.animate(
				withDuration: self.animationDuration,
				delay: 0.0,
				options: .layoutSubviews,
				animations: {
					self.resetContentOffset()
				},
				completion: nil
			)
		} else {
			self.resetContentOffset()
		}
	}

	internal func resetContentOffset()
	{
		self.view.layoutIfNeeded()

		if let offset = self.offsetForViewControllerAtIndex(at: self.selectedIndex) {
			self.scrollView.contentOffset = offset
			self.adjustBackgroundImageView()
		}
	}


// MARK: View Controllers for Cards

	private var _viewControllers: [UIViewController]!
	open var viewControllers: [UIViewController]!
	{
		set
		{
			setViewControllers(newValue, animated: false)
		}

		get
		{
			return _viewControllers
		}
	}

	open func setViewControllers(_ viewControllers: [UIViewController]!, animated: Bool)
	{
		_viewControllers = viewControllers
		assert(self.dataSource == nil
			|| (self.viewControllers.count == self.dataSource!.numberOfCards(in: self))
		)

		// Make the selectedIndex valid based on new cards
		_selectedIndex = min(self.selectedIndex, self.viewControllers.count - 1)

		// Add the view controllers, we will trigger a layout to place them correctly
		self.setupViewControllers()
	}


	internal func setupViewControllers()
	{
		if (!self.isViewLoaded) {
			return
		}

		// Remove any views from the content area. This should remove all constraints
		// from those views as well
		self.contentView.subviews.forEach({ $0.removeFromSuperview() })

		// Add the view controllers to the scroll view's content
		for viewController in self.viewControllers {
			let index = self.viewControllers.index(of: viewController)!
			let currentView = viewController.view!
			let previousView = index > 0
				? self.viewControllers[index - 1].view
				: nil

			// Disable the conversion of autosizing to constraints
			currentView.translatesAutoresizingMaskIntoConstraints = false

			// Just in case the view controller was not in the subviews above, we need
			// to make sure it's view is not in any hierarchy.
			currentView.removeFromSuperview()

			// Add the controller to the content
			self.contentView.addSubview(currentView)

			// Set-up the constraints for the view controllers
			self.setupConstraints(
				currentView,
				previousView: previousView,
				at: index,
				count: self.viewControllers.count,
				setupSizeConstraints: true
			)
		}
	}


// MARK: UIScrollViewDelegate Implementation

	public func scrollViewDidScroll(_ scrollView: UIScrollView) {
		self.adjustBackgroundImageView()
	}

	public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView)
	{
		self.snapToViewController(at: scrollView.contentOffset, animated: true)
	}

	public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView)
	{
		self.snapToViewController(at: scrollView.contentOffset, animated: true)
	}

	public func scrollViewWillEndDragging(
		_ scrollView: UIScrollView,
		withVelocity velocity: CGPoint,
		targetContentOffset: UnsafeMutablePointer<CGPoint>)
	{
		var offset : CGPoint? = targetContentOffset.pointee

		let index = self.indexOfViewController(at: offset)
		if (index != nil) {
			_selectedIndex = index
			offset = self.offsetForViewControllerAtIndex(at: index)
		}

		if (offset != nil) {
			targetContentOffset.pointee = offset!
		}
	}


// MARK: Card Removal

	public func remove(_ card: UIViewController!)
	{
		self.remove(card, animated: false)
	}

	public func remove(_ card: UIViewController!, animated: Bool)
	{
		let index = self.viewControllers.index(of: card)
		if (index == nil) {
			return
		}

		self.remove(at: index!, animated: animated)
	}

	public func remove(at index: Int!)
	{
		self.remove(at: index, animated: false)
	}

	public func remove(at index: Int!, animated: Bool)
	{
		if (index < 0) {
			return
		}
		if (index >= self.viewControllers.count) {
			return
		}

		let removedCard = self.viewControllers.remove(at: index)

		if (animated) {
			// Remove the view from scroll view and add to main view (above background)
			// Also set translatesAutoresizingMaskIntoConstraints to true
			var rect = removedCard.view.convert(removedCard.view.bounds, to: self.view)
			rect.origin.x -= self.scrollView.contentOffset.x
			removedCard.view.removeFromSuperview()
			removedCard.view.translatesAutoresizingMaskIntoConstraints = true
			removedCard.view.frame = rect
			self.view.insertSubview(removedCard.view, aboveSubview: self.backgroundImageView)

			// Animate the removal and the layout change for the other cards
			UIView.animate(
				withDuration: self.animationDuration,
				delay: 0,
				options: .curveEaseOut,
				animations: {
					// Force a layout NOW to animate the other cards
					self.view.setNeedsLayout()
					self.view.setNeedsUpdateConstraints()
					self.view.layoutIfNeeded()
					self.view.updateConstraintsIfNeeded()

					// Adjust the content offset if needed
					self.adjustContentOffset(for: removedCard, at: index)

					// Move up and shrink the removed card
					var t = CGAffineTransform(
						translationX: 0,
						y: 0 - self.view.bounds.height
					)
					t = t.scaledBy(x: 0.5, y: 0.5)
					removedCard.view.transform = t
				},
				completion: { _ in
					removedCard.view.removeFromSuperview()
				}
			)

		} else {
			removedCard.view.removeFromSuperview()
			self.adjustContentOffset(for: removedCard, at: index)
		}
	}

	func adjustContentOffset(for removedCard: UIViewController!, at index: Int!)
	{
		if (index < 0 || index >= self.viewControllers.count) {
			return
		}

		if (index < self.selectedIndex) {
			_selectedIndex = index

			var contentOffset = self.scrollView.contentOffset
			contentOffset.x -= self.spacing
			contentOffset.x -= removedCard.view.frame.width
			self.scrollView.contentOffset = contentOffset

			self.adjustBackgroundImageView()
		}
	}


// MARK: Card Insertion

	public func add(card : UIViewController!)
	{
		self.insert(card: card, at: self.viewControllers.count, animated: false)
	}

	public func add(card : UIViewController!, animated : Bool)
	{
		self.insert(card: card, at: self.viewControllers.count, animated: animated)
	}

	public func add()
	{
		self.insert(at: self.viewControllers.count, animated: false)
	}

	public func add(animated : Bool)
	{
		self.insert(at: self.viewControllers.count, animated: animated)
	}

	public func insert(at index : Int)
	{
		if let card = self.dataSource?.cardViewController(self, index: index) {
			self.insert(card: card, at: index, animated: false)
		}
	}

	public func insert(at index : Int, animated : Bool)
	{
		if let card = self.dataSource?.cardViewController(self, index: index) {
			self.insert(card: card, at: index, animated: animated)
		}
	}

	public func insert(card : UIViewController!, at index : Int)
	{
		self.insert(card: card, at: index, animated: false)
	}

	public func insert(card newCard: UIViewController!, at index : Int, animated : Bool)
	{
		if (index < 0 || index > self.viewControllers.count) {
			return
		}

		if (animated) {
			var rect = CGRect()

			// Define the location where it should go
			if (index < self.viewControllers.count) {
				let card = self.viewControllers[index];
				rect = card.view.frame
			} else {
				let card = self.viewControllers.last!
				rect = card.view.frame
				rect.origin.x += card.view.frame.width
				rect.origin.x += self.spacing
			}
			rect.size = newCard.view.frame.size
			newCard.view.frame = rect

			self.contentView.addSubview(newCard.view)

			// Now, scale it and translate it
			let priorAlpha = newCard.view.alpha
			newCard.view.alpha = 0
//			var t = CGAffineTransform(
//				translationX: 0,
//				y: 0 - self.view.bounds.height
//			)
////			t = t.scaledBy(x: 0.5, y: 0.5)
//			newCard.view.transform = t

			// Now we can add the new card
			self.viewControllers.insert(newCard, at: index)

			UIView.animate(
				withDuration: self.animationDuration,
				delay: 0,
				options: .curveEaseOut,
				animations: {
//					newCard.view.transform = CGAffineTransform.identity
					newCard.view.alpha = priorAlpha

					// Force a layout NOW to animate where everything should go
					self.view.setNeedsLayout()
					self.view.setNeedsUpdateConstraints()
					self.view.layoutIfNeeded()
					self.view.updateConstraintsIfNeeded()
				},
				completion: { _ in
				}
			)
		} else {
			self.viewControllers.insert(newCard, at: index)
			self.contentView.addSubview(newCard.view)
			self.view.setNeedsLayout()
			self.view.setNeedsUpdateConstraints()
		}
	}


	// MARK: Utilities

	internal func snapToViewController(at offset : CGPoint?, animated: Bool)
	{
		let index = self.indexOfViewController(at: offset)
		self.snapToViewController(at: index, animated: animated)
	}

	internal func snapToViewController(at index: Int?, animated: Bool)
	{
		if (index == nil) {
			return
		}

		_selectedIndex = index

		if let expected = self.offsetForViewControllerAtIndex(at: index) {
			if (!expected.equalTo(self.scrollView.contentOffset)) {
				self.scrollView.setContentOffset(expected, animated: animated)
			}
		}
	}

	internal func offsetForViewControllerAtIndex(at index : Int!) -> CGPoint?
	{
		if (self.viewControllers.count == 0) {
			return nil
		}
		if (index < 0 || index >= self.viewControllers.count) {
			return nil
		}
		if (index == 0) {
			return CGPoint()
		}

		let vc = self.viewControllers[index]
		let frame = vc.view.frame

		// Start from the current scroll view offset (in order to keep the y-axis as is)
		var x : CGFloat = frame.origin.x
		x -= (self.scrollView.frame.width - frame.width) / 2

		return CGPoint(
			x: x,
			y: self.scrollView.contentOffset.y
		)
	}

	internal func viewController(at offset: CGPoint?) -> UIViewController?
	{
		if (offset == nil) {
			return nil
		}
		var point = offset!

		// Check which view controller will be in the horizontal center
		// at the given offset
		point.x += self.scrollView.frame.width / 2.0

		for controller in self.viewControllers {
			if let bounds = controller.view.boundsWithMargins {
				let rect = self.scrollView.convert(bounds, from: controller.view)

				// Since we do not care about the Y-axis, put the offset's y in the middle
				// of the current view's rect
				point.y = rect.midY

				// Ok, check if we are in this view controller
				if (rect.contains(point)) {
					return controller
				}
			}
		}
		
		return nil
	}

	internal func indexOfViewController(at offset: CGPoint?) -> Int?
	{
		let viewController = self.viewController(at: offset)
		if (viewController != nil) {
			return self.viewControllers.index(of: viewController!)
		}

		return nil
	}
}


// MARK: BTCardViewControllerDataSource Protocol

@objc public protocol BTCardViewControllerDataSource
{
	/// Asks the data source to return the number of cards in the card view controller.
	///
	/// - Parameter cardViewController: The card view controller requesting this information.
	/// - Returns: The number of cards in the card view controller.
	func numberOfCards(in cardViewController: BTCardViewController) -> Int

	/// Asks the data source for a view controller for the card in a particular location.
	///
	/// - Parameters:
	///   - cardViewController: The card view controller requesting this information.
	///   - index: An index locating the card in cardViewController
	/// - Returns: A view controller that the card view controller can use for the specified location.
	func cardViewController(_ cardViewController: BTCardViewController, index: Int) -> UIViewController
}


// MARK: BTCardViewControllerDelegate Protocol

@objc public protocol BTCardViewControllerDelegate
{
	/// Tells the delegate that the card view controller is about to display the the view controller for a
	/// particular card.
	///
	/// - Parameters:
	///   - cardViewController: The card view controller object informing the delegate of this impending event.
	///   - viewController: A view controller object that cardViewController is going to display.
	///   - index: An index locating the card in cardViewController.
	func cardViewController(
		_ cardViewController: BTCardViewController,
		willDisplay viewController: UIViewController,
		at index: Int
	)

	/// Tells the delegate that the specified card is now displayed.
	///
	/// - Parameters:
	///   - cardViewController: A card view controller informing the delegate about the event.
	///   - viewController: A view controller object that cardViewController has displayed.
	///   - index: An index locating the card in cardViewController
	func cardViewController(
		_ cardViewController: BTCardViewController,
		didDisplay viewController: UIViewController,
		at index: Int
	)

	/// Tells the delegate that the card view controller is about to select the the view controller for a
	/// particular card.
	///
	/// - Parameters:
	///   - cardViewController: The card view controller object informing the delegate of this impending event.
	///   - viewController: A view controller object that cardViewController is going to select.
	///   - index: An index locating the card in cardViewController.
	func cardViewController(
		_ cardViewController: BTCardViewController,
		willSelect viewController: UIViewController,
		at index: Int
	)

	/// Tells the delegate that the specified card is now selected.
	///
	/// - Parameters:
	///   - cardViewController: A card view controller informing the delegate about the event.
	///   - viewController: A view controller object that cardViewController has selected.
	///   - index: An index locating the card in cardViewController
	func cardViewController(
		_ cardViewController: BTCardViewController,
		didSelect viewController: UIViewController,
		at index: Int
	)

/// MARK: TODO
    // willRemoveCard
	// didRemoveCard
	// willInsertCard
	// didInsertCard
	// cardWillMove
	// cardDidMove
}

