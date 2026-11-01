# SkillConnect — Practical MVP Specification

SkillConnect is a **Trust & Safety-First Local Service Marketplace** connecting customers with verified nearby service providers (electricians, plumbers, AC repair technicians, electronic repair specialists).

Instead of relying on unpredictable AI price predictions, SkillConnect focuses on **real-world feasibility, worker fairness, doorstep security, and emergency parallel dispatch**.

---

## 1. Core Platform Identity & Values

1. **Trust & Safety**: Verification at doorstep via QR Code & Dual OTP, transparent digital quotation approval, and safety reporting.
2. **Worker Fairness**: 🟢 Available / 🔴 Busy toggle, preferred worker repeat bookings, direct cash/UPI payment recording, and worker earnings dashboard.
3. **Emergency Parallel Dispatch**: Instant SOS broadcasting to top 3 nearest online workers where the first worker to accept locks the job.

---

## 2. Complete Feature Breakdown (14 Feasible Features)

### Feature 1: Worker Availability Toggle (🟢 Available / 🔴 Busy)
- Worker presses **Available** or **Busy** switch on their dashboard.
- Customers only see and request workers who are active and online.

### Feature 2: Instant Booking vs Scheduled Booking
- **Book Now**: Immediate request for urgent repairs.
- **Schedule Later**: Book a service for a specific date and time slot.

### Feature 3: Service Progress Tracking
- Status flow: `Accepted` ➔ `Worker Started` ➔ `Worker Reached` ➔ `Work In Progress` ➔ `Completed`.

### Feature 4: Emergency Parallel Dispatch ⭐ (Core Innovation)
- Customer triggers Emergency SOS.
- Nearest 3 available workers within 5 km receive instant parallel notification.
- First worker to press "Accept" claims the job; notifications to other workers automatically clear.

### Feature 5: Doorstep QR Verification
- When worker arrives at customer location, customer displays a time-sensitive QR code on their app.
- Worker scans QR code with mobile camera to officially verify arrival and start the service timer.

### Feature 6: Preferred & Favorite Workers
- Customers save trusted plumbers or electricians to their favorites.
- One-tap repeat booking for future maintenance.

### Feature 7: Worker Work Portfolio
- Workers upload photos of previous repair work and list certifications/experience.

### Feature 8: Digital Quotation Approval
- After inspecting the issue on site, worker enters line items (e.g. Capacitor: ₹300, Labor: ₹350 = Total ₹650).
- Customer receives an in-app pop-up to **Accept** or **Reject** the quotation before work begins.

### Feature 9: Dual OTP Verification & Payment Acknowledgement
- **1st OTP (Registration)**: Phone/Email OTP during registration to verify user identity.
- **2nd OTP (Completion)**: Once service is done, customer generates a 4-digit completion OTP. Worker inputs OTP into app to confirm customer satisfaction.
- **Payment Acknowledgement**: Upon OTP verification, worker enters amount received (Cash or UPI) for personal earnings dashboard tracking, and status marks **Completed**.

### Feature 10: Report Unsafe Behaviour & Cancellation Reason
- Both customers and workers can report harassment, abusive behavior, late arrival, or fake bookings.
- Instant alert dispatched to platform admin.

### Feature 11: Worker Earnings Dashboard
- Worker dashboard displays **Today's Earnings**, **Weekly Earnings**, **Completed Jobs Count**, and **Average Rating**.

### Feature 12: Real-time Live Map Tracking (Leaflet + OpenStreetMap)
- Open-source, 100% free mapping engine displaying worker en-route position live on map.

### Feature 13: Masked Communication Proxy
- In-app masked call/message simulation keeping customer and worker personal contact numbers private.

### Feature 14: Ratings & Reviews
- Post-service rating (1 to 5 stars) and feedback to maintain platform service quality.

---

## 3. Technology Stack

* **Frontend**: Flutter (Cross-platform Android / iOS / Web)
* **Maps & Navigation**: **Leaflet + OpenStreetMap** (`flutter_map` + `latlong2`) — *100% Free & Open Source*
* **Backend API**: Node.js, Express.js
* **Database**: MongoDB Atlas
* **Real-time Comms**: Socket.io WebSockets
* **Device GPS**: `geolocator` package
