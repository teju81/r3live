#!/bin/bash

# Build and source workspace
source /opt/ros/noetic/setup.bash
#catkin_make
source devel/setup.bash

# --- Config ---
SESSION="r3live_ros_session"

CONFIG_FILE="handheld_config.yaml" # r3live_config.yaml or handheld_config.yaml

CONFIG_DIR="/root/code/catkin_ws/src/r3live/config"
CONFIG_FILE="${CONFIG_DIR}/${CONFIG_FILE}"

ROS_BAG=$(yq -r '.dataset.ros_bag' "$CONFIG_FILE")
LAUNCH_FILE=$(yq -r '.launch_file' "$CONFIG_FILE")
OUTPUT_DIR=$(yq -r '.path.output_dir' "$CONFIG_FILE")

# Command to run fastlivo2 mapping node + RViz + republish
LAUNCH_R3LIVE="roslaunch r3live $LAUNCH_FILE"

LAUNCH_MESH_RECONSTRUCTION="roslaunch r3live r3live_reconstruct_mesh.launch"


# Command to play rosbag
PLAY_ROSBAG="rosbag play $ROS_BAG"

# Create tmux session if it doesn't exist
tmux has-session -t $SESSION 2>/dev/null
if [ $? != 0 ]; then
    # Step 1: Create a new tmux session and run rosbag in the first pane
    tmux new-session -d -s $SESSION -n "ROS"

    # Step 2: Split the window into 4 panes (2x2 grid)
    tmux split-window -h  # Split horizontally
    # tmux split-window -v  # Split the left pane vertically
    # tmux select-pane -t 0  # Move focus to the first pane (top-left)
    # tmux split-window -v  # Split the right pane vertically

    tmux send-keys -t 0 "$PLAY_ROSBAG" C-m # Top-left pane
    tmux send-keys -t 1 "$LAUNCH_R3LIVE" C-m # Top-right pane
    #tmux send-keys -t 2 "$ECHO_COMMANDS" C-m # Bottom-left pane
    #tmux send-keys -t 2 "roscore" C-m # Bottom-left pane

    # Step 3: Attach to session
    tmux attach-session -t $SESSION
else
    echo "Session $SESSION already exists. Attaching to it."
    tmux attach-session -t $SESSION
fi
