package com.botoom.hydraflow

import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "hydraflow/device",
        ).setMethodCallHandler { call, result ->
            if (call.method == "formFactor") {
                result.success(
                    mapOf(
                        "isWatch" to packageManager.hasSystemFeature(
                            PackageManager.FEATURE_WATCH,
                        ),
                        "isRound" to resources.configuration.isScreenRound,
                    ),
                )
            } else {
                result.notImplemented()
            }
        }
    }
}
