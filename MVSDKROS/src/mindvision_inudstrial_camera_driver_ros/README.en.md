# Mindvision_Inudstrial_Camera_Driver_ROS

#### Description
MindVision Industrial Camera ROS1 Driver
This driver is based on code from "https://github.com/pixmoving-moveit/mv-camera-ros". If you meet problem like following, you can try this driver:
    
    openin the camera device id 
    Camera SDK init status : 0
    No camera found
    Status = -16
    [ERROR] [1540560413.389152223]: cv camera open failed: No camera found

In the driver of mv-camera-ros, develper use old version of SDK which has bug when connect to the camera. The offical of MindVision fixed bug in thier .so file, but forget to update ros driver. I use the latest .so in this driver and can get image of camera in rviz.

#### Installation

1.  git clone https://gitee.com/zhang_zhi_he/mindvision_inudstrial_camera_driver_ros.git
2.  copy driver code into "your ros workspace"/src/
3.  catkin_make
4.  source devel/setup.bash
5.  roslaunch mv-camera-ros mv-camera-ros.launch

#### Gitee Feature

1.  You can use Readme\_XXX.md to support different languages, such as Readme\_en.md, Readme\_zh.md
2.  Gitee blog [blog.gitee.com](https://blog.gitee.com)
3.  Explore open source project [https://gitee.com/explore](https://gitee.com/explore)
4.  The most valuable open source project [GVP](https://gitee.com/gvp)
5.  The manual of Gitee [https://gitee.com/help](https://gitee.com/help)
6.  The most popular members  [https://gitee.com/gitee-stars/](https://gitee.com/gitee-stars/)
