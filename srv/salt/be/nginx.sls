---
nginx:
  pkg:
    - installed
  service.running:
    - watch:
        - file: /etc/nginx/nginx.conf
    - enable: true
    - require:
      - pkg: nginx

/etc/nginx/nginx.conf:
  file.managed:
    - source: salt://backend/files/nginx/nginx.conf.jinja
    - template: jinja
...