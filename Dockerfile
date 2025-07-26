# Stage 1: Build and test
FROM php:8.2-fpm-alpine AS builder

# System deps
RUN apk add --no-cache bash libpng-dev libzip-dev zip unzip curl git

# PHP extensions
RUN docker-php-ext-install pdo pdo_mysql zip

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /var/www

# Copy everything
COPY . .

# Install dependencies
RUN composer install --prefer-dist --no-dev --no-interaction --optimize-autoloader

# Set env
COPY .env.example .env

# Generate app key
RUN php artisan key:generate

# Cache config
RUN chmod -R 775 storage bootstrap/cache \
 && php artisan config:cache

# Run tests
RUN ./vendor/bin/phpunit


# Stage 2: Production image
FROM php:8.2-fpm-alpine

RUN apk add --no-cache libpng libzip bash curl

# PHP extensions
RUN docker-php-ext-install pdo pdo_mysql zip

# Set working dir
WORKDIR /var/www

# Copy app from builder stage
COPY --from=builder /var/www /var/www

# Set correct permissions
RUN chmod -R 775 storage bootstrap/cache

CMD ["php-fpm"]
