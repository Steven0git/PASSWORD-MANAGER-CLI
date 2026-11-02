#!/bin/bash

# ==========================================
# SECURE PASSWORD MANAGER - ALL IN ONE SCRIPT
# (English Version)
# ==========================================

# Colors & ANSI Styling
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
MAGENTA='\033[1;35m'
NC='\033[0m' # No Color

# Banner / Header Function
print_banner() {
  clear
  echo -e "${CYAN}┌──────────────────────────────────────────────┐${NC}"
  echo -e "${CYAN}│${NC}          ${MAGENTA}🔐 SECURE PASSWORD MANAGER${NC}          ${CYAN}│${NC}"
  echo -e "${CYAN}└──────────────────────────────────────────────┘${NC}"
}

# 1. AUTOMATICALLY CREATE DATABASE FOLDER IF NOT EXISTS
if [ ! -d "database" ]; then
  print_banner
  echo -e "${YELLOW}[i] 'database' folder not found. Creating folder automatically...${NC}"
  mkdir -p database
  sleep 1
fi

# ==========================================
# DATABASE & SCHEMA INITIALIZATION FUNCTION
# ==========================================
init_database() {
  local db_path="$1"
  if [ ! -f "$db_path" ]; then
    echo -e "${GREEN}[+] Creating new database: $db_path${NC}"
    sqlite3 "$db_path" <<EOF
-- Main Password Manager Table
CREATE TABLE IF NOT EXISTS PasswordManager (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    username TEXT NOT NULL,
    password TEXT NOT NULL,
    description TEXT NOT NULL
);

-- Deletion Log Table
CREATE TABLE IF NOT EXISTS PasswordManagerLog (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    deleted_id INTEGER,
    name TEXT,
    username TEXT,
    password TEXT,
    description TEXT,
    deleted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Trigger to automatically log deleted records
CREATE TRIGGER IF NOT EXISTS LogDeletion
AFTER DELETE ON PasswordManager
BEGIN
    INSERT INTO PasswordManagerLog (deleted_id, name, username, password, description)
    VALUES (OLD.id, OLD.name, OLD.username, OLD.password, OLD.description);
END;

-- Configuration Table for PIN (PIN Mode only)
CREATE TABLE IF NOT EXISTS AppConfig (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL
);
EOF
    echo -e "${GREEN}[✔] Schema and Trigger successfully applied to $db_path${NC}\n"
    sleep 1.5
  fi
}

# ==========================================
# MAIN FUNCTIONS (CRUD, BACKUP, RESTORE)
# ==========================================
add_data() {
  print_banner
  echo -e "${GREEN}➕ ADD NEW ACCOUNT${NC}\n"

  echo -ne "${BLUE}Service/Web Name  :${GREEN} "
  read -r name
  echo -ne "${BLUE}Username/Email    :${GREEN} "
  read -r usr
  echo -e "\n${YELLOW}[INFO] Type 'gen' in the password field to auto-generate a strong password.${NC}"
  echo -ne "${BLUE}Password          :${GREEN} "
  read -r pass
  echo -e "${NC}"

  if [ "$pass" = "gen" ]; then
    pass=$(openssl rand -base64 12 | tr -d '/+=' | cut -c1-14)
    echo -e "${GREEN}✨ Auto-Generated Password: ${YELLOW}$pass${NC}"
  fi

  echo -ne "${BLUE}Description/Notes :${GREEN} "
  read -r desc

  if [ -z "$name" ] || [ -z "$usr" ] || [ -z "$pass" ] || [ -z "$desc" ]; then
    echo -e "\n${RED}[✖] Error: All fields are required!${NC}"
    return
  fi

  pass_len=${#pass}
  if [ $pass_len -lt 8 ]; then
    strength="${RED}Weak (Too Short)${NC}"
  elif [ $pass_len -ge 8 ] && [ $pass_len -lt 12 ]; then
    strength="${YELLOW}Medium${NC}"
  else
    strength="${GREEN}Strong 🛡️${NC}"
  fi

  name=${name//\'/\'\'}
  usr=${usr//\'/\'\'}
  pass=${pass//\'/\'\'}
  desc=${desc//\'/\'\'}

  echo -e "\n${CYAN}┌──────────────────────────────────────────────┐${NC}"
  echo -e "${CYAN}│                  DATA PREVIEW                │${NC}"
  echo -e "${CYAN}├──────────────────────────────────────────────┤${NC}"
  echo -e "  ${BLUE}Service     :${NC} $name"
  echo -e "  ${BLUE}Username    :${NC} $usr"
  echo -e "  ${BLUE}Password    :${NC} $pass"
  echo -e "  ${BLUE}Strength    :${NC} $strength"
  echo -e "  ${BLUE}Description :${NC} $desc"
  echo -e "${CYAN}└──────────────────────────────────────────────┘${NC}\n"

  echo -ne "${YELLOW}Save this data? [y/n]: ${NC}"
  read -r confirm
  echo -e "${NC}"

  if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
    sqlite3 "$1" "INSERT INTO PasswordManager (name, username, password, description) VALUES ('$name', '$usr', '$pass', '$desc');"
    echo -e "${GREEN}✔ Data successfully saved!${NC}"
  else
    echo -e "${YELLOW}✖ Save cancelled.${NC}"
  fi
}

delete_data() {
  print_banner
  echo -e "${RED}🗑️  DELETE ACCOUNT (Log Trigger Active)${NC}\n"
  
  echo -e "${BLUE}Current Accounts List:${NC}"
  sqlite3 -header -column "$1" "SELECT id, name, username FROM PasswordManager;"
  echo

  echo -ne "${YELLOW}Enter the ID of the data to delete: ${NC}"
  read -r id_del
  echo -e "${NC}"

  if [ -z "$id_del" ]; then
    echo -e "${RED}[✖] ID cannot be empty.${NC}"
    return
  fi

  echo -ne "${RED}Are you sure you want to delete data with ID $id_del? [y/n]: ${NC}"
  read -r confirm
  echo -e "${NC}"

  if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
    sqlite3 "$1" "DELETE FROM PasswordManager WHERE id = $id_del;"
    echo -e "${GREEN}✔ Data with ID $id_del successfully deleted (Log recorded automatically).${NC}"
  else
    echo -e "${YELLOW}✖ Deletion cancelled.${NC}"
  fi
}

edit_data() {
  print_banner
  echo -e "${YELLOW}✏️  EDIT ACCOUNT DATA${NC}\n"

  echo -e "${BLUE}Current Accounts List:${NC}"
  sqlite3 -header -column "$1" "SELECT id, name, username FROM PasswordManager;"
  echo

  echo -ne "${YELLOW}Enter the ID of the data to edit: ${NC}"
  read -r id_edit
  echo -e "${NC}"

  if [ -z "$id_edit" ]; then
    echo -e "${RED}[✖] ID cannot be empty.${NC}"
    return
  fi

  exists=$(sqlite3 "$1" "SELECT COUNT(*) FROM PasswordManager WHERE id = $id_edit;")
  if [ "$exists" -eq 0 ]; then
    echo -e "${RED}[✖] ID not found!${NC}"
    return
  fi

  echo -e "\n${CYAN}Enter new data (leave blank to keep unchanged):${NC}"
  echo -ne "${BLUE}New Name     :${GREEN} "
  read -r new_name
  echo -ne "${BLUE}New Username :${GREEN} "
  read -r new_usr
  echo -ne "${BLUE}New Password :${GREEN} "
  read -r new_pass
  echo -ne "${BLUE}New Desc     :${GREEN} "
  read -r new_desc
  echo -e "${NC}"

  if [ -n "$new_name" ]; then sqlite3 "$1" "UPDATE PasswordManager SET name='${new_name//\'/\'\'}' WHERE id=$id_edit;"; fi
  if [ -n "$new_usr" ]; then sqlite3 "$1" "UPDATE PasswordManager SET username='${new_usr//\'/\'\'}' WHERE id=$id_edit;"; fi
  if [ -n "$new_pass" ]; then sqlite3 "$1" "UPDATE PasswordManager SET password='${new_pass//\'/\'\'}' WHERE id=$id_edit;"; fi
  if [ -n "$new_desc" ]; then sqlite3 "$1" "UPDATE PasswordManager SET description='${new_desc//\'/\'\'}' WHERE id=$id_edit;"; fi

  echo -e "${GREEN}✔ Data successfully updated!${NC}"
}

search_data() {
  print_banner
  echo -e "${CYAN}🔍 SEARCH DATA${NC}\n"

  echo -ne "${BLUE}Enter keyword (name/username): ${NC}"
  read -r keyword
  echo -e "${NC}"

  if [ -z "$keyword" ]; then
    echo -e "${RED}[✖] Keyword cannot be empty.${NC}"
    return
  fi

  echo -e "\n${YELLOW}Search Results for '${CYAN}$keyword${NC}':${NC}\n"
  sqlite3 -header -column "$1" "SELECT id, name, username, password, description FROM PasswordManager WHERE name LIKE '%$keyword%' OR username LIKE '%$keyword%';"
  echo
}

show_all() {
  print_banner
  echo -e "${BLUE}📋 ALL ACCOUNTS LIST:${NC}\n"
  sqlite3 -header -column "$1" "SELECT * FROM PasswordManager;"
  echo
}

backup_db() {
  local db_path="$1"
  backup_name="database/backup_$(basename "$db_path" .db)_$(date +%Y%m%d_%H%M%S).db"
  cp "$db_path" "$backup_name"
  echo -e "\n${GREEN}✔ Successfully backed up database to: ${CYAN}$backup_name${NC}"
}

restore_db() {
  local current_db="$1"
  print_banner
  echo -e "${CYAN}♻️  RESTORE DATABASE${NC}\n"

  backups=(database/backup_*.db)

  if [ ! -e "${backups[0]}" ]; then
    echo -e "${RED}[✖] No backup files found in the database/ folder${NC}"
    return
  fi

  echo -e "${YELLOW}📂 Select the backup file to restore:${NC}\n"
  
  select b_file in "${backups[@]}" "Cancel"; do
    case $b_file in
      "Cancel")
        echo -e "${YELLOW}✖ Restore cancelled.${NC}"
        return
        ;;
      "")
        echo -e "${RED}[!] Invalid option.${NC}"
        ;;
      *)
        if [ ! -f "$b_file" ]; then
          echo -e "${RED}[✖] Invalid backup file!${NC}"
          return
        fi

        echo -e "\n${RED}⚠️ WARNING: Restoring will overwrite the active database ($current_db) with data from ($b_file)!${NC}"
        echo -ne "${YELLOW}Are you sure you want to proceed with restore? [y/n]: ${NC}"
        read -r confirm
        echo -e "${NC}"

        if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
          cp "$b_file" "$current_db"
          echo -e "${GREEN}✔ Successfully restored database from: ${CYAN}$b_file${NC}"
        else
          echo -e "${YELLOW}✖ Restore cancelled.${NC}"
        fi
        break
        ;;
    esac
  done
}

# ==========================================
# MAIN MENU (AFTER DATABASE IS SELECTED)
# ==========================================
run_manager() {
  local db="$1"
  while true; do
    print_banner
    echo -e "${GREEN}📁 Active Database:${NC} ${CYAN}$db${NC}\n"
    
    echo -e "${BLUE}⚡ MAIN MENU:${NC}"
    echo -e "  ${YELLOW}[1]${NC} Add Data (ADD)"
    echo -e "  ${YELLOW}[2]${NC} Delete Data (DELETE - Log Triggered)"
    echo -e "  ${YELLOW}[3]${NC} Edit Data (EDIT)"
    echo -e "  ${YELLOW}[4]${NC} Search Data (SEARCH)"
    echo -e "  ${YELLOW}[5]${NC} Show All (SHOW ALL)"
    echo -e "  ${YELLOW}[6]${NC} Backup Database (BACKUP)"
    echo -e "  ${YELLOW}[7]${NC} Restore Database (RESTORE)"
    echo -e "  ${YELLOW}[8]${NC} Change Mode/Database (BACK)"
    echo -e "  ${YELLOW}[9]${NC} Quit (EXIT)\n"
    
    echo -ne "${BLUE}👉 Select menu [1-9]: ${NC}"
    read -r menu_choice
    echo -e "${NC}"
    
    case $menu_choice in
      1)
        add_data "$db"
        read -p "Press [Enter] to continue..."
        ;;
      2)
        delete_data "$db"
        read -p "Press [Enter] to continue..."
        ;;
      3)
        edit_data "$db"
        read -p "Press [Enter] to continue..."
        ;;
      4)
        search_data "$db"
        read -p "Press [Enter] to continue..."
        ;;
      5)
        show_all "$db"
        read -p "Press [Enter] to continue..."
        ;;
      6)
        backup_db "$db"
        read -p "Press [Enter] to continue..."
        ;;
      7)
        restore_db "$db"
        read -p "Press [Enter] to continue..."
        ;;
      8)
        return
        ;;
      9)
        echo -e "\n${GREEN}👋 Thank you for using Password Manager!${NC}"
        exit 0
        ;;
      *)
        echo -e "${RED}[!] Invalid option.${NC}"
        sleep 1
        ;;
    esac
  done
}

# ==========================================
# STARTUP: SELECT ACCESS MODE (LIST / PIN)
# ==========================================
while true; do
  print_banner
  echo -e "${YELLOW}🔐 SELECT DATABASE ACCESS METHOD:${NC}\n"
  echo -e "  ${YELLOW}[1]${NC} List Mode (Use/Create 'Password_List.db')"
  echo -e "  ${YELLOW}[2]${NC} PIN Mode  (Use/Create 'Password_Pin.db')"
  echo -e "  ${YELLOW}[3]${NC} Exit (Exit)\n"

  echo -ne "${BLUE}👉 Select mode [1-3]: ${NC}"
  read -r mode_choice
  echo -e "${NC}"

  case $mode_choice in
    1)
      # --- LIST MODE ---
      db_target="database/Password_List.db"
      init_database "$db_target"
      run_manager "$db_target"
      ;;

    2)
      # --- PIN MODE ---
      db_target="database/Password_Pin.db"
      
      if [ ! -f "$db_target" ]; then
        print_banner
        echo -e "${CYAN}🔐 SETUP PIN FOR 'Password_Pin.db'${NC}\n"
        echo -ne "${BLUE}Create a new PIN for this database: ${NC}"
        read -s -r new_pin
        echo -e "${NC}"

        if [ -z "$new_pin" ]; then
          echo -e "${RED}[✖] PIN cannot be empty!${NC}"
          sleep 1.5
          continue
        fi
        init_database "$db_target"
        sqlite3 "$db_target" "INSERT INTO AppConfig (key, value) VALUES ('pin', '$new_pin');"
        echo -e "${GREEN}[✔] PIN successfully set!${NC}"
        sleep 1.5
      fi

      print_banner
      echo -e "${CYAN}🔐 LOGIN WITH SECURITY PIN${NC}\n"
      echo -ne "${BLUE}Enter PIN for 'Password_Pin.db': ${NC}"
      read -s -r input_pin
      echo -e "${NC}"

      saved_pin=$(sqlite3 "$db_target" "SELECT value FROM AppConfig WHERE key='pin';")

      if [ "$input_pin" = "$saved_pin" ]; then
        echo -e "${GREEN}[✔] Correct PIN! Opening database...${NC}"
        sleep 1
        run_manager "$db_target"
      else
        echo -e "${RED}[✖] Incorrect PIN! Access denied.${NC}"
        sleep 1.5
      fi
      ;;

    3)
      echo -e "\n${GREEN}👋 Thank you! See you later.${NC}"
      exit 0
      ;;

    *)
      echo -e "${RED}[!] Invalid option. Please enter a number between 1 and 3.${NC}"
      sleep 1.5
      ;;
  esac
done
