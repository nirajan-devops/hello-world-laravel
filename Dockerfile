FROM php:8.2-fpm-alpine AS production

# Install PHP extensions
RUN docker-php-ext-install pdo pdo_mysql zip mbstring

# Install Composer
COPY --from=composer:2.7 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www

# Copy only manifest files
COPY composer.json composer.lock ./

# Install dependencies
RUN composer install --no-dev --no-interaction --prefer-dist --optimize-autoloader

# Copy application code
COPY . .

# Set permissions
RUN chmod -R 775 storage bootstrap/cache \
 && php artisan config:cache

EXPOSE 9000
CMD ["php-fpm"]
