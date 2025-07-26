# Stage 1: Builder
FROM php:8.2-fpm-alpine AS builder

WORKDIR /var/www

# Install system dependencies and PHP extensions
RUN apk add --no-cache \
    bash \
    libpng-dev \
    libjpeg-turbo-dev \
    libzip-dev \
    icu-dev \
    oniguruma-dev \
    libxml2-dev \
    sqlite \
    sqlite-dev \
    zip \
    unzip \
    curl \
    git \
    g++ \
    make \
    autoconf

RUN docker-php-ext-configure zip
RUN docker-php-ext-install pdo pdo_mysql pdo_sqlite mbstring zip intl xml

# Install Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Copy app files
COPY . .

# Prepare Laravel
COPY .env.example .env

RUN mkdir -p storage bootstrap/cache database \
    && touch database/database.sqlite \
    && chmod -R 775 storage bootstrap/cache database

RUN composer install --no-interaction --prefer-dist

RUN php artisan key:generate \
    && php artisan config:cache

# Stage 2: Production Image
FROM php:8.2-fpm-alpine

WORKDIR /var/www

# Install prod system dependencies and PHP extensions
RUN apk add --no-cache \
    bash \
    libpng-dev \
    libjpeg-turbo-dev \
    libzip-dev \
    icu-dev \
    oniguruma-dev \
    libxml2-dev \
    sqlite \
    sqlite-dev \
    zip \
    unzip \
    curl \
    git \
    g++ \
    make \
    autoconf

RUN docker-php-ext-configure zip
RUN docker-php-ext-install pdo pdo_mysql pdo_sqlite mbstring zip intl xml

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Copy built app from builder
COPY --from=builder /var/www /var/www

# Set correct permissions
RUN chmod -R 775 storage bootstrap/cache database

RUN php artisan config:cache

EXPOSE 8000
CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=8000"]
