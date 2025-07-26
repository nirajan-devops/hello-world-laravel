# ------------------------------------
# Stage 0: PHP base with extensions
# ------------------------------------
FROM php:8.2-fpm-alpine AS php-base

RUN apk add --no-cache \
      bash git curl icu-dev oniguruma libzip-dev libpng-dev libjpeg-turbo-dev libxml2-dev zlib-dev \
  && docker-php-ext-install intl pdo_mysql zip opcache

WORKDIR /var/www

# ------------------------------------
# Stage 1: Build & Test (with dev deps)
# ------------------------------------
FROM php-base AS build

# Bring in Composer
COPY --from=composer:2.7 /usr/bin/composer /usr/bin/composer

# Copy only composer manifests first (better caching)
COPY composer.json composer.lock ./
RUN composer install --no-interaction --prefer-dist --optimize-autoloader

# Copy source
COPY . .

# Prepare app for testing
RUN cp .env.example .env \
 && php artisan key:generate \
 && chmod -R 775 storage bootstrap/cache \
 && php artisan config:cache

# Run the test suite (use artisan so it works with Pest or PHPUnit)
RUN php artisan test --no-interaction --without-tty

# ------------------------------------
# Stage 2: Production image (no dev deps)
# ------------------------------------
FROM php-base AS production

# Bring in Composer again to install prod deps only
COPY --from=composer:2.7 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www

# Copy manifests again and install prod deps
COPY composer.json composer.lock ./

# Install only prod dependencies
RUN composer install --no-dev --no-interaction --prefer-dist --optimize-autoloader

# Now copy the *application code* (but not the vendor from build)
COPY . .

# Cache config, fix perms
RUN php artisan config:cache \
 && chmod -R 775 storage bootstrap/cache

EXPOSE 9000
CMD ["php-fpm"]
