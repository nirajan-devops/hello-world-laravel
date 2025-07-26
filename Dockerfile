FROM php:8.2-fpm

# Set working directory
WORKDIR /var/www

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    libpng-dev \
    libjpeg-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    curl \
    sqlite3 \
    libsqlite3-dev \
    git \
    && docker-php-ext-install pdo pdo_mysql pdo_sqlite mbstring zip xml intl

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Copy app files
COPY . .

# Set permissions
RUN mkdir -p storage bootstrap/cache database \
    && touch database/database.sqlite \
    && chmod -R 775 storage bootstrap/cache database \
    && chown -R www-data:www-data .

# Install PHP dependencies
RUN composer install --no-dev --no-interaction --prefer-dist --optimize-autoloader

# Set environment
COPY .env.example .env

# Generate app key
RUN php artisan key:generate

# Run migrations (optional; skip if no tables needed at start)
RUN php artisan migrate --force || true

# Expose port and run app
EXPOSE 8000
CMD ["php", "-S", "0.0.0.0:8000", "-t", "public"]
