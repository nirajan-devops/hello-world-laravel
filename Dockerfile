# ──────────────────────────────────────────────────────────────────────────────
# Stage 1: Build and test Laravel app
# ──────────────────────────────────────────────────────────────────────────────
FROM php:8.2-fpm-alpine AS builder

# Set working directory
WORKDIR /var/www

# Install system dependencies
RUN apk add --no-cache \
    git \
    curl \
    zip \
    unzip \
    libpng \
    libpng-dev \
    oniguruma-dev \
    libxml2-dev \
    icu-dev \
    zlib-dev \
    g++ \
    make \
    autoconf \
    bash

# Install PHP extensions
RUN docker-php-ext-install pdo pdo_mysql mbstring zip xml intl

# Install Composer
COPY --from=composer:2.7 /usr/bin/composer /usr/bin/composer

# Copy only composer files and install dependencies with dev tools
COPY composer.json composer.lock ./
RUN composer install --no-interaction --prefer-dist

# Copy the rest of the application
COPY . .

# Ensure .env exists and cache dirs are writable
COPY .env.example .env
RUN chmod -R 775 storage bootstrap/cache

# Set application key and cache config
RUN php artisan key:generate \
 && php artisan config:cache

# Run tests
RUN ./vendor/bin/phpunit

# ──────────────────────────────────────────────────────────────────────────────
# Stage 2: Production-ready image
# ──────────────────────────────────────────────────────────────────────────────
FROM php:8.2-fpm-alpine AS production

# Set working directory
WORKDIR /var/www

# Install system dependencies
RUN apk add --no-cache \
    curl \
    zip \
    unzip \
    libpng \
    libpng-dev \
    oniguruma-dev \
    libxml2-dev \
    icu-dev \
    zlib-dev \
    bash

# Install PHP extensions
RUN docker-php-ext-install pdo pdo_mysql mbstring zip xml intl

# Install Composer
COPY --from=composer:2.7 /usr/bin/composer /usr/bin/composer

# Copy only composer files and install prod-only dependencies
COPY composer.json composer.lock ./
COPY .env.example .env
RUN mkdir -p storage bootstrap/cache \
 && chmod -R 775 storage bootstrap/cache \
 && composer install --no-dev --no-interaction --prefer-dist --optimize-autoloader

# Copy application code (excluding vendor from builder)
COPY . .

# Cache configuration (optional in prod)
RUN php artisan config:cache

# Expose port (php-fpm default)
EXPOSE 9000

# Start PHP-FPM
CMD ["php-fpm"]
