FROM ubuntu:focal

ARG DEBIAN_FRONTEND=noninteractive

WORKDIR /edra

# --------------- ROS2-SETUP ---------------------
# setup environment
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
ENV ROS_DISTRO foxy

# setup timezone
RUN echo 'Etc/UTC' > /etc/timezone && \
    ln -s /usr/share/zoneinfo/Etc/UTC /etc/localtime && \
    apt-get update && \
    apt-get install -q -y --no-install-recommends tzdata && \
    rm -rf /var/lib/apt/lists/*

# install packages
RUN apt-get update \
    && apt-get install -q -y --no-install-recommends \
    dirmngr \
    gnupg \
    lsb-release \
    && rm -rf /var/lib/apt/lists/*

# setup keys
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 4B63CF8FDE49746E98FA01DDAD19BAB3CBF125EA

# setup sources.list
RUN echo "deb http://snapshots.ros.org/${ROS_DISTRO}/final/ubuntu focal main" > /etc/apt/sources.list.d/ros2-snapshots.list

# install bootstrap tools
RUN apt-get update && apt-get install --no-install-recommends --fix-missing -y \
    build-essential \
    git \
    sudo \
    wget \
    python3-pip \
    python3-colcon-common-extensions \
    python3-colcon-mixin \
    python3-rosdep \
    python3-vcstool \
    && rm -rf /var/lib/apt/lists/*

# bootstrap rosdep
RUN rosdep init && \
  rosdep update --rosdistro $ROS_DISTRO

# setup colcon mixin and metadata
RUN colcon mixin add default \
      https://raw.githubusercontent.com/colcon/colcon-mixin-repository/master/index.yaml && \
    colcon mixin update && \
    colcon metadata add default \
      https://raw.githubusercontent.com/colcon/colcon-metadata-repository/master/index.yaml && \
    colcon metadata update

# install ros2 packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    ros-${ROS_DISTRO}-ros-base \
    && rm -rf /var/lib/apt/lists/*

# --------------- PX4 SETUP
RUN pip install --user -U pyros-genmsg setuptools

#  install latest CMAKE VERSION
RUN apt-get update \
  && wget https://github.com/Kitware/CMake/releases/download/v3.24.1/cmake-3.24.1-Linux-x86_64.sh \
      -q -O /tmp/cmake-install.sh \
      && chmod u+x /tmp/cmake-install.sh \
      && mkdir /opt/cmake-3.24.1 \
      && /tmp/cmake-install.sh --skip-license --prefix=/opt/cmake-3.24.1 \
      && rm /tmp/cmake-install.sh \
      && ln -s /opt/cmake-3.24.1/bin/* /usr/local/bin

# Install PX4
RUN git clone https://github.com/PX4/PX4-Autopilot.git --recursive \
    && bash ./PX4-Autopilot/Tools/setup/ubuntu.sh \
    && cd PX4-Autopilot \
    && make px4_sitl

# Setup Micro XRCE-DDS Agent & Client
# Setup the Agent
RUN git clone https://github.com/eProsima/Micro-XRCE-DDS-Agent.git \
    && cd Micro-XRCE-DDS-Agent \
    && mkdir build \
    && cd build \
    && cmake .. \
    && make \
    && make install \
    && ldconfig /usr/local/lib/

# setup entrypoint
COPY ../ros_entrypoint.sh /
RUN chmod +x /ros_entrypoint.sh

ENTRYPOINT ["/ros_entrypoint.sh"]
CMD ["bash"]
