# Google Maps Setup for Smart Waste Management App

## Getting Google Maps API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the following APIs:
   - Maps SDK for Android
   - Geocoding API
   - Places API (optional, for future features)
4. Go to "Credentials" and create an API Key
5. (Optional) Restrict the API key to Android apps with your package name

## Configure the App

1. Open `android/app/src/main/AndroidManifest.xml`
2. Find the line:
   ```xml
   android:value="YOUR_API_KEY_HERE"/>
   ```
3. Replace `YOUR_API_KEY_HERE` with your actual Google Maps API key

## Note for Development

For development and testing without a real API key:
- The app will still work but the map will show a "For development purposes only" watermark
- Location picking will still function
- You can use the app without adding a real API key for now

## Location Features

- **Current Location**: Uses device GPS to get your current location
- **Pick from Map**: Opens Google Maps to select a location by tapping
- **Draggable Marker**: Long press and drag the marker to adjust the location
- **Address Reverse Geocoding**: Automatically converts coordinates to human-readable address
