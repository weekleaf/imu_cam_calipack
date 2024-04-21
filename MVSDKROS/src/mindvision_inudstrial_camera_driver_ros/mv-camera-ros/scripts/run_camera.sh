#!/bin/sh
. /opt/ros/noetic/setup.sh
export ROS_MASTER_URI=http://localhost:11311
. /home/atakanoinu/catkin_ws/devel/setup.sh
roslaunch mv_camera_ros mv-camera-ros.launch
