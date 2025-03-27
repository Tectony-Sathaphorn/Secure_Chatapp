package com.securechat.messenger2025

import io.flutter.app.FlutterApplication
import androidx.multidex.MultiDex
import android.content.Context

class SecureChatApplication : FlutterApplication() {
    override fun attachBaseContext(base: Context) {
        super.attachBaseContext(base)
        MultiDex.install(this)
    }
} 