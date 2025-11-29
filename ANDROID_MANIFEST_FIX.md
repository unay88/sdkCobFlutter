# Android Manifest Merger Conflict Fix

## Problem
```
Attribute application@usesCleartextTraffic value=(false) from (unknown)
is also present at [com.bjb.cob:cob-lib:0.2.3-SNAPSHOT] AndroidManifest.xml:14:9-44 value=(true).
```

## Solution

The `cob-lib` dependency requires `usesCleartextTraffic=true` for HTTP connections. You need to override this in your app's AndroidManifest.xml.

### Step 1: Update AndroidManifest.xml

Open your app's `android/app/src/main/AndroidManifest.xml` and add `tools:replace`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools"
    package="your.package.name">

    <application
        android:name=".MainApplication"
        android:label="@string/app_name"
        android:icon="@mipmap/ic_launcher"
        android:usesCleartextTraffic="true"
        tools:replace="android:usesCleartextTraffic">
        
        <!-- Your activities here -->
        
    </application>
</manifest>
```

### Step 2: Update Debug AndroidManifest (if exists)

If you have `android/app/src/debug/AndroidManifest.xml`, update it too:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools">

    <application
        android:usesCleartextTraffic="true"
        tools:replace="android:usesCleartextTraffic" />
        
</manifest>
```

### Key Changes:
1. Add `xmlns:tools="http://schemas.android.com/tools"` to `<manifest>` tag
2. Change `android:usesCleartextTraffic="false"` to `"true"`
3. Add `tools:replace="android:usesCleartextTraffic"` to `<application>` tag

### Why?
The BJB COB library (`cob-lib`) requires HTTP cleartext traffic for API communication. Setting this to `true` allows the library to function properly.

### Security Note
For production builds, consider using HTTPS endpoints and setting this back to `false` if possible.
