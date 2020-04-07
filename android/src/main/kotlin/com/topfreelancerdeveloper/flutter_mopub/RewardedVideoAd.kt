package com.topfreelancerdeveloper.flutter_mopub

import android.app.Activity
import android.os.Handler
import android.util.Log

import com.mopub.common.MoPubReward
import com.mopub.mobileads.MoPubErrorCode
import com.mopub.mobileads.MoPubRewardedVideoListener
import com.mopub.mobileads.MoPubRewardedVideos

import java.util.HashMap

import io.flutter.plugin.common.MethodChannel

class RewardedVideoAd private constructor(private val activity: Activity, private val channel: MethodChannel) : MoPubRewardedVideoListener {
    private var isListenerProvided: Boolean = false
    private var applyRateLimiting: Boolean = false
    private val adStates: MutableMap<String, AdStates>

    private enum class AdStates {
        SUCCESS,
        FAILURE,
        LOADSTARTED,
        STARTED,
        PLAYBACKERROR,
        CLICKED,
        SHOWING,
        CLOSED,
        COMPLETED,
        RATELIMITED,
        RATELIMITEDLIFTED
    }

    init {
        this.isListenerProvided = false
        this.applyRateLimiting = true
        adStates = HashMap()
        MoPubRewardedVideos.setRewardedVideoListener(this)
    }

    fun setListenerProvided(listen: Boolean) {
        this.isListenerProvided = listen
    }

    fun setApplyRateLimiting(apply: Boolean) {
        this.applyRateLimiting = apply
    }

    fun load(adUnitId: String): Int {
        //0 = first time load , 1 = load after failure, 2 = load after ratelimiting lifted, 3 = load after closed
        //-1 = already trying to load or loaded or its on screen , -2 = rate limitation
        if (adStates.containsKey(adUnitId)) {
            if (!applyRateLimiting) {
                if (adStates[adUnitId] == AdStates.FAILURE) {
                    MoPubRewardedVideos.loadRewardedVideo(adUnitId)
                    adStates[adUnitId] = AdStates.LOADSTARTED
                    return 1
                }
                if (adStates[adUnitId] == AdStates.CLOSED) {
                    MoPubRewardedVideos.loadRewardedVideo(adUnitId)
                    adStates[adUnitId] = AdStates.LOADSTARTED
                    return 3
                }
                return -1
            } else {
                if (adStates[adUnitId] == AdStates.RATELIMITED) {
                    return -2
                }
                if (adStates[adUnitId] == AdStates.RATELIMITEDLIFTED) {
                    MoPubRewardedVideos.loadRewardedVideo(adUnitId)
                    adStates[adUnitId] = AdStates.LOADSTARTED
                    return 2
                }
                return -1
            }
        } else {
            MoPubRewardedVideos.loadRewardedVideo(adUnitId)
            adStates[adUnitId] = AdStates.LOADSTARTED
            return 0
        }
    }

    internal fun show(adUnitId: String, customData: String?): Int {
        //0 = show , 1 = isShowing , -1 = not loaded
        if (adStates.containsKey(adUnitId)) {

            if (adStates[adUnitId] == AdStates.SHOWING) {
                return 1
            } else {
                if (MoPubRewardedVideos.hasRewardedVideo(adUnitId)) {
                    MoPubRewardedVideos.showRewardedVideo(adUnitId, customData)
                    adStates[adUnitId] = AdStates.SHOWING
                    return 0
                }
                Log.d(FlutterMopubPlugin.TAG, "unallowed load stopped with no adunit loaded")
                return -1
            }
        } else {
            if (MoPubRewardedVideos.hasRewardedVideo(adUnitId)) {
                Log.d(FlutterMopubPlugin.TAG, "confilct happened loaded but not show")
            }
            Log.d(FlutterMopubPlugin.TAG, "unallowed load stopped with no adunit created")
            return -1
        }
    }

    override fun onRewardedVideoLoadSuccess(adUnitId: String) {
        adStates[adUnitId] = AdStates.SUCCESS
        if (isListenerProvided) {
            channel.invokeMethod("onRewardedVideoLoadSuccess", argumentsMap("adUnitId", adUnitId))
        }
    }

    override fun onRewardedVideoLoadFailure(adUnitId: String, errorCode: MoPubErrorCode) {
        if (!applyRateLimiting) {
            adStates[adUnitId] = AdStates.FAILURE
        } else {
            adStates[adUnitId] = AdStates.RATELIMITED
            val handler = Handler()
            handler.postDelayed({ adStates[adUnitId] = AdStates.RATELIMITEDLIFTED }, TEN_SECONDS_MILLIS.toLong())
        }
        if (isListenerProvided) {
            channel.invokeMethod("onRewardedVideoLoadFailure", argumentsMap("adUnitId", adUnitId, "errorCodeInt", errorCode.intCode,"errorCodeName", errorCode.name,"errorCodeOrdinal", errorCode.ordinal))
        }
    }

    override fun onRewardedVideoStarted(adUnitId: String) {
        adStates[adUnitId] = AdStates.STARTED
        if (isListenerProvided) {
            channel.invokeMethod("onRewardedVideoStarted", argumentsMap("adUnitId", adUnitId))
        }
    }

    override fun onRewardedVideoPlaybackError(adUnitId: String, errorCode: MoPubErrorCode) {
        adStates[adUnitId] = AdStates.PLAYBACKERROR
        if (isListenerProvided) {
            channel.invokeMethod("onRewardedVideoPlaybackError", argumentsMap("adUnitId", adUnitId, "errorCodeInt", errorCode.intCode,"errorCodeName", errorCode.name,"errorCodeOrdinal", errorCode.ordinal))
        }
    }

    override fun onRewardedVideoClicked(adUnitId: String) {
        adStates[adUnitId] = AdStates.CLICKED
        if (isListenerProvided) {
            channel.invokeMethod("onRewardedVideoClicked", argumentsMap("adUnitId", adUnitId))
        }
    }

    override fun onRewardedVideoClosed(adUnitId: String) {
        adStates[adUnitId] = AdStates.CLOSED
        if (isListenerProvided) {
            channel.invokeMethod("onRewardedVideoClosed", argumentsMap("adUnitId", adUnitId))
        }
    }

    override fun onRewardedVideoCompleted(adUnitIds: Set<String>, reward: MoPubReward) {
        if (isListenerProvided) {
            val amount = reward.amount
            val label = reward.label
            val isSuccessful = reward.isSuccessful
            val adUnitIdsAsList = ArrayList<String>(adUnitIds)
            channel.invokeMethod("onRewardedVideoCompleted", argumentsMap("adUnitIds" , adUnitIdsAsList , "amount" , amount , "label" , label , "isSuccessful" , isSuccessful))
        }
    }


    private fun argumentsMap(vararg args: Any): Map<String, Any> {
        val arguments = HashMap<String, Any>()
        var i = 0
        Log.d(FlutterMopubPlugin.TAG , "argsSize = ${args.size}")
        while (i < args.size) {
            Log.d(FlutterMopubPlugin.TAG , "currenIndex = $i")
            arguments[args[i].toString()] = args[i + 1]
            i += 2
        }
        return arguments
    }

    companion object {

        val TEN_SECONDS_MILLIS = 10 * 1000

        var instance: RewardedVideoAd? = null
            private set

        fun createInstance(activity: Activity, channel: MethodChannel){
            if (instance == null) {
                instance = RewardedVideoAd(activity, channel)
            }
        }
    }
}
