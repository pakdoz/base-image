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
RUN apk add --update \
    python3 python3-dev py-pip build-base ffmpeg-libs musl cairo libdc1394 libgcc gtk+3.0 gdk-pixbuf glib \
    libgomp libgphoto2 gst-plugins-base1 gstreamer1 libjpeg-turbo libpng libstdc++ tiff zlib \
    musl libgcc opencv-libs libstdc++ \
    jasper-libs@edge \
    py-numpy@edgunity \
    openexr@edgunity \
    libwebp@edge \
    ilmbase@edgunity \
    opencv@testing

RUN apk add --update opencv-dev@testing
RUN pip3 install --upgrade pip
RUN pip3 install --user opencv-python  
RUN pip install numpy opencv-python

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
