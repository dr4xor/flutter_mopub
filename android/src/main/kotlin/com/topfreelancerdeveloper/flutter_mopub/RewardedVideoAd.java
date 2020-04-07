package com.topfreelancerdeveloper.flutter_mopub;

import android.app.Activity;
import android.os.Handler;
import android.util.Log;

import androidx.annotation.NonNull;

import com.mopub.common.MoPubReward;
import com.mopub.mobileads.MoPubErrorCode;
import com.mopub.mobileads.MoPubRewardedVideoListener;
import com.mopub.mobileads.MoPubRewardedVideoManager;
import com.mopub.mobileads.MoPubRewardedVideos;

import java.util.HashMap;
import java.util.Map;
import java.util.Set;

import io.flutter.plugin.common.MethodChannel;

public class RewardedVideoAd implements MoPubRewardedVideoListener {

    public static final int TEN_SECONDS_MILLIS = 10 * 1000;

    private MethodChannel channel;
    private Activity activity;
    private boolean isListenerProvided;
    private boolean applyRateLimiting;
    private Map<String, AdStates> adStates;

    private static RewardedVideoAd instance;
    static public RewardedVideoAd getInstance(){
      return instance;
    }

    private enum AdStates {
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

    private RewardedVideoAd(Activity activity , MethodChannel channel){
        this.activity = activity;
        this.channel = channel;
        this.isListenerProvided = false;
        this.applyRateLimiting = true;
        adStates = new HashMap<>();
        MoPubRewardedVideos.setRewardedVideoListener(this);
    }

    public static RewardedVideoAd createInstance(Activity activity , MethodChannel channel){
        if(instance == null){
            instance = new RewardedVideoAd(activity , channel);
        }
        return instance;
    }

    public void setListenerProvided(boolean listen){
        this.isListenerProvided = listen;
    }

    public void setApplyRateLimiting(boolean apply){
        this.applyRateLimiting = apply;
    }

    public int load(String adUnitId){
        //0 = first time load , 1 = load after failure, 2 = load after ratelimiting lifted, 3 = load after closed
        //-1 = already trying to load or loaded or its on screen , -2 = rate limitation
        if(adStates.containsKey(adUnitId)){
            if(!applyRateLimiting){
                if(adStates.get(adUnitId) == AdStates.FAILURE){
                    MoPubRewardedVideos.loadRewardedVideo(adUnitId);
                    adStates.put(adUnitId , AdStates.LOADSTARTED);
                    return 1;
                }
                if(adStates.get(adUnitId) == AdStates.CLOSED){
                    MoPubRewardedVideos.loadRewardedVideo(adUnitId);
                    adStates.put(adUnitId , AdStates.LOADSTARTED);
                    return 3;
                }
                return -1;
            }else {
                if(adStates.get(adUnitId) == AdStates.RATELIMITED){
                    return -2;
                }
                if(adStates.get(adUnitId) == AdStates.RATELIMITEDLIFTED){
                    MoPubRewardedVideos.loadRewardedVideo(adUnitId);
                    adStates.put(adUnitId , AdStates.LOADSTARTED);
                    return 2;
                }
                return -1;
            }
        }else{
            MoPubRewardedVideos.loadRewardedVideo(adUnitId);
            adStates.put(adUnitId , AdStates.LOADSTARTED);
            return 0;
        }
    }

    int show(String adUnitId , String customData){
        //0 = show , 1 = isShowing , -1 = not loaded
        if(adStates.containsKey(adUnitId)){

            if(adStates.get(adUnitId) == AdStates.SHOWING){
                return 1;
            }else {
                if (MoPubRewardedVideos.hasRewardedVideo(adUnitId)) {
                    MoPubRewardedVideos.showRewardedVideo(adUnitId, customData);
                    adStates.put(adUnitId, AdStates.SHOWING);
                    return 0;
                }
                return -1;
            }
        }else{
            if(MoPubRewardedVideos.hasRewardedVideo(adUnitId)){
                Log.d("FlutterMopubPlugin" , "confilct happened loaded but not show");
            }
            return -1;
        }
    }

    @Override
    public void onRewardedVideoLoadSuccess(@NonNull String adUnitId) {
        adStates.put(adUnitId , AdStates.SUCCESS);
        if(isListenerProvided){
            channel.invokeMethod("onRewardedVideoLoadSuccess" , argumentsMap("adUnitId" , adUnitId));
        }
    }

    @Override
    public void onRewardedVideoLoadFailure(@NonNull final String adUnitId, @NonNull MoPubErrorCode errorCode) {
        if(!applyRateLimiting) {
            adStates.put(adUnitId, AdStates.FAILURE);
        }else {
            adStates.put(adUnitId, AdStates.RATELIMITED);
            final Handler handler = new Handler();
            handler.postDelayed(new Runnable() {
                @Override
                public void run() {
                    adStates.put(adUnitId, AdStates.RATELIMITEDLIFTED);
                }
            }, TEN_SECONDS_MILLIS);
        }
        if(isListenerProvided){
            channel.invokeMethod("onRewardedVideoLoadFailure" ,argumentsMap("adUnitId" , adUnitId , "errorCode" , errorCode) );
        }
    }

    @Override
    public void onRewardedVideoStarted(@NonNull String adUnitId) {
        adStates.put(adUnitId , AdStates.STARTED);
        if(isListenerProvided){
            channel.invokeMethod("onRewardedVideoStarted" , argumentsMap("adUnitId" , adUnitId));
        }
    }

    @Override
    public void onRewardedVideoPlaybackError(@NonNull String adUnitId, @NonNull MoPubErrorCode errorCode) {
        adStates.put(adUnitId , AdStates.PLAYBACKERROR);
        if(isListenerProvided){
            channel.invokeMethod("onRewardedVideoPlaybackError" ,argumentsMap("adUnitId" , adUnitId , "errorCode" , errorCode) );
        }
    }

    @Override
    public void onRewardedVideoClicked(@NonNull String adUnitId) {
        adStates.put(adUnitId , AdStates.CLICKED);
        if(isListenerProvided){
            channel.invokeMethod("onRewardedVideoClicked" , argumentsMap("adUnitId" , adUnitId));
        }
    }

    @Override
    public void onRewardedVideoClosed(@NonNull String adUnitId) {
        adStates.put(adUnitId , AdStates.CLOSED);
        if(isListenerProvided){
            channel.invokeMethod("onRewardedVideoClosed" , argumentsMap("adUnitId" , adUnitId));
        }
    }

    @Override
    public void onRewardedVideoCompleted(@NonNull Set<String> adUnitIds, @NonNull MoPubReward reward) {
        if(isListenerProvided){
            int amount = reward.getAmount();
            String label = reward.getLabel();
            boolean isSuccessful = reward.isSuccessful();
            Object[] args = new Object[adUnitIds.size() * 2 + 6];
            int i = 0;
            for (String adUnitId : adUnitIds) {
                adStates.put(adUnitId , AdStates.COMPLETED);
                args[i * 2] = "adUnitId" + i;
                args[i * 2 + 1] = adUnitId;
                i++;
            }
            args[i * 2] = "amount";
            args[i * 2  + 1] = amount;
            args[(i + 1) * 2] = "label";
            args[(i + 1) * 2 + 1] = label;
            args[(i + 2) * 2] = "isSuccessful";
            args[(i + 2) * 2 + 1] = isSuccessful;
            channel.invokeMethod("onRewardedVideoCompleted" , argumentsMap(args));
        }
    }


    private Map<String, Object> argumentsMap(Object... args) {
        Map<String, Object> arguments = new HashMap<String, Object>();
        for (int i = 0; i < args.length; i += 2) arguments.put(args[i].toString(), args[i + 1]);
        return arguments;
    }
}
