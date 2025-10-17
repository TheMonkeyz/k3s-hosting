# Use the official PHP 8.2 FPM image as a base
FROM php:8.2-fpm

# Set the working directory
WORKDIR /var/www

# Install system dependencies required for TYPO3
RUN apt-get update && apt-get install -y \
    graphicsmagick \
    ghostscript \
    libzip-dev \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libicu-dev \
    libxml2-dev \
    unzip \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install required PHP extensions for TYPO3
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-install zip \
    && docker-php-ext-install intl \
    && docker-php-ext-install mysqli \
    && docker-php-ext-install opcache \
    && pecl install apcu \
    && docker-php-ext-enable apcu

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Create a new TYPO3 project
RUN composer create-project typo3/cms-base-distribution:^13 html --no-interaction

# Set file permissions
RUN chown -R www-data:www-data /var/www/html

# Switch to the www-data user
USER www-data

# Expose port 9000 and start php-fpm server
EXPOSE 9000
CMD ["php-fpm"]