package com.alertsense

import android.content.Context
import android.content.ContextWrapper
import android.content.Intent
import android.content.IntentFilter
import android.net.Uri
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.BatteryManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.provider.Telephony
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.alertsense/device"

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getBatteryLevel" -> {
                    val batteryLevel = getBatteryLevel()
                    if (batteryLevel != -1) {
                        result.success(batteryLevel)
                    } else {
                        result.error("UNAVAILABLE", "Battery level not available.", null)
                    }
                }
                "isIgnoringBatteryOptimizations" -> {
                    val isIgnoring = isIgnoringBatteryOptimizations()
                    result.success(isIgnoring)
                }
                "sendDirectSms" -> {
                    val recipient = call.argument<String>("recipient") ?: ""
                    val message = call.argument<String>("message") ?: ""
                    val success = sendDirectSms(recipient, message)
                    result.success(success)
                }
                "isLocationServiceEnabled" -> {
                    val isEnabled = isLocationServiceEnabled()
                    result.success(isEnabled)
                }
                "checkPermission" -> {
                    val hasFine = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        checkSelfPermission(android.Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
                    } else true
                    val hasCoarse = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        checkSelfPermission(android.Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED
                    } else true
                    result.success(hasFine || hasCoarse)
                }
                "getLastKnownLocation" -> {
                    val loc = getLastKnownLocation()
                    result.success(loc)
                }
                "getCurrentLocation" -> {
                    getCurrentLocation(result)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun sendDirectSms(recipient: String, message: String): Boolean {
        return try {
            val defaultSmsPackage = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
                Telephony.Sms.getDefaultSmsPackage(applicationContext)
            } else null

            val cleanRecipient = recipient.trim().replace(" ", "")
            val encodedRecipient = Uri.encode(cleanRecipient, "+,;")
            val encodedBody = Uri.encode(message)
            val smsUri = Uri.parse("smsto:" + encodedRecipient + "?body=" + encodedBody)
            val intent = Intent(Intent.ACTION_SENDTO).apply {
                data = smsUri
                putExtra("address", cleanRecipient)
                putExtra(Intent.EXTRA_PHONE_NUMBER, cleanRecipient)
                putExtra("sms_body", message)
                putExtra(Intent.EXTRA_TEXT, message)
                putExtra("exit_on_sent", true)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                if (!defaultSmsPackage.isNullOrEmpty()) {
                    setPackage(defaultSmsPackage)
                }
            }

            if (intent.resolveActivity(packageManager) != null) {
                startActivity(intent)
                true
            } else {
                val fallbackIntent = Intent(Intent.ACTION_SENDTO).apply {
                    data = smsUri
                    putExtra("address", cleanRecipient)
                    putExtra(Intent.EXTRA_PHONE_NUMBER, cleanRecipient)
                    putExtra("sms_body", message)
                    putExtra(Intent.EXTRA_TEXT, message)
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                startActivity(fallbackIntent)
                true
            }
        } catch (e: Exception) {
            false
        }
    }

    private fun getBatteryLevel(): Int {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                val batteryManager = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
                batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
            } else {
                val intent = ContextWrapper(applicationContext).registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
                if (intent != null) {
                    val level = intent.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
                    val scale = intent.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
                    if (level != -1 && scale > 0) {
                        (level * 100) / scale
                    } else {
                        -1
                    }
                } else {
                    -1
                }
            }
        } catch (e: Exception) {
            -1
        }
    }

    private fun isIgnoringBatteryOptimizations(): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
                powerManager.isIgnoringBatteryOptimizations(packageName)
            } else {
                true
            }
        } catch (e: Exception) {
            true
        }
    }

    private fun isLocationServiceEnabled(): Boolean {
        return try {
            val locationManager = getSystemService(Context.LOCATION_SERVICE) as? LocationManager ?: return false
            val gps = locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER)
            val network = locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)
            gps || network
        } catch (e: Exception) {
            false
        }
    }

    private fun isBetterLocation(location: Location, currentBestLocation: Location?): Boolean {
        if (currentBestLocation == null) return true
        val timeDelta = location.time - currentBestLocation.time
        val isSignificantlyNewer = timeDelta > 1000 * 60 * 2 // 2 minutes newer
        val isSignificantlyOlder = timeDelta < -1000 * 60 * 2 // 2 minutes older
        val isNewer = timeDelta > 0

        if (isSignificantlyNewer) return true
        if (isSignificantlyOlder) return false

        val accuracyDelta = (location.accuracy - currentBestLocation.accuracy).toInt()
        val isLessAccurate = accuracyDelta > 0
        val isMoreAccurate = accuracyDelta < 0
        val isSignificantlyLessAccurate = accuracyDelta > 200

        if (isMoreAccurate) return true
        if (isNewer && !isLessAccurate) return true
        if (isNewer && !isSignificantlyLessAccurate && location.provider == currentBestLocation.provider) return true
        return false
    }

    private fun getLastKnownLocation(): Map<String, Any>? {
        return try {
            val locationManager = getSystemService(Context.LOCATION_SERVICE) as? LocationManager ?: return null
            val hasFine = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                checkSelfPermission(android.Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
            } else true
            val hasCoarse = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                checkSelfPermission(android.Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED
            } else true
            if (!hasFine && !hasCoarse) return null

            var bestLocation: Location? = null
            val providers = listOf(
                LocationManager.GPS_PROVIDER,
                LocationManager.NETWORK_PROVIDER,
                LocationManager.PASSIVE_PROVIDER
            )
            for (provider in providers) {
                try {
                    if (locationManager.isProviderEnabled(provider)) {
                        val loc = locationManager.getLastKnownLocation(provider)
                        if (loc != null && isBetterLocation(loc, bestLocation)) {
                            bestLocation = loc
                        }
                    }
                } catch (_: Exception) {}
            }

            if (bestLocation != null) {
                mapOf(
                    "latitude" to bestLocation.latitude,
                    "longitude" to bestLocation.longitude,
                    "accuracy" to bestLocation.accuracy.toDouble(),
                    "timestamp" to bestLocation.time
                )
            } else null
        } catch (e: Exception) {
            null
        }
    }

    private fun getCurrentLocation(result: MethodChannel.Result) {
        try {
            val lastKnown = getLastKnownLocation()
            val locationManager = getSystemService(Context.LOCATION_SERVICE) as? LocationManager
            if (locationManager == null) {
                result.success(lastKnown)
                return
            }

            val hasFine = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                checkSelfPermission(android.Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
            } else true
            val hasCoarse = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                checkSelfPermission(android.Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED
            } else true
            if (!hasFine && !hasCoarse) {
                result.error("PERMISSION_DENIED", "Location permissions not granted.", null)
                return
            }

            val activeProviders = mutableListOf<String>()
            if (locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)) {
                activeProviders.add(LocationManager.NETWORK_PROVIDER)
            }
            if (locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER)) {
                activeProviders.add(LocationManager.GPS_PROVIDER)
            }

            if (activeProviders.isEmpty()) {
                if (lastKnown != null) {
                    result.success(lastKnown)
                } else {
                    result.error("LOCATION_DISABLED", "Location services are disabled.", null)
                }
                return
            }

            var responded = false
            var currentBest: Location? = null
            val listeners = mutableListOf<LocationListener>()

            val finishWithLocation: (Location?) -> Unit = { loc ->
                if (!responded) {
                    responded = true
                    for (l in listeners) {
                        try { locationManager.removeUpdates(l) } catch (_: Exception) {}
                    }
                    if (loc != null) {
                        result.success(mapOf(
                            "latitude" to loc.latitude,
                            "longitude" to loc.longitude,
                            "accuracy" to loc.accuracy.toDouble(),
                            "timestamp" to loc.time
                        ))
                    } else {
                        result.success(lastKnown)
                    }
                }
            }

            val listener = object : LocationListener {
                override fun onLocationChanged(location: Location) {
                    if (isBetterLocation(location, currentBest)) {
                        currentBest = location
                    }
                    // Instant return if accuracy is good enough for emergency location (<= 35m)
                    if (location.accuracy <= 35.0f) {
                        finishWithLocation(location)
                    }
                }
                override fun onProviderDisabled(p: String) {}
                override fun onProviderEnabled(p: String) {}
                @Deprecated("Deprecated in Java")
                override fun onStatusChanged(p: String?, status: Int, extras: Bundle?) {}
            }
            listeners.add(listener)

            for (provider in activeProviders) {
                try {
                    locationManager.requestLocationUpdates(
                        provider,
                        0L,
                        0f,
                        listener,
                        Looper.getMainLooper()
                    )
                } catch (_: Exception) {}
            }

            // Strict fast watchdog timeout: 2400ms to guarantee response before Dart timeout
            Handler(Looper.getMainLooper()).postDelayed({
                finishWithLocation(currentBest)
            }, 2400)
        } catch (e: Exception) {
            result.success(getLastKnownLocation())
        }
    }
}
