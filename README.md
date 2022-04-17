# SwiftTipJar

On Apple patforms, tip jars are a concept of letting users make in-app purchases to show appreciation for the app/developer, which don't actually unlock any additional features of the app.

**This package lets you have a tip jar running in minutes**. 

Here are [SwiftUI sample code](https://github.com/dkasaj/SwiftTipJar-SwiftUI-Example) and [UIKit sample code](https://github.com/dkasaj/SwiftTipJar-UIKit-Example) that demonstrate this.

All you need to do is polish your UI and configure _Consumable_ APIs in App Store Connect or an Xcode StoreKit Configuration<br>(see [Setting up StoreKit testing in Xcode](https://developer.apple.com/documentation/xcode/setting-up-storekit-testing-in-xcode)).


## Installation

SwiftTipJar is available through [Swift Package Manager](https://swift.org/package-manager/).

- In Xcode, click File > Add Packages...
- Select GitHub under Source Control Accounts
- Search for SwiftTipJar
- Click "Add Package" in bottom right


## Usage

For a quick start refer to [SwiftUI sample code](https://github.com/dkasaj/SwiftTipJar-SwiftUI-Example) and [UIKit sample code](https://github.com/dkasaj/SwiftTipJar-UIKit-Example).

## Backstory

There are [many](https://www.namiml.com/blog/let-your-fans-support-your-app-with-a-tip-jar) - [good](https://www.appcoda.com/in-app-purchases-guide/) -  [tutorials](https://levelup.gitconnected.com/beginner-ios-dev-in-app-purchase-iap-made-simple-with-swiftystorekit-3add60e9065d) for implementing IAPs in Swift. 

Following any of them will help you understand how StoreKit works, what are products request and products response, 
what makes up StoreKit products, how to initiate a purchase, how to observe the transaction queue, how to process a transaction...

I had to re-learn all that when I recently developed a tip jar for [Tubist, a macOS menu bar YouTube player](https://apps.apple.com/hr/app/tubist-menu-bar-for-youtube/id1603180719?mt=12) even though I've dealt with IAPs like less than two years ago. Memory fades!

Then it hit me - pretty much all tip jars work the same way, right? While learning how StoreKit works is useful and ahem noble, if all you need is a working tip jar, why not reach for a single package that already does all the lifting?

Thus I created SwiftTipJar. Use it, and hopefully get some tips out of it!

P.S.
If you find any code smells or documentation smells, feel free to open an issue 
