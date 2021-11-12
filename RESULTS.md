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
```sh
openqa-cli api -X POST isos \
  ISO=Rocky-8.4-x86_64-boot.iso \
  ARCH=x86_64 \
  DISTRI=rocky \
  FLAVOR=boot-iso \
  VERSION=8.4 \
  BUILD="-boot-iso-$(date +%Y%m%d.%H%M%S).0"
```

rocky-minimal-iso-x86_64-*
```sh
openqa-cli api -X POST isos \
  ISO=Rocky-8.4-x86_64-minimal.iso \
  ARCH=x86_64 \
  DISTRI=rocky \
  FLAVOR=minimal-iso \
  VERSION=8.4 \
  BUILD="-minimal-iso-$(date +%Y%m%d.%H%M%S).0"
```

rocky-dvd-iso-x86_64-*
```sh
openqa-cli api -X POST isos \
  ISO=Rocky-8.4-x86_64-dvd1.iso \
  ARCH=x86_64 DISTRI=rocky \
  FLAVOR=dvd-iso \
  PACKAGE_SET=minimal \
  VERSION=8.4 \
  BUILD="-minimal-$(date +%Y%m%d.%H%M%S).0"

openqa-cli api -X POST isos \
  ISO=Rocky-8.4-x86_64-dvd1.iso \
  ARCH=x86_64 \
  DISTRI=rocky \
  FLAVOR=dvd-iso \
  PACKAGE_SET=server \
  VERSION=8.4 \
  BUILD="-server-$(date +%Y%m%d.%H%M%S).0"

openqa-cli api -X POST isos \
  ISO=Rocky-8.4-x86_64-dvd1.iso \
  ARCH=x86_64 \
  DISTRI=rocky \
  FLAVOR=dvd-iso \
  PACKAGE_SET=graphical-server \
  DESKTOP=gnome \
  VERSION=8.4 \
  BUILD="-graphical-server-$(date +%Y%m%d.%H%M%S).0"

openqa-cli api -X POST isos \
  ISO=Rocky-8.4-x86_64-dvd1.iso \
  ARCH=x86_64 \
  DISTRI=rocky \
  FLAVOR=dvd-iso \
  PACKAGE_SET=workstation \
  DESKTOP=gnome \
  VERSION=8.4 \
  BUILD="-workstation-$(date +%Y%m%d.%H%M%S).0"
```

rocky-universal-x86_64-*
```sh
openqa-cli api -X POST isos \
  ISO=Rocky-8.4-x86_64-dvd1.iso \
  ARCH=x86_64 \
  DISTRI=rocky \
  FLAVOR=universal \
  VERSION=8.4 \
  BUILD="-universal-$(date +%Y%m%d.%H%M%S).0"
```
