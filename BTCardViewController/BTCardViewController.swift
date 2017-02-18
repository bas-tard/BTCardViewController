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
	@IBOutlet private (set) public var scrollView : UIScrollView!

	/// Single content view in scroll view from the storyboard (CAN NOT BE NIL!)
	@IBOutlet private (set) public var contentView : UIView!

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
		_cards = []
		_selectedIndex = 0
		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
	}

	public required init?(coder aDecoder: NSCoder)
	{
		_spacing = 8
		_backgroundImage = nil
		_cards = []
		_selectedIndex = 0
		super.init(coder: aDecoder)
	}


// MARK: View Life Cycle

	public override func viewDidLoad()
	{
		super.viewDidLoad()

		// Remove any dummy IB views in the content view
		self.contentView.subviews.forEach({
			$0.removeFromSuperview()
		})

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
		self.refreshCards(animated: false)

		// Adjust the scroll position
		self.scrollTo(self.selectedIndex, animated: false)
	}

	public override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		self.view.setNeedsUpdateConstraints()
		self.view.updateConstraintsIfNeeded()
		self.view.setNeedsLayout()
		self.view.layoutIfNeeded()
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
			self.refreshCards(animated: animated)
		}
	}


// MARK: Delegate

	/// The object that acts as the delegate of the card view controller.
	open var delegate: BTCardViewControllerDelegate?


	open func refreshCards(animated: Bool)
	{
		var cards : [UIViewController] = []

		if (self.dataSource != nil) {
			let dataSource = self.dataSource!
			let count = dataSource.numberOfCards(in: self)

			for index in 0..<count {
				let card = dataSource.cardViewController(self, index: index)
				cards.append(card)
			}
		}

		self.setCards(cards, animated: animated)
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
			self.view.setNeedsUpdateConstraints()
			self.view.setNeedsLayout()

			if (animated) {
				UIView.animate(
					withDuration: self.animationDuration,
					animations: {
						self.view.updateConstraintsIfNeeded()
						self.view.layoutIfNeeded()

						self.resetContentOffset()
					}
				)
			} else {

				self.view.updateConstraintsIfNeeded()
				self.view.layoutIfNeeded()
				self.resetContentOffset()

			}
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
		if (newValue < 0 || newValue >= self.cards.count) {
			return
		}

		let card = self.cards[newValue]
		self.delegate?.cardViewController?(self, willSelect: card, at: newValue)

		_selectedIndex = newValue

		let completion = { () -> Void in
			self.delegate?.cardViewController?(self, didSelect: card, at: newValue)
		}

		if (self.isViewLoaded) {
			self.scrollTo(newValue, animated: animated, completion: completion)
		} else {
			completion()
		}
	}

	internal func scrollTo(
		_ index: Int!,
		animated: Bool,
		completion: (() -> Swift.Void)? = nil
		)
	{
		if (index < 0 || index >= self.cards.count) {
			completion?()
			return
		}

		if let offset = self.offsetForCard(at: index) {

			if (animated && completion != nil) {
				// Wrap from a CATransaction in order to set the block
				// Then use UIView animation for duration and for the
				// changes to have effect on setContentOffset
				CATransaction.begin()
				CATransaction.setCompletionBlock(completion)
				UIView.beginAnimations(nil, context: nil)
				UIView.setAnimationDuration(self.animationDuration)

				self.scrollView.contentOffset = offset
				UIView.commitAnimations()
				CATransaction.commit()
			} else {
				self.scrollView.setContentOffset(offset, animated: animated)
			}

		}

		if (!animated || completion == nil) {
			completion?()
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
		for card in self.cards {
			let index = self.cards.index(of: card)!
			let currentView = card.view!
			let previousView = index > 0
				? self.cards[index - 1].view
				: nil

			// Set-up the new constraints
			setupConstraints(
				currentView,
				previousView: previousView,
				at: index,
				count: self.cards.count
			)
		}
	}

	private func setupConstraints(
		_ currentView : UIView!,
		previousView : UIView?,
		at index : Int!,
		count : Int!)
	{
		if (!self.isViewLoaded) {
			return
		}

		var constraints : [NSLayoutConstraint] = []

		// Align all views to the vertical center of the content view
		let constraintCenter = NSLayoutConstraint(
			item: currentView,
			attribute: .centerY,
			relatedBy: .equal,
			toItem:self.contentView,
			attribute: .centerY,
			multiplier: 1.0,
			constant:0
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

		currentView.setNeedsUpdateConstraints()
	}

	internal func resetContentOffset()
	{
		self.view.layoutIfNeeded()

		if let offset = self.offsetForCard(at: self.selectedIndex) {
			self.scrollView.contentOffset = offset
			self.adjustBackgroundImageView()
		}
	}


// MARK: View Controllers for Cards

	private var _cards: [UIViewController]!
	open var cards: [UIViewController]!
	{
		set
		{
			setCards(newValue, animated: false)
		}

		get
		{
			return _cards
		}
	}

	open func setCards(_ cards: [UIViewController]!, animated: Bool)
	{
		_cards = cards
		assert(self.dataSource == nil
			|| (self.cards.count == self.dataSource!.numberOfCards(in: self))
		)

		// Make the selectedIndex valid based on new cards
		_selectedIndex = min(self.selectedIndex, self.cards.count - 1)

		// Add the view controllers, we will trigger a layout to place them correctly
		self.setupCards()
	}

	internal func setupCards()
	{
		if (!self.isViewLoaded) {
			return
		}

		// Keep a list of the subviews that will not be part of the new cards
		let cardsToRemove = NSMutableArray(array: self.cards, copyItems: false)

		// Add the view controllers to the scroll view's content
		for card in self.cards {
			let currentView = card.view!

			// Disable the conversion of autosizing to constraints
			currentView.translatesAutoresizingMaskIntoConstraints = false

			// Just in case the view controller was not in the subviews above, we need
			// to make sure it's view is not in any hierarchy.
			if (currentView.superview != self.contentView) {
				currentView.removeFromSuperview()
			}

			// If added for the first time, we need to add to the subview
			if (currentView.superview == nil) {
				self.contentView.addSubview(currentView)
			}

			// Setup the card
			card.cardViewController = self
			card.cardIndex = self.cards.index(of: card)

			// We card remove that cards from the ones we don't need anymore
			cardsToRemove.remove(card)
		}

		// Remove uneeded cards
		cardsToRemove.forEach({
			if let card = $0 as? UIViewController {
				card.cardViewController = nil
				card.cardIndex = nil
				card.view.removeFromSuperview()
			}
		})

		// Need a new contraints pass
		self.view.setNeedsUpdateConstraints()
	}


// MARK: UIScrollViewDelegate Implementation

	public func scrollViewDidScroll(_ scrollView: UIScrollView) {
		self.adjustBackgroundImageView()
	}

	public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView)
	{
		self.snapToCard(at: scrollView.contentOffset, animated: true)
	}

	public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView)
	{
		self.snapToCard(at: scrollView.contentOffset, animated: true)
	}

	public func scrollViewWillEndDragging(
		_ scrollView: UIScrollView,
		withVelocity velocity: CGPoint,
		targetContentOffset: UnsafeMutablePointer<CGPoint>)
	{
		var offset : CGPoint? = targetContentOffset.pointee

		let index = self.indexOfCard(at: offset)
		if (index != nil) {
			_selectedIndex = index
			offset = self.offsetForCard(at: index)
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
		let index = self.cards.index(of: card)
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
		if (index >= self.cards.count) {
			return
		}

		let removedCard = self.cards[index]
		self.delegate?.cardViewController?(self, willRemove: removedCard, at: index)

		self.cards.remove(at: index)
		if (animated) {
			// Remove the view from scroll view and add to main view (above background)
			// Also set translatesAutoresizingMaskIntoConstraints to true
			let rect = removedCard.view.convert(removedCard.view.bounds, to: self.view)
			removedCard.view.removeFromSuperview()
			removedCard.view.translatesAutoresizingMaskIntoConstraints = true
			removedCard.view.frame = rect
			self.view.insertSubview(removedCard.view, belowSubview: self.contentView)

			// Animate the removal and the layout change for the other cards
			UIView.animate(
				withDuration: self.animationDuration,
				delay: 0,
				options: .curveEaseOut,
				animations: {
					// Force a layout NOW to animate the other cards
					self.view.setNeedsUpdateConstraints()
					self.view.setNeedsLayout()
					self.view.updateConstraintsIfNeeded()
					self.view.layoutIfNeeded()

					// Adjust the content offset if needed
					self.adjustContentOffsetIfNeeded(removedCard: removedCard, at: index)

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
					self.view.updateConstraintsIfNeeded()
					self.view.layoutIfNeeded()
					self.adjustContentOffsetIfNeeded(removedCard: removedCard, at: index)

					self.delegate?.cardViewController?(self, didRemove: removedCard, at: index)
				}
			)

		} else {
			removedCard.view.removeFromSuperview()
			self.view.updateConstraintsIfNeeded()
			self.view.layoutIfNeeded()
			self.adjustContentOffsetIfNeeded(removedCard: removedCard, at: index)

			self.delegate?.cardViewController?(self, didRemove: removedCard, at: index)
		}
	}

	func adjustContentOffsetIfNeeded(removedCard: UIViewController!, at index: Int!)
	{
		if (index < 0 || index >= self.cards.count) {
			return
		}

		if (index < self.selectedIndex) {
			_selectedIndex = self.selectedIndex - 1

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
		self.insert(card: card, at: self.cards.count, animated: false)
	}

	public func add(card : UIViewController!, animated : Bool)
	{
		self.insert(card: card, at: self.cards.count, animated: animated)
	}

	public func add()
	{
		self.insert(at: self.cards.count, animated: false)
	}

	public func add(animated : Bool)
	{
		self.insert(at: self.cards.count, animated: animated)
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
		if (index < 0 || index > self.cards.count) {
			return
		}

		self.delegate?.cardViewController?(self, willInsert: newCard, at: index)

		if (animated) {
			// Compute the initial rect where the view should go
			let rect = index < self.cards.count
				? self.cards[index].view.frame
				: self.cards.count > 0
					? self.cards.last!.view.frame
					: CGRect()

			// Insert the new card in the view right now, but as a autosize view
			newCard.view.translatesAutoresizingMaskIntoConstraints = true
			newCard.view.frame = rect
			self.contentView.insertSubview(newCard.view, at: index)

			// Scale and translate the new card
			var t = CGAffineTransform(
				translationX: 0,
				y: 0 - self.view.bounds.height
			)
			t = t.scaledBy(x: 0.5, y: 0.5)
			newCard.view.transform = t

			// We can add to _cards now
			_cards.insert(newCard, at: index)

			// Now, we animate the clean-up
			UIView.animate(
				withDuration: self.animationDuration,
				delay: 0,
				options: .curveEaseOut,
				animations: {
					newCard.view.transform = CGAffineTransform.identity

					// Apply all the layout changes from earlier
					self.setupCards()
					self.view.updateConstraintsIfNeeded()
					self.view.layoutIfNeeded()

					// TODO: make this eventable
					self.adjustContentOffsetIfNeeded(addedCard: newCard, at: index)
				},
				completion: { _ in
					self.delegate?.cardViewController?(self, didInsert: newCard, at: index)
				}
			)
		} else {
			self.cards.insert(newCard, at: index)
			self.view.updateConstraintsIfNeeded()
			self.view.layoutIfNeeded()

			// TODO: make this eventable
			self.adjustContentOffsetIfNeeded(addedCard: newCard, at: index)

			self.delegate?.cardViewController?(self, didInsert: newCard, at: index)
		}
	}

	func adjustContentOffsetIfNeeded(addedCard: UIViewController!, at index: Int!)
	{
		if (index < 0 || index >= self.cards.count) {
			return
		}

		if (index <= self.selectedIndex) {
			_selectedIndex = index + 1

			var contentOffset = self.scrollView.contentOffset
			contentOffset.x += self.spacing
			contentOffset.x += addedCard.view.frame.width
			self.scrollView.contentOffset = contentOffset

			self.adjustBackgroundImageView()
		}
	}


// MARK: Utilities

	internal func snapToCard(at offset : CGPoint?, animated: Bool)
	{
		let index = self.indexOfCard(at: offset)
		self.snapToCard(at: index, animated: animated)
	}

	internal func snapToCard(at index: Int?, animated: Bool)
	{
		if (index == nil) {
			return
		}

		_selectedIndex = index

		if let expected = self.offsetForCard(at: index) {
			if (!expected.equalTo(self.scrollView.contentOffset)) {
				self.scrollView.setContentOffset(expected, animated: animated)
			}
		}
	}

	internal func offsetForCard(at index : Int!) -> CGPoint?
	{
		if (self.cards.count == 0) {
			return nil
		}
		if (index < 0 || index >= self.cards.count) {
			return nil
		}
		if (index == 0) {
			return CGPoint()
		}

		let vc = self.cards[index]
		let frame = vc.view.frame

		// Start from the current scroll view offset (in order to keep the y-axis as is)
		var x : CGFloat = frame.origin.x
		x -= (self.scrollView.frame.width - frame.width) / 2

		return CGPoint(
			x: x,
			y: self.scrollView.contentOffset.y
		)
	}

	internal func card(at offset: CGPoint?) -> UIViewController?
	{
		if (offset == nil) {
			return nil
		}
		var point = offset!

		// Check which view controller will be in the horizontal center
		// at the given offset
		point.x += self.scrollView.frame.width / 2.0

		for controller in self.cards {
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

	internal func indexOfCard(at offset: CGPoint?) -> Int?
	{
		let card = self.card(at: offset)
		if (card != nil) {
			return self.cards.index(of: card!)
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
	/// Tells the delegate that the card view controller is about to select the view controller for a
	/// particular card.
	///
	/// - Parameters:
	///   - cardViewController: The card view controller object informing the delegate of this impending event.
	///   - viewController: A view controller object that cardViewController is going to select.
	///   - index: An index locating the card in cardViewController.
	@objc optional func cardViewController(
		_ cardViewController: BTCardViewController!,
		willSelect viewController: UIViewController!,
		at index: Int
	)

	/// Tells the delegate that the specified card is now selected.
	///
	/// - Parameters:
	///   - cardViewController: A card view controller informing the delegate about the event.
	///   - viewController: A view controller object that cardViewController has selected.
	///   - index: An index locating the card in cardViewController
	@objc optional func cardViewController(
		_ cardViewController: BTCardViewController!,
		didSelect viewController: UIViewController!,
		at index: Int
	)

	/// Tells the delegate that the card view controller is about to insert the view controller for a
	/// particular card.
	///
	/// - Parameters:
	///   - cardViewController: The card view controller object informing the delegate of this impending event.
	///   - viewController: A view controller object that cardViewController is going to insert.
	///   - index: An index locating the card in cardViewController.
	@objc optional func cardViewController(
		_ cardViewController: BTCardViewController!,
		willInsert viewController: UIViewController!,
		at index: Int
	)

	/// Tells the delegate that the specified card is now inserted.
	///
	/// - Parameters:
	///   - cardViewController: A card view controller informing the delegate about the event.
	///   - viewController: A view controller object that cardViewController has inserted.
	///   - index: An index locating the card in cardViewController
	@objc optional func cardViewController(
		_ cardViewController: BTCardViewController!,
		didInsert viewController: UIViewController!,
		at index: Int
	)

	/// Tells the delegate that the card view controller is about to remove the view controller for a
	/// particular card.
	///
	/// - Parameters:
	///   - cardViewController: The card view controller object informing the delegate of this impending event.
	///   - viewController: A view controller object that cardViewController is going to remove.
	///   - index: An index locating the card in cardViewController.
	@objc optional func cardViewController(
		_ cardViewController: BTCardViewController!,
		willRemove viewController: UIViewController!,
		at index: Int
	)

	/// Tells the delegate that the specified card is now removed.
	///
	/// - Parameters:
	///   - cardViewController: A card view controller informing the delegate about the event.
	///   - viewController: A view controller object that cardViewController has removed.
	///   - index: An index locating the card in cardViewController
	@objc optional func cardViewController(
		_ cardViewController: BTCardViewController!,
		didRemove viewController: UIViewController!,
		at index: Int
	)

	/// Tells the delegate that the card view controller is about to move the view controller for a
	/// particular card.
	///
	/// - Parameters:
	///   - cardViewController: The card view controller object informing the delegate of this impending event.
	///   - viewController: A view controller object that cardViewController is going to move.
	///   - fromIndex: The original index locating the card in cardViewController.
	///	  - toIndex: The new index locating the card in cardViewController
	@objc optional func cardViewController(
		_ cardViewController: BTCardViewController!,
		willMove viewController: UIViewController!,
		from fromIndex: Int,
		to toIndex: Int
	)

	/// Tells the delegate that the specified card is now moved.
	///
	/// - Parameters:
	///   - cardViewController: A card view controller informing the delegate about the event.
	///   - viewController: A view controller object that cardViewController has moved.
	///   - fromIndex: The original index locating the card in cardViewController.
	///	  - toIndex: The new index locating the card in cardViewController
	@objc optional func cardViewController(
		_ cardViewController: BTCardViewController!,
		didMove viewController: UIViewController!,
		from fromIndex: Int,
		to toIndex: Int
	)
}


private var KEY_CARD_VIEW_CONTROLLER = "UIViewController.cardViewController"
private var KEY_CARD_INDEX = "UIViewController.cardIndex"

// MARK: UIViewController Extension for Cards
extension UIViewController
{
	open var cardViewController: BTCardViewController?
	{
		get
		{
			return objc_getAssociatedObject(
				self,
				&KEY_CARD_VIEW_CONTROLLER
			) as? BTCardViewController
		}

		set
		{
			objc_setAssociatedObject(
				self,
				&KEY_CARD_VIEW_CONTROLLER,
				newValue,
				.OBJC_ASSOCIATION_ASSIGN
			)
		}
	}

	open var cardIndex : Int?
	{
		get
		{
			return objc_getAssociatedObject(
				self,
				&KEY_CARD_INDEX
			) as? Int
		}

		set
		{
			objc_setAssociatedObject(
				self,
				&KEY_CARD_INDEX,
				newValue,
				.OBJC_ASSOCIATION_RETAIN
			)
		}
	}

}
