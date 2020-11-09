FROM nvidia/cuda:10.0-cudnn7-devel-ubuntu18.04

ENV CMAKE_URI https://cmake.org/files/v3.13/cmake-3.13.2-Linux-x86_64.tar.gz

RUN rm -rf /var/lib/apt/lists/* \
    /etc/apt/sources.list.d/cuda.list \
    /etc/apt/sources.list.d/nvidia-ml.list && \
    sed -i "s@http://.*archive.ubuntu.com@http://mirrors.huaweicloud.com@g" /etc/apt/sources.list && \
    sed -i "s@http://.*security.ubuntu.com@http://mirrors.huaweicloud.com@g" /etc/apt/sources.list && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        cmake \
        wget \
        git \
        vim \
        fish \
        openssl \
        libssl-dev \
        libc6-dev \ 
        gcc \
        zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm tk-dev \
        libsparsehash-dev && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        software-properties-common && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        libboost-all-dev && \    
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        python3 python3-dev python3-numpy python3-pip && \        
    ldconfig && \    
    apt-get clean && \
    apt-get autoremove && \
    rm -rf /var/lib/apt/lists/* /tmp/* ~/*

RUN wget -qc ${CMAKE_URI} && \
    tar zxf cmake-3.13.2-Linux-x86_64.tar.gz && \
    mv cmake-3.13.2-Linux-x86_64 /opt/cmake-3.13.2 && \
    ln -sf /opt/cmake-3.13.2/bin/* /usr/bin/ && \
    rm cmake-3.13.2-Linux-x86_64.tar.gz

RUN python3 -m pip --no-cache-dir install pip -U --trusted-host https://mirrors.huaweicloud.com -i https://mirrors.huaweicloud.com/repository/pypi/simple && \
    python3 -m pip --no-cache-dir install --upgrade --trusted-host https://mirrors.huaweicloud.com -i https://mirrors.huaweicloud.com/repository/pypi/simple \
        setuptools wheel && \
    python3 -m pip --no-cache-dir install --upgrade --trusted-host https://mirrors.huaweicloud.com -i https://mirrors.huaweicloud.com/repository/pypi/simple \
        numpy jupyter ipython seaborn psutil flask shapely pyopengl scikit-image scipy numba pillow==6.2.2 pybind11 matplotlib fire tensorboardX protobuf opencv-python && \
    python3 -m pip --no-cache-dir install --upgrade --trusted-host https://mirrors.huaweicloud.com -i https://mirrors.huaweicloud.com/repository/pypi/simple \
        torch==1.3.1 torchvision==0.4.2 

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        sudo wget curl git ssh                                  \
    && rm -rf /var/lib/apt/lists/*                              \      
    && useradd -m torcher                                       \
    && usermod -s /bin/bash torcher                             \
    && echo 'torcher:torcher' | chpasswd                        \ 
    && chmod u+w /etc/sudoers                                   \
    && echo "torcher ALL=(ALL:ALL) ALL" >> /etc/sudoers         \
    && chmod u-w /etc/sudoers

WORKDIR /home/torcher

ADD home /home/torcher

RUN cd spconv && \
    python3 setup.py bdist_wheel && \
    python3 -m pip install ./dist/spconv-1.2.1-cp36-cp36m-linux_x86_64.whl && \
    echo "export PYTHONPATH=$PYTHONPATH:/home/torcher/second.pytorch/ " >> /home/torcher/.bashrc && \
    mkdir -p /home/torcher/data && \
    chown -R torcher:torcher /home/torcher/spconv && \
    chown -R torcher:torcher /home/torcher/second.pytorch && \
    chown -R torcher:torcher /home/torcher/data

USER torcher

ENV NUMBAPRO_CUDA_DRIVER=/usr/lib/x86_64-linux-gnu/libcuda.so
ENV NUMBAPRO_NVVM=/usr/local/cuda/nvvm/lib64/libnvvm.so
ENV NUMBAPRO_LIBDEVICE=/usr/local/cuda/nvvm/libdevice

VOLUME [ "/root/dataset" ]
VOLUME [ "/root/data"]

EXPOSE 8888

CMD ["/bin/bash"]

# Test
# docker run -it --rm -p 8888:8888 kevinlad/second.pytorch:latest
# > python -m jupyter notebook --port 8888 --no-browser --ip=0.0.0.0 --allow-root" ]

# data
#   - config/all.fhd.config
#   - model_voxenet/ss_100
# dataset
#   - nuscene
#     - v1.0-trainval
#     - v1.0-mini
#   - kitti  