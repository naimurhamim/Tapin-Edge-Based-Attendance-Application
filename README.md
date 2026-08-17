<div align="center">

<img src="assets/icon.png" width="120" />

<br/><br/>

<img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white"/>
<img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white"/>
<img src="https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white"/>
<img src="https://img.shields.io/badge/NodeMCU-Arduino-00979D?style=for-the-badge&logo=arduino&logoColor=white"/>
<img src="https://img.shields.io/badge/PostgreSQL-4169E1?style=for-the-badge&logo=postgresql&logoColor=white"/>
<img src="https://img.shields.io/badge/License-MIT-27ae60?style=for-the-badge"/>

<br/><br/>

```text
 _____          ___       
|_   _|_ _ _ __|_ _|_ __  
  | |/ _` | '_ \| || '_ \ 
  | | (_| | |_) | || | | |
  |_|\__,_| .__/___|_| |_|
          |_|             
```

<h1 align="center">🎓 TapIn — Smart Attendance System</h1>

<h3 align="center"><em>IoT-Integrated Real-Time University Attendance — Powered by Flutter + Supabase</em></h3>

<br/>

> **A seamless ecosystem that combines edge IoT hardware and a cross-platform mobile app**
> **to automatically and securely manage attendance using RFID and Geofenced QR Codes.**
> Replaces manual roll-calls with real-time syncing, intelligent analytics,
> and instant leave management.

<br/>

[![Made by](https://img.shields.io/badge/Made%20by-Naimur%20&%20Sourav-7d3c98?style=flat-square)](https://github.com/naimurhamim)
[![Year](https://img.shields.io/badge/Year-2026-7d3c98?style=flat-square)](#)
[![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)](#license)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20IoT-blue?style=flat-square)](#)

🔗 **Live Documentation & Overview:** [tapin.naimurrashid.dev](https://tapin.naimurrashid.dev)

</div>

---

## ✨ Features

| Feature | Description |
|---|---|
| 📡 **Dual Attendance Modes** | Students can tap an RFID card or scan a dynamic QR code. |
| 📍 **Geofence Security** | QR scanning is secured by GPS location and radius constraints. |
| 🧠 **Intelligent Grouping** | Auto-assigns Lab Groups (G1/G2) based on University ID. |
| 📊 **Real-time Analytics** | Teachers and Admins get live updates of present students. |
| 🚨 **Risk Warnings** | Visual alerts for students dropping below the 90% attendance mark. |
| 📝 **Leave Management** | In-app leave applications that auto-count as present if approved. |
| 📥 **Export Reports** | Generate and export class attendance sheets in PDF or Excel. |
| 🛡️ **Role-Based Access** | Secure routing for Students, Teachers, and Administrators. |
| ⚙️ **Edge Hardware Node** | NodeMCU setup with a 3-second cooldown to prevent double taps. |

---

## 🛠️ Tech Stack

| Component | Technology |
|---|---|
| Mobile App Framework | Flutter (Dart) |
| Backend Cloud | Supabase |
| Database | PostgreSQL |
| Serverless Logic | Supabase Edge Functions |
| IoT Hardware Node | NodeMCU ESP8266 |
| Sensor Module | RC522 (13.56 MHz RFID) |
| Location Services | geolocator (Geofencing) |
| QR Code Engine | qr_flutter, mobile_scanner |
| Reports Generation | pdf, printing, excel |

---

## 📁 Project Structure

```text
tapin_attendance/
│
├── 📁 android/                     # Android native project files
├── 📁 assets/
│   ├── 📁 icons/                   # App icons and logos
│   └── 📁 nodemcucode/             # C++ Arduino code for the NodeMCU hardware
│
├── 📁 docs/                        # Static website documentation & showcase
│   └── 📁 assets/
│       ├── CircuitDiagram.jpg      # Physical hardware circuit schema
│       └── 📁 screenshots/         # App interface screenshots
│
├── 📁 lib/                         # Main Flutter application code
│   ├── 📁 core/                    # Theme, constants, routing
│   ├── 📁 data/                    # Supabase repositories and models
│   └── 📁 presentation/            # UI screens (Admin, Teacher, Student)
│
├── 📁 supabase/
│   ├── 📁 functions/               # Edge Functions (e.g. mark-attendance)
│   └── 📁 migrations/              # Database SQL schemas and RLS policies
│
├── Project_Document.md             # In-depth technical documentation
└── pubspec.yaml                    # Dart dependencies
```

---

## 🔌 Hardware Setup (NodeMCU + RC522)

The physical IoT node reads 13.56 MHz RFID cards via SPI and sends a secure HTTP POST request directly to the Supabase Edge Function.

<div align="center">
  <img src="docs/assets/CircuitDiagram.jpg" alt="Hardware Circuit Diagram" width="550" />
</div>

<br/>

**Pin Connections:**

| RC522 Pin | NodeMCU Pin | Label |
|---|---|---|
| SDA (SS) | GPIO 15 | D8 |
| RST | GPIO 0 | D3 |
| MOSI | GPIO 13 | D7 |
| MISO | GPIO 12 | D6 |
| SCK | GPIO 14 | D5 |
| GND | GND | GND |
| 3.3V | 3.3V | 3V3 |

> **Source Code:** Find the Arduino `.ino` file in `assets/nodemcucode/nodemcucode.ino`

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (stable channel)
- Android Studio or VS Code
- A Supabase project with Edge Functions deployed

### 1. Clone the Repository
```bash
git clone https://github.com/naimurhamim/Tapin-Edge-Based-Attendance-Application.git
cd Tapin-Edge-Based-Attendance-Application
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Run the App
```bash
flutter run
```

### 4. Build Release APK
```bash
flutter build apk --release
```
*APK will be generated at: `build/app/outputs/flutter-apk/app-release.apk`*

---

## 📱 App Screens

<div align="center">

### Authentication
| Login | Student Register | Teacher Register |
|:---:|:---:|:---:|
| <img src="docs/assets/screenshots/authPage/login.jpg" width="250" /> | <img src="docs/assets/screenshots/authPage/student-register.jpg" width="250" /> | <img src="docs/assets/screenshots/authPage/teacher-register.jpg" width="250" /> |

### Teacher View
| Dashboard | Course Selection | Class Attendance |
|:---:|:---:|:---:|
| <img src="docs/assets/screenshots/TeacherPanel/teacher-dashboard.jpg" width="250" /> | <img src="docs/assets/screenshots/TeacherPanel/teacher-course-selection.jpg" width="250" /> | <img src="docs/assets/screenshots/TeacherPanel/teacher-class-attendance.jpg" width="250" /> |
| **Manual Attendance** | **QR Attendance** | **Student Analytics** |
| <img src="docs/assets/screenshots/TeacherPanel/teacher-manual-attendance.jpg" width="250" /> | <img src="docs/assets/screenshots/TeacherPanel/teacher-qr-attendance.jpg" width="250" /> | <img src="docs/assets/screenshots/TeacherPanel/teacher-student-analytics.jpg" width="250" /> |
| **Export Reports** | **Teacher Students** | **Teacher Profile** |
| <img src="docs/assets/screenshots/TeacherPanel/teacher-attendance-report.jpg" width="250" /> | <img src="docs/assets/screenshots/TeacherPanel/teacher-students.jpg" width="250" /> | <img src="docs/assets/screenshots/TeacherPanel/teacher-profile.jpg" width="250" /> |

### Student View
| Dashboard | Attendance | History |
|:---:|:---:|:---:|
| <img src="docs/assets/screenshots/StudentPanel/student-dashboard.jpg" width="250" /> | <img src="docs/assets/screenshots/StudentPanel/student-attendance.jpg" width="250" /> | <img src="docs/assets/screenshots/StudentPanel/student-history.jpg" width="250" /> |
| **Leave Management** | **Profile** | |
| <img src="docs/assets/screenshots/StudentPanel/student-leave.jpg" width="250" /> | <img src="docs/assets/screenshots/StudentPanel/student-profile.jpg" width="250" /> | |

### Admin View
| Dashboard | Geofencing | Student Details |
|:---:|:---:|:---:|
| <img src="docs/assets/screenshots/AdminPanel/admin-dashboard.jpg" width="250" /> | <img src="docs/assets/screenshots/AdminPanel/admin-geofence.jpg" width="250" /> | <img src="docs/assets/screenshots/AdminPanel/admin-student-details.jpg" width="250" /> |
| **All Students** | **Unassigned Scans** | **Add Schedule** |
| <img src="docs/assets/screenshots/AdminPanel/admin-students.jpg" width="250" /> | <img src="docs/assets/screenshots/AdminPanel/admin-unassigned-scans.jpg" width="250" /> | <img src="docs/assets/screenshots/AdminPanel/admin-add-schedule.jpg" width="250" /> |
| **View Schedules** | **Admin Profile** | |
| <img src="docs/assets/screenshots/AdminPanel/admin-schedule.jpg" width="250" /> | <img src="docs/assets/screenshots/AdminPanel/admin-profile.jpg" width="250" /> | |

</div>

---

## 📄 License

Licensed under the **MIT License** — see [LICENSE](LICENSE) for details.

---

<div align="center">

## 👨‍💻 Authors & Contributors

| 👨‍💻 **Author** | 🤝 **Contributor** |
|:---:|:---:|
| <img src="docs/assets/presenters/Naimur_Rashid.jpg" width="120" style="border-radius: 50%;" /> | <img src="docs/assets/presenters/Sourav_Chakraborty.png" width="120" style="border-radius: 50%;" /> |
| **MD Naimur Rashid** | **Sourav Chakraborty** |
| *Department of IoT and Robotics Engineering*<br/>*University of Frontier Technology* | *Department of IoT and Robotics Engineering*<br/>*University of Frontier Technology* |
| [![Website](https://img.shields.io/badge/Website-naimurrashid.dev-2563EB?style=flat-square&logo=globe&logoColor=white)](https://naimurrashid.dev/) [![GitHub](https://img.shields.io/badge/GitHub-naimurhamim-181717?style=flat-square&logo=github&logoColor=white)](https://github.com/naimurhamim) | |

<br/>

⭐ **If you found this project helpful, please give it a star!** ⭐

</div>
