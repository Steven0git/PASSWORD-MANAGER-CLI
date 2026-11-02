# 🔐 Secure Password Manager (CLI)

A lightweight, feature-rich, and interactive **Command-Line Interface (CLI) Password Manager** written entirely in Bash and powered by SQLite3. It features modern ANSI styling, automated database and schema creation, deletion audit logs, password generation, strength checking, backup/restore, and dual access modes (List Mode and PIN-protected Mode).

---

## ✨ Key Features

- **📂 Dual Access Modes:**
  - **List Mode:** Directly accesses or creates `Password_List.db`.
  - **PIN Mode:** Secures access using a custom PIN stored securely inside `Password_Pin.db`.
- **🚀 Auto-Initialization:** Automatically creates the `database/` folder and required SQLite databases, tables, and triggers if they don't exist.
- **⚡ Smart Password Generator:** Type `gen` during password creation to instantly generate a secure, random 14-character password.
- **🛡️ Password Strength Meter:** Evaluates password complexity (Weak, Medium, Strong) in real-time.
- **📋 Full CRUD Operations:**
  - **Add (INSERT):** Add new services, usernames, and passwords with automated data escaping.
  - **Delete (DELETE):** Remove entries safely with automatic audit logging.
  - **Edit (UPDATE):** Modify existing entries selectively.
  - **Search (SEARCH):** Quickly look up credentials by name or username (displays passwords clearly).
  - **Show All:** View all stored accounts in a clean columnized format.
- **🔄 Backup & Restore:**
  - **Backup:** Create timestamped database backups (`backup_*.db`) instantly.
  - **Restore:** Select and restore from any previous backup file with confirmation checks.
- **📝 Audit Logging Trigger:** Built-in SQLite trigger (`LogDeletion`) that automatically logs deleted records into a separate `PasswordManagerLog` table.

---

## 🛠️ Prerequisites

Before running the script, ensure your system has the following tools installed:
- **Bash** (v4+)
- **SQLite3**
- **OpenSSL** (required for the auto-password generator)

To install them on Debian/Ubuntu/Termux:
```bash
sudo apt update && sudo apt install bash sqlite3 openssl

📦 Installation & Setup
 * Save the main script as manager.sh in your project directory.
 * Grant execution permissions to the script:
   chmod +x manager.sh

 * Run the script:
   ./manager.sh

🚀 How to Use
When you launch ./manager.sh, you will be greeted by the startup menu offering two primary access methods:
┌──────────────────────────────────────────────┐
│          🔐 SECURE PASSWORD MANAGER          │
└──────────────────────────────────────────────┘

🔐 SELECT DATABASE ACCESS METHOD:

  [1] List Mode (Use/Create 'Password_List.db')
  [2] PIN Mode  (Use/Create 'Password_Pin.db')
  [3] Exit (Exit)

1. List Mode
 * Uses or creates database/Password_List.db.
 * Directly opens the Main Menu without requiring a password or PIN.
2. PIN Mode
 * Uses or creates database/Password_Pin.db.
 * If launched for the first time, it will prompt you to set a security PIN.
 * Subsequent launches will require you to enter the correct PIN to unlock the database.
⚡ Main Menu Options
Once inside a database, you will have access to the following operations:
📁 Active Database: database/Password_List.db

⚡ MAIN MENU:
  [1] Add Data (ADD)
  [2] Delete Data (DELETE - Log Triggered)
  [3] Edit Data (EDIT)
  [4] Search Data (SEARCH)
  [5] Show All (SHOW ALL)
  [6] Backup Database (BACKUP)
  [7] Restore Database (RESTORE)
  [8] Change Mode/Database (BACK)
  [9] Quit (EXIT)

 * [1] Add Data: Input service name, username, description, and password (type gen for an automatic strong password).
 * [2] Delete Data: View records and delete by ID. Automatically records the deletion to the PasswordManagerLog table.
 * [3] Edit Data: Update individual fields of an existing record by providing its ID and leaving unchanged fields blank.
 * [4] Search Data: Search records by keyword (service name or username) and view matching passwords.
 * [5] Show All: Display all stored accounts.
 * [6] Backup: Generates a safe copy of the active database with a timestamp suffix (backup_name_YYYYMMDD_HHMMSS.db).
 * [7] Restore: Overwrites the active database with a selected backup file.
 * [8] Back: Returns to the initial mode selection screen.
 * [9] Exit: Closes the application.
🗄️ Database Schema Structure
The script automatically provisions the following structure:
 * PasswordManager: Main table storing id, name, username, password, and description.
 * PasswordManagerLog: Audit log table storing deleted row data and deletion timestamps.
 * LogDeletion: SQLite AFTER DELETE trigger handling automatic archival of deleted entries.
 * AppConfig: Key-value store table managing security configurations (like PIN hashes/values) for PIN Mode. 