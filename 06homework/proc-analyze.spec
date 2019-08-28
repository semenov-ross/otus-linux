Name:           proc-analyze
Version:        0
Release:        1%{?dist}
Summary:        Bash scripts style ps

License:        GPLv3
URL:            https://github.com/semenov-ross/otus-linux/tree/master/05homework
%undefine       _disable_source_fetch
Source0:        https://raw.githubusercontent.com/semenov-ross/otus-linux/master/05homework/pars_proc_psax.sh

BuildArch:      noarch

Requires:       bash >= 4.1

%description
Bash scripts parsing proc style ps 


%prep


%build


%install
mkdir -p %{buildroot}%{_bindir}
install -D -p -m 0755 %{SOURCE0} %{buildroot}%{_bindir}


%files
%{_bindir}/*

%changelog
* Tue Aug 28 2019 <semenov.ross@gmail.com> 0-1
- Initial package
