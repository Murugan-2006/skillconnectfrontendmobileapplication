# SkillConnect – Location-Based Local Service Marketplace

**SkillConnect** is a Flutter-based mobile application that connects customers with nearby local service providers such as electricians, plumbers, carpenters, painters, and appliance repair technicians. It simplifies the process of discovering, booking, and managing local services through a location-based service marketplace.

The application follows a **Rapido-like service allocation model**, where customers can either select a specific service provider or send a service request to nearby eligible providers. Requests can be allocated on a **First-Come, First-Served (FCFS)** basis, allowing available providers to accept service requests efficiently.

To ensure service authenticity and prevent unauthorized job completion, the application implements **QR Code-based customer verification**. After a booking is confirmed, a QR code is generated for the booking, which the service provider scans to verify the customer before starting or completing the service. The service provider dashboard also displays booking details and the corresponding service amount, helping providers manage their assigned jobs and earnings.

### Key Features
- **Location-Based Service Discovery:** Find nearby service providers based on customer location.
- **Dynamic Service Allocation:** Send requests to nearby providers or choose a specific provider.
- **FCFS Request Handling:** Allow eligible providers to accept requests on a first-come, first-served basis.
- **QR Code Verification:** Verify customers and validate service bookings through QR code scanning.
- **Service Provider Dashboard:** Display assigned bookings, customer details, and service amounts.
- **Booking Management:** Manage service requests and booking status.

### Technology Stack
- **Mobile Application:** Flutter (Dart)
- **Backend:** Node.js, Express.js
- **Database:** MongoDB
- **Location Services:** Google Maps API
- **Verification:** QR Code Generation and Scanning
