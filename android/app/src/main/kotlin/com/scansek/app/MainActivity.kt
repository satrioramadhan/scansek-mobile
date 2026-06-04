package com.scansek.app

import android.content.Intent
import androidx.activity.result.contract.ActivityResultContracts
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import androidx.lifecycle.lifecycleScope
import kotlinx.coroutines.launch
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlin.coroutines.resume
import org.json.JSONArray
import org.json.JSONObject
import android.util.Log

import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.records.ExerciseSessionRecord
import androidx.health.connect.client.records.ExerciseRouteResult
import androidx.health.connect.client.records.ExerciseRoute
import androidx.health.connect.client.time.TimeRangeFilter
import java.time.Instant

class MainActivity: FlutterFragmentActivity() {
    private val CHANNEL = "com.scansek.app/health_route"
    private var pendingConsentCoroutine: kotlin.coroutines.Continuation<Boolean>? = null

    private val requestRouteLauncher = registerForActivityResult(
        ActivityResultContracts.StartActivityForResult()
    ) { result ->
        if (result.resultCode == RESULT_OK) {
            pendingConsentCoroutine?.resume(true)
        } else {
            pendingConsentCoroutine?.resume(false)
        }
        pendingConsentCoroutine = null
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "requestRouteConsent") {
                val sessionId = call.argument<String>("sessionId")
                if (sessionId != null) {
                    lifecycleScope.launch {
                        try {
                            val routeData = getRouteDataWithConsent(sessionId)
                            result.success(routeData)
                        } catch (e: Exception) {
                            Log.e("ScanSekHealth", "Error extracting route: ${e.message}")
                            result.error("ROUTE_ERROR", e.message, null)
                        }
                    }
                } else {
                    result.error("INVALID_ARGS", "Session ID is required", null)
                }
            } else if (call.method == "getRawSessionMetadata") {
                val sessionId = call.argument<String>("sessionId")
                if (sessionId != null) {
                    lifecycleScope.launch {
                        try {
                            val metadata = getSessionMetadata(sessionId)
                            result.success(metadata)
                        } catch (e: Exception) {
                            Log.e("ScanSekHealth", "Error extracting metadata: ${e.message}")
                            result.error("METADATA_ERROR", e.message, null)
                        }
                    }
                } else {
                    result.error("INVALID_ARGS", "Session ID is required", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private suspend fun getSessionMetadata(sessionId: String): String? {
        val healthConnectClient = HealthConnectClient.getOrCreate(this)
        
        val response = healthConnectClient.readRecords(
            androidx.health.connect.client.request.ReadRecordsRequest(
                recordType = ExerciseSessionRecord::class,
                timeRangeFilter = TimeRangeFilter.after(Instant.EPOCH)
            )
        )
        
        val session = response.records.find { it.metadata.id == sessionId }
        if (session == null) return null

        val jsonObject = JSONObject()
        jsonObject.put("title", session.title ?: "")
        jsonObject.put("notes", session.notes ?: "")
        return jsonObject.toString()
    }

    private suspend fun getRouteDataWithConsent(sessionId: String): String? {
        val healthConnectClient = HealthConnectClient.getOrCreate(this)
        
        val response = healthConnectClient.readRecords(
            androidx.health.connect.client.request.ReadRecordsRequest(
                recordType = ExerciseSessionRecord::class,
                timeRangeFilter = TimeRangeFilter.after(Instant.EPOCH)
            )
        )
        
        val session = response.records.find { it.metadata.id == sessionId }
        if (session == null) return null

        when (val routeResult = session.exerciseRouteResult) {
            is ExerciseRouteResult.Data -> {
                return serializeRoute(routeResult.exerciseRoute)
            }
            is ExerciseRouteResult.ConsentRequired -> {
                Log.d("ScanSekHealth", "Consent required. Launching intent...")
                
                // Suspend and wait for user to click "Allow"
                val granted = suspendCancellableCoroutine<Boolean> { continuation ->
                    pendingConsentCoroutine = continuation
                    try {
                        val intent = Intent("android.health.connect.action.REQUEST_EXERCISE_ROUTE")
                        intent.putExtra("android.health.connect.extra.SESSION_ID", sessionId)
                        requestRouteLauncher.launch(intent)
                    } catch (e: Exception) {
                        continuation.resume(false)
                    }
                }
                
                if (granted) {
                    // Re-fetch the session now that we have consent
                    val newResponse = healthConnectClient.readRecords(
                        androidx.health.connect.client.request.ReadRecordsRequest(
                            recordType = ExerciseSessionRecord::class,
                            timeRangeFilter = TimeRangeFilter.after(Instant.EPOCH)
                        )
                    )
                    val newSession = newResponse.records.find { it.metadata.id == sessionId }
                    if (newSession != null) {
                        val newRouteResult = newSession.exerciseRouteResult
                        if (newRouteResult is ExerciseRouteResult.Data) {
                            return serializeRoute(newRouteResult.exerciseRoute)
                        }
                    }
                }
                return null
            }
            else -> {
                return null
            }
        }
    }

    private fun serializeRoute(route: ExerciseRoute?): String? {
        if (route == null) return null
        val jsonArray = JSONArray()
        for (location in route.route) {
            val jsonObject = JSONObject()
            jsonObject.put("lat", location.latitude)
            jsonObject.put("lng", location.longitude)
            jsonObject.put("timestamp", location.time.toString())
            jsonArray.put(jsonObject)
        }
        return jsonArray.toString()
    }
}
