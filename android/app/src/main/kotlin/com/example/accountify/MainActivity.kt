package com.example.accountify

import io.flutter.embedding.android.FlutterFragmentActivity

// local_auth requires FlutterFragmentActivity (not FlutterActivity) so the
// biometric prompt can attach to a FragmentActivity host.
class MainActivity : FlutterFragmentActivity()
