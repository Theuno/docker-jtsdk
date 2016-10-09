FROM ubuntu:14.04
MAINTAINER PA5PT

# Tell debconf to run in non-interactive mode
ENV DEBIAN_FRONTEND noninteractive

# Make sure the repository information is up to date
RUN apt-get update

# Install Chrome
RUN apt-get install -y ca-certificates wget
RUN wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -P /tmp/
RUN dpkg -i /tmp/google-chrome-stable_current_amd64.deb || true
RUN apt-get install -fy

# Install OpenSSH
RUN apt-get install -y openssh-server

# Create OpenSSH privilege separation directory
RUN mkdir /var/run/sshd

# Install Pulseaudio
RUN apt-get install -y pulseaudio

# Add the Chrome user that will run the browser
RUN adduser --disabled-password --gecos "Chrome User" --uid 5001 chrome

# Add SSH public key for the chrome user
RUN mkdir /home/chrome/.ssh
ADD id_rsa.pub /home/chrome/.ssh/authorized_keys
RUN chown -R chrome:chrome /home/chrome/.ssh
RUN usermod -a -G dialout chrome

# Set up the launch wrapper
RUN echo 'export PULSE_SERVER="tcp:localhost:64713"' >> /usr/local/bin/chrome-pulseaudio-forward
RUN echo 'google-chrome --no-sandbox' >> /usr/local/bin/chrome-pulseaudio-forward
RUN chmod 755 /usr/local/bin/chrome-pulseaudio-forward

# Set up the launch wrapper for wsjt
RUN echo 'export PULSE_SERVER="tcp:localhost:64713"' >> /usr/local/bin/wsjt-pulseaudio-forward
RUN echo 'cd /root/jtsdk/wsjt/10.0/install' >> /usr/local/bin/wsjt-pulseaudio-forward
RUN echo './wsjt.sh' >> /usr/local/bin/wsjt-pulseaudio-forward
RUN chmod 755 /usr/local/bin/wsjt-pulseaudio-forward


# Install JTSDK needed files
RUN apt-get update && \
    apt-get install -y automake asciidoc asciidoctor clang-3.5 cmake coderay \
dialog g++ gettext gfortran git libfftw3-dev libhamlib-dev libhamlib-utils \
libudev-dev libusb-dev libusb-1.0-0-dev libqt5multimedia5-plugins \
libqt5serialport5-dev libqt5opengl5-dev libsamplerate0-dev libtool \
libxml2-utils pkg-config portaudio19-dev python3-pil python3-pil.imagetk \
python3-tk python3-dev python3-numpy python3-pip python3-setuptools python3-dev \
qtbase5-dev qtmultimedia5-dev subversion texinfo xmlto vim

# Install portaudio
RUN wget http://portaudio.com/archives/pa_stable_v19_20140130.tgz && \
    tar xvf pa_stable_v19_20140130.tgz && \
    rm pa_stable_v19_20140130.tgz && \
    cd portaudio && \
    ./configure && \
    make && \
    make install 

# Install JTSDK
env TERM xterm
RUN git clone git://git.code.sf.net/p/jtsdk/jtsdk-nix jtsdk-jtsdk-nix && \
    cd jtsdk-jtsdk-nix && \
    ./autogen.sh && \
    make && \
    mkdir /home//jtsdk && \
    make install 
#RUN cd /jtsdk-jtsdk-nix/src && \
#    . jtsdk-wsjt

#RUN chown -R chrome:chrome /root/jtsdk

# Start SSH so we are ready to make a tunnel
ENTRYPOINT ["/usr/sbin/sshd",  "-D"]

# Expose the SSH port
EXPOSE 22
