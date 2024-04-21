# 联标文档（Genshin Start！）

> imu相机联合标定需要imu和相机分别单独标定再进行联标，本文档以相机标定，imu标定，imu相机联合标定的顺序讲述。

## 0. 标定前工作

* **各种依赖**：

  eigen，ceres-solver先装了，要是后面有报错就装更新的版本，ros的serial包应该也是要的，但据说apt装的会有问题，建议源码装，我记得哨兵这台nuc是都装了。

  1. *kalibr的依赖*：

     ```
     sudo apt-get install -y \
         git wget autoconf automake nano \
         libeigen3-dev libboost-all-dev libsuitesparse-dev \
         doxygen libopencv-dev \
         libpoco-dev libtbb-dev libblas-dev liblapack-dev libv4l-dev
        
      sudo apt-get install -y python3-dev python3-pip python3-scipy \
         python3-matplotlib ipython3 python3-wxgtk4.0 python3-tk python3-igraph
     ```

  2. *imu_utils的依赖*：

     catkin tools安装方法：

     ```
     sudo apt-get install python3-catkin-tools
     ```

     不行就：

     ```
     pip3 install catkin-tools catkin-tools-python
     ```

     再不行就：

     ```
     sudo apt install python3-pip
     sudo pip3 install -U catkin_tools
     ```

     code_utils是imu_utils的依赖，必须先编译：

     ```
     catkin build code_utils
     ```

  3. *迈德威视ROS驱动*：

     cd到MVSDKROS文件夹下，执行：

     ```
     catkin_make
     ```

* **编译标定工具箱**（Calibrate_tools文件夹下）

  1. *imu标定包*：

     ```
     catkin build imu_utils
     ```

  2. *kalibr*（会有点久）：

     ```
     catkin build kalibr
     ```

* **编译自定义串口协议包**（Calibrate_tools文件夹下）

  ```
  catkin build serial_port
  ```

## 1. 相机标定

1. **启动相机节点**

   在MVSDKROS文件夹下：

   ```
   source ./devel/setup.bash
   roslaunch mv_camera_ros mv-camera-ros.launch
   ```

   相机节点话题为/image_raw

2. **降低相机输出频率为4Hz**

   ```
   rosrun topic_tools throttle messages [相机话题] 4.0 [自定义改变频率的相机话题名字]
   rosrun topic_tools throttle messages /image_raw 4.0 /image_raw_throttle
   ```

3. **录制bag**

   ```
   rosbag record [相机话题] -O [保存的bag名字]
   rosbag record /image_raw_throttle -O cam_calib.bag
   ```

4. **标定**

   ```
   rosrun kalibr kalibr_calibrate_cameras \
   --bag /home/rm/cam_calib.bag  \
   --topics /image_raw_throttle \
   --models pinhole-radtan \
   --target /home/rm/Calibrate_tools/kalibr_ws/src/kalibr/aslam_offline_calibration/kalibr/config/checkerboard.yaml \
   --show-extraction 
   ```

   - –bag [录制的包]
   - –topics [（降频后的）相机话题]
   - –models [相机模型-畸变模型，我们相机用pinhole-radtan就行，其他详见kalibr文档]
   - –target [标定板配置文件，已经写好了，在/imu_cam_calipack/Calibrate_tools/kalibr_ws/src/kalibr/aslam_offline_calibration/kalibr/config/里的checkerboard.yaml（按照组内已有标定版设置的）]
   - –show-extraction(设置表示展示角点提取过程)
   - –bag-from-to 选择bag的时间段

   结果会保存在bag文件的同级目录。

## 2. IMU标定

1. **找电控烧代码**（stm32-imu_cali_proj包里有）

   ```
   cd stm32-imu_cali_proj
   make -j12
   make download_jlink
   ```

2. **imu标定数据采集**

   nuc插上C板等一会初始化（等它个20s大概）然后跑：

   ```
   ./collect_imu_data.sh
   ```

   imu话题为/imu/data_raw

   （采集时间最好大于两小时）

   采集的bag在kalibr_ws/src/serial_port/record_bags/下

   如果想要录制bag：

   在serial_port包内的imu_cali.launch文件里将

   ```
   <!-- <node pkg="rosbag" type="record" name="bag_record" output="screen" 
               args="/imu/data_raw -o $(find serial_port)/record_bags/imu_raw_data.bag" /> -->
   ```

   注释取消掉（默认是注释的）。

3. **imu标定**

   播放录好的bag：

   ```
   rosbag play -r 200 imu_raw_data_2024-04-10-22-46-42.bag（bag名换成你采集的那个） // 200 倍速播放rosbag
   ```

   然后跑标定程序：

   ```
   roslaunch imu_utils C-BOARD.launch 
   ```

   （记得在这个launch文件中改max_time_min这个参数，这个参数是你标定至少的时间，例如bag录了120min，该参数我设置为110min，那么只会标110min，切忌不要设置大于实际的bag录制时间）

   等一段时间，imu的标定结果会自动存放在kalibr_ws/src/imu_utils/data，标定参数文件名字为c-board-bmi088_imu_param.yaml

## 3. imu相机联合标定

1. **启动相机，imu节点**

   ```
   source ./devel/setup.bash
   roslaunch mv_camera_ros mv-camera-ros.launch
   rosrun topic_tools throttle messages /image_raw 4.0 /image_raw_throttle
   ./collect_imu_data.sh
   ```

2. **录制bag**

   ```
   rosbag record /imu/data_raw /image_raw_throttle -O cam_imu.bag
   ```

   充分激励imu六个轴的运动，参考[B站搬运视频](https://www.bilibili.com/video/av795841344/?vd_source=e630362562112e7d3bfd6326d997ab38)，俯仰角、偏航角、横滚角、上下平移、左右平移、前后平移，各弄三次，幅度尽量大一点，之后再混合运动三次，录制时间大概一两分钟。

3. **kalibr标定**

   需要三个配置文件：标定板配置文件、imu内参文件、相机内参文件；
    一个bag文件：imu和相机联合录制的bag。

   注意：
    （1）imu和相机内参文件包含了imu和相机节点话题，要和录制bag时候的话题对应
    （2）相机的配置文件可以直接用相机标定生成的.yaml文件，imu的配置文件需要修改成如下格式（示例文件在imu_cam_calipack/Calibrate_tools/kalibr_ws/下的imu.yaml）：

   ```
   #Accelerometers
   accelerometer_noise_density: 5.43036e-03   #Noise density (continuous-time)
   accelerometer_random_walk:   1.44598e-04   #Bias random walk
   #Gyroscopes
   gyroscope_noise_density:     4.9700e-03   #Noise density (continuous-time)
   gyroscope_random_walk:       6.8522e-05   #Bias random walk
   rostopic:                    /imu      #the IMU ROS topic
   update_rate:                 200.0      #Hz (for discretization of the values above)
   ```

   联合标定：

   ```
   rosrun kalibr kalibr_calibrate_imu_camera \
   --imu /home/rm/imu.yaml \
   --cam /home/rm/cam_calib-camchain.yaml \
   --target /home/rm/Calibrate_tools/kalibr_ws/src/kalibr/aslam_offline_calibration/kalibr/config/checkerboard.yaml \
   --bag /home/rm/cam_imu.bag --show-extraction
   ```

   此处所花时间较久，耐心等待，可以去玩会原神（

---

参考文档：

https://blog.csdn.net/LoveJSH/article/details/131953776