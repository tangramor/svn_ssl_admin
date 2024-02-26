FROM node:alpine as builder

WORKDIR /app

RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories && \
    apk add git && \
    npm config set registry https://registry.npmmirror.com/ && \
    git clone https://gitee.com/witersen/SvnAdminV2.0.git && \
    sed -i 's/chmod 777/chmod 755/g' `grep 'chmod 777' -rl /app/SvnAdminV2.0/*` && \
    cd SvnAdminV2.0/01.web/ && \
    npm update && \
    npm run build && \
    ls -l

FROM centos:7

LABEL org.opencontainers.image.authors="tangramor<tangramor@gmail.com>"

ADD files /
COPY --from=builder /app/SvnAdminV2.0/02.php/ /app/
COPY --from=builder /app/SvnAdminV2.0/01.web/dist/* /app/
COPY --from=builder /app/SvnAdminV2.0/03.cicd/svnadmin_docker/data/ /data.template/

WORKDIR /app

RUN localedef -c -i en_US -f UTF-8 C.UTF-8 && \
    echo 'LANG="C.UTF-8"' >> /etc/sysconfig/i18n && \
    echo 'LC_ALL="C.UTF-8"' >> /etc/sysconfig/i18n && \
    echo 'export LANG="C.UTF-8"' >> /etc/profile && \
    echo 'export LC_ALL="C.UTF-8"' >> /etc/profile && \
    yum install -y centos-release-scl epel-release yum-utils && \
    rpm -Uvh https://mirrors.aliyun.com/remi/enterprise/remi-release-7.rpm && \
    yum-config-manager --enable remi-php74 && \
    yum install -y sclo-subversion19 sclo-subversion19-mod_dav_svn sclo-subversion19-subversion-tools \
        wget unzip which httpd24-httpd httpd24-mod_ssl perl-CPAN perl-Module-Build \
        perl-Net-SMTP-SSL perl-Net-SMTPS perl-HTML-Entities-Numbered perl-Pod-Usage  \
        net-tools hostname inotify-tools supervisor php php-common php-cli php-fpm \
        php-json php-mysqlnd php-mysql php-pdo php-process php-json php-gd php-bcmath \
        php-ldap php-mbstring cyrus-sasl cyrus-sasl-lib cyrus-sasl-plain && \
    yum clean all && \
    rm -rf /opt/rh/httpd24/root/var/www/html && \
    ln -s /app /opt/rh/httpd24/root/var/www/html && \
    chown -R apache:apache /app && \
    /usr/bin/cp -pf /etc/httpd/conf.d/* /opt/rh/httpd24/root/etc/httpd/conf.d/ && \
    /usr/bin/cp -pf /etc/httpd/modules/libphp7* /opt/rh/httpd24/root/etc/httpd/modules/ && \
    /usr/bin/cp -pf /etc/httpd/conf.modules.d/15-php.conf /opt/rh/httpd24/root/etc/httpd/conf.modules.d/ && \
    chmod +x /bootstrap.sh
    # cpan -i SVN::Notify && \
    # cpan -i Net::SMTP::TLS

ENTRYPOINT ["/bootstrap.sh"]