<h1 align="center">👁️‍🗨️ ShiftWatch</h1>

<p align="center">
  <b>AI-powered workplace monitoring & employee tracking application</b>
</p>

---

<div align="center">

<table>
  <tr>
    <!-- النص -->
    <td style="width: 60%; vertical-align: middle; text-align: right; padding: 20px;">
      <p>
        <strong>ShiftWatch</strong> is an intelligent application built with <b>Flutter</b> that helps organizations track employee attendance, manage workplaces, and analyze surveillance videos using artificial intelligence.
      </p>
      <p>
        The supervisor uploads a video of the workplace, and the system automatically analyzes attendance times, tracks movement within designated spaces, and calculates the actual work hours for each employee.
      </p>
    </td>
    <!-- الصورة -->
    <td style="width: 40%; text-align: center; vertical-align: middle; padding: 20px;">
      <img src="https://github.com/user-attachments/assets/bd9a3e9a-b4c8-4d9c-8f47-7e04a774e5c7" 
           alt="App Screenshot" width="250" style="border-radius: 12px; box-shadow: 0 4px 12px rgba(0,0,0,0.15);"/>
    </td>
  </tr>
</table>

</div>

---

## 🧠 Project Idea

The supervisor uploads a workplace surveillance video, and through AI analysis, the system:

- 📅 Accurately determines employee attendance times.  
- 🚶 Tracks whether an employee has left their assigned workspace.  
- ⏱ Calculates actual hours worked by each employee.  
- 📊 Displays insightful statistics and visual graphics.  

---

## 🚀 Key Features

- 🔐 User login & registration (**Firebase Authentication**)  
- 🎥 Upload & analyze surveillance videos  
- 📍 Polygon-based workspace setup  
- 👨‍🏭 Employee management with profile setup  
- 📊 Visual attendance analytics (dashboard with charts)  
- ☁️ Firebase Realtime Database & Azure Cloud Storage  
- 🛎 Real-time notifications via Firebase Messaging  
- 🖼 Draw & manage work zones manually  
- 🌍 Multilingual (English + Arabic)  
- ⚙️ Full profile management (email, password, etc.)  

---

## 🧭 App Flow

1. **Login & Register Screen**  
<p float="left">
  <img src="https://github.com/user-attachments/assets/7091af75-c07d-42e6-ab6e-42f26ecee4d0" width="250" />
  <img src="https://github.com/user-attachments/assets/968b0266-0cba-48fa-a2fc-2f546567d8aa" width="250" />
</p>

2. **Setup & Location Selection**  
<p float="left">
  <img src="https://github.com/user-attachments/assets/30251f26-4ddf-46b7-9177-c1b965fb4120" width="250" />
  <img src="https://github.com/user-attachments/assets/1aedd2c0-bec2-4dfe-a79d-8e1b2f60ac59" width="250" />
  <img src="https://github.com/user-attachments/assets/bd130a7e-8ed1-4650-ab53-ee98d85a0d23" width="250" />
</p>

3. **Drawing Workspaces**  
<p float="left">
  <img src="https://github.com/user-attachments/assets/c221e544-0f1b-4a41-8825-dae141bf0c18" width="250" />
  <img src="https://github.com/user-attachments/assets/798f851b-d588-416b-9730-a668abfa047e" width="250" />
</p>

4. **Employee Setup & Home Screen**  
<p float="left">
  <img src="https://github.com/user-attachments/assets/b03d65c3-f48b-4864-b0f3-c6a9293273a3" width="250" />
  <img src="https://github.com/user-attachments/assets/45b21ec4-bba8-4128-8842-4c57bd3aa3e0" width="250" />
  <img src="https://github.com/user-attachments/assets/0ba18d88-bc24-4602-80aa-e97ec2aa4c48" width="250" />
</p>

5. **Dashboard & Profile**  
<p float="left">
  <img src="https://github.com/user-attachments/assets/adc5bc7b-b0d1-4ae6-ab17-d2e6165b8cff" width="250" />
  <img src="https://github.com/user-attachments/assets/73ed0e8c-b14e-4f88-b321-6e55d1ceb001" width="250" />
  <img src="https://github.com/user-attachments/assets/53153f91-e4d1-40b2-a431-fbcf08a86482" width="250" />
</p>

6. **Notifications & Settings**  
<p float="left">
  <img src="https://github.com/user-attachments/assets/42e2156e-684e-4419-a5e9-2c2f99243334" width="250" />
  <img src="https://github.com/user-attachments/assets/d7d0cdd8-ef4c-4b51-833d-3b6027e94859" width="250" />
  <img src="https://github.com/user-attachments/assets/c3733ddd-e971-464c-b98a-709799657187" width="250" />
</p>

---

## 📁 Project Structure

```text
lib/
├── main.dart
├── models/                   # Data models
│   ├── app_notification.dart
│   └── locations.dart
├── screens/                  # App Screens
│   ├── splash_screen.dart
│   ├── login_screen.dart
│   ├── sign_up_screen.dart
│   ├── dashboard_screen.dart
│   ├── employee_setup_screen.dart
│   ├── location_screen.dart
│   ├── choose_location_screen.dart
│   ├── employee_screen.dart
│   ├── edit_profile_screen.dart
│   ├── profile_screen.dart
│   ├── notification_screen.dart
│   ├── location_detail_screen.dart
│   ├── setupScreen.dart
│   ├── num_of_location.dart
│   └── ...
├── user_panel/               # Profile & Settings
│   ├── change_password_screen.dart
│   ├── update_email_screen.dart
│   ├── setting_screen.dart
│   ├── privacy_policy_screen.dart
│   └── user_panel_screen.dart
├── widgets/                  # Reusable components
│   └── user_panel.dart

```

## How to Run the App

**Install Flutter** – Make sure you have Flutter SDK installed.
👉 Flutter Installation [Guide](https://docs.flutter.dev/get-started/install)

**Clone & Run the Repository**

git clone https://github.com/MahmoudAbogamihe/shiftwatch.git
cd shiftwatch
flutter pub get
flutter run
