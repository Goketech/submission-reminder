# Submission Reminder Application

A comprehensive shell script-based application for managing student submission reminders. This application allows educators to track student submissions and send automated reminders to students who haven't submitted their assignments.

## 🚀 Quick Start

### Prerequisites
- Linux/Unix environment or WSL on Windows
- Bash shell (version 4.0+)
- Basic Unix utilities: `grep`, `awk`, `sed`, `cut`

### Installation & Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Goketech/submission-reminder.git
   cd submission_reminder
   ```

2. **Make scripts executable:**
   ```bash
   chmod +x create_environment.sh copilot_shell_script.sh
   ```

3. **Create your application environment:**
   ```bash
   ./create_environment.sh
   ```
   - Enter your name when prompted
   - The script will create a directory named `submission_reminder_yourname`

4. **Test the application:**
   ```bash
   cd submission_reminder_yourname
   ./startup.sh
   ```

## 📁 Application Structure

After running `create_environment.sh`, you'll get this structure:

```
submission_reminder_yourname/
├── config/
│   └── config.env              # Application configuration
├── app/
│   ├── reminder.sh             # Reminder logic
├── modules/
│   └── functions.sh            # Utility functions
├── assets/
│   └── submissions.txt         # Student submission data
└── startup.sh                  # Main application entry point
```

## 🔧 Usage Guide

### Running the Main Application

```bash
cd submission_reminder_yourname
./startup.sh
```

The application provides an interactive menu with options to:
1. **Check submission status** - View all student submissions
2. **Run Reminder Application** - Reminders for assignments not submitted
3. **Submission Statistics** - Percentage of submissions