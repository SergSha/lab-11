---
php-packages:
  pkg.installed:
    - pkgs:
      - php-fpm
      - php-mysqlnd
      - php-bcmath
      - php-ctype
      - php-json
      - php-mbstring
      - php-pdo
      - php-tokenizer
      - php-xml
      - php-curl

php-fpm:
  service.running:
    - enable: true
