//
//  SwiftTipJar.swift
//  SwiftTipJar
//
//  Created by Daniel Kasaj on 13.04.2022..
//

import Foundation
import StoreKit

public protocol TransactionProcessing {
    func processTransactions(_ transactions: [SKPaymentTransaction])
}

public final class SwiftTipJar: NSObject, ObservableObject {

    public private(set) var productIdentifiers: Set<String>
    public private(set) var productsRequest: SKProductsRequest?
    public private(set) var productsResponse: SKProductsResponse?

    @Published public private(set) var tips: [Tip] = []

    // Closure to run after product info has come back from ASC or Xcode StoreKit Configuration
    public var productsReceivedBlock: (() -> Void)?

    // Closure to run after payment is successful
    public var transactionSuccessfulBlock: (() -> Void)?

    // Closure to run after payment is cancelled
    public var transactionFailedBlock: (() -> Void)?

    public var transactionProcessor: TransactionProcessing?

    public let priceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter
    }()

    public init(tipsIdentifiers: Set<String>) {
        productIdentifiers = tipsIdentifiers
        super.init()
        transactionProcessor = self
        setupProductsRequest()
    }

    // MARK: - Safety precaution

    deinit {
        stopObservingPaymentQueue()
    }

    // MARK: - Products

    public func makeProductsRequest() -> SKProductsRequest? {
        guard productIdentifiers.isEmpty == false else {
            return nil
        }
        return SKProductsRequest(productIdentifiers: productIdentifiers)
    }

    public func setupProductsRequest() {
        productsRequest = makeProductsRequest()
        productsRequest?.delegate = self
    }

    public func productFor(identifier: String) -> SKProduct? {
        return productsResponse?.products.first(where: { $0.productIdentifier == identifier })
    }

    public func priceFor(identifier: String) -> NSDecimalNumber? {
        return productFor(identifier: identifier)?.price
    }

    public func localizedPriceFor(identifier: String) -> String? {
        guard let product = productFor(identifier: identifier) else {
            return nil
        }
        priceFormatter.locale = product.priceLocale
        return priceFormatter.string(from: product.price)
    }

    public func localizedTitleFor(identifier: String) -> String? {
        guard let product = productFor(identifier: identifier) else {
            return nil
        }
        return product.localizedTitle
    }

    public func tipWith(identifier: String) -> Tip? {
        return tips.first(where: { $0.identifier == identifier })
    }

    // MARK: - Payment queue

    public var isObservingPaymentQueue: Bool {
        return SKPaymentQueue.default().transactionObservers.contains { observer in
            return observer === self
        }
    }

    public func startObservingPaymentQueue() {
        SKPaymentQueue.default().add(self)
    }

    public func stopObservingPaymentQueue() {
        SKPaymentQueue.default().remove(self)
    }

    // MARK: - Purchases

    public func initiatePurchase(productIdentifier: String) {
        guard SKPaymentQueue.canMakePayments(),
              let product = productFor(identifier: productIdentifier) else {
            return
        }
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }

}

extension SwiftTipJar: SKProductsRequestDelegate {
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        if request === productsRequest {
            productsResponse = response
            for product in response.products.sorted(by: { ($0.price as Decimal) < ($1.price as Decimal) }) {
                let tip = Tip()
                tip.identifier = product.productIdentifier
                tip.displayName = product.localizedTitle
                tip.displayPrice = localizedPriceFor(identifier: product.productIdentifier) ?? ""
                if tip.isValid {
                    tips.append(tip)
                }
            }
            productsReceivedBlock?()
        }
    }
}

extension SwiftTipJar: SKPaymentTransactionObserver {
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        transactionProcessor?.processTransactions(transactions)
    }
}

extension SwiftTipJar: TransactionProcessing {
    public func processTransactions(_ transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                transactionSuccessfulBlock?()
                SKPaymentQueue.default().finishTransaction(transaction)
            case .failed:
                transactionFailedBlock?()
                SKPaymentQueue.default().finishTransaction(transaction)

            case .purchasing, .restored, .deferred:
                break
            @unknown default:
                break
            }
        }
    }
}

public final class Tip {
    public var identifier: String = ""
    public var displayName: String = ""
    public var displayPrice: String = ""

    /// TipJar uses this to quickly check if it should include this Tip in its published array.
    var isValid: Bool {
        return !identifier.isEmpty && !displayName.isEmpty && !displayPrice.isEmpty
    }
}
