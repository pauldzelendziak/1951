# AppMetrica SDK Integration Guide

## Step 1: Add Dependencies

Add AppMetrica library to your app's `build.gradle`:

```gradle
dependencies {
    implementation("io.appmetrica.analytics:analytics:7.9.0")
}
```

## Step 2: Initialize AppMetrica

### Option A: Basic Initialization
```kotlin
class YourApplication : Application() {
    override fun onCreate() {
        super.onCreate()

        val config = AppMetricaConfig.newConfigBuilder(API_KEY).build()
        AppMetrica.activate(this, config)
    }
}
```

### Option B: With Firebase (Required for Push Notifications)
```kotlin
class YourApplication : Application() {
    override fun onCreate() {
        super.onCreate()

        // Initialize Firebase first (required for AppMetrica Push)
        FirebaseApp.initializeApp(this)

        val config = AppMetricaConfig.newConfigBuilder(API_KEY).build()
        AppMetrica.activate(this, config)
    }
}
```

## Step 3: Set User Profile ID

### Before Initialization (Recommended)
```kotlin
val config = AppMetricaConfig.newConfigBuilder(API_KEY)
    .withUserProfileID("user_id")
    .build()
AppMetrica.activate(this, config)
```

### After Initialization
```kotlin
AppMetrica.setUserProfileID("user_id")
```

⚠️ **Important:** Configure ProfileId to see predefined attributes in AppMetrica web interface.

## Step 4: Add Location Permission (Optional)

For city-level location tracking, add to `AndroidManifest.xml`:

```xml
<manifest>
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
    <application>...</application>
</manifest>
```

## Step 5: Register Application Class

Add to `AndroidManifest.xml`:

```xml
<application
    android:name=".YourApplication"
    ...>
</application>
```

## Verification

### Test Integration
1. Run app with internet connection
2. Use app for a few minutes
3. Check AppMetrica dashboard:
   - **Audience report**: New user appears
   - **Sessions report**: Session count increases
   - **Events report**: Events are recorded

### Debug Logs
Enable debug logging for troubleshooting:
```kotlin
val config = AppMetricaConfig.newConfigBuilder(API_KEY)
    .withLogs()
    .build()
```

## Common Configuration

### With Push Notifications
```kotlin
dependencies {
    implementation("io.appmetrica.analytics:analytics:7.9.0")
    implementation("io.appmetrica.analytics:push:3.0.0")
}
```

### Send Custom Events
```kotlin
AppMetrica.reportEvent("event_name")
AppMetrica.reportEvent("event_name", mapOf("key" to "value"))
```

### Send Revenue
```kotlin
val revenue = Revenue.newBuilder(price, currency)
    .withProductID("product_id")
    .build()
AppMetrica.reportRevenue(revenue)
```

### User Profiles
```kotlin
val profile = UserProfile.newBuilder()
    .apply(Attribute.name().withValue("John"))
    .apply(Attribute.customString("category").withValue("premium"))
    .build()
AppMetrica.reportUserProfile(profile)
```

## Testing Checklist
- [ ] SDK initialized in Application class
- [ ] Application class registered in manifest
- [ ] User profile ID configured
- [ ] Internet connectivity available
- [ ] Events appear in AppMetrica dashboard
- [ ] Sessions tracked correctly
- [ ] User appears in Audience report