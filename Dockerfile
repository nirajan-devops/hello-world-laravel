# ------------------------------------
# STAGE 1 – Build & Test
# ------------------------------------
FROM php:8.2-fpm AS build

# System dependencies
RUN apt-get update && apt-get install -y \
    git unzip curl libpng-dev libonig-dev libxml2-dev zip libzip-dev \
    && docker-php-ext-install pdo pdo_mysql zip

# Install Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /var/www

# Copy project files
COPY . .

# Install PHP dependencies
RUN composer install --no-interaction --prefer-dist --optimize-autoloader

# Run Laravel tests
RUN php artisan key:generate \
 && php artisan config:cache \
 && ./vendor/bin/phpunit

# ------------------------------------
# STAGE 2 – Production-ready image
# ------------------------------------
FROM php:8.2-fpm AS production

# System dependencies
RUN apt-get update && apt-get install -y \
    libpng-dev libonig-dev libxml2-dev zip libzip-dev unzip \
    && docker-php-ext-install pdo pdo_mysql zip

# Set working directory
WORKDIR /var/www

# Copy app from builder stage, excluding vendor/bin/phpunit, .env, etc.
COPY --from=build /var/www /var/www

# Expose port
EXPOSE 9000

# Run PHP-FPM
CMD ["php-fpm"]
