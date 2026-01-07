import Flutter
import UIKit
import DynalinksSDK

public class DynalinksPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {

    private var eventSink: FlutterEventSink?
    private var initialLink: DeepLinkResult?
    private var initialLinkConsumed = false

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = DynalinksPlugin()

        // Method channel for one-off calls
        let methodChannel = FlutterMethodChannel(
            name: "com.dynalinks.sdk/dynalinks",
            binaryMessenger: registrar.messenger()
        )
        registrar.addMethodCallDelegate(instance, channel: methodChannel)

        // Event channel for streaming deep links
        let eventChannel = FlutterEventChannel(
            name: "com.dynalinks.sdk/deep_links",
            binaryMessenger: registrar.messenger()
        )
        eventChannel.setStreamHandler(instance)

        // Register for app delegate callbacks
        registrar.addApplicationDelegate(instance)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "configure":
            handleConfigure(call, result: result)
        case "checkForDeferredDeepLink":
            handleCheckForDeferredDeepLink(result: result)
        case "handleDeepLink":
            handleDeepLink(call, result: result)
        case "getInitialLink":
            handleGetInitialLink(result: result)
        case "reset":
            handleReset(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Method Handlers

    private func handleConfigure(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let clientAPIKey = args["clientAPIKey"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing clientAPIKey", details: nil))
            return
        }

        let baseURLString = args["baseURL"] as? String
        let baseURL = baseURLString.flatMap { URL(string: $0) } ?? URL(string: "https://dynalinks.app/api/v1")!
        let logLevelString = args["logLevel"] as? String ?? "error"
        let allowSimulator = args["allowSimulatorOrEmulator"] as? Bool ?? false

        let logLevel: DynalinksLogLevel
        switch logLevelString {
        case "none": logLevel = .none
        case "error": logLevel = .error
        case "warning": logLevel = .warning
        case "info": logLevel = .info
        case "debug": logLevel = .debug
        default: logLevel = .error
        }

        do {
            try Dynalinks.configure(
                clientAPIKey: clientAPIKey,
                baseURL: baseURL,
                logLevel: logLevel,
                allowSimulator: allowSimulator
            )
            result(nil)
        } catch let error as DynalinksError {
            result(flutterError(from: error))
        } catch {
            result(FlutterError(code: "UNKNOWN", message: error.localizedDescription, details: nil))
        }
    }

    private func handleCheckForDeferredDeepLink(result: @escaping FlutterResult) {
        Task {
            do {
                let deepLinkResult = try await Dynalinks.checkForDeferredDeepLink()
                DispatchQueue.main.async {
                    result(self.encodeResult(deepLinkResult, isDeferred: true))
                }
            } catch let error as DynalinksError {
                DispatchQueue.main.async {
                    result(self.flutterError(from: error))
                }
            } catch {
                DispatchQueue.main.async {
                    result(FlutterError(code: "UNKNOWN", message: error.localizedDescription, details: nil))
                }
            }
        }
    }

    private func handleDeepLink(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let uriString = args["uri"] as? String,
              let url = URL(string: uriString) else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing or invalid URI", details: nil))
            return
        }

        Task {
            do {
                let deepLinkResult = try await Dynalinks.handleUniversalLink(url: url)
                DispatchQueue.main.async {
                    result(self.encodeResult(deepLinkResult, isDeferred: false))
                }
            } catch let error as DynalinksError {
                DispatchQueue.main.async {
                    result(self.flutterError(from: error))
                }
            } catch {
                DispatchQueue.main.async {
                    result(FlutterError(code: "UNKNOWN", message: error.localizedDescription, details: nil))
                }
            }
        }
    }

    private func handleGetInitialLink(result: @escaping FlutterResult) {
        guard !initialLinkConsumed else {
            result(nil)
            return
        }
        initialLinkConsumed = true

        if let link = initialLink {
            result(encodeResult(link, isDeferred: false))
        } else {
            result(nil)
        }
    }

    private func handleReset(result: @escaping FlutterResult) {
        Dynalinks.reset()
        initialLink = nil
        initialLinkConsumed = false
        result(nil)
    }

    // MARK: - FlutterStreamHandler

    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }

    // MARK: - App Delegate

    public func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([Any]) -> Void
    ) -> Bool {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let url = userActivity.webpageURL else {
            return false
        }

        handleIncomingLink(url)
        return true
    }

    private func handleIncomingLink(_ url: URL) {
        Task {
            do {
                let result = try await Dynalinks.handleUniversalLink(url: url)
                DispatchQueue.main.async {
                    if let sink = self.eventSink {
                        sink(self.encodeResult(result, isDeferred: false))
                    } else {
                        // Store for getInitialLink if no listener yet
                        self.initialLink = result
                    }
                }
            } catch {
                // Log error but don't crash
                print("Dynalinks: Failed to handle Universal Link: \(error)")
            }
        }
    }

    // MARK: - Helpers

    private func encodeResult(_ result: DeepLinkResult, isDeferred: Bool) -> [String: Any?] {
        var dict: [String: Any?] = [
            "matched": result.matched,
            "confidence": result.confidence?.rawValue,
            "match_score": result.matchScore,
            "is_deferred": isDeferred,
        ]

        if let link = result.link {
            dict["link"] = encodeLinkData(link)
        }

        return dict
    }

    private func encodeLinkData(_ link: DeepLinkResult.LinkData) -> [String: Any?] {
        return [
            "id": link.id,
            "name": link.name,
            "path": link.path,
            "shortened_path": link.shortenedPath,
            "url": link.url?.absoluteString,
            "full_url": link.fullURL?.absoluteString,
            "deep_link_value": link.deepLinkValue,
            "ios_deferred_deep_linking_enabled": link.iosDeferredDeepLinkingEnabled,
            "android_fallback_url": link.androidFallbackURL?.absoluteString,
            "ios_fallback_url": link.iosFallbackURL?.absoluteString,
            "enable_forced_redirect": link.enableForcedRedirect,
            "social_title": link.socialTitle,
            "social_description": link.socialDescription,
            "social_image_url": link.socialImageURL?.absoluteString,
            "clicks": link.clicks,
        ]
    }

    private func flutterError(from error: DynalinksError) -> FlutterError {
        let code: String
        let message: String

        switch error {
        case .notConfigured:
            code = "NOT_CONFIGURED"
            message = error.errorDescription ?? "SDK not configured"
        case .invalidAPIKey(let msg):
            code = "INVALID_API_KEY"
            message = msg
        case .simulator:
            code = "SIMULATOR"
            message = error.errorDescription ?? "Not available on simulator"
        case .networkError:
            code = "NETWORK_ERROR"
            message = error.errorDescription ?? "Network error"
        case .invalidResponse:
            code = "INVALID_RESPONSE"
            message = error.errorDescription ?? "Invalid response"
        case .serverError(let statusCode, let msg):
            code = "SERVER_ERROR"
            message = msg ?? "Server error: \(statusCode)"
        case .noMatch:
            code = "NO_MATCH"
            message = error.errorDescription ?? "No match"
        }

        return FlutterError(code: code, message: message, details: nil)
    }
}
