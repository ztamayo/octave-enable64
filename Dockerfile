FROM ztamayo/mnap_os:octave
WORKDIR /opt/Octave/octave-enable64
ADD . .
RUN yum install -y \
      automake \
      autoconf
RUN scl enable devtoolset-3 -- make -j$(nproc)
