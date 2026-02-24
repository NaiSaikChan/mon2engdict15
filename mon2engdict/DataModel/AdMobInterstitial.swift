import GoogleMobileAds
import SwiftUI
import UIKit

class InterstitialAdManager: NSObject, GADFullScreenContentDelegate, ObservableObject {
    
    private var interstitial: GADInterstitialAd?
    @Published var isAdReady = false
    private var adLoadAttempts = 0
    private let maxAdLoadAttempts = 5
    private var adLoadTimer: Timer?
    private var sdkObserver: NSObjectProtocol?
    
    /// Track whether the SDK is initialized — ads must not be loaded before this.
    private var isSDKInitialized = false
    
    private let adUnitID = "ca-app-pub-2824674932258413/4008105412"
    
    override init() {
        super.init()
        // Do NOT load an ad here — the SDK isn't ready yet.
        // Instead, listen for the SDK-ready notification.
        sdkObserver = NotificationCenter.default.addObserver(
            forName: .adMobSDKDidInitialize,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isSDKInitialized = true
            self?.loadInterstitialAd()
        }
    }
    
    deinit {
        if let observer = sdkObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        adLoadTimer?.invalidate()
    }
    
    // MARK: - Load
    
    func loadInterstitialAd() {
        guard isSDKInitialized else {
            print("AdMob SDK not ready yet, skipping ad load.")
            return
        }
        
        adLoadAttempts += 1
        let request = GADRequest()
        
        GADInterstitialAd.load(withAdUnitID: adUnitID, request: request) { [weak self] ad, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if let error = error {
                    print("Failed to load interstitial ad: \(error.localizedDescription)")
                    self.isAdReady = false
                    return
                }
                self.interstitial = ad
                self.interstitial?.fullScreenContentDelegate = self
                self.isAdReady = true
                print("Interstitial ad loaded and ready.")
            }
        }
    }
    
    // MARK: - Show
    
    /// Show the ad only if it's ready. Returns true if the ad was presented.
    @discardableResult
    func showAd(from rootViewController: UIViewController) -> Bool {
        guard let interstitial = interstitial else {
            print("Interstitial ad is not ready yet.")
            return false
        }
        interstitial.present(fromRootViewController: rootViewController)
        return true
    }
    
    // MARK: - GADFullScreenContentDelegate
    
    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        print("Ad was dismissed.")
        isAdReady = false
        interstitial = nil
        
        if adLoadAttempts < maxAdLoadAttempts {
            scheduleRetry()
        }
    }
    
    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("Ad failed to present: \(error.localizedDescription)")
        isAdReady = false
        interstitial = nil
    }
    
    // MARK: - Retry
    
    private func scheduleRetry() {
        print("Scheduling ad retry in 3 minutes.")
        adLoadTimer?.invalidate()
        adLoadTimer = Timer.scheduledTimer(withTimeInterval: 180.0, repeats: false) { [weak self] _ in
            self?.loadInterstitialAd()
        }
    }
}
