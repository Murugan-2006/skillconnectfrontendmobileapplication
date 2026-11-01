# SkillConnect Mobile App

SkillConnect is an emergency service marketplace app matching customers with nearby verified service providers.

## Key Features & Tech Stack
- **Live Location Tracking**: Built using **Leaflet + OpenStreetMap** (`flutter_map`) for 100% free, open-source real-time map rendering.
- **GPS Location Streaming**: Powered by `geolocator` and `Socket.io` real-time WebSocket communication.
- **Doorstep Verification**: QR Code & OTP validation using `mobile_scanner` and `qr_flutter`.
- **Backend API**: Node.js, Express, Socket.io, and MongoDB.

## Getting Started

1. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```

2. Run the application:
   ```bash
   flutter run
   ```
