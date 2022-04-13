//
//  SwiftTipJarTests.swift
//  SwiftTipJarTests
//
//  Created by Daniel Kasaj on 13.04.2022..
//

import XCTest
import StoreKit
import SwiftTipJar

class SwiftTipJarTests: XCTestCase {

    var sut: SwiftTipJar!

    let testProducts: [String: NSDecimalNumber] = [
        "com.test.smallTip": 0.99,
        "com.test.largeTip": 9.99
    ]

    var testIdentifiers: Set<String> {
        return Set(testProducts.keys)
    }

    let timeoutForProductsResponse = 0.2 // Shortest time in which your Mac can get a SKProductsResponse from local StoreKit Configuration

    // MARK: - Lifecycle

    override func setUpWithError() throws {
        try super.setUpWithError()

        sut = SwiftTipJar(tipsIdentifiers: testIdentifiers)
    }

    override func tearDownWithError() throws {
        sut = nil
        try super.tearDownWithError()
    }

    // MARK: - Tests

    func test_canInit() {
        XCTAssertNotNil(sut)
        XCTAssertEqual(sut.productIdentifiers, testIdentifiers)
    }

    func test_canMake_productsRequest() {
        let request = sut.makeProductsRequest()
        XCTAssertNotNil(request)
    }

    func test_canSetup_productsRequestDelegate() {
        sut.setupProductsRequest()
        XCTAssertNotNil(sut.productsRequest)
        XCTAssertNotNil(sut.productsRequest?.delegate)
    }

    func test_canReceive_testProducts() {
        requestProducts()
        XCTAssertNotNil(sut.productsResponse)
        for identifier in testIdentifiers {
            XCTAssertNotNil(sut.productFor(identifier: identifier), "\(identifier) isn't set up as an IAP in StoreKit Configuration file")
        }
    }

    func test_canProvide_prices() {
        requestProducts()
        for testProduct in testProducts {
            XCTAssertEqual(sut.priceFor(identifier: testProduct.key), testProduct.value, "Price for \(testProduct.key) is not set up to be \(testProduct.value)")
        }
    }

    func test_canProvide_localizedPrices() {
        requestProducts()
        for testProduct in testProducts {
            // Set locale to US to match default StoreKit Configuration File localization
            // Adjust if your StoreKit Configuration File uses different localization
            sut.priceFormatter.locale = NSLocale.init(localeIdentifier: "en-US") as Locale

            let locallyFormattedPrice = sut.priceFormatter.string(from: testProduct.value)
            XCTAssertEqual(sut.localizedPriceFor(identifier: testProduct.key), locallyFormattedPrice)
        }
    }

    func test_canStartAndStop_observingPaymentQueue() {
        XCTAssertFalse(sut.isObservingPaymentQueue)

        sut.startObservingPaymentQueue()
        XCTAssertTrue(sut.isObservingPaymentQueue)

        sut.stopObservingPaymentQueue()
        XCTAssertFalse(sut.isObservingPaymentQueue)
    }

    func test_canInitiate_purchaseUsingProductIdentifier() {
        let transactionProcessingSpy = TransactionProcessingSpy()
        sut.transactionProcessor = transactionProcessingSpy

        requestProducts()
        sut.startObservingPaymentQueue()

        // Will show system UI for purchase
        sut.initiatePurchase(productIdentifier: "hr.uxfirst.Tubist.tips.coffeeSized")
        XCTAssertEqual(transactionProcessingSpy.timesRequestedToProcess, 1)

        sut.stopObservingPaymentQueue()
    }

    /// NOTE: enable and run this test manually, and use the system UI to successfully complete the purchase
    func DISABLED_test_canProcess_successfulTransaction() {
        var successfulCompletionCount = 0
        let successCompletionBlock = {
            successfulCompletionCount += 1
        }
        sut.transactionSuccessfulBlock = successCompletionBlock
        requestProducts()
        sut.startObservingPaymentQueue()
        sut.initiatePurchase(productIdentifier: "hr.uxfirst.Tubist.tips.coffeeSized")

        let expectation = XCTestExpectation(description: "Waiting for user to confirm purchase")
        expectation.isInverted = true
        wait(for: [expectation], timeout: 5)

        XCTAssertEqual(successfulCompletionCount, 1)
    }

    /// NOTE: enable and run this test manually, and use the system UI to cancel the purchase
    func DISABLED_test_canProcess_failedTransaction() {
        var failedCompletionCount = 0
        let failedCompletionBlock = {
            failedCompletionCount += 1
        }
        sut.transactionFailedBlock = failedCompletionBlock
        requestProducts()
        sut.startObservingPaymentQueue()
        sut.initiatePurchase(productIdentifier: "hr.uxfirst.Tubist.tips.coffeeSized")

        let expectation = XCTestExpectation(description: "Waiting for user to confirm purchase")
        expectation.isInverted = true
        wait(for: [expectation], timeout: 5)

        XCTAssertEqual(failedCompletionCount, 1)
    }

    // MARK: - Helpers

    /// Sets up SKProductRequest, delegate and starts the request, then waits for a short time for request to receive a response
    private func requestProducts() {
        sut.setupProductsRequest()
        sut.productsRequest?.start()

        let expectation = XCTestExpectation(description: "Waiting for SKProductsResponse")
        expectation.isInverted = true
        wait(for: [expectation], timeout: timeoutForProductsResponse)
    }

}

public final class TransactionProcessingSpy: NSObject, TransactionProcessing {
    public var timesRequestedToProcess: Int = 0

    public func processTransactions(_ transactions: [SKPaymentTransaction]) {
        timesRequestedToProcess += 1
    }
}
