---
chrony:
  pkg:
    - installed
  service.running:
    - enable: true

Europe/Moscow:
  timezone.system