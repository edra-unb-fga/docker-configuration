FROM ubuntu:focal

RUN apt update && apt install -y wget gnupg
RUN wget http://packages.osrfoundation.org/gazebo.key -O - | apt-key add -