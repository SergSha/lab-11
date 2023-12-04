---
base:
  '*':
    - chrony
  'db-*':
    - percona
  'backend-*':
    - backend
  'nginx-*':
    - nginx-balancer
    