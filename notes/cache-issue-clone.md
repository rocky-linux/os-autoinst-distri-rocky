


@neil I suspect a cache issue is hampering debug of test clone failures from our openQA box. For example the following clone command fails...

```
$ openqa-clone-job --from https://openqa.rockylinux.org --host localhost 14364
downloading
https://openqa.rockylinux.org/tests/14364/asset/iso/Rocky-9.1-20221214.1-x86_64-dvd.iso
to
/var/lib/openqa/share/factory/iso/Rocky-9.1-20221214.1-x86_64-dvd.iso
14364 failed: Rocky-9.1-20221214.1-x86_64-dvd.iso, 403 Forbidden
Can't clone due to missing assets: 403 Forbidden
```

With this logged...

```
[root@i-08575289b44969b2a rocky]# tail -n 1000 -f /var/log/httpd/access_log | grep "asset/iso" -C2
162.158.186.69 - - [23/Mar/2023:15:56:13 +0000] "GET /api/v1/jobs/14364 HTTP/1.1" 200 677 "-" "Mojolicious (Perl)"
172.71.254.117 - - [23/Mar/2023:15:56:27 +0000] "GET /dashboard_build_results?group=&limit_builds=8&time_limit_days=2&interval=90 HTTP/1.1" 200 932 "https://openqa.rockylinux.org/?group=&limit_builds=8&time_limit_days=2&interval=90" "Mozilla/5.0 (X11; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/111.0"
162.158.186.242 - - [23/Mar/2023:15:56:45 +0000] "GET /tests/14364/asset/iso HTTP/1.1" 404 7355 "-" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/111.0.0.0 Safari/537.36"
162.158.186.242 - - [23/Mar/2023:15:56:53 +0000] "GET /tests/14364 HTTP/1.1" 200 4133 "-" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/111.0.0.0 Safari/537.36"
162.158.186.242 - - [23/Mar/2023:15:56:53 +0000] "GET /tests/14364/details_ajax HTTP/1.1" 200 925 "https://openqa.rockylinux.org/tests/14364" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/111.0.0.0 Safari/537.36"
162.158.186.112 - - [23/Mar/2023:15:56:53 +0000] "GET /asset/6e669b2b22/logo-passed.svg HTTP/1.1" 200 38952 "https://openqa.rockylinux.org/tests/14364" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/111.0.0.0 Safari/537.36"
162.158.186.242 - - [23/Mar/2023:15:56:54 +0000] "GET /tests/14364/downloads_ajax HTTP/1.1" 200 423 "https://openqa.rockylinux.org/tests/14364" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/111.0.0.0 Safari/537.36"
162.158.186.170 - - [23/Mar/2023:15:57:21 +0000] "GET /tests/14364/asset/iso/Rocky-9.1-20221214.1-x86_64-dvd.iso HTTP/1.1" 302 - "https://openqa.rockylinux.org/tests/14364" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/111.0.0.0 Safari/537.36"
162.158.187.3 - - [23/Mar/2023:15:57:21 +0000] "GET /assets/iso/fixed/Rocky-9.1-20221214.1-x86_64-dvd.iso HTTP/1.1" 403 306 "https://openqa.rockylinux.org/tests/14364" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/111.0.0.0 Safari/537.36"
162.158.186.242 - - [23/Mar/2023:15:57:21 +0000] "GET /favicon.ico HTTP/1.1" 200 90022 "https://openqa.rockylinux.org/assets/iso/fixed/Rocky-9.1-20221214.1-x86_64-dvd.iso" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/111.0.0.0 Safari/537.36"
```

However, subsequent commands also fail but nothing is logged on the openQA server.
