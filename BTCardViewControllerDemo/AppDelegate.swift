//
//  AppDelegate.swift
//  BTCardViewControllerDemo
//
//  Created by Sébastien Tardif on 2017-02-14.
//  Copyright © 2017 Tardif.ca. All rights reserved.
//

import UIKit
import BTCardViewController

class DemoCardViewController : UIViewController
{
	@IBOutlet var label : UILabel!

	private var _color : UIColor?
	var color : UIColor?
	{
		set
		{
			_color = newValue
			if (self.isViewLoaded) {
				self.view.backgroundColor = _color;
			}
		}
		get
		{
			return _color
		}
	}

	override func viewDidLoad() {
		self.view.backgroundColor = self.color
	}
}


@UIApplicationMain
class AppDelegate
	: UIResponder
	, UIApplicationDelegate
	, BTCardViewControllerDataSource
	, BTCardViewControllerDelegate
{
	var window: UIWindow?
	var cardViewController: BTCardViewController!

	let transparency : CGFloat = 0.333

	let colors: [UIColor]! =
	[
		UIColor.red,
		UIColor.green,
		UIColor.blue,
		UIColor.magenta,
		UIColor.cyan,
		UIColor.brown,
		UIColor.orange,
	]
	let titles: [String]! =
	[
		"Red",
		"Green",
		"Blue",
		"Magenta",
		"Cyan",
		"Brown",
		"Orange",
	]

	var items : [Int]! = []

	var cards : [DemoCardViewController?]! = []

	var animated : Bool = true


// MARK: UIApplicationDelegate

	func application(
		_ application: UIApplication,
		didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?
	) -> Bool
	{
		// Build the initial items
		self.buildItems()

		// Extract card view controller from root view controller
		let navCtrl = self.window?.rootViewController as? UINavigationController
		self.cardViewController = navCtrl?.topViewController as? BTCardViewController
		self.cardViewController.loadView()

		// Set-up the datasource and delegate
		self.cardViewController.dataSource = self
		self.cardViewController.delegate = self

		// Set-up card view controller attributes
		self.cardViewController.backgroundImage = UIImage(
			named: "galaxy",
			in: Bundle.main,
			compatibleWith: nil
		)
		self.cardViewController.spacing = 16
		self.cardViewController.selectedIndex =
			Int(arc4random_uniform(UInt32(self.items.count)))

		// Set-up the navigation
		self.cardViewController.navigationItem.title = "Card Demo"
		self.cardViewController.navigationItem.leftBarButtonItems = [
			UIBarButtonItem(
				barButtonSystemItem: .refresh,
				target: self,
				action: #selector(refresh(sender:))
			),
		]
		self.cardViewController.navigationItem.rightBarButtonItems = [
			UIBarButtonItem(
				barButtonSystemItem: .add,
				target: self,
				action: #selector(add(sender:))
			),

			UIBarButtonItem(
				barButtonSystemItem: .trash,
				target: self,
				action: #selector(remove(sender:))
			),
		]

		// Set-up tool bar
		self.cardViewController.toolbarItems = [
			UIBarButtonItem(
				barButtonSystemItem: .organize,
				target: self,
				action: #selector(randomSpacing(sender:))
			),

			UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),

			UIBarButtonItem(
				barButtonSystemItem: .rewind,
				target: self,
				action: #selector(previousIndex(sender:))
			),

			UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),

			self.animatedButton(),
			
			UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),

			UIBarButtonItem(
				barButtonSystemItem: .fastForward,
				target: self,
				action: #selector(nextIndex(sender:))
			),

			UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),

			UIBarButtonItem(
				barButtonSystemItem: .redo,
				target: self,
				action: #selector(rebuild(sender:))
			),
		]

		return true
	}


// MARK: Actions

	func refresh(sender: UIBarButtonItem!)
	{
		self.cardViewController.view.layoutIfNeeded()
		self.cardViewController.view.setNeedsUpdateConstraints()
		self.cardViewController.view.updateConstraintsIfNeeded()
		self.cardViewController.view.layoutIfNeeded()
	}

	func add(sender : UIBarButtonItem!)
	{
		if (self.cardViewController == nil) {
			return
		}

		let sheet = UIAlertController(
			title: "Add a card",
			message: nil,
			preferredStyle: .actionSheet
		)
		sheet.popoverPresentationController?.barButtonItem = sender

		sheet.addAction(UIAlertAction(
			title: "At current position",
			style: .default,
			handler: { _ in
				// TODO
			}
		))
		sheet.addAction(UIAlertAction(
			title: "At front",
			style: .default,
			handler: { _ in
				// TODO
			}
		))
		sheet.addAction(UIAlertAction(
			title: "At back",
			style: .default,
			handler: { _ in
				// TODO
			}
		))
		sheet.addAction(UIAlertAction(
			title: "Cancel",
			style: .cancel,
			handler: nil
		))

		self.window?.rootViewController?.present(sheet, animated: true, completion: nil)
	}

	func remove(sender : UIBarButtonItem!)
	{
		if (self.cardViewController == nil) {
			return
		}

		let sheet = UIAlertController(
			title: "Remove a card",
			message: nil,
			preferredStyle: .actionSheet
		)
		sheet.popoverPresentationController?.barButtonItem = sender

		sheet.addAction(UIAlertAction(
			title: "At current position",
			style: .default,
			handler: { _ in
				let index = self.cardViewController.selectedIndex
				self.remove(at: index, animated: self.animated)
			}
		))
		sheet.addAction(UIAlertAction(
			title: "At previous position",
			style: .default,
			handler: { _ in
				if (self.cardViewController.selectedIndex > 0) {
					let index = self.cardViewController.selectedIndex - 1
					self.remove(at: index, animated: self.animated)
				}
			}
		))
		sheet.addAction(UIAlertAction(
			title: "At next position",
			style: .default,
			handler: { _ in
				if (self.cardViewController.selectedIndex < (self.items.count - 1)) {
					let index = self.cardViewController.selectedIndex + 1
					self.remove(at: index, animated: self.animated)
				}
		}
		))
		sheet.addAction(UIAlertAction(
			title: "From front",
			style: .default,
			handler: { _ in
				self.remove(at: 0, animated: self.animated)
			}
		))
		sheet.addAction(UIAlertAction(
			title: "From back",
			style: .default,
			handler: { _ in
				let index = self.items.count - 1
				self.remove(at: index, animated: self.animated)
			}
		))
		sheet.addAction(UIAlertAction(
			title: "Cancel",
			style: .cancel,
			handler: nil
		))

		self.window?.rootViewController?.present(sheet, animated: true, completion: nil)
	}

	func remove(at index: Int!, animated: Bool) {
		if (index >= self.items.count) {
			return
		}

		self.items.remove(at: index)
		self.cards.remove(at: index)
		self.cardViewController.remove(
			at: index,
			animated: animated
		)

		self.relabelCards()
	}

	func randomSpacing(sender : UIBarButtonItem!)
	{
		var spacing : CGFloat = 16
		repeat {
			spacing = 16 + CGFloat(arc4random_uniform(32))
		} while (spacing == self.cardViewController.spacing)

		self.cardViewController.setSpacing(spacing, animated: self.animated)
	}

	func previousIndex(sender : UIBarButtonItem!)
	{
		if let index = self.cardViewController.selectedIndex {
			self.cardViewController.setSelectedIndex(index - 1, animated: self.animated)
		}
	}

	func nextIndex(sender : UIBarButtonItem!)
	{
		if let index = self.cardViewController.selectedIndex {
			self.cardViewController.setSelectedIndex(index + 1, animated: self.animated)
		}
	}
	
	func rebuild(sender : UIBarButtonItem!)
	{
		self.buildItems()
		self.cardViewController.refresh(animated: self.animated)
	}

	func toggleAnimated(sender : UIBarButtonItem!)
	{
		self.animated = !self.animated

		if var toolbarItems = self.cardViewController.toolbarItems {
			if let index = toolbarItems.index(of: sender) {
				toolbarItems[index] = self.animatedButton()
				self.cardViewController.toolbarItems = toolbarItems
			}
		}
	}

	func animatedButton() -> UIBarButtonItem!
	{
		return UIBarButtonItem(
			barButtonSystemItem: self.animated
				? .play
				: .pause,
			target: self,
			action: #selector(toggleAnimated(sender:))
		)
	}


// MARK: Utilities

	func buildItems()
	{
		let count = 10 + Int(arc4random_uniform(16))

		// Clear existing cards
		self.cards.forEach({
			if ($0 != nil) {
				$0!.view.removeConstraints($0!.view.constraints)
				$0!.view.removeFromSuperview()
			}
		})
		self.cards.removeAll()

		// Recreate the cards placeholders
		self.cards = [DemoCardViewController?](repeating: nil, count: count)

		// Create the color items
		self.items.removeAll()
		for i in 0..<count {
			let index = i % self.colors.count
			self.items.append(index)
		}
	}

	private var _storyboard : UIStoryboard!
	private func storyboard() -> UIStoryboard!
	{
		if (_storyboard == nil) {
			_storyboard = UIStoryboard(name: "Main", bundle: nil)
		}

		return _storyboard
	}

	func buildItem(at index: Int!) -> DemoCardViewController
	{
		let card = self.storyboard().instantiateViewController(withIdentifier: "DemoCardViewController") as! DemoCardViewController
		card.loadView()

		card.view.frame = CGRect(x: 0, y: 0, width: 192, height: 320)

		let dataIndex = self.items[index]
		card.view.tag = dataIndex
		self.setup(card: card, at: index)

		return card
	}

	func relabelCards()
	{
		var index : Int = 0
		for card in self.cards {
			self.setup(card: card, at: index)
			index = index + 1
		}
	}

	func setup(card: DemoCardViewController!, at index: Int)
	{
		let dataIndex = card.view.tag
		card.view.backgroundColor = self.colors[dataIndex].withAlphaComponent(self.transparency)
		card.label.text = "\(self.titles[dataIndex]) Card!\nIndex \(index)"
	}


// MARK: BTCardViewControllerDataSource

	func numberOfCards(in cardViewController: BTCardViewController) -> Int
	{
		return self.cards.count
	}

	func cardViewController(_ cardViewController: BTCardViewController, index: Int) -> UIViewController
	{
		var card = self.cards[index]
		if (card == nil) {
			card = self.buildItem(at: index)
			self.cards[index] = card
		}

		return card!
	}


// MARK: BTCardViewControllerDelegate

	func cardViewController(
		_ cardViewController: BTCardViewController,
		willDisplay viewController: UIViewController,
		at index: Int)
	{
	}

	func cardViewController(
		_ cardViewController: BTCardViewController,
		didDisplay viewController: UIViewController,
		at index: Int)
	{
	}

	func cardViewController(
		_ cardViewController: BTCardViewController,
		willSelect viewController: UIViewController,
		at index: Int)
	{
	}

	func cardViewController(
		_ cardViewController: BTCardViewController,
		didSelect viewController: UIViewController,
		at index: Int)
	{
	}
}

