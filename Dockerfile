FROM php:7.1-fpm-alpine

MAINTAINER sadoknet@gmail.com
ENV DEBIAN_FRONTEND=noninteractive

RUN echo -e '@edgunity http://nl.alpinelinux.org/alpine/edge/community\n@edge http://nl.alpinelinux.org/alpine/edge/main\n@testing http://nl.alpinelinux.org/alpine/edge/testing' >> /etc/apk/repositories

RUN \
    apk add --update nginx supervisor zip unzip  \
    imagemagick@edge libwebp gcc g++ nasm make wget vim git shadow@edgunity bash

#PHP7 dependencies
RUN docker-php-ext-install opcache

#install MozJPEG
RUN \
    wget "https://github.com/mozilla/mozjpeg/releases/download/v3.2/mozjpeg-3.2-release-source.tar.gz" && \
    tar xvf "mozjpeg-3.2-release-source.tar.gz" && \
    cd mozjpeg && \
    ./configure && \
    make && \
    make install

#facedetect
#1 OpenCV
RUN apk add --update \
  bash@edge \
  python2@edge \
  python2-dev@edge \
  python3@edge \
  python3-dev@edge \
  make \
  cmake \
  gcc \
  g++ \
  pkgconf \
  py-pip \
  build-base \
  gsl \
  libavc1394-dev  \
  libtbb@testing  \
  libtbb-dev@testing   \
  libjpeg  \
  libjpeg-turbo-dev \
  libpng-dev \
  libjasper \
  libdc1394-dev \
  clang-dev \
  clang \
  tiff-dev \
  libwebp-dev@edge \
  py-numpy-dev@edgunity \
  py-scipy-dev@testing \
  openblas-dev@edgunity \
  linux-headers

ENV CC /usr/bin/clang
ENV CXX /usr/bin/clang++

RUN mkdir -p /opt && cd /opt && \
  wget https://github.com/opencv/opencv/archive/3.1.0.zip && \
  unzip 3.1.0.zip && \
  cd /opt/opencv-3.1.0 && \
  mkdir build && \
  cd build && \
  cmake -D CMAKE_BUILD_TYPE=RELEASE -D CMAKE_INSTALL_PREFIX=/usr/local -D WITH_FFMPEG=NO \
  -D WITH_IPP=NO -D WITH_OPENEXR=NO .. && \
  make VERBOSE=1 && \
  make && \
  make install

RUN ln -s /var/www/html/opencv-3.1.0/build/lib/python3/cv2.cpython-36m-x86_64-linux-gnu.so /usr/lib/python3.6/site-packages/cv2.so
RUN ln /dev/null /dev/raw1394

#2 Facedetect lib
RUN cd /var && \
    git clone https://github.com/wavexx/facedetect.git && \
    chmod +x /var/facedetect/facedetect && \
    ln -s /var/facedetect/facedetect /usr/local/bin/facedetect

#phantomjs
RUN \
    mkdir /tmp/phantomjs && \
    curl -L https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-2.1.1-linux-x86_64.tar.bz2 \
        | tar -xj --strip-components=1 -C /tmp/phantomjs && \
    mv /tmp/phantomjs/bin/phantomjs /usr/local/bin

#composer
RUN \
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

#copy etc/
COPY resources/etc/ /etc/

COPY .    /var/www/html

WORKDIR /var/www/html

#add www-data + mdkdir var folder
RUN usermod -u 1000 www-data && \
    mkdir -p /var/www/html/var && \
    chown -R www-data:www-data /var/www/html/var && \
    mkdir -p var/cache/ var/log/ var/sessions/ web/uploads/.tmb && \
    chown -R www-data:www-data var/  web/uploads/ && \
    chmod 777 -R var/  web/uploads/

RUN rm -rf /var/cache/apk/*



EXPOSE 80

ENTRYPOINT ["supervisord", "--nodaemon", "--configuration", "/etc/supervisord/supervisord.conf"]
