package com.example.barcode_scanner_reader

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel

class MainActivity : FlutterActivity() {

    private val SCANNER_CHANNEL = "scanner_channel"
    private var eventSink: EventChannel.EventSink? = null

    private val scannerReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent == null) return

            val action = intent.action ?: return

            val code: String? = when (action) {

                // ✅ UROVO
                "android.intent.ACTION_DECODE_DATA" -> {
                    intent.getStringExtra("barcode_string")
                }

                // ✅ HONEYWELL
                "com.honeywell.intent.action.BARCODE" -> {
                    intent.getStringExtra("data")
                }

                // ✅ ZEBRA (DataWedge)
                "com.symbol.datawedge.api.RESULT_ACTION" -> {
                    intent.getStringExtra("com.symbol.datawedge.data_string")
                }

                else -> null
            }

            if (!code.isNullOrEmpty()) {
                eventSink?.success(code)
            }
        }
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SCANNER_CHANNEL
        ).setStreamHandler(object : EventChannel.StreamHandler {

            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events

                val filter = IntentFilter().apply {
                    addAction("android.intent.ACTION_DECODE_DATA") // Urovo
                    addAction("com.honeywell.intent.action.BARCODE") // Honeywell
                    addAction("com.symbol.datawedge.api.RESULT_ACTION") // Zebra
                }

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    registerReceiver(
                        scannerReceiver,
                        filter,
                        Context.RECEIVER_NOT_EXPORTED
                    )
                } else {
                    @Suppress("DEPRECATION")
                    registerReceiver(scannerReceiver, filter)
                }
            }

            override fun onCancel(arguments: Any?) {
                unregisterReceiver(scannerReceiver)
                eventSink = null
            }
        })
    }
}
