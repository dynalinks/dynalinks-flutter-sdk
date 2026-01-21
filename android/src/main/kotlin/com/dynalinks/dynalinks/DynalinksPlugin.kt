package com.dynalinks.dynalinks

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import com.dynalinks.sdk.DeepLinkResult
import com.dynalinks.sdk.Dynalinks
import com.dynalinks.sdk.DynalinksError
import com.dynalinks.sdk.DynalinksLogLevel
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.NewIntentListener
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

class DynalinksPlugin : FlutterPlugin, MethodCallHandler, ActivityAware,
    EventChannel.StreamHandler, NewIntentListener {

    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var context: Context? = null
    private var activity: Activity? = null
    private var activityBinding: ActivityPluginBinding? = null
    private var eventSink: EventChannel.EventSink? = null
    private var initialLink: DeepLinkResult? = null
    private var initialLinkConsumed = false

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext

        methodChannel = MethodChannel(binding.binaryMessenger, "com.dynalinks.sdk/dynalinks")
        methodChannel.setMethodCallHandler(this)

        eventChannel = EventChannel(binding.binaryMessenger, "com.dynalinks.sdk/deep_links")
        eventChannel.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        scope.cancel()
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "configure" -> handleConfigure(call, result)
            "checkForDeferredDeepLink" -> handleCheckForDeferredDeepLink(result)
            "handleDeepLink" -> handleDeepLink(call, result)
            "getInitialLink" -> handleGetInitialLink(result)
            "reset" -> handleReset(result)
            else -> result.notImplemented()
        }
    }

    // MARK: - Method Handlers

    private fun handleConfigure(call: MethodCall, result: Result) {
        val ctx = context ?: run {
            result.error("NO_CONTEXT", "Application context not available", null)
            return
        }

        val clientAPIKey = call.argument<String>("clientAPIKey") ?: run {
            result.error("INVALID_ARGUMENTS", "Missing clientAPIKey", null)
            return
        }

        val baseURL = call.argument<String>("baseURL") ?: "https://dynalinks.app/api/v1"
        val logLevelString = call.argument<String>("logLevel") ?: "error"
        val allowEmulator = call.argument<Boolean>("allowSimulatorOrEmulator") ?: false

        val logLevel = when (logLevelString) {
            "none" -> DynalinksLogLevel.NONE
            "error" -> DynalinksLogLevel.ERROR
            "warning" -> DynalinksLogLevel.WARNING
            "info" -> DynalinksLogLevel.INFO
            "debug" -> DynalinksLogLevel.DEBUG
            else -> DynalinksLogLevel.ERROR
        }

        try {
            Dynalinks.configure(
                context = ctx,
                clientAPIKey = clientAPIKey,
                baseURL = baseURL,
                logLevel = logLevel,
                allowEmulator = allowEmulator
            )
            result.success(null)
        } catch (e: IllegalArgumentException) {
            result.error("INVALID_API_KEY", e.message, null)
        } catch (e: Exception) {
            result.error("UNKNOWN", e.message, null)
        }
    }

    private fun handleCheckForDeferredDeepLink(result: Result) {
        scope.launch {
            try {
                val deepLinkResult = Dynalinks.checkForDeferredDeepLink()
                result.success(encodeResult(deepLinkResult))
            } catch (e: DynalinksError) {
                result.error(errorCode(e), e.message, null)
            } catch (e: Exception) {
                result.error("UNKNOWN", e.message, null)
            }
        }
    }

    private fun handleDeepLink(call: MethodCall, result: Result) {
        val uriString = call.argument<String>("uri") ?: run {
            result.error("INVALID_ARGUMENTS", "Missing URI", null)
            return
        }

        val uri = Uri.parse(uriString)

        scope.launch {
            try {
                val deepLinkResult = Dynalinks.handleAppLink(uri)
                result.success(encodeResult(deepLinkResult.copy(isDeferred = false)))
            } catch (e: DynalinksError) {
                result.error(errorCode(e), e.message, null)
            } catch (e: Exception) {
                result.error("UNKNOWN", e.message, null)
            }
        }
    }

    private fun handleGetInitialLink(result: Result) {
        if (initialLinkConsumed) {
            result.success(null)
            return
        }
        initialLinkConsumed = true

        val link = initialLink
        if (link != null) {
            result.success(encodeResult(link.copy(isDeferred = false)))
        } else {
            result.success(null)
        }
    }

    private fun handleReset(result: Result) {
        Dynalinks.reset()
        initialLink = null
        initialLinkConsumed = false
        result.success(null)
    }

    // MARK: - ActivityAware

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        activityBinding = binding
        binding.addOnNewIntentListener(this)

        // Check initial intent
        handleIntent(binding.activity.intent)
    }

    override fun onDetachedFromActivity() {
        activityBinding?.removeOnNewIntentListener(this)
        activity = null
        activityBinding = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        activityBinding = binding
        binding.addOnNewIntentListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activityBinding?.removeOnNewIntentListener(this)
        activity = null
        activityBinding = null
    }

    // MARK: - NewIntentListener

    override fun onNewIntent(intent: Intent): Boolean {
        handleIntent(intent)
        return false
    }

    private fun handleIntent(intent: Intent?) {
        val uri = intent?.data ?: return

        scope.launch {
            try {
                val result = Dynalinks.handleAppLink(uri)
                val sink = eventSink
                if (sink != null) {
                    sink.success(encodeResult(result.copy(isDeferred = false)))
                } else {
                    // Store for getInitialLink if no listener yet
                    initialLink = result
                }
            } catch (e: Exception) {
                // Log but don't crash
                android.util.Log.e("DynalinksPlugin", "Failed to handle App Link", e)
            }
        }
    }

    // MARK: - EventChannel.StreamHandler

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    // MARK: - Helpers

    private fun encodeResult(result: DeepLinkResult): Map<String, Any?> {
        val map = mutableMapOf<String, Any?>(
            "matched" to result.matched,
            "confidence" to result.confidence?.name?.lowercase(),
            "match_score" to result.matchScore,
            "is_deferred" to result.isDeferred
        )

        result.link?.let { link ->
            map["link"] = hashMapOf<String, Any?>(
                "id" to link.id,
                "name" to link.name,
                "path" to link.path,
                "shortened_path" to link.shortenedPath,
                "url" to link.url,
                "full_url" to link.fullUrl,
                "deep_link_value" to link.deepLinkValue,
                "android_fallback_url" to link.androidFallbackUrl,
                "ios_fallback_url" to link.iosFallbackUrl,
                "enable_forced_redirect" to link.enableForcedRedirect,
                "social_title" to link.socialTitle,
                "social_description" to link.socialDescription,
                "social_image_url" to link.socialImageUrl,
                "clicks" to link.clicks,
                "ios_deferred_deep_linking_enabled" to link.iosDeferredDeepLinkingEnabled,
                "referrer" to link.referrer,
                "provider_token" to link.providerToken,
                "campaign_token" to link.campaignToken
            )
        }

        return map
    }

    private fun errorCode(error: DynalinksError): String = when (error) {
        is DynalinksError.NotConfigured -> "NOT_CONFIGURED"
        is DynalinksError.InvalidAPIKey -> "INVALID_API_KEY"
        is DynalinksError.Emulator -> "EMULATOR"
        is DynalinksError.InvalidIntent -> "INVALID_INTENT"
        is DynalinksError.NetworkError -> "NETWORK_ERROR"
        is DynalinksError.InvalidResponse -> "INVALID_RESPONSE"
        is DynalinksError.ServerError -> "SERVER_ERROR"
        is DynalinksError.NoMatch -> "NO_MATCH"
        is DynalinksError.InstallReferrerUnavailable -> "INSTALL_REFERRER_UNAVAILABLE"
        is DynalinksError.InstallReferrerTimeout -> "INSTALL_REFERRER_TIMEOUT"
    }
}
