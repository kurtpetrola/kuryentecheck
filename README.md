# KuryenteCheck

**KuryenteCheck** is a Crowd-Sourced Mobile App for Monitoring Electricity Outages and Voltage Fluctuations in Mangaldan, Pangasinan.

## 📱 Features

### For Residents (Users)

- **Report Outages**: Easily report issues like "Total Blackout", "Low Voltage", or "Flickering Lights".
- **Live Map**: View a real-time map of reported outages in your barangay (pinned to Mangaldan, Pangasinan).
- **Community Feed**: See what's happening in your area with a feed of recent reports.
- **Real-time Notifications**: Get notified instantly when your report is **Acknowledged** or **Resolved** by an admin.
- **Profile Management**: Track your submitted reports and toggle between English and Filipino languages.

### For Admins (CENPELCO)

- **Command Center**: A dedicated dashboard to view all incoming reports.
- **Status Management**: Filter reports by status (Pending, Acknowledged, Resolved).
- **Actionable & Efficient**: Acknowledge valid reports and mark them as resolved once fixed, automatically notifying the affected resident.

## 🛠️ Technology Stack

- **Framework**: [Flutter](https://flutter.dev) (Dart)
- **State Management**: [Riverpod](https://riverpod.dev)
- **Routing**: [GoRouter](https://pub.dev/packages/go_router)
- **Backend**: [Firebase](https://firebase.google.com)
  - **Authentication**: Email/Password Sign-in & Registration.
  - **Cloud Firestore**: Real-time database for users and reports.
- **Maps**: [flutter_map](https://pub.dev/packages/flutter_map) (OpenStreetMap)
- **Notifications**: [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications)
- **Design**: Standardized "Dark Teal" theme (`#0F4C45`) with FontAwesome & Lucide icons.

## 🔐 Roles

- **Resident**: Standard users who can report outages and track their status. Register a new account via the app.
- **Admin**: Cooperative administrators who process reports.

## 📂 Project Structure

- `lib/features/`: Feature-based architecture (Auth, Report, Feed, Map, Admin).
- `lib/services/`: Core business logic (AuthService, ReportService, NotificationService).
- `lib/shared/`: Reusable widgets and router configuration.
