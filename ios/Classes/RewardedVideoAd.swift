

import Foundation
import MoPub
import Flutter
enum AdStates {
    case SUCCESS
    , FAILURE
    , LOADSTARTED
    , STARTED
    , PLAYBACKERROR
    , CLICKED
    , SHOWING
    , CLOSED
    , COMPLETED
    , RATELIMITED
    , RATELIMITEDLIFTED
}

class RewardedVideoAd : NSObject,MPRewardedVideoDelegate {
    
    private var isListenerProvided = false
    private var applyRateLimiting  = false
    private var adStates =  [String: AdStates]()
    private var channel : FlutterMethodChannel?
    static var instance : RewardedVideoAd!;
    static let TEN_SECONDS = 10.0
    
    init (channel : FlutterMethodChannel) {
        super.init()
        self.isListenerProvided = false
        self.applyRateLimiting = true
        self.channel = channel
        //listen for calls from mpub
        RewardedVideoAd.instance = self
    }
    func load(adUnitId: String) -> Int {
        //0 = first time load , 1 = load after failure, 2 = load after ratelimiting lifted, 3 = load after closed
        //-1 = already trying to load or loaded or its on screen , -2 = rate limitation
        MPRewardedVideo.setDelegate(self, forAdUnitId: adUnitId)
        if (adStates.keys.contains(adUnitId)) {
            if(applyRateLimiting) {
                if (adStates[adUnitId] == AdStates.RATELIMITED) {
                    return -2
                }
                if (adStates[adUnitId] == AdStates.RATELIMITEDLIFTED) {
                    MPRewardedVideo.loadAd(withAdUnitID: adUnitId, withMediationSettings: [])
                    adStates[adUnitId] = AdStates.LOADSTARTED
                    return 2
                }
            }
            if (adStates[adUnitId] == AdStates.FAILURE) {
                MPRewardedVideo.loadAd(withAdUnitID: adUnitId, withMediationSettings: [])
                adStates[adUnitId] = AdStates.LOADSTARTED
                return 1
            }
            if (adStates[adUnitId] == AdStates.CLOSED) {
                MPRewardedVideo.loadAd(withAdUnitID: adUnitId, withMediationSettings: [])
                adStates[adUnitId] = AdStates.LOADSTARTED
                return 3
            }
            return -1
        } else {
            MPRewardedVideo.loadAd(withAdUnitID: adUnitId, withMediationSettings: [])
            adStates[adUnitId] = AdStates.LOADSTARTED
            return 0
        }
    }
    
    func show(adUnitId: String, customData: String?) -> Int {
        //0 = show , 1 = isShowing , -1 = not loaded
        if (adStates.keys.contains(adUnitId)) {

            if (adStates[adUnitId] == AdStates.SHOWING) {
                return 1
            } else {
                if (MPRewardedVideo.hasAdAvailable(forAdUnitID: adUnitId)) {
                    if customData == nil {
                        MPRewardedVideo.presentAd(forAdUnitID: adUnitId, from: (UIApplication.shared.delegate?.window??.rootViewController)!, with: MPRewardedVideo.availableRewards(forAdUnitID: adUnitId)[0] as! MPRewardedVideoReward)
                    }else{
                        MPRewardedVideo.presentAd(forAdUnitID: adUnitId, from: (UIApplication.shared.delegate?.window??.rootViewController)!, with: MPRewardedVideo.availableRewards(forAdUnitID: adUnitId)[0] as! MPRewardedVideoReward,customData: customData)
                    }
                    adStates[adUnitId] = AdStates.SHOWING
                    return 0
                }
                
                return -1
            }
        } else {
            if (MPRewardedVideo.hasAdAvailable(forAdUnitID: adUnitId)) {
                NSLog("confilct happened loaded but not show")
            }
            NSLog("unallowed load stopped with no adunit created")
            return -1
        }
    }



    func setListenerProvided(listen: Bool) {
        self.isListenerProvided = listen
    }

    func setApplyRateLimiting(apply: Bool) {
        self.applyRateLimiting = apply
    }
    
    func rewardedVideoAdDidLoad(forAdUnitID adUnitID: String!) {
        adStates[adUnitID] = AdStates.SUCCESS
        if isListenerProvided {
            channel?.invokeMethod("onRewardedVideoLoadSuccess", arguments: argumentsMap(vararg: "adUnitId", adUnitID))
        }
    }
    
    func rewardedVideoAdDidFailToLoad(forAdUnitID adUnitID: String!, error: Error!) {
        if !applyRateLimiting {
            adStates[adUnitID] = AdStates.FAILURE
        } else {
            adStates[adUnitID] = AdStates.RATELIMITED
            DispatchQueue.main.asyncAfter(deadline: .now() + RewardedVideoAd.TEN_SECONDS) {
                self.adStates[adUnitID] = AdStates.RATELIMITEDLIFTED
            }
        }
        if isListenerProvided {
            channel?.invokeMethod("onRewardedVideoLoadFailure", arguments: argumentsMap(vararg: "adUnitId", adUnitID, "errorCodeInt", "-2","errorCodeName", error.debugDescription,"errorCodeOrdinal", error.localizedDescription))
        }
    }
    func rewardedVideoAdDidExpire(forAdUnitID adUnitID: String!) {
        
    }
    func rewardedVideoAdDidFailToPlay(forAdUnitID adUnitID: String!, error: Error!) {
        adStates[adUnitID] = AdStates.PLAYBACKERROR
        if (isListenerProvided) {
            
            channel?.invokeMethod("onRewardedVideoPlaybackError", arguments: argumentsMap(vararg: "adUnitId", adUnitID, "errorCodeInt", "-2","errorCodeName", error.debugDescription,"errorCodeOrdinal", error.localizedDescription))
        }
    }
    func rewardedVideoAdDidAppear(forAdUnitID adUnitID: String!) {
        adStates[adUnitID] = AdStates.STARTED
        if (isListenerProvided) {
            channel?.invokeMethod("onRewardedVideoStarted", arguments: argumentsMap(vararg: "adUnitId", adUnitID))
        }
    }
    
    func rewardedVideoAdWillAppear(forAdUnitID adUnitID: String!) {
        
    }
    
    func rewardedVideoAdDidDisappear(forAdUnitID adUnitID: String!) {
        adStates[adUnitID] = AdStates.CLICKED
        if (isListenerProvided) {
           channel?.invokeMethod("onRewardedVideoClosed", arguments : argumentsMap(vararg: "adUnitId", adUnitID))
        }
        
    }
    func rewardedVideoAdWillDisappear(forAdUnitID adUnitID: String!) {
        
    }
    func rewardedVideoAdDidReceiveTapEvent(forAdUnitID adUnitID: String!) {
        
    }
    func rewardedVideoAdWillLeaveApplication(forAdUnitID adUnitID: String!) {
        
    }
    func rewardedVideoAdShouldReward(forAdUnitID adUnitID: String!, reward: MPRewardedVideoReward!) {
        let amount = reward.amount
        let label = reward.currencyType
        channel?.invokeMethod("onRewardedVideoCompleted", arguments: argumentsMap(vararg: "adUnitIds" , [adUnitID] , "amount" , amount , "label" , label , "isSuccessful" , true))
    }
    func didTrackImpression(withAdUnitID adUnitID: String!, impressionData: MPImpressionData!) {
        
    }
    
    private func argumentsMap(vararg args: Any...) -> [String: Any] {
        var arguments = [String: Any]()
        var i = 0
        while (i < args.count) {
            arguments[args[i] as! String] = args[i + 1]
            i += 2
        }
        return arguments
    }
}
