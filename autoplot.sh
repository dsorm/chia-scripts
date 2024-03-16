#!/bin/bash

# User configurable variables
# ---------------------------
# Define the directory prefix to search for
prefix="/data/chia-plot"
# Blacklist file location
blacklist_file="blacklist.txt"
# Lock file path (adjust only if necessary)
lock_file="autoplot.lock"
# ---------------------------
# Users can change the values above as needed

# Dry run flag, 0 by default (meaning actual run), set to 1 for dry run
dry_run=0

# Check for command-line arguments
for arg in "$@"
do
    if [ "$arg" == "--dry-run" ]; then
        dry_run=1
    fi
done

# Ensure blacklist file exists, create if not
if [ ! -f "$blacklist_file" ]; then
    touch "$blacklist_file"
fi

# Check if the script is already running
if [ -f "$lock_file" ]; then
    echo "Another instance of the script is already running."
    exit 1
else
    # Create a lock file
    touch "$lock_file"
fi

# Cleanup function to remove lock file on script exit
cleanup() {
    rm -f "$lock_file"
}
trap cleanup EXIT

# Read blacklist into an array, each line is an entry
mapfile -t blacklist < "$blacklist_file"

# Convert blacklist array to a grep pattern
blacklist_pattern=$(printf "|%s" "${blacklist[@]}")
blacklist_pattern=${blacklist_pattern:1} # Remove leading '|'
echo "Active blacklist pattern: $blacklist_pattern"

# Size of a k32 plot in megabytes (108.9 GB)
if ! plot_size_mb=$(echo "108.9 * 1024" | bc); then
    echo "Error: 'bc' utility is not installed. Please install 'bc' to continue."
    exit 1
fi

# Discover mounted drives that are not in the blacklist
mapfile -t target_drives < <(df | awk -v prefix="$prefix" '$6 ~ prefix {print $6}' | grep -Ev "($blacklist_pattern)")

# Function to calculate the number of plots that can be created on a drive
calculate_plots () {
    local available_space_mb=$(df --output=avail -m "$1" | tail -n 1)
    # Use bc to perform floating-point division, then convert to an integer with floor (removing the decimal part)
    local plots=$(echo "scale=2; $available_space_mb / $plot_size_mb" | bc | cut -d. -f1)
    if [[ "$plots" == "" || "$plots" == " " ]]; then
    	plots="0"
    fi
    echo $plots
}

# Main loop to create plots on each target drive
for drive in "${target_drives[@]}"; do
    echo "Processing $drive..."
    num_plots=$(calculate_plots "$drive")
    if [ "$num_plots" -gt 0 ]; then
        if [ "$dry_run" -eq 1 ]; then
            echo "[DRY RUN] create $num_plots plots on $drive"
        else
            echo "Creating $num_plots plots on $drive..."
            ./plot.sh "$drive" "$num_plots"
        fi
    else
        echo "$drive is already full, skipping"
    fi
done
echo "Plotting process completed, sending pushover notification"
echo "Plotting done, sending pushover notification..."
curl -s \
  --form-string "token=YOURTOKENHERE" \
  --form-string "user=YOURUSERHERE" \
  --form-string "message=Autoplot done" \
  https://api.pushover.net/1/messages.json