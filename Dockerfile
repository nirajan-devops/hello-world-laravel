# Stage 1: Test and Build
FROM php:8.2-fpm AS builder

# Install dependencies
RUN apt-get update && apt-get install -y \
    unzip git curl zip libzip-dev libpng-dev libonig-dev libxml2-dev \
    && docker-php-ext-install pdo pdo_mysql zip gd

WORKDIR /var/www

# Copy app files
COPY . .

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Install PHP deps
RUN composer install --no-interaction --prefer-dist --optimize-autoloader

# Set env and cache config
COPY .env.example .env
RUN php artisan key:generate
RUN php artisan config:cache

# Run tests
RUN ./vendor/bin/phpunit

# Stage 2: Final clean image
FROM php:8.2-fpm

WORKDIR /var/www

# Install PHP extensions again (required for runtime)
RUN apt-get update && apt-get install -y \
    unzip git curl zip libzip-dev libpng-dev libonig-dev libxml2-dev \
    && docker-php-ext-install pdo pdo_mysql zip gd

# Copy files from build image
COPY --from=builder /var/www /var/www

EXPOSE 9000
CMD ["php-fpm"]
