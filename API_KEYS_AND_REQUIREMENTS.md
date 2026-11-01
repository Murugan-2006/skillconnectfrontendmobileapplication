# SkillConnect — Complete API Keys & Third-Party Requirements Guide

This document lists **all required third-party APIs, SDK keys, credentials, and environment variables** needed to build the **Practical MVP Feature Set** for SkillConnect (Customer + Worker App).

---

## Summary of Required Third-Party Services

| Service Category | Recommended Provider | Purpose | Free Tier Available? | Mandatory / Optional |
| :--- | :--- | :--- | :--- | :--- |
| **Maps & Location** | **Leaflet + OpenStreetMap** | Displaying nearby workers, map routes, live tracking | Yes (100% Free, Open-Source) | **Mandatory** |
| **Push Notifications** | **Firebase Cloud Messaging (FCM)** | Instant alerts for Emergency SOS, booking updates | Yes (100% Free, Unlimited) | **Mandatory** |
| **Media Storage** | **Cloudinary** | Storing worker portfolios, certificates, profile photos | Yes (25 GB free storage) | **Mandatory** |
| **SMS / OTP** | **Twilio** or **Firebase Auth** | Doorstep OTP verification & phone login | Free Trial Credits ($15) | **Optional** (Can use In-App OTP or Email OTP for zero cost) |
| **Email Service** | **Gmail SMTP / Nodemailer** | Invoices, digital quotes, admin alerts | Yes (Free using Gmail App Password) | **Mandatory** |
| **Payments / Quotes** | **Razorpay** / **Stripe** | In-app digital quotation payments | Free in Test Mode (0 setup cost) | **Optional** (Can also use Cash / Direct UPI QR) |

---

## 1. Feature-by-Feature API Mapping

### Feature 1: Worker Availability Toggle (🟢 Available / 🔴 Busy)
* **API / Service Needed**: **None (Backend Database + Socket.io)**
* **Details**: Worker updates status in MongoDB/Database via Socket.io/REST API. No paid third-party key required.

### Feature 2: Instant Booking vs Scheduled Booking
* **API / Service Needed**: **None (Backend Logic)**
* **Details**: Backend filters workers by availability schedule and handles instant vs scheduled queues.

### Feature 3: Service Progress Tracking
* **API / Service Needed**: **Firebase Cloud Messaging (FCM) & Socket.io**
* **Details**: Real-time status pushes (`Accepted` ➔ `Worker Started` ➔ `Reached` ➔ `Work In Progress` ➔ `Completed`).

### Feature 4: Emergency Parallel SOS Booking ⭐
* **API / Service Needed**: **Haversine Distance Formula (Local Math) + Socket.io & Firebase Cloud Messaging (FCM)**
* **Details**: Finds top 3 nearest available workers within 5 km radius using latitude/longitude math and sends parallel high-priority WebSocket/FCM notifications. First worker to press "Accept" locks the job.

### Feature 5: Doorstep Verification (QR + OTP)
* **API / Service Needed**: **Flutter Local Libraries (`mobile_scanner`, `qr_flutter`) + Twilio SMS / In-App OTP**
* **Details**: App generates QR/OTP locally on customer device; worker scans QR using mobile camera. No expensive AI or facial recognition needed.

### Feature 6: Preferred / Favorite Worker & History
* **API / Service Needed**: **Backend Database (MongoDB / PostgreSQL)**
* **Details**: Customer saves preferred workers in user profile.

### Feature 7: Worker Portfolio (Photos & Experience)
* **API / Service Needed**: **Cloudinary API Key & Secret**
* **Details**: Worker uploads work photos/certificates from Flutter app directly to Cloudinary.

### Feature 8: Digital Quotation Approval
* **API / Service Needed**: **Backend API + Optional Razorpay/Stripe Key**
* **Details**: Worker enters breakdown (e.g. Capacitor: ₹300, Labor: ₹350 = Total ₹650). Customer gets pop-up: `[Accept]` or `[Reject]`.

### Feature 9: Report Unsafe Behaviour & Cancellation Analytics
* **API / Service Needed**: **Backend Database + SMTP (Nodemailer)**
* **Details**: Sends instant email alert to platform admin when safety threshold is triggered.

---

## 2. Complete Environment Configuration File (`backend/.env`)

Copy this structure into your `backend/.env` file:

```env
# ==========================================
# SERVER & DATABASE CONFIGURATION
# ==========================================
PORT=5000
NODE_ENV=development
MONGO_URI=mongodb+srv://<username>:<password>@cluster0.mongodb.net/skillconnect?retryWrites=true&w=majority
JWT_SECRET=your_super_secret_jwt_key_here

# ==========================================
# 1. EMAIL SERVICE (Nodemailer / SMTP)
# ==========================================
# Used for OTPs, Digital Quotation Emails, Admin Safety Alerts
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your_email@gmail.com
SMTP_PASS=your_gmail_app_password
EMAIL_FROM="SkillConnect Support <your_email@gmail.com>"

# ==========================================
# 2. MEDIA STORAGE (Cloudinary)
# ==========================================
# Used for Worker Portfolio, Work Photos, Profile Avatars, Verification Docs
CLOUDINARY_NAME=your_cloudinary_cloud_name
CLOUDINARY_API_KEY=your_cloudinary_api_key
CLOUDINARY_SECRET_KEY=your_cloudinary_api_secret

# ==========================================
# 3. SMS & OTP (Twilio)
# ==========================================
# Used for Doorstep OTP & Emergency SMS Notifications
TWILIO_ACCOUNT_SID=your_twilio_account_sid
TWILIO_AUTH_TOKEN=your_twilio_auth_token
TWILIO_PHONE_NUMBER=+1xxxxxxxxxx

# ==========================================
# 4. PUSH NOTIFICATIONS (Firebase Admin SDK)
# ==========================================
# Used for Emergency SOS Parallel Broadcast & Status Updates
FIREBASE_PROJECT_ID=your_firebase_project_id
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxx@your_project.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nYOUR_KEY_HERE\n-----END PRIVATE KEY-----\n"

# ==========================================
# 5. GOOGLE MAPS API (Backend Server Keys)
# ==========================================
# Used for distance calculation and reverse geocoding
GOOGLE_MAPS_SERVER_API_KEY=AIzaSy...

# ==========================================
# 6. PAYMENTS (Razorpay / Stripe - Optional)
# ==========================================
RAZORPAY_KEY_ID=rzp_test_your_key_id
RAZORPAY_KEY_SECRET=your_razorpay_secret
```

---

## 3. Flutter Frontend Configuration Keys

### A. Android Configuration (`android/app/src/main/AndroidManifest.xml`)
Required for Google Maps rendering and GPS location:

```xml
<manifest ...>
    <!-- Permissions for Emergency SOS & Live Worker Tracking -->
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.CAMERA" /> <!-- For QR Scanner -->

    <application ...>
        <!-- Google Maps API Key -->
        <meta-data
            android:name="com.google.android.geo.API_KEY"
            android:value="YOUR_ANDROID_GOOGLE_MAPS_API_KEY_HERE"/>
    </application>
</manifest>
```

### B. iOS Configuration (`ios/Runner/Info.plist`)

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>SkillConnect needs your location to find nearby available workers and send emergency SOS requests.</string>
<key>NSCameraUsageDescription</key>
<string>SkillConnect needs camera access to scan worker doorstep verification QR codes.</string>
```

---

## 4. Where to Get Free Keys Step-by-Step

1. **Google Maps API Key**:
   - Go to [Google Cloud Console](https://console.cloud.google.com/).
   - Enable **Maps SDK for Android**, **Maps SDK for iOS**, and **Geocoding API**.
   - Create API Key & add Android package restriction (`com.example.skillconnect`).

2. **Firebase Push Notifications (FCM)**:
   - Go to [Firebase Console](https://console.firebase.google.com/).
   - Add Android App & download `google-services.json` to `android/app/`.
   - Go to **Project Settings > Service Accounts** and generate a Node.js Private Key JSON for your backend.

3. **Cloudinary (Portfolio Storage)**:
   - Create a free account at [Cloudinary](https://cloudinary.com/).
   - Copy **Cloud Name**, **API Key**, and **API Secret** from Dashboard.

4. **Gmail App Password (Email & Free OTP)**:
   - Go to Google Account > Security > Enable 2-Factor Authentication.
   - Search **App Passwords** > Generate a 16-character password for "Nodemailer".

---

## 5. Cost Breakdown for Final Year Project (PBL)

| Resource | Expected Cost |
| :--- | :--- |
| Google Maps SDK | **₹0** (Stays well within $200 free monthly credit) |
| Firebase Cloud Messaging | **₹0** (100% free) |
| Cloudinary Storage | **₹0** (Free tier 25GB) |
| Gmail SMTP (Email/OTP) | **₹0** (Free) |
| Razorpay Test Mode | **₹0** (Free simulation mode) |
| **Total Cost** | **₹0 (Zero Cost)** |
