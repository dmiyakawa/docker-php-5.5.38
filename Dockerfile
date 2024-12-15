FROM debian:bookworm
LABEL Name=dockerphp55 Version=0.0.1

# RUN apt-get -y update && apt-get install -y fortunes
# CMD ["sh", "-c", "/usr/games/fortune -a | cowsay"]

WORKDIR /root

COPY bison-2.7.1.tar.gz \
    icu-60.3.zip \
    php-5.5.38.tar.bz2 110-glibc-change-work-around.patch \
    mysql-apt-config_0.8.33-1_all.deb \
    bzip2-1.0.7.tar.gz \
    ./

# lsb-release libaio1 wget -> mysql

RUN apt-get -y update \
    && apt-get install -y \
    build-essential autoconf libtool lsb-release \
    unzip git libaio1 wget \
    libtiff-dev libxml2-dev libxpm-dev libpam-dev \
    libsqlite3-dev \
    libpq-dev \
    libfcgi-dev \
    libfcgi0ldbl \
    libjpeg-dev \
    libpng-dev \
    libssl-dev \
    libxml2-dev \
    libcurl4-openssl-dev \
    libxpm-dev \
    libgd-dev \
    libfreetype6-dev \
    libxslt1-dev \
    libpspell-dev \
    libzip-dev

# コーナーケースで面倒な可能性があるので上のRUNと繋いだ方が安心は安心
RUN dpkg -i mysql-apt-config_0.8.33-1_all.deb \
    && apt-get -y update \
    && apt-get install -y \
    libmysql++-dev default-mysql-client default-mysql-server 

RUN tar xvf bison-2.7.1.tar.gz \
    && unzip icu-60.3.zip \
    && tar xvf php-5.5.38.tar.bz2 \
    && tar xvf bzip2-1.0.7.tar.gz

# patchのバックグラウンドについては https://github.com/ARM-software/arm-enterprise-acs/issues/73 
RUN cd bison-2.7.1 && cat ../110-glibc-change-work-around.patch | git apply - \
    && ./configure --prefix=/opt/bison-2.7.1 && make -j4 && make install

RUN cd icu-release-60-3/icu4c/source \
    && CXXFLAGS=-std=c++11 CFLAGS=-std=c11 ./runConfigureICU Linux --prefix=/opt/icu4c-60.3 \
    && make -j4 \
    && make install \
    && ldconfig /opt/icu4c-60.3/lib/

#
RUN ln -s /usr/include/x86_64-linux-gnu/curl /usr/include/curl

# https://wiki.php.net/internals/windows/stepbystepbuild
# https://qiita.com/shadowhat/items/ec8b2b8135b65400608b
RUN cd php-5.5.38 \
    && ./configure --enable-cli --enable-intl --enable-mbstring --enable-fpm \
        --with-mysqli  \
        --with-pdo-mysql \
        --with-fpm-user=www-data \
        --with-fpm-group=www-data \
        --with-icu-dir=/opt/icu4c-60.3 \
        --with-xsl \
        --with-zlib \
        --prefix=/opt/php-5.3.38 \
    && make -j4 \
    && make install

# TODO: phpでmake testが一部失敗している。大丈夫か確認する
# - zend multibyte (8) [ext/mbstring/tests/zend_multibyte-08.phpt] (warn: XFAIL section but test passes)
# - Phar: bug #69958: Segfault in Phar::convertToData on invalid file [ext/phar/tests/bug69958.phpt] (warn: XFAIL section but test passes)
# - Bug #70172 - Use After Free Vulnerability in unserialize() [ext/standard/tests/serialize/bug70172.phpt] (warn: XFAIL section but test passes)
# TODO: まだphpのモジュール類が入っていないので必要なものをインストールする
# TODO: できれば-devパッケージではなく当時のライブラリにする（動作しないか、動作しても挙動がずれる可能性があるため）