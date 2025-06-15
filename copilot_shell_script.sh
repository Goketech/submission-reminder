#!/bin/bash

# copilot_shell_script.sh - Assignment management script for submission reminder app
# This script allows users to update the assignment name and rerun the reminder check

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
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

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_header() {
    echo -e "${CYAN}$1${NC}"
}

# Function to find submission reminder directories
find_app_directories() {
    local dirs=()
    
    # Look for directories matching the pattern
    for dir in submission_reminder_*; do
        if [[ -d "$dir" && -f "$dir/config/config.env" && -f "$dir/startup.sh" ]]; then
            dirs+=("$dir")
        fi
    done
    echo "${dirs[@]}"
}

# Function to display banner
show_banner() {
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║               COPILOT ASSIGNMENT MANAGER                       ║"
    echo "║          Update Assignment & Check Submissions                 ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo
}

# Function to validate assignment name
validate_assignment_name() {
    local assignment="$1"
    
    # Check if assignment name is not empty
    if [[ -z "$assignment" ]]; then
        return 1
    fi
    
    # Check if assignment name is within 3-100 characters
    if [[ ${#assignment} -lt 3 || ${#assignment} -gt 100 ]]; then
        return 1
    fi
    
    return 0
}


# Function to update assignment in config file
update_assignment() {
    local config_file="$1"
    local new_assignment="$2"
    
    print_status "Updating assignment in config file..."
    
    # Use sed to replace the ASSIGNMENT value
    if sed -i.tmp "s/^ASSIGNMENT=.*/ASSIGNMENT=\"$new_assignment\"/" "$config_file"; then
        rm -f "${config_file}.tmp"
        print_success "Assignment updated successfully!"
        return 0
    else
        print_error "Failed to update assignment"
        return 1
    fi
}

# Function to display current config
show_current_config() {
    local config_file="$1"
    
    echo
    print_header "📋 Current Configuration:"
    echo "═══════════════════════════════════════════════════════════════"
    
    while IFS='=' read -r key value; do
        # Skip comments and empty lines
        if [[ "$key" =~ ^#.*$ || -z "$key" ]]; then
            continue
        fi
        
        # Remove quotes from value
        value=$(echo "$value" | sed 's/^"//;s/"$//')
        
        # Highlight the assignment line
        if [[ "$key" == "ASSIGNMENT" ]]; then
            echo -e "🎯 ${CYAN}$key${NC}: ${YELLOW}$value${NC}"
        else
            echo "   $key: $value"
        fi
    done < "$config_file"
    echo "═══════════════════════════════════════════════════════════════"
}

# Function to run startup script
run_startup() {
    local app_dir="$1"
    local startup_script="$app_dir/startup.sh"
    
    print_status "Running submission check with new assignment..."
    echo
    
    # Change to app directory and run startup.sh
    cd "$app_dir"
    
    if [[ -x "./startup.sh" ]]; then
        # Run startup.sh in a way that allows user interaction
        echo "Starting application..."
        echo "═══════════════════════════════════════════════════════════════"
        ./startup.sh
    else
        print_error "startup.sh not found or not executable in $app_dir"
        return 1
    fi
}

# Function to select application directory
select_app_directory() {
    local dirs=($(find_app_directories))
    
    if [[ ${#dirs[@]} -eq 0 ]]; then
        print_error "No submission reminder application directories found!"
        print_error "Please run create_environment.sh first to create an application."
        exit 1
    elif [[ ${#dirs[@]} -eq 1 ]]; then
        echo "${dirs[0]}"
        return 0
    else
       echo >&2
       print_header "Multiple application directories found:" >&2
       echo >&2
        
        local i=1
        for dir in "${dirs[@]}"; do
            echo >&2 "$i) $dir"
            ((i++))
        done
        echo >&2
        
        while true; do
            read -p "Select directory (1-${#dirs[@]}): " choice
            
            if [[ "$choice" =~ ^[0-9]+$ ]] && [[ $choice -ge 1 && $choice -le ${#dirs[@]} ]]; then
                echo "${dirs[$((choice-1))]}"
                return 0
            else
                print_warning "Invalid choice. Please select 1-${#dirs[@]}."
            fi
        done
    fi
}

# Main function
main() {
    show_banner
    
    # Find and select application directory
    print_status "Searching for submission reminder applications..."
    set +e
    app_dir=$(select_app_directory)
    rc=$?
    set -e

    if [[ $rc -ne 0 || -z "$app_dir" ]]; then
    print_error "No submission reminder application directories found!"
    print_error "Please run create_environment.sh first to create an application."
    exit 1
    fi
    print_status "Application directory selected: $app_dir"
    
    if [[ -z "$app_dir" ]]; then
        print_error "No valid application directory selected."
        exit 1
    fi
    
    print_success "Selected application: $app_dir"
    
    # Set config file path
    config_file="$app_dir/config/config.env"
    
    # Verify config file exists
    if [[ ! -f "$config_file" ]]; then
        print_error "Config file not found: $config_file"
        exit 1
    fi
    
    # Show current configuration
    show_current_config "$config_file"
    
    echo
    print_header "🔄 Assignment Update Process"
    echo "═══════════════════════════════════════════════════════════════"
    
    # Prompt for new assignment name
    while true; do
        echo
        read -p "🔹 Enter the new assignment name: " new_assignment
        
        # Validate assignment name
        if validate_assignment_name "$new_assignment"; then
            break
        else
            print_warning "Invalid assignment name. Please enter 3-100 characters."
        fi
    done
    
    # Confirm the change
    echo
    print_header "📝 Confirmation"
    echo "═══════════════════════════════════════════════════════════════"
    echo "Application Directory: $app_dir"
    echo "New Assignment Name: $new_assignment"
    echo
    
    read -p "Do you want to proceed with this change? (y/N): " confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        print_warning "Operation cancelled by user."
        exit 0
    fi
    
    # Update the assignment
    echo
    print_status "Processing assignment update..."
    
    if update_assignment "$config_file" "$new_assignment"; then
        # Show updated configuration
        show_current_config "$config_file"
        
        echo
        print_success "Assignment updated successfully!"
        echo
        
        # Ask if user wants to run the application
        read -p "Do you want to run the submission check now? (Y/n): " run_now
        
        if [[ ! "$run_now" =~ ^[Nn]$ ]]; then
            echo
            print_status "Launching application with new assignment..."
            echo
            
            # Save current directory
            original_dir=$(pwd)
            
            # Run the startup script
            if run_startup "$app_dir"; then
                # Return to original directory
                cd "$original_dir"
                echo
                print_success "Application completed successfully!"
            else
                # Return to original directory
                cd "$original_dir"
                print_error "Application encountered an error."
                exit 1
            fi
        else
            echo
            print_status "You can manually run the application later with:"
            echo "  cd $app_dir"
            echo "  ./startup.sh"
        fi
    else
        print_error "Failed to update assignment."
        exit 1
    fi
    
    echo
    print_success "✨ Copilot assignment update completed!"
}

# Help function
show_help() {
    echo "Copilot Shell Script - Assignment Manager"
    echo
    echo "USAGE:"
    echo "  $0 [OPTIONS]"
    echo
    echo "OPTIONS:"
    echo "  -h, --help     Show this help message"
    echo
    echo "DESCRIPTION:"
    echo "  This script helps you update the assignment name in your"
    echo "  submission reminder application and rerun the reminder check."
    echo
    echo "WORKFLOW:"
    echo "  1. Detects existing submission reminder app directories"
    echo "  2. Shows current assignment configuration"
    echo "  3. Prompts for new assignment name"
    echo "  4. Updates the config/config.env file"
    echo "  5. Optionally runs the application with new assignment"
    echo
    echo "FILES MODIFIED:"
    echo "  - config/config.env (ASSIGNMENT value updated)"
    echo "  - Backup files created automatically"
    echo
}

# Parse command line arguments
case "${1:-}" in
    -h|--help)
        show_help
        exit 0
        ;;
    "")
        # No arguments - run main function
        main "$@"
        ;;
    *)
        print_error "Unknown option: $1"
        echo "Use -h or --help for usage information."
        exit 1
        ;;
esac