package com.example.naver_login_flutter

import android.app.Activity
import android.content.Context
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.util.Log
import com.navercorp.nid.NidOAuth
import com.navercorp.nid.oauth.NidOAuthLogin
import com.navercorp.nid.oauth.util.NidOAuthCallback

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.json.JSONException
import org.json.JSONObject
import java.io.BufferedReader
import java.io.InputStreamReader
import java.net.HttpURLConnection
import java.net.URL
import java.text.SimpleDateFormat
import java.util.*
import java.util.concurrent.ExecutionException

/// 네이버 로그인 상태를 나타내는 열거형
enum class NaverLoginStatus(val value: String) {
    LOGGED_IN("loggedIn"),
    LOGGED_OUT("loggedOut"),
    ERROR("error")
}

/// Flutter 플러그인 메서드를 나타내는 열거형
enum class FlutterPluginMethod {
    InitSdk,
    LogIn,
    LogOut,
    LogOutAndDeleteToken,
    GetCurrentAccount,
    GetCurrentAccessToken,
    RefreshAccessTokenWithRefreshToken,
    IsLoggedIn,
    SetLogEnabled,
    Unknown;

    companion object {
        fun fromMethodName(methodName: String): FlutterPluginMethod {
            return when (methodName) {
                "initSdk" -> InitSdk
                "logIn" -> LogIn
                "logOut" -> LogOut
                "logoutAndDeleteToken" -> LogOutAndDeleteToken
                "getCurrentAccount", "getCurrentAcount" -> GetCurrentAccount // 오타 지원
                "getCurrentAccessToken" -> GetCurrentAccessToken
                "refreshAccessTokenWithRefreshToken" -> RefreshAccessTokenWithRefreshToken
                "isLoggedIn" -> IsLoggedIn
                "setLogEnabled" -> SetLogEnabled
                else -> Unknown
            }
        }
    }
}

/** FlutterNaverLoginPlugin */
class FlutterNaverLoginPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {

    /// The MethodChannel that will facilitate communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel

    private val mainScope = CoroutineScope(Dispatchers.Main)

    // Must use this activity instead of context (flutterPluginBinding.applicationContext) to avoid AppCompat issue
    private var activity: Activity? = null

    private lateinit var context: Context

    // pendingResult in login function
    // used to call flutter result in launcher
    private var pendingResult: Result? = null

    // 플러그인/SDK 로그 출력 여부. onAttachedToEngine에서 결정되고
    // setLogEnabled 채널 메서드로 런타임에 변경할 수 있다.
    private var isLogEnabled: Boolean = false

    // MARK: - FlutterPlugin

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "naver_login_flutter")
        channel.setMethodCallHandler(this)

        try {
            context.packageName?.let { packageName ->
                val bundle = context.packageManager?.getApplicationInfo(
                    packageName,
                    PackageManager.GET_META_DATA
                )?.metaData

                applyInitialLogSetting(bundle)

                if (bundle != null) {
                    val clientId = bundle.getString("com.naver.sdk.clientId")
                    val clientSecret = bundle.getString("com.naver.sdk.clientSecret")
                    val clientName = bundle.getString("com.naver.sdk.clientName")

                    logD("=== Naver Login Plugin Registration ===")
                    logD("ClientID: $clientId")
                    logD("ClientSecret: ${clientSecret.masked()}")
                    logD("ClientName: $clientName")
                    logD("===================================")

                    if (clientId != null && clientSecret != null && clientName != null) {
                        try {
                            NidOAuth.initialize(context, clientId, clientSecret, clientName)
                            logD("Naver Login SDK initialized successfully on plugin registration")
                        } catch (e: Exception) {
                            Log.e(LOG_TAG, "Failed to initialize Naver Login SDK: ${e.message}", e)
                        }
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(LOG_TAG, "Error reading AndroidManifest.xml meta-data: ${e.message}", e)
        }
    }

    /// 로그 초기값을 결정한다.
    /// AndroidManifest의 com.naver.sdk.logEnabled 가 있으면 그 값을,
    /// 없으면 호스트 앱의 debuggable 여부를 따른다.
    private fun applyInitialLogSetting(bundle: android.os.Bundle?) {
        val debuggable = (context.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0
        setLogEnabled(bundle?.getBoolean("com.naver.sdk.logEnabled", debuggable) ?: debuggable)
    }

    private fun setLogEnabled(enabled: Boolean) {
        isLogEnabled = enabled
        NidOAuth.setLogEnabled(enabled)
    }

    private fun logD(message: String) {
        if (isLogEnabled) Log.d(LOG_TAG, message)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    // MARK: - ActivityAware

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    // MARK: - MethodCallHandler

    override fun onMethodCall(call: MethodCall, result: Result) {
        logD("Called method: ${call.method}")

        when (FlutterPluginMethod.fromMethodName(call.method)) {
            FlutterPluginMethod.InitSdk -> {
                @Suppress("UNCHECKED_CAST") val args = call.arguments as Map<String, String?>
                val clientId = args["clientId"] as String
                val clientName = args["clientName"] as String
                val clientSecret = args["clientSecret"] as String
                initSdk(result, clientId, clientName, clientSecret)
            }
            FlutterPluginMethod.LogIn -> login(result)
            FlutterPluginMethod.LogOut -> logout(result)
            FlutterPluginMethod.LogOutAndDeleteToken -> logoutAndDeleteToken(result)
            FlutterPluginMethod.GetCurrentAccessToken -> getCurrentAccessToken(result)
            FlutterPluginMethod.GetCurrentAccount -> {
                mainScope.launch {
                    getCurrentAccount(result)
                }
            }
            FlutterPluginMethod.RefreshAccessTokenWithRefreshToken -> refreshAccessTokenWithRefreshToken(result)
            FlutterPluginMethod.IsLoggedIn -> isLoggedIn(result)
            FlutterPluginMethod.SetLogEnabled -> {
                val enabled = (call.arguments as? Map<*, *>)?.get("enabled") as? Boolean ?: false
                setLogEnabled(enabled)
                result.success(null)
            }
            FlutterPluginMethod.Unknown -> result.notImplemented()
        }
    }

    // MARK: - Private Methods

    private fun initSdk(result: Result, clientId: String, clientName: String, clientSecret: String) {
        try {
            logD("Init SDK")
            logD("- clientId: $clientId")
            logD("- clientName: $clientName")
            logD("- clientSecret: ${clientSecret.masked()}")

            NidOAuth.initialize(context, clientId, clientSecret, clientName)
            sendResult(NaverLoginStatus.LOGGED_OUT, null, null, result)

        } catch (e: Exception) {
            e.printStackTrace()
            result.error(
                e.javaClass.simpleName,
                "NaverIdLoginSDK.initialize failed. message: " + e.localizedMessage,
                null
            )
        }
    }

    private suspend fun getCurrentAccount(result: Result, includeToken: Boolean = false) {
        // SDK 초기화 상태 확인
        try {
            val state = NidOAuth.getState()
        } catch (e: Exception) {
            sendError("SDK not initialized. Please call initSdk first.", result)
            return
        }

        val accessToken = NidOAuth.getAccessToken()

        if (accessToken == null) {
            sendResult(NaverLoginStatus.LOGGED_OUT, null, null, result)
            return
        }

        // 로그인 결과에는 iOS와 동일하게 토큰 정보를 함께 반환한다 (#14)
        val tokenInfo = if (includeToken) mapOf(
            "accessToken" to accessToken,
            "refreshToken" to (NidOAuth.getRefreshToken() ?: ""),
            "tokenType" to (NidOAuth.getTokenType() ?: "bearer"),
            "expiresAt" to formatExpiresAt(NidOAuth.getExpiresAt())
        ) else null

        try {
            val res = getUserInfo(accessToken)
            val obj = JSONObject(res)
            val account = jsonObjectToMap(obj.getJSONObject("response"))
            sendResult(NaverLoginStatus.LOGGED_IN, tokenInfo, account, result)
        } catch (e: InterruptedException) {
            e.printStackTrace()
            sendError("Failed to get user info: ${e.message}", result)
        } catch (e: ExecutionException) {
            e.printStackTrace()
            sendError("Failed to get user info: ${e.message}", result)
        } catch (e: JSONException) {
            e.printStackTrace()
            sendError("Failed to parse user info: ${e.message}", result)
        }
    }



    private fun login(result: Result) {
        // SDK 초기화 상태 확인
        try {
            val state = NidOAuth.getState()
            logD("Current SDK state: $state")
        } catch (e: Exception) {
            sendError("SDK not initialized. Please call initSdk first.", result)
            return
        }

        pendingResult = result

        val mOAuthLoginHandler = object : NidOAuthCallback {
            override fun onSuccess() {
                mainScope.launch {
                    getCurrentAccount(result, includeToken = true)
                }
            }

            override fun onFailure(errorCode: String, errorDesc: String) {
                // 사용자 취소인지 확인
                if (errorCode == "user_cancel" || errorDesc.contains("cancel", ignoreCase = true)) {
                    sendResult(NaverLoginStatus.LOGGED_OUT, null, null, result)
                } else {
                    result.success(object : HashMap<String, String>() {
                        init {
                            put("status", "error")
                            put("errorMessage", "errorCode:$errorCode, errorDesc:$errorDesc")
                        }
                    })
                }
                // Already handled result. We don't need this at the ActivityResult as pending status
                pendingResult = null
            }
        }

        val performLogin = {
            activity?.let {
                NidOAuth.requestLogin(it, mOAuthLoginHandler)
            } ?: run {
                sendError("Activity is null", result)
                pendingResult = null
            }
        }

        // 기존 토큰이 있다면 먼저 삭제 (user_cancel 문제 방지)
        try {
            if (NidOAuth.getAccessToken() != null) {
                logD("Existing token found, logging out first")
                NidOAuth.logout(object : NidOAuthCallback {
                    override fun onSuccess() { performLogin() }
                    override fun onFailure(errorCode: String, errorDesc: String) { performLogin() }
                })
            } else {
                performLogin()
            }
        } catch (e: Exception) {
            // 토큰 체크 실패는 무시하고 계속 진행
            logD("Token check failed: ${e.message}")
            performLogin()
        }
    }

    private fun logout(result: Result) {
        try {
            NidOAuth.logout(object : NidOAuthCallback {
                override fun onSuccess() {
                    sendResult(NaverLoginStatus.LOGGED_OUT, null, null, result)
                }
                override fun onFailure(errorCode: String, errorDesc: String) {
                    sendResult(NaverLoginStatus.LOGGED_OUT, null, null, result)
                }
            })
        } catch (e: Exception) {
            /**
            Firebase Crasylytics error workaround

            ArrayDecoders.decodeUnknownField
            com.google.crypto.tink.shaded.protobuf.c0 - Protocol message contained an invalid tag (zero).
             */
            e.printStackTrace()
            sendResult(NaverLoginStatus.LOGGED_OUT, null, null, result)
        }
    }

    private fun logoutAndDeleteToken(result: Result) {
        val mOAuthLoginHandler = object : NidOAuthCallback {
            override fun onSuccess() {
                sendResult(NaverLoginStatus.LOGGED_OUT, null, null, result)
            }

            override fun onFailure(errorCode: String, errorDesc: String) {
                // 서버에서 token 삭제에 실패했어도 클라이언트에 있는 token 은 삭제되어 로그아웃된 상태이다
                // 실패했어도 클라이언트 상에 token 정보가 없기 때문에 추가적으로 해줄 수 있는 것은 없음
                result.success(object : HashMap<String, String>() {
                    init {
                        put("status", "error")
                        put("errorMessage", "errorCode:$errorCode, errorDesc:$errorDesc")
                    }
                })
            }
        }

        NidOAuth.disconnect(mOAuthLoginHandler)
    }

    private fun getCurrentAccessToken(result: Result) {
        logD("handleGetCurrentAccessToken")

        // SDK 초기화 상태 확인
        try {
            val state = NidOAuth.getState()
        } catch (e: Exception) {
            sendError("SDK not initialized. Please call initSdk first.", result)
            return
        }

        val accessToken = NidOAuth.getAccessToken()
        val refreshToken = NidOAuth.getRefreshToken()
        val expiresAt = NidOAuth.getExpiresAt()
        val tokenType = NidOAuth.getTokenType()

        if (accessToken == null) {
            sendResult(NaverLoginStatus.LOGGED_OUT, null, null, result)
            return
        }

        val tokenInfo = mapOf(
            "accessToken" to accessToken,
            "refreshToken" to (refreshToken ?: ""),
            "tokenType" to (tokenType ?: "bearer"),
            "expiresAt" to formatExpiresAt(expiresAt)
        )

        sendResult(NaverLoginStatus.LOGGED_IN, tokenInfo, null, result)
    }

    private fun refreshAccessTokenWithRefreshToken(result: Result) {
        val refreshToken = NidOAuth.getRefreshToken()
        if (refreshToken == null) {
            sendError("No refresh token available", result)
            return
        }

        val mOAuthLoginHandler = object : NidOAuthCallback {
            override fun onSuccess() {
                val accessToken = NidOAuth.getAccessToken()
                val newRefreshToken = NidOAuth.getRefreshToken()
                val expiresAt = NidOAuth.getExpiresAt()
                val tokenType = NidOAuth.getTokenType()

                if (accessToken != null) {
                    val tokenInfo = mapOf(
                        "accessToken" to accessToken,
                        "refreshToken" to (newRefreshToken ?: ""),
                        "tokenType" to (tokenType ?: "bearer"),
                        "expiresAt" to formatExpiresAt(expiresAt)
                    )
                    sendResult(NaverLoginStatus.LOGGED_IN, tokenInfo, null, result)
                } else {
                    sendError("Failed to get refreshed access token", result)
                }
            }

            override fun onFailure(errorCode: String, errorDesc: String) {
                result.success(object : HashMap<String, String>() {
                    init {
                        put("status", "error")
                        put("errorMessage", "errorCode:$errorCode, errorDesc:$errorDesc")
                    }
                })
            }
        }

        NidOAuthLogin().callRefreshAccessTokenApi(mOAuthLoginHandler)
    }

    private fun isLoggedIn(result: Result) {
        // SDK 초기화 상태 확인
        try {
            val state = NidOAuth.getState()
        } catch (e: Exception) {
            sendError("SDK not initialized. Please call initSdk first.", result)
            return
        }

        val accessToken = NidOAuth.getAccessToken()
        if (accessToken != null) {
            sendResult(NaverLoginStatus.LOGGED_IN, null, null, result)
        } else {
            sendResult(NaverLoginStatus.LOGGED_OUT, null, null, result)
        }
    }

    // MARK: - Helper Methods

    private suspend fun getUserInfo(token: String): String = withContext(Dispatchers.IO) {
        val header = "Bearer $token"
        try {
            val apiURL = "https://openapi.naver.com/v1/nid/me"
            val url = URL(apiURL)
            val con = url.openConnection() as HttpURLConnection
            con.requestMethod = "GET"
            con.setRequestProperty("Authorization", header)
            val responseCode = con.responseCode
            val br: BufferedReader = if (responseCode == 200) {
                BufferedReader(InputStreamReader(con.inputStream))
            } else {
                BufferedReader(InputStreamReader(con.errorStream))
            }
            val response = br.use(BufferedReader::readText)
            br.close()
            response
        } catch (e: Exception) {
            e.printStackTrace()
            ""
        }
    }

    private fun formatExpiresAt(expiresAt: Long): String {
        val date = Date(expiresAt * 1000) // 초를 밀리초로 변환
        val formatter = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'", Locale.getDefault())
        formatter.timeZone = TimeZone.getTimeZone("UTC")
        return formatter.format(date)
    }

    @Throws(JSONException::class)
    fun jsonObjectToMap(jObject: JSONObject): HashMap<String, String> {
        val map = HashMap<String, String>()
        val keys = jObject.keys()

        while (keys.hasNext()) {
            val key = keys.next() as String
            val value = jObject.getString(key)
            map[key] = value
        }
        return map
    }

    // MARK: - Result Handling

    private fun sendResult(
        status: NaverLoginStatus,
        accessToken: Map<String, Any>? = null,
        account: Map<String, String>? = null,
        result: Result
    ) {
        val resultMap = mutableMapOf<String, Any>("status" to status.value.lowercase())

        accessToken?.let { resultMap["accessToken"] = it }
        account?.let { resultMap["account"] = it }

        result.success(resultMap)
    }

    private fun sendError(message: String, result: Result) {
        val errorInfo = mapOf(
            "status" to NaverLoginStatus.ERROR.value.lowercase(),
            "errorMessage" to message
        )

        result.success(errorInfo)
    }
}
private const val LOG_TAG = "NaverLoginFlutter"

/// 값이 들어왔는지만 확인할 수 있게 앞 3자와 길이만 남긴다.
private fun String?.masked(): String = when {
    this.isNullOrEmpty() -> "(not set)"
    length <= 4 -> "*".repeat(length) + " ($length chars)"
    else -> take(3) + "*".repeat(length - 3) + " ($length chars)"
}
