import GoogleMobileAds
import SwiftUI
import UIKit

class InterstitialAdManager: NSObject, GADFullScreenContentDelegate, ObservableObject {
    
    private var interstitial: GADInterstitialAd?
    @Published var isAdReady = false
    private var adLoadAttempts = 0
    private var maxAdLoadAttempts = 5
    private var adLoadTimer: Timer?
    
    override init() {
        super.init()
        loadInterstitialAd()
    }
    
    // Load the Interstitial Ad
    func loadInterstitialAd() {
        let request = GADRequest()
        let adUnitID = "ca-app-pub-2824674932258413/4008105412" // Replace with your AdMob Interstitial Unit ID
        adLoadAttempts += 1
        GADInterstitialAd.load(withAdUnitID: adUnitID, request: request) { ad, error in
            if let error = error {
                print("Failed to load interstitial ad with error: \(error.localizedDescription)")
                self.isAdReady = false
                return
            }
            self.interstitial = ad
            self.interstitial?.fullScreenContentDelegate = self
            self.isAdReady = true
            print("Interstitial ad is loaded and ready to be shown.")
        }
    }
    
    // Show the Interstitial Ad
    func showAd(from rootViewController: UIViewController) {
        if let interstitial = interstitial {
            interstitial.present(fromRootViewController: rootViewController)
        } else {
            print("Interstitial ad is not ready yet.")
        }
    }
    
    // Ad delegate methods
    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        print("Ad was dismissed.")
        if adLoadAttempts < maxAdLoadAttempts {
            scheduleRetry()
            print("adLoadAttempts: \(adLoadAttempts)")
        }
        //loadInterstitialAd()  // Load a new ad after dismissal
    }
    
    // Function to retry loading ad after a delay
    func scheduleRetry() {
        print("Scheduling retry in 3 minute.")
        adLoadTimer?.invalidate() // Cancel previous timer if it's still active
        adLoadTimer = Timer.scheduledTimer(withTimeInterval: 180.0, repeats: false) { [weak self] _ in
            self?.loadInterstitialAd()
        }
    }
}
