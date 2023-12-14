---
nginx:
  pkg:
    - installed
  service.running:
    - watch:
      - pkg: nginx
      - file: /etc/nginx/nginx.conf
      - file: /etc/nginx/conf.d/upstream.conf
    - enable: true
  file.managed:
    - name: etc/nginx/nginx.conf
    - source: salt://balancer/files/nginx/nginx.conf.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 640
  file.managed:
    - name: /etc/nginx/conf.d/upstream.conf
    - source: salt://balancer/files/nginx/upstream.conf.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 640
...