---
base:
  '*':
    - chrony
  'db-*':
    - percona
  'backend-*':
    - backend
  'nginx-*':
    - balancer
    