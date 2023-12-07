---
base:
  '*':
    - chrony
  'db-*':
    - db
  'backend-*':
    - backend
  'nginx-*':
    - balancer
    