################################################################################
##
##  Building GNU Octave with 64-bit libraries on GNU Linux
##
################################################################################

## Credit to https://github.com/octave-de/GNU-Octave-enable-64

# build libraries like "libopenblas_Octave64.so"
SONAME_SUFFIX ?= Octave64
# specify root directory (default: current directory)
ROOT_DIR      ?= /usr/local/

# create necessary file structure
SRC_CACHE       = $(ROOT_DIR)/source-cache
BUILD_DIR       = $(ROOT_DIR)/build
INSTALL_DIR     = $(ROOT_DIR)/install
LD_LIBRARY_PATH = $(INSTALL_DIR)/lib64
IGNORE := $(shell mkdir -p $(SRC_CACHE) $(BUILD_DIR) $(INSTALL_DIR))

# if no SONAME suffix is wanted, leave everything blank
ifeq ($(strip $(SONAME_SUFFIX)),)
_SONAME_SUFFIX =
else
_SONAME_SUFFIX = _$(SONAME_SUFFIX)
endif

# Set GCC version
CC=gcc
CXX=g++
FC=gfortran

# small helper function to search for a library name pattern for replacing
fix_soname = grep -Rl '$(2)' $(BUILD_DIR)/$(1) | xargs sed -i "s/$(2)/$(3)/g";

.PHONY: clean

.EXPORT_ALL_VARIABLES:

all: octave

clean:
	rm -Rf $(BUILD_DIR) $(INSTALL_DIR) $(SRC_CACHE)

################################################################################
#
#   OpenBLAS  - http://www.openblas.net
#
#   The OpenBLAS library will be build from a specific version, ensuring
#   64 bit indices.
#
################################################################################

OPENBLAS_VER = 0.2.20

$(SRC_CACHE)/openblas-$(OPENBLAS_VER).zip:
	@echo -e "\n>>> Download OpenBLAS <<<\n"
	cd $(SRC_CACHE) && wget -q \
	"https://github.com/xianyi/OpenBLAS/archive/v$(OPENBLAS_VER).zip" \
	                && mv v$(OPENBLAS_VER).zip $@

$(INSTALL_DIR)/lib/libopenblas$(_SONAME_SUFFIX).so: \
	$(SRC_CACHE)/openblas-$(OPENBLAS_VER).zip
	@echo -e "\n>>> Unzip to $(BUILD_DIR)/openblas <<<\n"
	cd $(BUILD_DIR) && unzip -q $< \
	                && mv OpenBLAS-$(OPENBLAS_VER) openblas
	cd $(BUILD_DIR)/openblas \
	&& $(MAKE) BINARY=64 INTERFACE64=1 LIBNAMESUFFIX=$(SONAME_SUFFIX) \
	&& $(MAKE) install PREFIX=$(INSTALL_DIR) LIBNAMESUFFIX=$(SONAME_SUFFIX)

openblas: $(INSTALL_DIR)/lib/libopenblas$(_SONAME_SUFFIX).so


################################################################################
#
#   SuiteSparse  - http://www.suitesparse.com
#
#   The SuiteSparse library will be build from a specific version, ensuring
#   64 bit indices and using the self compiled OpenBLAS.
#
################################################################################

SUITESPARSE_VER = 5.3.0

SUITESPARSE_LIBS = amd camd colamd ccolamd csparse cxsparse cholmod umfpack \
	spqr klu rbio ldl btf suitesparseconfig

$(SRC_CACHE)/suitesparse-$(SUITESPARSE_VER).tar.gz:
	@echo -e "\n>>> Download SuiteSparse <<<\n"
	cd $(SRC_CACHE) && wget -q \
	"http://faculty.cse.tamu.edu/davis/SuiteSparse/SuiteSparse-$(SUITESPARSE_VER).tar.gz" \
	                && mv SuiteSparse-$(SUITESPARSE_VER).tar.gz $@

$(INSTALL_DIR)/lib/libsuitesparseconfig$(_SONAME_SUFFIX).so: \
	$(SRC_CACHE)/suitesparse-$(SUITESPARSE_VER).tar.gz \
	$(INSTALL_DIR)/lib/libopenblas$(_SONAME_SUFFIX).so
	@echo -e "\n>>> Untar to $(BUILD_DIR)/suitesparse <<<\n"
	cd $(BUILD_DIR) && tar -xf $< \
	                && mv SuiteSparse suitesparse
	# fix library names
	$(foreach l,$(SUITESPARSE_LIBS), \
		$(call fix_soname,suitesparse,LIBRARY = lib$(l),LIBRARY = lib$(l)$(_SONAME_SUFFIX)))
	$(foreach l,$(SUITESPARSE_LIBS), \
		$(call fix_soname,suitesparse,\-l$(l)\ ,\-l$(l)$(_SONAME_SUFFIX)\ ))
	$(foreach l,$(SUITESPARSE_LIBS), \
		$(call fix_soname,suitesparse,\-l$(l)$$,\-l$(l)$(_SONAME_SUFFIX)\ ))
	# build and install library
	cd $(BUILD_DIR)/suitesparse \
	&& $(MAKE) library \
	           UMFPACK_CONFIG=-D'LONGBLAS=long' \
	           CHOLMOD_CONFIG=-D'LONGBLAS=long' \
	           LDFLAGS='-L$(INSTALL_DIR)/lib -L$(BUILD_DIR)/suitesparse/lib -L/opt/Octave/install/lib' \
	           BLAS="-lopenblas$(_SONAME_SUFFIX)" \
	           CMAKE_OPTIONS=-D'CMAKE_INSTALL_PREFIX=$(INSTALL_DIR)' \
	&& $(MAKE) install \
	           INSTALL=$(INSTALL_DIR) \
	           INSTALL_DOC=/tmp/doc \
	           UMFPACK_CONFIG=-D'LONGBLAS=long' \
	           CHOLMOD_CONFIG=-D'LONGBLAS=long' \
	           LDFLAGS='-L$(INSTALL_DIR)/lib -L$(BUILD_DIR)/suitesparse/lib -L/opt/Octave/install/lib' \
	           BLAS="-lopenblas$(_SONAME_SUFFIX)"

suitesparse: $(INSTALL_DIR)/lib/libsuitesparseconfig$(_SONAME_SUFFIX).so


################################################################################
#
#   QRUPDATE  - http://sourceforge.net/projects/qrupdate/
#
#   The QRUPDATE library will be build from a specific version, ensuring
#   64 bit indices and using the self compiled OpenBLAS.
#
################################################################################

QRUPDATE_VER = 1.1.2

QRUPDATE_CONFIG_FLAGS = \
  PREFIX=$(INSTALL_DIR) \
  LAPACK="" \
  LDFLAGS='-L$(INSTALL_DIR)/lib -L$(BUILD_DIR)/suitesparse/lib -L/opt/Octave/install/lib' \
  BLAS="-lopenblas$(_SONAME_SUFFIX)" \
  FFLAGS="-L$(INSTALL_DIR)/lib -fdefault-integer-8"

$(SRC_CACHE)/qrupdate-$(QRUPDATE_VER).tar.gz:
	@echo -e "\n>>> Download QRUPDATE <<<\n"
	cd $(SRC_CACHE) && wget -q \
	"http://downloads.sourceforge.net/project/qrupdate/qrupdate/1.2/qrupdate-$(QRUPDATE_VER).tar.gz"

$(INSTALL_DIR)/lib/libqrupdate$(_SONAME_SUFFIX).so: \
	$(SRC_CACHE)/qrupdate-$(QRUPDATE_VER).tar.gz \
	$(INSTALL_DIR)/lib/libopenblas$(_SONAME_SUFFIX).so
	@echo -e "\n>>> Untar to $(BUILD_DIR)/qrupdate <<<\n"
	cd $(BUILD_DIR) && tar -xf $< \
	                && mv qrupdate-$(QRUPDATE_VER) qrupdate
	# fix library name
	$(call fix_soname,qrupdate,libqrupdate,libqrupdate$(_SONAME_SUFFIX))
	# build and install library
	cd $(BUILD_DIR)/qrupdate \
	&& $(MAKE) test    $(QRUPDATE_CONFIG_FLAGS) \
	&& $(MAKE) install $(QRUPDATE_CONFIG_FLAGS)

qrupdate: $(INSTALL_DIR)/lib/libqrupdate$(_SONAME_SUFFIX).so


################################################################################
#
#   ARPACK  - https://github.com/opencollab/arpack-ng
#
#   The ARPACK library will be build from a specific version, ensuring
#   64 bit indices and using the self compiled OpenBLAS.
#
################################################################################

ARPACK_VER = 3.5.0

$(SRC_CACHE)/arpack-$(ARPACK_VER).tar.gz:
	@echo -e "\n>>> Download ARPACK <<<\n"
	cd $(SRC_CACHE) && wget -q \
	"https://github.com/opencollab/arpack-ng/archive/$(ARPACK_VER).tar.gz" \
	                && mv $(ARPACK_VER).tar.gz $@

$(INSTALL_DIR)/lib/libarpack$(_SONAME_SUFFIX).so: \
	$(SRC_CACHE)/arpack-$(ARPACK_VER).tar.gz \
	$(INSTALL_DIR)/lib/libopenblas$(_SONAME_SUFFIX).so
	@echo -e "\n>>> Untar to $(BUILD_DIR)/arpack <<<\n"
	cd $(BUILD_DIR) && tar -xf $< \
	                && mv arpack-ng-$(ARPACK_VER) arpack
	# build and install library
	cd $(BUILD_DIR)/arpack \
	&& ./bootstrap \
	&& ./configure --prefix=$(INSTALL_DIR) \
	               --libdir=$(INSTALL_DIR)/lib \
	               --with-blas='-L/opt/Octave/install/lib -lopenblas$(_SONAME_SUFFIX)' \
	               --with-lapack='' \
	               INTERFACE64=1 \
				   FC=/opt/rh/devtoolset-3/root/bin/gfortran \
	               LT_SYS_LIBRARY_PATH=$(INSTALL_DIR)/lib \
	               LDFLAGS='-L$(INSTALL_DIR)/lib' \
	               LIBSUFFIX='$(_SONAME_SUFFIX)' \
	&& $(MAKE) check \
	&& $(MAKE) install

arpack: $(INSTALL_DIR)/lib/libarpack$(_SONAME_SUFFIX).so


################################################################################
#
#   GNU Octave  - http://www.gnu.org/software/octave/
#
#   Build GNU Octave using --enable-64 and all requirements.
#
################################################################################

OCTAVE_VER = 4.4.1

LDSUITESPARSE = \
  '-lamd$(_SONAME_SUFFIX) \
   -lcamd$(_SONAME_SUFFIX) \
   -lcolamd$(_SONAME_SUFFIX) \
   -lccolamd$(_SONAME_SUFFIX) \
   -lcholmod$(_SONAME_SUFFIX) \
   -lcxsparse$(_SONAME_SUFFIX) \
   -lklu$(_SONAME_SUFFIX) \
   -lumfpack$(_SONAME_SUFFIX) \
   -lsuitesparseconfig$(_SONAME_SUFFIX)'

OCTAVE_CONFIG_FLAGS = \
  CPPFLAGS='-I$(INSTALL_DIR)/include' \
  LDFLAGS='-L$(INSTALL_DIR)/lib -L/opt/rh/devtoolset-3/root/lib/gcc/x86_64-redhat-linux/4.9.2' \
  #F77_INTEGER_8_FLAG='-fdefault-integer-8' \
  LD_LIBRARY_PATH='$(INSTALL_DIR)/lib' \
  --prefix=$(ROOT_DIR) \
  --libdir='$(INSTALL_DIR)/lib' \
  --enable-64 \
  --with-qt=5 \
  --with-pcre=/usr/lib64/libpcre.so \
  #--with-pcre-includedir=/usr/local/pcre/8.42/include \
  #--with-pcre-libdir=/usr/local/pcre/8.42/lib \
  --with-hdf5=/usr/lib64/libhdf5.so \
  #--with-hdf5-includedir=/usr/local/HDF5/1.10.1/include \
  #--with-hdf5-libdir=/usr/local/HDF5/1.10.1/lib \
  --with-lapack=/usr/lib64/liblapack.so  \
  --with-blas='-L/opt/Octave/install/lib -lopenblas$(_SONAME_SUFFIX)' \
  --with-fftw3=/usr/lib64/libfftw3.so \
  #--with-fftw3-libdir=/usr/local/FFTW/3.3.7/openmpi2.1.2-gcc4.8.5/lib/ \
  #--with-fftw3-includedir=/usr/local/FFTW/3.3.7/openmpi2.1.2-gcc4.8.5/include/ \
  --with-magick=GraphicsMagick \
  --with-qhull=/usr/lib64/libqhull.so \
  #--with-qhull-includedir=/usr/local/apps/octave/qhull-2015.2/include \
  #--with-qhull-libdir=/usr/local/apps/octave/qhull-2015.2/lib \
  --with-fltk=/usr/lib64/libfltk.so \
  #--with-fltk-prefix=/usr/local/apps/octave/fltk-1.3.4-2 \
  --with-suitesparseconfig='-lsuitesparseconfig$(_SONAME_SUFFIX)' \
  --with-amd='-lamd$(_SONAME_SUFFIX) \
              -lsuitesparseconfig$(_SONAME_SUFFIX)' \
  --with-camd='-lcamd$(_SONAME_SUFFIX) \
               -lsuitesparseconfig$(_SONAME_SUFFIX)' \
  --with-colamd='-lcolamd$(_SONAME_SUFFIX) \
                 -lsuitesparseconfig$(_SONAME_SUFFIX)' \
  --with-ccolamd='-lccolamd$(_SONAME_SUFFIX) \
                  -lsuitesparseconfig$(_SONAME_SUFFIX)' \
  #--with-cxsparse='-lcxsparse$(_SONAME_SUFFIX) \
                   #-lsuitesparseconfig$(_SONAME_SUFFIX)' \
  --with-cxsparse=/usr/local/install/lib/libcxsparse_Octave64.so \
  --with-glpk=/usr/lib64/libglpk.so \
  #--with-glpk-includedir=/usr/local/apps/octave/glpk-4.6.5/include \
  #--with-glpk-libdir=/usr/local/apps/octave/glpk-4.6.5/lib \
  --with-sundials_nvecserial=/usr/lib64/libsundials_nvecserial.so \
  --with-sundials_ida=/usr/lib64/libsundials_ida.so \
  #--with-sundials_nvecserial-includedir=/usr/local/apps/octave/sundials-3.1.0/include/ \
  #--with-sundials_nvecserial-libdir=/usr/local/apps/octave/sundials-3.1.0/lib \
  #--with-sundials_ida-includedir=/usr/local/apps/octave/sundials-3.1.0/include/ \
  #--with-sundials_ida-libdir=/usr/local/apps/octave/sundials-3.1.0/lib \
  --with-java-libdir=/usr/lib/jvm/jre-1.8.0-openjdk/lib/amd64/server \
  --with-java-includedir=/usr/lib/jvm/java-1.8.0-openjdk/include \
  --with-klu=$(LDSUITESPARSE) \
  #--with-klu-includedir=/usr/local/apps/octave/SuiteSparse-4.5.6/include \
  #--with-klu-libdir=/usr/local/apps/octave/SuiteSparse-4.5.6/lib \
  --with-cholmod=$(LDSUITESPARSE) \
  --with-umfpack=$(LDSUITESPARSE) \
  --with-qrupdate='-lqrupdate$(_SONAME_SUFFIX)' \
  --with-arpack='-larpack$(_SONAME_SUFFIX)'
  #--with-arpack-libdir=/usr/local/apps/octave/arpack-ng-3.5.0/lib

$(SRC_CACHE)/octave-$(OCTAVE_VER).tar.gz:
	@echo -e "\n>>> Download GNU Octave <<<\n"
	cd $(SRC_CACHE) && wget -q \
	  "https://ftp.gnu.org/gnu/octave/octave-$(OCTAVE_VER).tar.gz"

$(INSTALL_DIR)/bin/octave: $(SRC_CACHE)/octave-$(OCTAVE_VER).tar.gz \
	$(INSTALL_DIR)/lib/libopenblas$(_SONAME_SUFFIX).so \
	$(INSTALL_DIR)/lib/libsuitesparseconfig$(_SONAME_SUFFIX).so \
	$(INSTALL_DIR)/lib/libqrupdate$(_SONAME_SUFFIX).so \
	$(INSTALL_DIR)/lib/libarpack$(_SONAME_SUFFIX).so
	@echo -e "\n>>> Untar to $(BUILD_DIR)/octave <<<\n"
	cd $(BUILD_DIR) && tar -xf $< \
	                && mv octave-$(OCTAVE_VER) octave
	@echo -e "\n>>> Octave: configure (1/3) <<<\n"
	cd $(BUILD_DIR)/octave && ./configure $(OCTAVE_CONFIG_FLAGS)
	@echo -e "\n>>> Octave: build (2/3) <<<\n"
	cd $(BUILD_DIR)/octave && $(MAKE) install
	#@echo -e "\n>>> Octave: check (3/3) <<<\n"
	#cd $(BUILD_DIR)/octave && $(MAKE) check \
	                          LD_LIBRARY_PATH='$(INSTALL_DIR)/lib'

octave: $(INSTALL_DIR)/bin/octave
	@echo -e "\n\n"
	@echo -e " >>> Finished building GNU Octave with 64-bit libraries!!! <<<"
	@echo -e "\n  To start GNU Octave run:\n\n    $<\n\n"
