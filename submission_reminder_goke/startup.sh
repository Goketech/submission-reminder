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
