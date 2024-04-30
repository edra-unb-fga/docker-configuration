FROM ubuntu:focal

ARG DEBIAN_FRONTEND=noninteractive

# RUN apt update && apt install -y git cmake make
RUN apt update && apt install -y --no-install-recommends \
    python3-pip \
    git \
    wget \
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

# RUN MicroXRCEAgent udp4 -p 8888
RUN apt-get update && apt-get install -y lsb-release && apt-get clean all
RUN apt install -y sudo

# Install PX4
RUN git clone https://github.com/PX4/PX4-Autopilot.git --recursive
    # && bash ./PX4-Autopilot/Tools/setup/ubuntu.sh \
    # && cd PX4-Autopilot \
    # && make px4_sitl


ENTRYPOINT ["/bin/bash"]