FROM ubuntu:focal

SHELL ["/bin/bash", "-c"]

# setup timezone
RUN apt update && apt install locales \ 
    && locale-gen en_US en_US.UTF-8 \
    && update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 \
    && export LANG=en_US.UTF-8

# install packages
RUN apt install -y software-properties-common && add-apt-repository universe

# setup keys
RUN apt update && apt install curl -y
RUN curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg

# setup sources.list
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | tee /etc/apt/sources.list.d/ros2.list > /dev/null

RUN apt-get update && apt-get install -y --no-install-recommends \
ros-foxy-ros-core=0.9.2-1* \
&& rm -rf /var/lib/apt/lists/*

# ->> cmake, git, python3, python3-setuptools, python3-bloom, python3-colcon-common-extensions, python3-rosdep, python3-vcstool, wget
RUN apt update && apt install -y \
    ros-dev-tools

# RUN echo "source /opt/ros/foxy/setup.bash" >> ~/.bashrc

ENTRYPOINT ["/bin/bash"]