package com.example.partiu

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.google.android.libraries.maps.MapsInitializer
import com.google.android.libraries.maps.OnMapsSdkInitializedCallback

class MainActivity : FlutterActivity(), OnMapsSdkInitializedCallback {
    private val CHANNEL = "com.example.partiu/google_maps"
    private var googleMapsChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        googleMapsChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        
        googleMapsChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "setApiKey" -> {
                    val apiKey = call.argument<String>("apiKey")
                    if (apiKey != null) {
                        try {
                            // Initialize Google Maps with the API key
                            MapsInitializer.initialize(applicationContext, MapsInitializer.Renderer.LATEST, this)
                            result.success("Google Maps initialized successfully")
                        } catch (e: Exception) {
                            result.error("INITIALIZATION_ERROR", e.message, null)
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "API key is required", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onMapsSdkInitialized(renderer: MapsInitializer.Renderer) {
        when (renderer) {
            MapsInitializer.Renderer.LATEST -> {
                // Using the latest renderer
            }
            MapsInitializer.Renderer.LEGACY -> {
                // Using the legacy renderer
            }
        }
    }

    override fun onDestroy() {
        googleMapsChannel?.setMethodCallHandler(null)
        super.onDestroy()
    }
}
