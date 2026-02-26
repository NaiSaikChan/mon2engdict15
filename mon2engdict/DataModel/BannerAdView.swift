//
//  BannerAdView.swift
//  mon2engdict
//
//  Created by Saik Chan on 27/02/2026.
//

import GoogleMobileAds
import SwiftUI

/// A reusable SwiftUI wrapper for AdMob anchored adaptive banner ads.
struct BannerAdView: UIViewRepresentable {
    typealias UIViewType = GADBannerView
    
    let adUnitID: String
    let adSize: GADAdSize
    
    init(adUnitID: String, width: CGFloat) {
        self.adUnitID = adUnitID
        self.adSize = GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(width)
    }
    
    func makeUIView(context: Context) -> GADBannerView {
        let banner = GADBannerView(adSize: adSize)
        banner.adUnitID = adUnitID
        banner.delegate = context.coordinator
        banner.load(GADRequest())
        return banner
    }
    
    func updateUIView(_ uiView: GADBannerView, context: Context) {}
    
    func makeCoordinator() -> BannerCoordinator {
        return BannerCoordinator()
    }
    
    // MARK: - Coordinator (GADBannerViewDelegate)
    
    class BannerCoordinator: NSObject, GADBannerViewDelegate {
        
        func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
            print("Banner ad loaded successfully.")
        }
        
        func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
            print("Banner ad failed to load: \(error.localizedDescription)")
        }
        
        func bannerViewDidRecordImpression(_ bannerView: GADBannerView) {
            print("Banner ad recorded an impression.")
        }
        
        func bannerViewDidRecordClick(_ bannerView: GADBannerView) {
            print("Banner ad recorded a click.")
        }
    }
}
