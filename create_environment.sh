#!/bin/bash

# create_environment.sh - Setup script for submission reminder application
# This script creates the directory structure and populates files for the submission reminder app

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to create directory structure
create_directories() {
    local base_dir=$1
    
    print_status "Creating directory structure..."
    
    # Create main directories
    mkdir -p "$base_dir"/{config,modules,assets,app}
    
    print_status "Directory structure created successfully!"
}

# Function to create config.env file
create_config_env() {
    local config_dir=$1
    
    print_status "Creating config.env file..."
    
    cat > "$config_dir/config.env" << 'EOF'
# This is the config file
ASSIGNMENT="Shell Navigation"
DAYS_REMAINING=2

EOF
    
    print_status "config.env created successfully!"
}

# Function to create reminder.sh file
create_reminder_sh() {
    local scripts_dir=$1
    
    print_status "Creating reminder.sh file..."
    
    cat > "$scripts_dir/reminder.sh" << 'EOF'
#!/bin/bash

# Source environment variables and helper functions
source ./config/config.env
source ./modules/functions.sh

# Path to the submissions file
submissions_file="./assets/submissions.txt"

# Print remaining time and run the reminder function
echo "Assignment: $ASSIGNMENT"
echo "Days remaining to submit: $DAYS_REMAINING days"
echo "--------------------------------------------"

check_submissions $submissions_file

EOF
    
    chmod +x "$scripts_dir/reminder.sh"
    print_status "reminder.sh created and made executable!"
}

# Function to create functions.sh file
create_functions_sh() {
    local scripts_dir=$1
    
    print_status "Creating functions.sh file..."
    
    cat > "$scripts_dir/functions.sh" << 'EOF'
#!/bin/bash

# Function to read submissions file and output students who have not submitted
function check_submissions {
    local submissions_file=$1
    echo "Checking submissions in $submissions_file"

    # Skip the header and iterate through the lines
    while IFS=, read -r student assignment status; do
        # Remove leading and trailing whitespace
        student=$(echo "$student" | xargs)
        assignment=$(echo "$assignment" | xargs)
        status=$(echo "$status" | xargs)

        # Check if assignment matches and status is 'not submitted'
        if [[ "$assignment" == "$ASSIGNMENT" && "$status" == "not submitted" ]]; then
            echo "Reminder: $student has not submitted the $ASSIGNMENT assignment!"
        fi
    done < <(tail -n +2 "$submissions_file") # Skip the header
}

EOF
    
    chmod +x "$scripts_dir/functions.sh"
    print_status "functions.sh created and made executable!"
}

# Function to create submissions.txt file with sample data
create_submissions_txt() {
    local data_dir=$1
    
    print_status "Creating submissions.txt with sample data..."
    
    cat > "$data_dir/submissions.txt" << 'EOF'
student, assignment, submission status
Chinemerem, Shell Navigation, not submitted
Chiagoziem, Git, submitted
Divine, Shell Navigation, not submitted
Anissa, Shell Basics, submitted
Goke, Shell Basics, submitted
Gideon, Shell Basics, not submitted
Annie, Shell Basics, late submission
David, Shell Basics, submitted
Mercy, Shell Basics, not submitted
Hassana, Shell Basics, late submission
EOF
    
    print_status "submissions.txt created with 15 student records!"
}

# Function to create startup.sh file
create_startup_sh() {
    local scripts_dir=$1
    
    print_status "Creating startup.sh file..."
    
    cat > "$scripts_dir/startup.sh" << 'EOF'
#!/bin/bash

# startup.sh - Main startup script for the submission reminder application
# This script initializes and runs the submission reminder app

# Source configuration and functions
source "config/config.env"
source "modules/functions.sh"


# Main application logic
main() {
    echo "╔════════════════════════════════════════╗"
    echo "║        SUBMISSION REMINDER APP         ║"
    echo "║            Version 1.0                 ║"
    echo "╚════════════════════════════════════════╝"
    echo
    
    echo "🎓 Welcome to the Submission Reminder Application!"
    echo "Current Assignment: $ASSIGNMENT"
    echo
    
    # Check if data file exists
    DATA_FILE="assets/submissions.txt"
    if [[ ! -f "$DATA_FILE" ]]; then
        echo "❌ Error: Data file not found at $DATA_FILE"
        log_message "ERROR: Data file not found at $DATA_FILE"
        exit 1
    fi
    
    # Display menu
    while true; do
        echo "════════════════════════════════════════"
        echo "Choose an option:"
        echo "1) Check submission status"
        echo "2) Send reminders to non-submitters"
        echo "3) View submission statistics"
        echo "4) Exit"
        echo "════════════════════════════════════════"
        
        read -p "Enter your choice (1-4): " choice
        
        case $choice in
            1)
                echo
                echo "📊 SUBMISSION STATUS REPORT"
                echo "Assignment: $ASSIGNMENT"
                echo "═══════════════════════════════════════════════════════════════════════"
                
                # Display all student statuses
                while IFS=',' read -r name assignment status; do
                    if [[ "$name" == "student" ]]; then
                        printf "%-10s %-20s %-30s %-15s %s\n" "Name" "Assignment" "Status"
                        echo "───────────────────────────────────────────────────────────────────────"
                        continue
                    fi
                    
                    # Color code status
                    case "$status" in
                        " submitted")
                            status_display="✅ $status"
                            ;;
                        " not submitted")
                            status_display="❌ $status"
                            ;;
                        " late submission")
                            status_display="⚠️ $status"
                            ;;
                        *)
                            status_display="❓ $status"
                            ;;
                    esac
                    
                    printf "%-10s %-20s %-30s %-15s %s\n" "$name" "$assignment" "$status_display"
                done < "$DATA_FILE"
                echo
                ;;
            2)
                echo
                app/reminder.sh
                echo
                ;;
            3)
                echo
                echo "📈 STATISTICS SUMMARY"
                echo "Assignment: $ASSIGNMENT"
                echo "═══════════════════════════════════════"

                # Function to get student count by status
                get_count_by_status() {
                    local status="$1"
                    local data_file="$2"
                    
                    grep -c ",$status" "$data_file" 2>/dev/null || echo "0"
                }
                
                local total=$(tail -n +2 "$DATA_FILE" | wc -l)
                local submitted=$(get_count_by_status " submitted" "$DATA_FILE")
                local not_submitted=$(get_count_by_status " not submitted" "$DATA_FILE")
                local late=$(get_count_by_status " late submission" "$DATA_FILE")
                
                echo "Total Students: $total"
                echo "✅ Submitted: $submitted"
                echo "❌ Not Submitted: $not_submitted"
                echo "⚠️ Late Submissions: $late"
                
                if [[ $total -gt 0 ]]; then
                    local percentage=$(( (submitted * 100) / total ))
                    echo "📊 Submission Rate: $percentage%"
                fi
                echo
                ;;
            4)
                echo "👋 Thank you for using the Submission Reminder App!"
                exit 0
                ;;
            *)
                echo "❌ Invalid choice. Please select 1-4."
                echo
                ;;
        esac
    done
}

# Run main function
main "$@"
EOF
    
    chmod +x "$scripts_dir/startup.sh"
    print_status "startup.sh created and made executable!"
}

# Function to update file permissions
update_permissions() {
    local base_dir=$1
    
    print_status "Updating permissions for .sh files..."
    
    # Find all .sh files and make them executable
    find "$base_dir" -name "*.sh" -type f -exec chmod +x {} \;
    
    print_status "All .sh files are now executable!"
}

# Main script execution
main() {
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║              SUBMISSION REMINDER APP SETUP                  ║"
    echo "║                    Environment Creator                       ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo
    
    # Prompt for user name
    while true; do
        read -p "🔹 Enter your name for the directory: " user_name
        
        # Validate input
        if [[ -z "$user_name" ]]; then
            print_warning "Name cannot be empty. Please try again."
            continue
        fi
        
        # Remove spaces and special characters, convert to lowercase
        user_name=$(echo "$user_name" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-zA-Z0-9]/_/g')
        break
    done
    
    # Create base directory name
    base_dir="submission_reminder_${user_name}"
    
    # Check if directory already exists
    if [[ -d "$base_dir" ]]; then
        print_warning "Directory '$base_dir' already exists!"
        read -p "Do you want to remove it and recreate? (y/N): " confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            rm -rf "$base_dir"
            print_status "Existing directory removed."
        else
            print_error "Setup cancelled."
            exit 1
        fi
    fi
    
    print_status "Creating application environment: $base_dir"
    echo
    
    # Create directory structure
    create_directories "$base_dir"
    
    # Create all required files
    create_config_env "$base_dir/config"
    create_functions_sh "$base_dir/modules"
    create_reminder_sh "$base_dir/app"
    create_startup_sh "$base_dir"
    create_submissions_txt "$base_dir/assets"
    
    # Update permissions
    update_permissions "$base_dir"   
    
    echo
    print_status "═══════════════════════════════════════════════════════════════"
    print_status "🎉 SETUP COMPLETE!"
    print_status "═══════════════════════════════════════════════════════════════"
    echo
    echo "Directory created: $base_dir"
    echo "Files created:"
    echo "  ├── config/config.env"
    echo "  ├── app/reminder.sh"
    echo "  ├── modules/functions.sh"
    echo "  ├── assets/submissions.txt"
    echo "  └── startup.sh"
    echo
    echo "To test the application:"
    echo "  cd $base_dir"
    echo "  ./startup.sh"
    echo
    print_status "All files have been made executable!"
}

# Execute main function
main "$@"