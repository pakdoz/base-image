FROM php:7.1-fpm-alpine

MAINTAINER sadoknet@gmail.com
ENV DEBIAN_FRONTEND=noninteractive

RUN \
  	apk update && \
  	apk add --no-cache \
  	nginx supervisor zip unzip git wget \
	imagemagick libwebp imagemagick-dev

RUN \
	apk add --no-cache \
	python3 python3-dev py-pip autoconf yaml-dev nasm gcompat libsm

RUN echo 'manylinux1_compatible = True' > /usr/lib/python3.7/site-packages/_manylinux.py
RUN python -c 'import sys; sys.path.append(r"/_manylinux.py")'

RUN \
   apk add --virtual build-dependencies \
   build-base freetype-dev libpng-dev openblas-dev \
   gcc g++ make && \
   cd /var && \
       pip3 install numpy && \
       pip3 install opencv-python && \
       git clone https://github.com/flyimg/facedetect.git && \
       chmod +x /var/facedetect/facedetect && \
       ln -s /var/facedetect/facedetect /usr/local/bin/facedetect && \
    wget "https://github.com/mozilla/mozjpeg/releases/download/v3.2/mozjpeg-3.2-release-source.tar.gz" && \
       tar xvf "mozjpeg-3.2-release-source.tar.gz" && \
       rm mozjpeg-3.2-release-source.tar.gz && \
       cd mozjpeg && \
       ./configure && \
       make && \
       make install   && \
     pecl install imagick yaml-2.0.0

#&& \
 #     apk del build-dependencies


#opcache
RUN docker-php-ext-install opcache

#Smart Cropping pytihon plugin
RUN pip install git+https://github.com/flyimg/python-smart-crop

#install Yaml
RUN \
    echo "extension=imagick.so" > /usr/local/etc/php/conf.d/imagick.ini && \
    echo "extension=yaml.so" > /usr/local/etc/php/conf.d/yaml.ini

#RUN apk del build-dependencies

#composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

#disable output access.log to stdout
RUN sed -i -e 's#access.log = /proc/self/fd/2#access.log = /proc/self/fd/1#g'  /usr/local/etc/php-fpm.d/docker.conf

#copy etc/
COPY resources/etc/ /etc/

RUN rm -rf /etc/nginx/conf.d/default.conf
#
#WORKDIR /var/www/html
#
EXPOSE 80
#
ENTRYPOINT ["supervisord", "--nodaemon", "--configuration", "/etc/supervisord.conf"]