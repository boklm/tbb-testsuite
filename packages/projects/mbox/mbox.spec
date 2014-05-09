Name:    mbox
Version: [% c('version') %]
Release: [% c('rpm_rel') %]%{?dist}
Summary: A lightweight sandboxing mechanism that can be used without special privileges

License: BSD
URL: http://pdos.csail.mit.edu/mbox/
Source0: mbox-%{version}.tar.xz

BuildRequires: openssl-devel

%description
Mbox introduces a novel sandbox usage model; when executing a program
in the sandbox, Mbox prevents programs from modifying the host filesystem
while giving them the impression that they are in fact making those
modifications. Mbox achieves this by providing a layered sandbox
filesystem and by interposing on system calls with ptrace and seccomp/BPF.
At the end of program execution, the user can examine changes in the
sandbox filesystem, and selectively commit them back to the host filesystem.

%prep
%setup -q

%build
cd src
cp {.,}configsbox.h
%configure
make %{?_smp_mflags}

%install
rm -rf $RPM_BUILD_ROOT
cd src
%make_install

%files
%doc doc/paper.pdf doc/slides.pdf doc/NOTE.web
%{_bindir}/mbox
