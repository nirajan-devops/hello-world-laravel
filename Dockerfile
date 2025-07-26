### Stage 1: Builder
FROM php:8.2-fpm-alpine AS builder

# Install system dependencies
RUN apk add --no-cache \
    git \
    curl \
    libpng-dev \
    libjpeg-turbo-dev \
    libzip-dev \
    oniguruma-dev \
    icu-dev \
    bash \
    libxml2-dev \
    zip \
    unzip

# PHP extensions
RUN docker-php-ext-install pdo pdo_mysql zip mbstring intl

# Install Composer
COPY --from=composer:2.7 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www

# Copy only manifest files and install dev dependencies
COPY composer.json composer.lock ./
RUN composer install --no-interaction --prefer-dist

# Copy full source
COPY . .

# Laravel setup
RUN cp .env.example .env \
 && php artisan key:generate \
 && chmod -R 775 storage bootstrap/cache \
 && php artisan config:cache \
 && ./vendor/bin/phpunit

---

### Stage 2: Production Image
FROM php:8.2-fpm-alpine AS production

# Install system dependencies again (required in prod too)
RUN apk add --no-cache \
    libpng \
    libjpeg-turbo \
    libzip \
    oniguruma \
    icu \
    libxml2 \
    zip \
    unzip

# PHP extensions again
RUN docker-php-ext-install pdo pdo_mysql zip mbstring intl

# Install Composer
COPY --from=composer:2.7 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www

# Copy only manifest files again
COPY composer.json composer.lock ./

# 🔥 This is the line that was failing before
RUN composer install --no-dev --no-interaction --prefer-dist --optimize-autoloader

# Now copy application code (except vendor)
COPY . .

# Laravel permissions & cache
RUN chmod -R 775 storage bootstrap/cache \
 && php artisan config:cache

EXPOSE 9000
CMD ["php-fpm"]
