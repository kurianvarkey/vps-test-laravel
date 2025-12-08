FROM php:8.4-fpm-alpine

# Install system dependencies
RUN apk add --no-cache \
    nginx \
    supervisor \
    postgresql-dev \
    mysql-client \
    libzip-dev \
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    oniguruma-dev \
    libxml2-dev \
    curl-dev \
    zip \
    unzip \
    git

# Install PHP extensions
RUN docker-php-ext-install \
    pdo \
    pdo_mysql \
    pdo_pgsql \
    mbstring \
    zip \
    exif \
    pcntl \
    bcmath \
    gd \
    xml \
    curl

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /var/www/html

# Copy application files
COPY . .

# Install dependencies
RUN composer install --no-dev --optimize-autoloader --no-interaction

# Create ALL necessary directories with proper structure
RUN mkdir -p storage/framework/cache/data \
    && mkdir -p storage/framework/sessions \
    && mkdir -p storage/framework/views \
    && mkdir -p storage/logs \
    && mkdir -p storage/app/public \
    && mkdir -p bootstrap/cache

# Set ownership to www-data BEFORE setting permissions
RUN chown -R www-data:www-data /var/www/html

# Set proper permissions
RUN chmod -R 775 storage \
    && chmod -R 775 bootstrap/cache

# Nginx configuration
RUN rm -f /etc/nginx/http.d/default.conf && \
    echo 'server {' > /etc/nginx/http.d/laravel.conf && \
    echo '    listen 80;' >> /etc/nginx/http.d/laravel.conf && \
    echo '    server_name _;' >> /etc/nginx/http.d/laravel.conf && \
    echo '    root /var/www/html/public;' >> /etc/nginx/http.d/laravel.conf && \
    echo '    index index.php;' >> /etc/nginx/http.d/laravel.conf && \
    echo '    error_log /var/log/nginx/error.log;' >> /etc/nginx/http.d/laravel.conf && \
    echo '    access_log /var/log/nginx/access.log;' >> /etc/nginx/http.d/laravel.conf && \
    echo '    location / {' >> /etc/nginx/http.d/laravel.conf && \
    echo '        try_files $uri $uri/ /index.php?$query_string;' >> /etc/nginx/http.d/laravel.conf && \
    echo '    }' >> /etc/nginx/http.d/laravel.conf && \
    echo '    location ~ \.php$ {' >> /etc/nginx/http.d/laravel.conf && \
    echo '        fastcgi_pass 127.0.0.1:9000;' >> /etc/nginx/http.d/laravel.conf && \
    echo '        fastcgi_index index.php;' >> /etc/nginx/http.d/laravel.conf && \
    echo '        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;' >> /etc/nginx/http.d/laravel.conf && \
    echo '        include fastcgi_params;' >> /etc/nginx/http.d/laravel.conf && \
    echo '    }' >> /etc/nginx/http.d/laravel.conf && \
    echo '    location ~ /\.(?!well-known).* {' >> /etc/nginx/http.d/laravel.conf && \
    echo '        deny all;' >> /etc/nginx/http.d/laravel.conf && \
    echo '    }' >> /etc/nginx/http.d/laravel.conf && \
    echo '}' >> /etc/nginx/http.d/laravel.conf

# Supervisor configuration  
RUN echo '[supervisord]' > /etc/supervisord.conf && \
    echo 'nodaemon=true' >> /etc/supervisord.conf && \
    echo 'user=root' >> /etc/supervisord.conf && \
    echo 'logfile=/dev/stdout' >> /etc/supervisord.conf && \
    echo 'logfile_maxbytes=0' >> /etc/supervisord.conf && \
    echo '[program:php-fpm]' >> /etc/supervisord.conf && \
    echo 'command=php-fpm --nodaemonize' >> /etc/supervisord.conf && \
    echo 'autostart=true' >> /etc/supervisord.conf && \
    echo 'autorestart=true' >> /etc/supervisord.conf && \
    echo 'stdout_logfile=/dev/stdout' >> /etc/supervisord.conf && \
    echo 'stdout_logfile_maxbytes=0' >> /etc/supervisord.conf && \
    echo 'stderr_logfile=/dev/stderr' >> /etc/supervisord.conf && \
    echo 'stderr_logfile_maxbytes=0' >> /etc/supervisord.conf && \
    echo '[program:nginx]' >> /etc/supervisord.conf && \
    echo 'command=nginx -g "daemon off;"' >> /etc/supervisord.conf && \
    echo 'autostart=true' >> /etc/supervisord.conf && \
    echo 'autorestart=true' >> /etc/supervisord.conf && \
    echo 'stdout_logfile=/dev/stdout' >> /etc/supervisord.conf && \
    echo 'stdout_logfile_maxbytes=0' >> /etc/supervisord.conf && \
    echo 'stderr_logfile=/dev/stderr' >> /etc/supervisord.conf && \
    echo 'stderr_logfile_maxbytes=0' >> /etc/supervisord.conf

EXPOSE 80

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]