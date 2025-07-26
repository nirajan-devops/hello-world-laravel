# Stage 1: Builder
FROM php:8.2-fpm-alpine AS builder

# Set working directory
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
    zip \
    unzip \
    curl \
    git \
    g++ \
    make \
    autoconf

RUN docker-php-ext-configure zip
RUN docker-php-ext-install pdo pdo_mysql mbstring zip intl xml

# Install Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Copy app files
COPY . .

# Setup Laravel for production build
COPY .env.example .env

# Ensure cache dirs exist
RUN mkdir -p storage bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache

# Install PHP dependencies (with dev for testing)
RUN composer install --no-interaction --prefer-dist

# Generate app key and config cache
RUN php artisan key:generate \
    && php artisan config:cache

# Optionally run tests
# RUN ./vendor/bin/phpunit

# Stage 2: Production Image
FROM php:8.2-fpm-alpine

# Set working directory
WORKDIR /var/www

# Install prod system deps and PHP extensions
RUN apk add --no-cache \
    bash \
    libpng-dev \
    libjpeg-turbo-dev \
    libzip-dev \
    icu-dev \
    oniguruma-dev \
    libxml2-dev \
    zip \
    unzip \
    curl \
    git \
    g++ \
    make \
    autoconf

RUN docker-php-ext-configure zip
RUN docker-php-ext-install pdo pdo_mysql mbstring zip intl xml

# Install Composer again (in production)
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Copy only necessary files from builder
COPY --from=builder /var/www /var/www

# Re-cache Laravel config
RUN php artisan config:cache

# Set proper permissions
RUN chmod -R 775 storage bootstrap/cache

EXPOSE 9000
CMD ["php-fpm"]
