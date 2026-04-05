package com.club.clubber

import android.app.Activity
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodCall
import org.json.JSONObject

class AcrCloudHandler(private val activity: Activity) : MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL = "com.clubber/acr_cloud"
    }

    private var isInitialized = false
    private var host: String = ""
    private var accessKey: String = ""
    private var accessSecret: String = ""

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "init" -> {
                host = call.argument<String>("host") ?: ""
                accessKey = call.argument<String>("accessKey") ?: ""
                accessSecret = call.argument<String>("accessSecret") ?: ""
                isInitialized = true
                result.success(true)
            }
            "startRecognition" -> {
                if (!isInitialized) {
                    result.error("NOT_INITIALIZED", "ACRCloud not initialized", null)
                    return
                }
                // TODO: Integrate actual ACRCloud SDK when dependency is added
                // For now, return a mock result for development
                val mockResult = JSONObject().apply {
                    put("status", "no_match")
                    put("title", "")
                    put("artist", "")
                    put("spotify_track_id", "")
                    put("confidence", 0)
                }
                result.success(mockResult.toString())
            }
            "stopRecognition" -> {
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }
}
