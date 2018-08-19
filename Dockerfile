FROM centos:7

# Set environment
ENV DEBIAN_FRONTEND noninteractive
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8
ENV TZ=America/New_York
ENV SCREEN_RESOLUTION 1024x768
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

ADD . /opt/octave-enable64
WORKDIR /opt/octave-enable64

# Update CentOS 7
RUN yum update -y && yum upgrade -y && \
# Install EPEL and CentOS SCLo RH Repository
    yum install -y epel-release centos-release-scl-rh && \
    yum --enablerepo=centos-sclo-rh-testing install -y devtoolset-3-gcc \
                                                       devtoolset-3-gcc-c++ \
                                                       devtoolset-3-gcc-gfortran \
# Install packages
RUN yum install -y \
      yum-utils \
      ca-certificates \
      curl \
      unzip \
      cmake \
      git \
      make \
      wget \
      vim \
      bc \
      file \
      perl \
      tcsh \
      tmux \
      patch \
      qt5-qtbase-devel \
      mesa-libOSMesa-devel \
      gl2ps-devel \
      qhull-devel \
      java-1.8.0-openjdk-devel \
      qt-devel \
      libcurl-devel \
      freetype-devel \
      bzip2-devel \
      atlas-devel \
      libsndfile-devel \
      portaudio-devel \
      GraphicsMagick-c++-devel \
      lapack64-devel \
      libblas-dev \
      libatlas-dev \
      liblapack-dev \
      freeglut-devel \
      gnuplot \
      fltk-devel \
      readline-devel \
      hdf5-devel \
      fftw-devel \
      libstdc++-static \
      glpk-devel \
      pcre-devel \
      systemd \
      units \
      ghostscript \
      python-devel \
      openssl-devel \
      libtool \
      automake \
      autoconf \
      dh-autoreconf \
      nettle-devel \
      zlib-devel && \
# Fix for an Octave 4.2.1 error
    ln -s /usr/lib64/atlas/libtatlas.so /usr/lib64/libatlas.so && \
# Install packages for Octave
    yum --enablerepo=epel-testing install -y plotutils && \
    yum --enablerepo=remi install -y gd-last && \
    yum install -y chrome-deps-stable && \
    # Manually install libraries needed for Octave
    wget --progress=bar:force -O /tmp/transfig-3.2.5d-13.el7.x86_64.rpm http://mirror.centos.org/centos/7/os/x86_64/Packages/transfig-3.2.5d-13.el7.x86_64.rpm  && \
    rpm -i /tmp/transfig-3.2.5d-13.el7.x86_64.rpm  && \
    rm -f /tmp/transfig-3.2.5d-13.el7.x86_64.rpm && \
    wget --progress=bar:force -O /tmp/libEMF-1.0.4-1.el6.x86_64.rpm http://mirror.centos.org/centos/6/os/x86_64/Packages/libEMF-1.0.4-1.el6.x86_64.rpm && \
    rpm -i /tmp/libEMF-1.0.4-1.el6.x86_64.rpm && \
    rm -f /tmp/libEMF-1.0.4-1.el6.x86_64.rpm && \
    wget --progress=bar:force -O /tmp/pstoedit-3.73-3.fc29.x86_64.rpm http://dl.fedoraproject.org/pub/fedora/linux/development/rawhide/Everything/x86_64/os/Packages/p/pstoedit-3.73-3.fc29.x86_64.rpm && \
    rpm -i /tmp/pstoedit-3.73-3.fc29.x86_64.rpm && \
    rm -f /tmp/pstoedit-3.73-3.fc29.x86_64.rpm && \
# Clean cache and other empty folders
    yum clean all && \
    rm -rf /var/lib/yum/* /var/cache/yum/* /tmp/* /var/tmp/* /boot /media /mnt /srv && \
    rm -rf ~/.cache/pip && \
    chmod 777 /opt && chmod a+s /opt
 
# Install Octave 4.2.1
RUN echo "Installing Ocatve 4.2.1..." && \
    export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk && \
    cd /opt/octave-enable64 && \
    scl enable devtoolset-3 -- make -j$(nproc) && \
    alias octave="/usr/local/bin/octave" && \
    echo "alias octave='/usr/local/bin/octave'" >> ~/.bashrc && \
# Install Octave packages
    echo "Installing Octave packages..." && \
    octave --no-gui --eval "pkg install -verbose -forge general" && \
    octave --no-gui --eval "pkg install -verbose -forge control" && \
    octave --no-gui --eval "pkg install -verbose -forge image" && \
    octave --no-gui --eval "pkg install -verbose -forge nan" && \
    octave --no-gui --eval "pkg install -verbose -forge signal" && \
    octave --no-gui --eval "pkg install -verbose -forge io" && \
    octave --no-gui --eval "pkg install -verbose -forge statistics" && \
    octave --no-gui --eval "pkg install -verbose -forge miscellaneous" && \
    octave --no-gui --eval "pkg install -verbose -forge struct" && \
    octave --no-gui --eval "pkg install -verbose -forge optim"

# Create Octave Sym Links
# Link octave install to /usr/bin
RUN ln -fs /usr/local/bin/octave-4.2.1 /usr/bin/octave && \
    ln -fs /usr/local/bin/octave-config-4.2.1 /usr/bin/octave-config && \
    ln -fs /usr/local/bin/octave-cli-4.2.1 /usr/bin/octave-cli && \
    ln -fs /usr/local/bin/mkoctfile-4.2.1 /usr/bin/mkoctfile && \
# Link octave install to /opt/Octave
    ln -fs /usr/local/bin/octave-4.2.1 /opt/Octave && \
    ln -fs /usr/local/bin/octave-config-4.2.1 /opt/Octave && \
    ln -fs /usr/local/bin/octave-cli-4.2.1 /opt/Octave && \
    ln -fs /usr/local/bin/mkoctfile-4.2.1 /opt/Octave && \
# Create directory in $TOOLS for octave packages and libraries and add sym links
    mkdir -p /opt/octavepkg && \
    ln -fs /usr/local/share/octave/packages /opt/octavepkg && \
    mkdir -p /opt/olib && \
    ln -fs /bin/epstool /opt/olib && \
    ln -sf /bin/fig2dev /opt/olib && \
    ln -sf /bin/pstoedit /opt/olib && \
    ln -sf /usr/bin/hdf5 /opt/olib && \
# Clear yum cache and other empty folders
    yum clean all && \
    rm -rf /var/lib/yum/lists/* /var/cache/yum/ /tmp/* /var/tmp/* /boot /media /mnt /srv && \
    rm -rf ~/.cache/pip

CMD ["bash"]
