#  STAGE 1
FROM ubuntu:focal AS pre-builder

ARG DEBIAN_FRONTEND=noninteractive

# Base Config
    # setup timezone
RUN echo 'Etc/UTC' > /etc/timezone && \
    ln -s /usr/share/zoneinfo/Etc/UTC /etc/localtime && \
    apt-get update && \
    apt-get install -q -y --no-install-recommends tzdata \
    # && rm -rf /var/lib/apt/lists/*

    # Installing base tools
    && apt update && apt install -y --no-install-recommends \
    git \
    wget \
    lsb-release \
    sudo \
    gnupg \
    build-essential \

    # C-MAKE installation
    && wget https://github.com/Kitware/CMake/releases/download/v3.24.1/cmake-3.24.1-Linux-x86_64.sh \
    -q -O /tmp/cmake-install.sh \
    && chmod u+x /tmp/cmake-install.sh \
    && mkdir /opt/cmake-3.24.1 \
    && /tmp/cmake-install.sh --skip-license --prefix=/opt/cmake-3.24.1 \
    && rm /tmp/cmake-install.sh \
    && ln -s /opt/cmake-3.24.1/bin/* /usr/local/bin

# --------------- PX4 SETUP ------------------ 
    # Setup Micro XRCE-DDS Agent & Client
    RUN git clone https://github.com/eProsima/Micro-XRCE-DDS-Agent.git \
    && cd Micro-XRCE-DDS-Agent \
    && mkdir build \
    && cd build \
    && cmake .. \
    && make \
    && make install \
    && ldconfig /usr/local/lib/ \

    # Install PX4
    RUN git clone https://github.com/PX4/PX4-Autopilot.git --recursive \
    && bash ./PX4-Autopilot/Tools/setup/ubuntu.sh \
    && cd PX4-Autopilot \
    && make px4_sitl


# STAGE 2
FROM ubuntu:focal

COPY --from=pre-builder ./PX4-Autopilot/build /PX4-Autopilot/build
COPY --from=pre-builder ./Micro-XRCE-DDS-Agent /Micro-XRCE-DDS-Agent
# Copia os binarios de todas as dependencias instaladas na primeira fase de build
COPY --from=pre-builder /usr/local/bin/* /usr/local/bin

# ---------------- ROS-FOXY SETUP ------------------
    # setup keys
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 4B63CF8FDE49746E98FA01DDAD19BAB3CBF125EA \
    # setup sources.list
    && echo "deb http://snapshots.ros.org/foxy/final/ubuntu focal main" > /etc/apt/sources.list.d/ros2-snapshots.list

    # install bootstrap tools
RUN apt update && apt install --no-install-recommends -y \
    python3-pip \
    python3-colcon-common-extensions \
    python3-colcon-mixin \
    python3-rosdep \
    python3-vcstool \
    # install ros2 packages
    ros-foxy-ros-base \
    && rm -rf /var/lib/apt/lists/* \
    

    # setup colcon mixin and metadata
    && colcon mixin add default \
    https://raw.githubusercontent.com/colcon/colcon-mixin-repository/master/index.yaml && \
    colcon mixin update && \
    colcon metadata add default \
    https://raw.githubusercontent.com/colcon/colcon-metadata-repository/master/index.yaml && \
    colcon metadata update \

    # bootstrap rosdep
    && rosdep init && rosdep update --rosdistro foxy

    # install needed dependencies
RUN pip install --user -U pyros-genmsg setuptools


ENTRYPOINT ["/bin/bash"]
