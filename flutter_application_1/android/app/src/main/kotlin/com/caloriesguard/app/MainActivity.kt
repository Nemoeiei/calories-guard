package com.caloriesguard.app

import io.flutter.embedding.android.FlutterFragmentActivity

// Must extend FlutterFragmentActivity (not FlutterActivity) so the health
// plugin's Activity Result APIs used for Health Connect permission prompts
// can attach to a fragment host. Without this, requestAuthorization() on
// Android silently returns false.
class MainActivity : FlutterFragmentActivity()
