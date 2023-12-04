---
chrony:
  pkg:
    - installed
  service.running:
    - watch:
      - pkg: chrony
    - enable: true

Europe/Moscow:
  timezone.system