# Snap Attend Enterprise - B2B AI Attendance System

A modern, dual-service web application designed for enterprise environments to track employee attendance using advanced AI Face Recognition and Voice Biometrics. 

This project consists of:
1. **Flask Landing Page (Port 5002)**: A lightweight, fast marketing and gateway portal.
2. **Streamlit AI Portal (Port 8501)**: A heavy-duty, state-of-the-art AI dashboard for Company Admins and Employees.

## 🚀 Features
- **Company Dashboards**: Manage projects, view attendance logs, and explicitly register new employees with custom Employee Codes.
- **Project Scoping**: AI scans are intelligently scoped to only scan for employees assigned to the selected project meeting.
- **Dual Biometrics**: Primary attendance through FaceID (`dlib`/`face_recognition`) and secondary/fallback attendance via Voice Verification (`resemblyzer`).
- **B2B Architecture**: Strict separation of data by `company_invite_code`.

## 🛠️ Prerequisites
- **Python 3.12** (Important: AI dependencies are highly sensitive to Python versions)
- **Visual Studio C++ Build Tools** (Required for compiling `dlib` and running `torch`)
- **CMake** (Required to build C++ backends for `dlib`)

## 📦 Installation & Setup

1. **Clone the repository and open the directory**
```powershell
cd app
```

2. **Create a Virtual Environment (Recommended)**
```powershell
python -m venv venv
.\venv\Scripts\activate
```

3. **Install standard dependencies**
```powershell
pip install -r requirements.txt
```

4. **Install dlib (Windows Specific)**
If `pip install dlib` fails due to C++ compilation issues on Windows, you can download a pre-compiled `.whl` file for Python 3.12 (e.g., from Z-Mahmud/dlib-wheels) and install it directly:
```powershell
pip install dlib-19.24.99-cp312-cp312-win_amd64.whl
```

5. **Initialize the Database**
If this is your first time running the app, or you need to wipe the data:
```powershell
python src/database/init_db.py
```

## 🎯 How to Run
We use a unified PowerShell script to boot both the Flask and Streamlit services simultaneously and handle background routing.

Run the following command from the `app` directory:
```powershell
.\start.ps1
```

Once the script executes, your browser will be served the following:
- **Landing Page**: `http://127.0.0.1:5002`
- **Enterprise Portal**: `http://localhost:8501`

*(Note: To stop the servers, just close the powershell window or hit `CTRL+C` in the terminal).*

## 👥 Usage Workflow
1. **Company Onboarding:** Go to the Enterprise Portal, click "Register Instead" and create a company account. Note your **Company Invite Code**.
2. **Create a Project:** In the Company Dashboard, navigate to the **Manage Projects** tab and create a new project.
3. **Register Employees:** You can register employees directly via the **Manage Employees** tab, OR employees can register themselves by going to the Employee Portal, clicking the **Register New Profile** tab, scanning their face, and entering your Invite Code.
4. **Take Attendance:** As the Admin, go to **Take AI Attendance**, select the project, upload meeting photos, and let the AI automatically identify who is present!
