#!/bin/bash

# Display Mode Switcher for Restore Toolkit
# Choose between emoji version and clean version

TOOLKIT_DIR="/home/paulo/projects/system-restore-toolkit"
EMOJI_SCRIPT="$TOOLKIT_DIR/manage_restore_points.sh"
CLEAN_SCRIPT="$TOOLKIT_DIR/manage_restore_points_clean.sh"
CURRENT_SCRIPT="$TOOLKIT_DIR/manage_restore_points_current.sh"

echo "System Restore Toolkit - Display Mode Switcher"
echo "=============================================="
echo ""

# Check current mode
if [ -L "$CURRENT_SCRIPT" ]; then
    current_target=$(readlink "$CURRENT_SCRIPT")
    if [[ "$current_target" == *"clean"* ]]; then
        current_mode="clean"
    else
        current_mode="emoji"
    fi
    echo "Current display mode: $current_mode"
else
    echo "Current display mode: emoji (default)"
    current_mode="emoji"
fi

echo ""
echo "Available modes:"
echo "1) emoji - Full visual mode with emoji icons"
echo "2) clean - Text-only mode (better terminal compatibility)"
echo ""

read -p "Select display mode (1/2) or press Enter to keep current: " choice

case "$choice" in
    "1")
        echo "Switching to emoji mode..."
        ln -sf manage_restore_points.sh "$CURRENT_SCRIPT"
        # Update global link
        ln -sf "$EMOJI_SCRIPT" ~/.local/bin/restore-toolkit
        echo "SUCCESS: Now using emoji display mode"
        ;;
    "2") 
        echo "Switching to clean mode..."
        ln -sf manage_restore_points_clean.sh "$CURRENT_SCRIPT"
        # Update global link
        ln -sf "$CLEAN_SCRIPT" ~/.local/bin/restore-toolkit
        echo "SUCCESS: Now using clean display mode"
        ;;
    "")
        echo "Keeping current display mode: $current_mode"
        ;;
    *)
        echo "Invalid choice. Keeping current mode."
        ;;
esac

echo ""
echo "Test the current mode:"
if [ -f ~/.local/bin/restore-toolkit ]; then
    echo "Running: restore-toolkit disk-usage | head -3"
    echo ""
    restore-toolkit disk-usage | head -3
else
    echo "Running: rt disk-usage | head -3"
    echo ""
    rt disk-usage | head -3
fi
