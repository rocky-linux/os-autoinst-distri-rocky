# Using perltidy, tidyall and tidy with the repository

## Purpose

Periodically it makes sense to be able to compare to our original upstream repository ([Fedora openQA](https://pagure.io/fedora-qa/os-autoinst-distri-fedora)) or even to cherry pick select improvements to our code. In the best case we might even contribute improvements or bug fixes back to Fedora. In order to do any of those things effectively it is good to keep the code we share with upstream as closely matching as possible.

After we forked from upstream the Fedora QA team [began using `perltidy`](https://pagure.io/fedora-qa/os-autoinst-distri-fedora/pull-request/271) to apply and enforce consistent coding stardards to their openQA test code. Additionally, they modified all existing code to implement these coding standards uniformly across the entire repository.

If we adopt the same standard we will benefit from being able to...

- directly compare code in our fork originating from upstream,
- more easily import any existing upstream code
- and we'll also improve our own code quality.


## Pre-Requisites

- pre-commit - [https://pre-commit.com/](https://pre-commit.com/)
- perltidy - [https://metacpan.org/dist/Perl-Tidy/view/bin/perltidy](https://metacpan.org/dist/Perl-Tidy/view/bin/perltidy)
- tidyall - [https://metacpan.org/dist/Code-TidyAll/view/bin/tidyall](https://metacpan.org/dist/Code-TidyAll/view/bin/tidyall)


Install above in your dev system via you preferred method. I used [`cpanm`](https://metacpan.org/dist/App-cpanminus/view/bin/cpanm) to install `Perl::Tidy` and `Code::TidyAll` in my macOS system and `cpanm` was installed with Homebrew.


### install `cpanm`
```
$ brew install cpanminus
==> Fetching cpanminus
==> Downloading https://ghcr.io/v2/homebrew/core/cpanminus/manifests/1.7046
Already downloaded: /Users/tcooper/Library/Caches/Homebrew/downloads/269f7cc3d0d07bf233458f3bf1d604ae2e8669d59eeb91e273bfda684987519f--cpanminus-1.7046.bottle_manifest.json
==> Downloading https://ghcr.io/v2/homebrew/core/cpanminus/blobs/sha256:ab901b1645c97fa50ee52ecc4bf51bac7f8a8959abe664bbdd66c3d1a5
Already downloaded: /Users/tcooper/Library/Caches/Homebrew/downloads/d3cf41a8aca082cd90acdfa8d79fc89e2b17d3ab13a2953b2bb58083a38a0779--cpanminus--1.7046.ventura.bottle.tar.gz
==> Pouring cpanminus--1.7046.ventura.bottle.tar.gz
==> Adding `/usr/bin/env perl` shebang to `cpanm`...
🍺  /usr/local/Cellar/cpanminus/1.7046: 11 files, 1.2MB
==> Running `brew cleanup cpanminus`...
Disable this behaviour by setting HOMEBREW_NO_INSTALL_CLEANUP.
Hide these hints with HOMEBREW_NO_ENV_HINTS (see `man brew`).

$ which cpanm
/usr/local/bin/cpanm
```

**NOTE: Homebrew automatically configures your default shell for `cpanm`.**


### install `perltidy`
```
$ cpanm --info Perl::Tidy
SHANCOCK/Perl-Tidy-20221112.tar.gz
$ cpanm Perl::Tidy
--> Working on Perl::Tidy
Fetching http://www.cpan.org/authors/id/S/SH/SHANCOCK/Perl-Tidy-20221112.tar.gz ... OK
Configuring Perl-Tidy-20221112 ... OK
Building and testing Perl-Tidy-20221112 ... OK
Successfully installed Perl-Tidy-20221112
1 distribution installed

$ which perltidy
/Users/tcooper/perl5/bin/perltidy
```

### install `tidyall`
```
$ cpanm --info Code::TidyAll
DROLSKY/Code-TidyAll-0.83.tar.gz

$ cpanm Code::TidyAll
--> Working on Code::TidyAll
Fetching http://www.cpan.org/authors/id/D/DR/DROLSKY/Code-TidyAll-0.83.tar.gz ... OK
Configuring Code-TidyAll-0.83 ... OK
Building and testing Code-TidyAll-0.83 ... OK
Successfully installed Code-TidyAll-0.83
1 distribution installed

$ which tidyall
/Users/tcooper/perl5/bin/tidyall
```

In an RPM based system like Rocky Linux or Fedora `Perl::Tidy` and `Code::TidyAll` may be installable, along with all dependencies, directly from the provided repositories.

### install `cpanm` in Rocky Linux 8

```
# dnf config-manager --set-enabled powertools
# dnf install perl-App-cpanminus
Rocky Linux 8 - AppStream                                                                         7.4 kB/s | 4.8 kB     00:00
Rocky Linux 8 - BaseOS                                                                            4.3 kB/s | 4.3 kB     00:01
Rocky Linux 8 - Extras                                                                            8.2 kB/s | 3.1 kB     00:00
Rocky Linux 8 - PowerTools                                                                        8.4 kB/s | 4.8 kB     00:00
Extra Packages for Enterprise Linux 8 - x86_64                                                     17 kB/s | 8.7 kB     00:00
Extra Packages for Enterprise Linux 8 - x86_64                                                    841 kB/s |  13 MB     00:16
Dependencies resolved.
==================================================================================================================================
 Package                                Architecture     Version                                        Repository           Size
==================================================================================================================================
Installing:
 perl-App-cpanminus                     noarch           1.7044-5.module+el8.6.0+961+8164b543           appstream            97 k
 perltidy                               noarch           20180220-1.el8                                 powertools          427 k
Installing dependencies:
 annobin                                x86_64           10.67-3.el8                                    appstream           954 k

...<snip>...

  unzip-6.0-46.el8.x86_64
  zip-3.0-23.el8.x86_64

Complete!

# which cpanm
/usr/bin/cpanm

# which perltidy
/usr/bin/perltidy
```

### configure `.bash_profile` for `cpanm`

Append your `$HOME/.bash_profile` file with the following if not already setup...

```
PATH="$HOME/perl5/bin${PATH:+:${PATH}}"; export PATH;
PERL5LIB="$HOME/perl5/lib/perl5${PERL5LIB:+:${PERL5LIB}}"; export PERL5LIB;
PERL_LOCAL_LIB_ROOT="$HOME/perl5${PERL_LOCAL_LIB_ROOT:+:${PERL_LOCAL_LIB_ROOT}}"; export PERL_LOCAL_LIB_ROOT;
PERL_MB_OPT="--install_base \"$HOME/perl5\""; export PERL_MB_OPT;
PERL_MM_OPT="INSTALL_BASE=$HOME/perl5"; export PERL_MM_OPT;
```


With `cpanm` installed you can follow steps above to install `Code::TidyAll`.

#### install `tidyall`

```
$ cpanm -l ~/perl5 --info Code::TidyAll
DROLSKY/Code-TidyAll-0.83.tar.gz

$ cpanm -l ~/perl5 Code::TidyAll
--> Working on Code::TidyAll
Fetching http://www.cpan.org/authors/id/D/DR/DROLSKY/Code-TidyAll-0.83.tar.gz ... OK
Configuring Code-TidyAll-0.83 ... OK
==> Found dependencies: List::SomeUtils, Specio, Specio::Library::String, Test::Class::Most, Time::Duration::Parse, Specio::Library::Path::Tiny, List::Compare, Try::Tiny, Test::Fatal, Date::Format, Specio::Library::Builtins, Capture::Tiny, Module::Runtime, Specio::Library::Numeric, IPC::Run3, Log::Any, Scope::Guard, Moo, Path::Tiny, Specio::Declare, Test::Warnings, Moo::Role, Test::Differences, lib::relative, Config::INI::Reader

...<snip>...

Building and testing Code-TidyAll-0.83 ... OK
Successfully installed Code-TidyAll-0.83
43 distributions installed

$ which tidyall
~/perl5/bin/tidyall
```


### install `cpanm` and `perltidy` in Rocky Linux 9

```
$ sudo dnf install perltidy perl-App-cpanminus
Last metadata expiration check: 0:06:42 ago on Sun Feb 12 19:29:29 2023.
Dependencies resolved.
==================================================================================================================================
 Package                                    Architecture         Version                            Repository               Size
==================================================================================================================================
Installing:
 perl-App-cpanminus                         noarch               1.7044-14.el9                      appstream                86 k
 perltidy                                   noarch               20210111-4.el9                     crb                     541 k

 ...<snip>...

  perl-utils-5.32.1-479.el9.noarch                               perl-vmsish-1.04-479.el9.noarch
  perltidy-20210111-4.el9.noarch                                 sombok-2.4.0-16.el9.x86_64
  systemtap-sdt-devel-4.7-2.el9.x86_64

Complete!

$ which cpanm
/usr/bin/cpanm

$ which perltidy
/usr/bin/perltidy
```

With `cpanm` and `perltidy` installed you can follow steps above to install `Code::TidyAll`.


### install `perltidy` and `tidyall` in Fedora 37 (`cpanm` not required)

```
# dnf install perltidy perl-Code-TidyAll
Last metadata expiration check: 0:03:32 ago on Mon 13 Feb 2023 03:59:12 AM UTC.
Dependencies resolved.
==================================================================================================================================
 Package                                    Architecture        Version                                Repository            Size
==================================================================================================================================
Installing:
 perl-Code-TidyAll                          noarch              0.82-3.fc37                            fedora               169 k
 perltidy                                   noarch              20220613-2.fc37                        fedora               655 k

...<snip>...

  php-soap-8.1.15-1.fc37.x86_64                                      php-xml-8.1.15-1.fc37.x86_64
  subversion-1.14.2-8.fc37.x86_64                                    subversion-libs-1.14.2-8.fc37.x86_64
  utf8proc-2.7.0-3.fc37.x86_64

Complete!

# which perltidy
/usr/bin/perltidy

# which tidyall
/usr/bin/tidyall
```


## `perltidy` usage

With the `.perltidyrc` configuration adopted from upstream analysis (and repair) of Perl source files is possible. For example...

```
$ perltidy -st main.pm > main.pm.tidy
```

```
$ diff main.pm main.pm.tidy
36c36
<     my @a   = @{ needle::tags($tag) };
---
>     my @a = @{needle::tags($tag)};
52c52
<     NEEDLE: for my $needle ( needle::all() ) {
---
>   NEEDLE: for my $needle (needle::all()) {
54c54
<         for my $tag ( @{$needle->{'tags'}} ) {
---
>         for my $tag (@{$needle->{'tags'}}) {
59c59
<                 for my $value ( @{$valueref} ) {
---
>                 for my $value (@{$valueref}) {
88c88
<         unregister_prefix_tags('DESKTOP', [ get_var('DESKTOP') ])
---
>         unregister_prefix_tags('DESKTOP', [get_var('DESKTOP')]);
94c94
<     my $langref = [ get_var('LANGUAGE') || 'english' ];
---
>     my $langref = [get_var('LANGUAGE') || 'english'];
198c198
<     if (! $partitioning || $partitioning ~~ ['guided_empty', 'guided_free_space']) {
---
>     if (!$partitioning || $partitioning ~~ ['guided_empty', 'guided_free_space']) {
202c202
<         $storage = "tests/disk_".$partitioning.".pm";
---
>         $storage = "tests/disk_" . $partitioning . ".pm";
206c206
<     if (get_var("ENCRYPT_PASSWORD")){
---
>     if (get_var("ENCRYPT_PASSWORD")) {
333c333
<     if (get_var("UEFI") &! get_var("NO_UEFI_POST") &! get_var("START_AFTER_TEST")) {
---
>     if (get_var("UEFI") & !get_var("NO_UEFI_POST") & !get_var("START_AFTER_TEST")) {
```

It should be evident from the above that without these changes it will become challenging to detect differences between our code and upstream code moving forward from the point where Fedora QA applied these code standards to all sources.


## Using `tidy` to check and/or fix code

The utility wrapper `tidy` provided by Fedora in the upstream repository can be used to launch `tidyall` with options described in `tidy`.

For example, dropping an untidy'd copy of our `main.pm` as `foo.pm`...

```
[geekotest@openqa-dev ~]$ cd /var/lib/openqa/tests/rocky

[geekotest@openqa-dev rocky]$ ./tidy --check foo.pm
[checked] foo.pm
*** needs tidying

[geekotest@openqa-dev rocky]$ ./tidy foo.pm
[tidied]  foo.pm

[geekotest@openqa-dev rocky]$ ls .tidyall.d/backups/
foo.pm-20230212-203202.bak
```

```
[geekotest@openqa-dev rocky]$ diff .tidyall.d/backups/foo.pm-20230212-203202.bak foo.pm
36c36
<     my @a   = @{ needle::tags($tag) };
---
>     my @a = @{needle::tags($tag)};
52c52
<     NEEDLE: for my $needle ( needle::all() ) {
---
>   NEEDLE: for my $needle (needle::all()) {
54c54
<         for my $tag ( @{$needle->{'tags'}} ) {
---
>         for my $tag (@{$needle->{'tags'}}) {
59c59
<                 for my $value ( @{$valueref} ) {
---
>                 for my $value (@{$valueref}) {
88c88
<         unregister_prefix_tags('DESKTOP', [ get_var('DESKTOP') ])
---
>         unregister_prefix_tags('DESKTOP', [get_var('DESKTOP')]);
94c94
<     my $langref = [ get_var('LANGUAGE') || 'english' ];
---
>     my $langref = [get_var('LANGUAGE') || 'english'];
198c198
<     if (! $partitioning || $partitioning ~~ ['guided_empty', 'guided_free_space']) {
---
>     if (!$partitioning || $partitioning ~~ ['guided_empty', 'guided_free_space']) {
202c202
<         $storage = "tests/disk_".$partitioning.".pm";
---
>         $storage = "tests/disk_" . $partitioning . ".pm";
206c206
<     if (get_var("ENCRYPT_PASSWORD")){
---
>     if (get_var("ENCRYPT_PASSWORD")) {
333c333
<     if (get_var("UEFI") &! get_var("NO_UEFI_POST") &! get_var("START_AFTER_TEST")) {
---
>     if (get_var("UEFI") & !get_var("NO_UEFI_POST") & !get_var("START_AFTER_TEST")) {
```


## Automatic application with pre-commit

While it's possible to manually apply these corrections using `tidy` when adding tests it is easy to forget this step and may be preferable to to use `pre-commit` to automatically check/apply these changes during normal workflow of developing and adding tests to openQA.

With `pre-commit` setup in your local clone you are able to do this easily for any new tests added to the repository.

For example...

```
$ cp main.pm foo.pm
$ git add foo.pm
$ pre-commit run
trim trailing whitespace.................................................Passed
fix end of files.........................................................Passed
check json...........................................(no files to check)Skipped
check yaml...........................................(no files to check)Skipped
check for added large files..............................................Passed
perltidy.................................................................Failed
- hook id: perltidy
- files were modified by this hook
```

...the issues are detected and automatically corrected...

```
$ git --no-pager diff foo.pm
diff --git a/foo.pm b/foo.pm
index b8470550..7a873fe2 100644
--- a/foo.pm
+++ b/foo.pm
@@ -33,7 +33,7 @@ testapi::set_distribution(fedoradistribution->new());
 # Stolen from openSUSE.
 sub unregister_needle_tags($) {
     my $tag = shift;
-    my @a   = @{ needle::tags($tag) };
+    my @a = @{needle::tags($tag)};
     for my $n (@a) { $n->unregister(); }
 }

@@ -49,14 +49,14 @@ sub unregister_needle_tags($) {
 # 'LANGUAGE-' at all.
 sub unregister_prefix_tags {
     my ($prefix, $valueref) = @_;
-    NEEDLE: for my $needle ( needle::all() ) {
+  NEEDLE: for my $needle (needle::all()) {
         my $unregister = 0;
-        for my $tag ( @{$needle->{'tags'}} ) {
+        for my $tag (@{$needle->{'tags'}}) {
             if ($tag =~ /^\Q$prefix/) {
                 # We have at least one tag matching the prefix, so we
                 # *MAY* want to un-register the needle
                 $unregister = 1;
-                for my $value ( @{$valueref} ) {
+                for my $value (@{$valueref}) {
                     # At any point if we hit a prefix-value match, we
                     # know we need to keep this needle and can skip
                     # to the next
@@ -85,13 +85,13 @@ sub cleanup_needles() {

     # Unregister desktop needles of other desktops when DESKTOP is specified
     if (get_var('DESKTOP')) {
-        unregister_prefix_tags('DESKTOP', [ get_var('DESKTOP') ])
+        unregister_prefix_tags('DESKTOP', [get_var('DESKTOP')]);
     }

     # Unregister non-language-appropriate needles. See unregister_except_
     # tags for details; basically all needles with at least one LANGUAGE-
     # tag will be unregistered unless they match the current langauge.
-    my $langref = [ get_var('LANGUAGE') || 'english' ];
+    my $langref = [get_var('LANGUAGE') || 'english'];
     unregister_prefix_tags('LANGUAGE', $langref);
 }
 $needle::cleanuphandler = \&cleanup_needles;
@@ -195,15 +195,15 @@ sub load_install_tests() {
     my $partitioning = get_var('PARTITIONING');
     # if PARTITIONING is unset, or one of [...], use disk_guided_empty,
     # which is the simplest / 'default' case.
-    if (! $partitioning || $partitioning ~~ ['guided_empty', 'guided_free_space']) {
+    if (!$partitioning || $partitioning ~~ ['guided_empty', 'guided_free_space']) {
         $storage = "tests/disk_guided_empty.pm";
     }
     else {
-        $storage = "tests/disk_".$partitioning.".pm";
+        $storage = "tests/disk_" . $partitioning . ".pm";
     }
     autotest::loadtest $storage;

-    if (get_var("ENCRYPT_PASSWORD")){
+    if (get_var("ENCRYPT_PASSWORD")) {
         autotest::loadtest "tests/disk_guided_encrypted.pm";
     }

@@ -330,7 +330,7 @@ sub load_postinstall_tests() {
     }
     autotest::loadtest $storagepost if ($storagepost);

-    if (get_var("UEFI") &! get_var("NO_UEFI_POST") &! get_var("START_AFTER_TEST")) {
+    if (get_var("UEFI") & !get_var("NO_UEFI_POST") & !get_var("START_AFTER_TEST")) {
         autotest::loadtest "tests/uefi_postinstall.pm";
     }
```


## Automatic application of check/modify with git pre-commit hook

By adding the perltidy hook to the `pre-commit` configuration the hook is automatically run when trying to commit Perl code. If problems are found they are fixed and the the commit is rejected allowing you an opportunity to investigate before continuing.

### add file and attempt commit (rejected with file modified with perltidy)

```
$ cp main.pm foo.pm
$ git add foo.pm
$ git commit -m "add foo.pm"
trim trailing whitespace.................................................Passed
fix end of files.........................................................Passed
check json...........................................(no files to check)Skipped
check yaml...........................................(no files to check)Skipped
check for added large files..............................................Passed
perltidy.................................................................Failed
- hook id: perltidy
- files were modified by this hook

$ git add foo.pm
```

### commit now

```
$ git add foo.pm
$ git commit -m "add foo.pm"
trim trailing whitespace.................................................Passed
fix end of files.........................................................Passed
check json...........................................(no files to check)Skipped
check yaml...........................................(no files to check)Skipped
check for added large files..............................................Passed
perltidy.................................................................Passed
[add_perltidy_support 19720035] add foo.pm
 1 file changed, 454 insertions(+)
 create mode 100644 foo.pm
```

## Automatically tidying all existing code

`perltidy` and `tidy` can check specific files and the `pre-commit` hook can check any new files added to the repository in new commits.

How do we repair all of the existing code in the repository so that it matches upstream?

For that we can use `tidyall` for everything in the hierarchy of our openQA repository. For example...

```
$ tidyall --check-only -a
[checked] main.pm
*** needs tidying
[checked] tests/server_cockpit_default.pm
*** needs tidying
[checked] tests/disk_guided_delete_partial_postinstall.pm
*** needs tidying

...<snip>...

[checked] lib/utils.pm
*** needs tidying
[checked] lib/anacondatest.pm
*** needs tidying
```

```
$ tidyall -a
[tidied]  main.pm
[tidied]  tests/server_cockpit_default.pm
[tidied]  tests/disk_guided_delete_partial_postinstall.pm

...<snip>...

[tidied]  lib/modularity.pm
[tidied]  lib/utils.pm
[tidied]  lib/anacondatest.pm
```

```
$ git status
On branch add_perltidy_support
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   lib/anaconda.pm
	modified:   lib/anacondatest.pm
	modified:   lib/bugzilla.pm

...<snip>...

	modified:   tests/upgrade_preinstall.pm
	modified:   tests/upgrade_run.pm
	modified:   tests/workstation_core_applications.pm

Untracked files:
  (use "git add <file>..." to include in what will be committed)
	.tidyall.d/
	.tidyallrc
	README_perltidy.md

no changes added to commit (use "git add" and/or "git commit -a")
```

```
$ git add $(git status -s | awk '/\.pm$/ {print $2}')

$ git commit -m "enforce standard coding on all Perl files"
trim trailing whitespace.................................................Passed
fix end of files.........................................................Passed
check json...........................................(no files to check)Skipped
check yaml...........................................(no files to check)Skipped
check for added large files..............................................Passed
perltidy.................................................................Passed
[add_perltidy_support 61d57d45] enforce standard coding on all Perl files
 237 files changed, 950 insertions(+), 950 deletions(-)
```

```
$ git --no-pager log -n2
commit 61d57d4591bc37798b87b54eae44a016538f8880 (HEAD -> add_perltidy_support)
gpg: Signature made Sun Feb 12 14:59:40 2023 PST
gpg:                using RSA key 2CA999800D11C5946C9DBFEE52364D7BBCEB35B8
gpg: Good signature from "Trevor Cooper <tcooper@sdsc.edu>" [ultimate]
gpg:                 aka "Trevor Cooper <tcooper@ucsd.edu>" [ultimate]
gpg:                 aka "Trevor Cooper <tcooper@rockylinux.org>" [ultimate]
Author: Trevor Cooper <tcooper@rockylinux.org>
Date:   Sun Feb 12 14:59:37 2023 -0800

    enforce standard coding on all Perl files

commit 4bfc29fc691568f36391560818fca0e7a3f7cac7
gpg: Signature made Sun Feb 12 14:08:53 2023 PST
gpg:                using RSA key 2CA999800D11C5946C9DBFEE52364D7BBCEB35B8
gpg: Good signature from "Trevor Cooper <tcooper@sdsc.edu>" [ultimate]
gpg:                 aka "Trevor Cooper <tcooper@ucsd.edu>" [ultimate]
gpg:                 aka "Trevor Cooper <tcooper@rockylinux.org>" [ultimate]
Author: Trevor Cooper <tcooper@rockylinux.org>
Date:   Sun Feb 12 14:08:52 2023 -0800

    add support for perltidy and pre-commit
```
