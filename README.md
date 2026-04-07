# KuryenteCheck

**KuryenteCheck** is a Crowd-Sourced Mobile App for Monitoring Electricity Outages and Voltage Fluctuations in Mangaldan, Pangasinan.

## Features

### For Residents

- **Report Outages**: Easily report issues like "Total Blackout", "Low Voltage", or "Flickering Lights".
- **Live Map**: View a real-time map of reported outages in your barangay (pinned to Mangaldan, Pangasinan).
- **Community Feed**: See what's happening in your area with a feed of recent reports.
- **Real-time Notifications**: Get notified instantly when your report is **Acknowledged** or **Resolved** by an admin.
- **Profile Management**: Track your submitted reports and toggle between English and Filipino languages.
- **Offline Reports**: Draft reports offline and sync them when you regain connection.

### For Admins

- **Command Center**: A dedicated dashboard to view all incoming reports.
- **Status Management**: Filter reports by status (Pending, Acknowledged, Resolved).
- **Status Report**: Acknowledge valid reports and mark them as resolved once fixed, automatically notifying the affected resident.

## Tech Stack

| Category             | Technology                                                                          | Details                                                         |
| :------------------- | :---------------------------------------------------------------------------------- | :-------------------------------------------------------------- |
| **Framework**        | [Flutter](https://flutter.dev) (Dart)                                               | Cross-platform UI toolkit                                       |
| **State Management** | [Riverpod](https://riverpod.dev)                                                    | State management and caching                                    |
| **Routing**          | [GoRouter](https://pub.dev/packages/go_router)                                      | Declarative routing package                                     |
| **Backend**          | [Firebase](https://firebase.google.com)                                             | Email/Password Auth & Cloud Firestore                           |
| **Maps**             | [flutter_map](https://pub.dev/packages/flutter_map)                                 | OpenStreetMap mapping implementation                            |
| **Notifications**    | [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications) | Instant cross-platform alerts                                   |
| **Data & Offline**   | Custom                                                                              | Local caching, Shared Preferences & sync queues                 |
| **Design**           | Theming                                                                             | "Dark Teal" (`#0F4C45`), Google Fonts, Cupertino & Lucide icons |


## Project Structure

The app follows a **strict layered architecture**:

```text
lib/
├── core/                  # App-wide utilities
│   ├── constants/         # App strings and configuration constants
│   ├── exceptions/        # Custom exception classes
│   ├── router/            # GoRouter configuration
│   └── utils/             # Helper utilities (error message formatting)
├── data/                  # Data layer
│   ├── models/            # Data definitions (BarangayData)
│   └── services/          # Backend and business logic (AuthService, ReportService...)
└── presentation/          # UI layer
    ├── providers/         # Riverpod controllers and state providers (ReportFormController...)
    ├── screens/           # All app screens (Login, Register, Feed, Map, Report...)
    └── widgets/           # Reusable UI components (AuthHeader, CustomTextField...)
```
