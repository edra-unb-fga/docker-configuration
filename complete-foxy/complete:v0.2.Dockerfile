FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive

# --------------- ROS2-SETUP
# set locale
RUN apt update && apt install locales \
    && locale-gen en_US en_US.UTF-8 \
    && update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8

# setup environment
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
ENV ROS_DISTRO humble

# install packages
RUN apt-get update && apt-get install -q -y --no-install-recommends \
    software-properties-common \
    dirmngr \
    gnupg \
    curl \
    && add-apt-repository universe \
    && rm -rf /var/lib/apt/lists/*
    
# setup keys
RUN curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg

# setup sources.list
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | tee /etc/apt/sources.list.d/ros2.list > /dev/null

# install bootstrap tools
RUN apt-get update && apt-get install --no-install-recommends -y \
    build-essential \
    git \
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

# --------------- PX4 SETUP ----------------------
RUN apt update && apt install -y --no-install-recommends \
    python3-pip \
    git \
    wget \
    lsb-release \
    build-essential

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

# setup user
ARG HOST_USER
RUN useradd -ms /bin/bash ${HOST_USER}
USER ${HOST_USER}

WORKDIR /edra
RUN apt install -y lsb-release
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

# Install PX4
RUN git clone https://github.com/PX4/PX4-Autopilot.git --recursive \
    && bash ./PX4-Autopilot/Tools/setup/ubuntu.sh \
    && cd PX4-Autopilot \
    && make px4_sitl

RUN echo "source /opt/ros/${ROS_DISTRO}/setup.bash" >> ~/.bashrc && echo "source /opt/ros/${ROS_DISTRO}/setup.sh" >> ~/.bashrc

ENTRYPOINT ["/bin/bash"]
