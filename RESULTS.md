Product Test result Summary
---

Product test results from be2fc0baeda69cad7480e29aa6714b2e5d916c8e tested on 2021-09-30

| Product                           | Passing | Failing | Skipped | Unfinished | Total |
|-----------------------------------|---------|---------|---------|------------|-------|
| rocky-boot-iso-x86_64-*           | 0       | 2       | 0       | 0          | 2     |
| rocky-minimal-iso-x86_64-*        | 2       | 0       | 0       | 0          | 2     |
| rocky-dvd-iso-x86_64-*            | 5       | 8       | 14      | 0          | 27    |
| rocky-universal-x86_64-*          | 23      | 22      | 0       | 2*         | 47    |

\* install_pxeboot and install_pxeboot@uefi can't run due to misssing `support_server@64bit`

Product test commands
---

rocky-boot-iso-x86_64-*
```
sudo openqa-cli api -X POST isos \
  ISO=Rocky-8.4-x86_64-boot.iso \
  DISTRI=rocky \
  VERSION=8.4 \
  FLAVOR=boot-iso \
  ARCH=x86_64 \
  BUILD="-boot-iso-$(date +%Y%m%d.%H%M%S).0"
```

rocky-minimal-iso-x86_64-*
```
sudo openqa-cli api -X POST isos \
  ISO=Rocky-8.4-x86_64-minimal.iso \
  DISTRI=rocky \
  VERSION=8.4 \
  FLAVOR=minimal-iso \
  ARCH=x86_64 \
  BUILD="-minimal-iso-$(date +%Y%m%d.%H%M%S).0"
```

rocky-dvd-iso-x86_64-*
```
sudo openqa-cli api -X POST isos \
  ISO=Rocky-8.4-x86_64-dvd1.iso \
  DISTRI=rocky \
  VERSION=8.4 \
  FLAVOR=dvd-iso \
  ARCH=x86_64 \
  BUILD="-dvd-iso-$(date +%Y%m%d.%H%M%S).0"
```

rocky-universal-x86_64-*
```
sudo openqa-cli api -X POST isos \
  ISO=Rocky-8.4-x86_64-dvd1.iso \
  DISTRI=rocky \
  VERSION=8.4 \
  FLAVOR=universal \
  ARCH=x86_64 \
  BUILD="-universal-$(date +%Y%m%d.%H%M%S).0"
```


