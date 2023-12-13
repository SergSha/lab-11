---
#nginx:
#  pkg:
#    - installed
#  
#  service:
#    - running
#    - enable: True
#    - require:
#      - pkg: nginx


#nginx:
#  pkg:
#    - installed
#  service.running:
#    - watch:
#        - file: /etc/nginx/nginx.conf
#    - enable: true
#
#/etc/nginx/nginx.conf:
#  file.managed:
#    - source: salt://balancer/files/nginx/nginx.conf.jinja
#    - template: jinja


nginx:
  pkg:
    - installed
  service.running:
    - watch:
      - pkg: nginx
      - file: /etc/nginx/nginx.conf
      - file: /etc/nginx/conf.d/upstream.conf
    - enable: true

/etc/nginx/nginx.conf:
  file.managed:
    - source: salt://balancer/files/nginx/nginx.conf.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 640

/etc/nginx/conf.d/upstream.conf:
  file.managed:
    - source: salt://balancer/files/nginx/upstream.conf.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 640
...