---
chrony:
  pkg:
    - installed

chronyd:
  service.running:
    - enable: true

Europe/Moscow:
  timezone.system
