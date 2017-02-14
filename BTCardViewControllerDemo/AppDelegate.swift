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
	var cardViewController: BTCardViewController?

	let transparency : CGFloat = 0.5

	var colors: [UIColor]! =
	[
		UIColor.red,
		UIColor.green,
		UIColor.blue,
		UIColor.magenta,
		UIColor.cyan,
		UIColor.brown,
		UIColor.orange,
	]

	var items : [UIColor]! = []

	var cards : [UIViewController?]! = []


// MARK: UIApplicationDelegate

	func application(
		_ application: UIApplication,
		didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?
	) -> Bool
	{
		// Build the initial items
		self.buildItems(animated: false)

		// Extract card view controller from root view controller
		let navCtrl = self.window?.rootViewController as? UINavigationController
		self.cardViewController = navCtrl?.topViewController as? BTCardViewController

		// Set-up card view controller attributes
		self.cardViewController?.backgroundImage = UIImage(
			named: "rainbow-wood",
			in: Bundle.main,
			compatibleWith: nil
		)
		self.cardViewController?.spacing = 16
		self.cardViewController?.selectedIndex = 1

		// Finally, set-up the datasource and delegate
		self.cardViewController?.dataSource = self
		self.cardViewController?.delegate = self

		// Set-up the toolbar
		self.cardViewController?.toolbarItems = [
			UIBarButtonItem(
				title: "Spacing",
				style: .plain,
				target: self,
				action: #selector(randomSpacing)
			),

			UIBarButtonItem(
				barButtonSystemItem: .flexibleSpace,
				target: nil,
				action: nil
			),

			UIBarButtonItem(
				title: "Index",
				style: .plain,
				target: self,
				action: #selector(randomIndex)
			),

			UIBarButtonItem(
				barButtonSystemItem: .flexibleSpace,
				target: nil,
				action: nil
			),

			UIBarButtonItem(
				title: "Views",
				style: .plain,
				target: self,
				action: #selector(changeViewControllers)
			),
		]

		// Set-up the navigation
		self.cardViewController?.navigationItem.rightBarButtonItem = UIBarButtonItem(
			barButtonSystemItem: .refresh,
			target: self,
			action: #selector(refresh)
		)

		return true
	}


// MARK: Actions

	func refresh(sender: UIBarButtonItem!)
	{
		self.cardViewController?.view.layoutIfNeeded()
		self.cardViewController?.view.setNeedsUpdateConstraints()
		self.cardViewController?.view.updateConstraintsIfNeeded()
		self.cardViewController?.view.layoutIfNeeded()
	}

	func randomSpacing(sender: UIBarButtonItem!)
	{
		if (self.cardViewController == nil) {
			return;
		}
		let cardViewController = self.cardViewController!

		var spacing : CGFloat = 16
		repeat {
			spacing = 16 + CGFloat(arc4random_uniform(32))
		} while (spacing == cardViewController.spacing)

		cardViewController.setSpacing(spacing, animated: true)
	}

	func randomIndex(sender: UIBarButtonItem!)
	{
		if (self.cardViewController == nil) {
			return;
		}
		let cardViewController = self.cardViewController!

		var index : Int = 0
		repeat {
			index = Int(arc4random_uniform(UInt32(cardViewController.viewControllers.count)))
		} while (index == cardViewController.selectedIndex)

		cardViewController.setSelectedIndex(index, animated: true)
	}

	func changeViewControllers(sender: UIBarButtonItem!)
	{
		buildItems(animated: true)
	}


// MARK: Utilities

	func buildItems(animated: Bool)
	{
		let count = Int(arc4random_uniform(16))

		// Clear existing cards
		self.cards.forEach({
			if ($0 != nil) {
				$0!.view.removeConstraints($0!.view.constraints)
				$0!.view.removeFromSuperview()
			}
		})
		self.cards.removeAll()

		// Recreate the cards placeholders
		self.cards = [UIViewController?](repeating: nil, count: count)

		// Create the color items
		self.items.removeAll()
		for i in 0..<count {
			let colorIndex = i % self.colors.count
			let color = self.colors[colorIndex]
			self.items.append(color)
		}

		self.cardViewController?.refresh(animated: animated)
	}

	private var _storyboard : UIStoryboard!
	private func storyboard() -> UIStoryboard!
	{
		if (_storyboard == nil) {
			_storyboard = UIStoryboard(name: "Main", bundle: nil)
		}

		return _storyboard
	}

	func buildItem(at index: Int!) -> UIViewController
	{
		let vc = self.storyboard().instantiateViewController(withIdentifier: "DemoCardViewController") as! DemoCardViewController
		vc.loadView()

		vc.view.frame = CGRect(x: 0, y: 0, width: 192, height: 320)

		vc.color = self.items[index].withAlphaComponent(self.transparency)

		vc.label.text = "Card #\(index! + 1)"

		return vc
	}


// MARK: BTCardViewControllerDataSource

	func numberOfCards(in cardViewController: BTCardViewController) -> Int
	{
		return self.cards.count
	}

	func cardViewController(_ cardViewController: BTCardViewController, index: Int) -> UIViewController
	{
		var vc = self.cards[index]
		if (vc == nil) {
			vc = buildItem(at: index)
			self.cards[index] = vc
		}

		return vc!
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

