#!/bin/bash

# SyncLife Device Testing Script
# Automates installation and basic testing on connected devices

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}SyncLife Device Testing${NC}"
echo -e "${GREEN}========================================${NC}"

# Function to list connected Android devices
list_android_devices() {
    echo -e "\n${BLUE}Connected Android Devices:${NC}"
    adb devices -l | grep -v "List of devices" | grep "device" || echo "No Android devices connected"
}

# Function to list connected iOS devices
list_ios_devices() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo -e "\n${BLUE}Connected iOS Devices:${NC}"
        xcrun xctrace list devices 2>&1 | grep -E "iPhone|iPad" || echo "No iOS devices connected"
    fi
}

# Function to get device info
get_android_device_info() {
    local device_id=$1
    echo -e "\n${YELLOW}Device Information:${NC}"
    echo "Device ID: $device_id"
    echo "Model: $(adb -s $device_id shell getprop ro.product.model)"
    echo "Android Version: $(adb -s $device_id shell getprop ro.build.version.release)"
    echo "SDK Version: $(adb -s $device_id shell getprop ro.build.version.sdk)"
    echo "Manufacturer: $(adb -s $device_id shell getprop ro.product.manufacturer)"
    echo "RAM: $(adb -s $device_id shell cat /proc/meminfo | grep MemTotal)"
}

# Function to install APK on Android device
install_android() {
    local device_id=$1
    local apk_path="build/app/outputs/flutter-apk/app-release.apk"
    
    if [ ! -f "$apk_path" ]; then
        echo -e "${RED}Error: APK not found at $apk_path${NC}"
        echo "Run 'flutter build apk --release' first"
        return 1
    fi
    
    echo -e "\n${YELLOW}Installing on Android device: $device_id${NC}"
    adb -s $device_id install -r "$apk_path"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Installation successful${NC}"
        return 0
    else
        echo -e "${RED}✗ Installation failed${NC}"
        return 1
    fi
}

# Function to launch app on Android
launch_android() {
    local device_id=$1
    local package_name="com.synclife.synclife_app"
    local activity_name="com.synclife.synclife_app.MainActivity"
    
    echo -e "\n${YELLOW}Launching app on device: $device_id${NC}"
    adb -s $device_id shell am start -n "$package_name/$activity_name"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ App launched${NC}"
    else
        echo -e "${RED}✗ Failed to launch app${NC}"
    fi
}

# Function to clear app data on Android
clear_android_data() {
    local device_id=$1
    local package_name="com.synclife.synclife_app"
    
    echo -e "\n${YELLOW}Clearing app data on device: $device_id${NC}"
    adb -s $device_id shell pm clear "$package_name"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ App data cleared${NC}"
    else
        echo -e "${RED}✗ Failed to clear app data${NC}"
    fi
}

# Function to capture logs from Android
capture_android_logs() {
    local device_id=$1
    local log_file="logs/device_${device_id}_$(date +%Y%m%d_%H%M%S).log"
    
    mkdir -p logs
    
    echo -e "\n${YELLOW}Capturing logs from device: $device_id${NC}"
    echo "Logs will be saved to: $log_file"
    echo "Press Ctrl+C to stop..."
    
    adb -s $device_id logcat -v time "*:V" > "$log_file"
}

# Function to take screenshot on Android
screenshot_android() {
    local device_id=$1
    local screenshot_file="screenshots/device_${device_id}_$(date +%Y%m%d_%H%M%S).png"
    
    mkdir -p screenshots
    
    echo -e "\n${YELLOW}Taking screenshot from device: $device_id${NC}"
    adb -s $device_id shell screencap -p /sdcard/screenshot.png
    adb -s $device_id pull /sdcard/screenshot.png "$screenshot_file"
    adb -s $device_id shell rm /sdcard/screenshot.png
    
    echo -e "${GREEN}✓ Screenshot saved to: $screenshot_file${NC}"
}

# Function to run integration tests on device
run_integration_tests() {
    local device_id=$1
    
    echo -e "\n${YELLOW}Running integration tests on device: $device_id${NC}"
    flutter drive --target=test_driver/app.dart -d "$device_id"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Integration tests passed${NC}"
    else
        echo -e "${RED}✗ Integration tests failed${NC}"
    fi
}

# Function to check app performance
check_performance() {
    local device_id=$1
    local package_name="com.synclife.synclife_app"
    
    echo -e "\n${YELLOW}Checking app performance on device: $device_id${NC}"
    
    # Get memory usage
    echo "Memory Usage:"
    adb -s $device_id shell dumpsys meminfo "$package_name" | grep -A 5 "App Summary"
    
    # Get CPU usage
    echo -e "\nCPU Usage:"
    adb -s $device_id shell top -n 1 | grep "$package_name"
    
    # Get battery stats
    echo -e "\nBattery Stats:"
    adb -s $device_id shell dumpsys batterystats "$package_name" | grep -A 10 "Estimated power use"
}

# Function to uninstall app
uninstall_android() {
    local device_id=$1
    local package_name="com.synclife.synclife_app"
    
    echo -e "\n${YELLOW}Uninstalling app from device: $device_id${NC}"
    adb -s $device_id uninstall "$package_name"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ App uninstalled${NC}"
    else
        echo -e "${RED}✗ Failed to uninstall app${NC}"
    fi
}

# Function to test on all connected Android devices
test_all_android() {
    local devices=$(adb devices | grep -v "List of devices" | grep "device" | awk '{print $1}')
    
    if [ -z "$devices" ]; then
        echo -e "${RED}No Android devices connected${NC}"
        return 1
    fi
    
    for device in $devices; do
        echo -e "\n${GREEN}========================================${NC}"
        echo -e "${GREEN}Testing on device: $device${NC}"
        echo -e "${GREEN}========================================${NC}"
        
        get_android_device_info "$device"
        install_android "$device"
        launch_android "$device"
        
        echo -e "\n${YELLOW}Please test the app manually on the device${NC}"
        echo "Press Enter when done to continue to next device..."
        read
    done
}

# Function to generate test report
generate_test_report() {
    local report_file="test_reports/device_test_report_$(date +%Y%m%d_%H%M%S).md"
    
    mkdir -p test_reports
    
    cat > "$report_file" << EOF
# SyncLife Device Test Report

## Test Information
- Date: $(date +%Y-%m-%d)
- Time: $(date +%H:%M:%S)
- Tester: $USER
- Build Version: $(grep 'version:' pubspec.yaml | sed 's/version: //')

## Devices Tested

### Android Devices
EOF
    
    local devices=$(adb devices | grep -v "List of devices" | grep "device" | awk '{print $1}')
    
    for device in $devices; do
        cat >> "$report_file" << EOF

#### Device: $device
- Model: $(adb -s $device shell getprop ro.product.model)
- Android Version: $(adb -s $device shell getprop ro.build.version.release)
- Manufacturer: $(adb -s $device shell getprop ro.product.manufacturer)

**Test Results:**
- [ ] Installation successful
- [ ] App launches
- [ ] Authentication works
- [ ] Core features functional
- [ ] Performance acceptable
- [ ] No crashes observed

**Notes:**
[Add notes here]

---
EOF
    done
    
    echo -e "${GREEN}✓ Test report template generated: $report_file${NC}"
    echo "Please fill in the test results manually"
}

# Main menu
show_menu() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}Device Testing Menu${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo "1. List connected devices"
    echo "2. Install APK on device"
    echo "3. Launch app on device"
    echo "4. Clear app data"
    echo "5. Capture logs"
    echo "6. Take screenshot"
    echo "7. Run integration tests"
    echo "8. Check performance"
    echo "9. Uninstall app"
    echo "10. Test on all devices"
    echo "11. Generate test report"
    echo "0. Exit"
    echo -e "${BLUE}========================================${NC}"
}

# Main execution
main() {
    # Check if adb is available
    if ! command -v adb &> /dev/null; then
        echo -e "${RED}Error: adb not found. Please install Android SDK Platform Tools.${NC}"
        exit 1
    fi
    
    # Parse command line arguments
    if [ $# -gt 0 ]; then
        case $1 in
            --install)
                list_android_devices
                echo -e "\nEnter device ID:"
                read device_id
                install_android "$device_id"
                launch_android "$device_id"
                ;;
            --test-all)
                test_all_android
                ;;
            --report)
                generate_test_report
                ;;
            --help)
                echo "Usage: $0 [OPTION]"
                echo ""
                echo "Options:"
                echo "  --install     Install APK on selected device"
                echo "  --test-all    Test on all connected devices"
                echo "  --report      Generate test report template"
                echo "  --help        Show this help message"
                echo ""
                echo "Run without options for interactive menu"
                ;;
            *)
                echo "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
        exit 0
    fi
    
    # Interactive menu
    while true; do
        show_menu
        echo -n "Select option: "
        read option
        
        case $option in
            1)
                list_android_devices
                list_ios_devices
                ;;
            2)
                list_android_devices
                echo -e "\nEnter device ID:"
                read device_id
                install_android "$device_id"
                ;;
            3)
                list_android_devices
                echo -e "\nEnter device ID:"
                read device_id
                launch_android "$device_id"
                ;;
            4)
                list_android_devices
                echo -e "\nEnter device ID:"
                read device_id
                clear_android_data "$device_id"
                ;;
            5)
                list_android_devices
                echo -e "\nEnter device ID:"
                read device_id
                capture_android_logs "$device_id"
                ;;
            6)
                list_android_devices
                echo -e "\nEnter device ID:"
                read device_id
                screenshot_android "$device_id"
                ;;
            7)
                list_android_devices
                echo -e "\nEnter device ID:"
                read device_id
                run_integration_tests "$device_id"
                ;;
            8)
                list_android_devices
                echo -e "\nEnter device ID:"
                read device_id
                check_performance "$device_id"
                ;;
            9)
                list_android_devices
                echo -e "\nEnter device ID:"
                read device_id
                uninstall_android "$device_id"
                ;;
            10)
                test_all_android
                ;;
            11)
                generate_test_report
                ;;
            0)
                echo "Exiting..."
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option${NC}"
                ;;
        esac
        
        echo -e "\nPress Enter to continue..."
        read
    done
}

# Run main function
main "$@"
