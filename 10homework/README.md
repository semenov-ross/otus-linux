## Пользователи и группы. Авторизация и аутентификация

При запуске виртуальной машины при помощи сценария ansible [playbooks/pam_login.yml](playbooks/pam_login.yml) с использованием ролей:
 [roles/pam_grp_admin](roles/pam_grp_admin) и [roles/pam_sudo](roles/pam_sudo), которые используют модули 
 template, pamd, group, user, lineinfile, 
создаётся скрипт /usr/local/bin/pam_login.sh из шаблона [pam_login.sh.j2](roles/pam_grp_admin/templates/pam_login.sh.j2), 
добавляется строка "account required pam_exec.so /usr/local/bin/pam_login.sh" в файл /etc/pam.d/sshd:
```console
[root@centos7 ~]# cat  /etc/pam.d/sshd
#%PAM-1.0
# Updated by Ansible - 2019-09-28T16:37:35.939737
auth       required pam_sepermit.so
auth       substack password-auth
auth       include postlogin
# Used with polkit to reauthorize users in remote sessions
-auth      optional pam_reauthorize.so prepare
account    required pam_nologin.so
account    required pam_exec.so /usr/local/bin/pam_login.sh
account    include password-auth
password   include password-auth
# pam_selinux.so close should be the first session rule
session    required pam_selinux.so close
session    required pam_loginuid.so
# pam_selinux.so open should only be followed by sessions to be executed in the user context
session    required pam_selinux.so open env_params
session    required pam_namespace.so
session    optional pam_keyinit.so force revoke
session    include password-auth
session    include postlogin
# Used with polkit to reauthorize users in remote sessions
-session   optional pam_reauthorize.so prepare
```
Создаётся группа admin и пользователи admin и user  
Запрещяется пользователям, кроме группы admin логин в выходные(суббота и воскресенье), без учета праздников.  
Добавляется пользователь admin в sudoers без необходимости ввода пароля

```console
centos7: Running ansible-playbook...

PLAY [Configure login user with PAM and add sudo] ******************************

TASK [Gathering Facts] *********************************************************
ok: [centos7]

TASK [pam_grp_admin : pam-login | Add script for PAM] **************************
changed: [centos7]

TASK [pam_grp_admin : pam-login | Add rule in pam_exec.so to ssh] **************
changed: [centos7]

TASK [pam_grp_admin : pam-login | Create group 'admin'] ************************
changed: [centos7]

TASK [pam_grp_admin : pam-login | Add user 'admin' with password 111222] *******
changed: [centos7]

TASK [pam_grp_admin : pam-login | Add user 'user' with password 333444] ********
changed: [centos7]

TASK [pam_sudo : add-sudo | Add ['admin'] to sudoers without password] *********
changed: [centos7] => (item=admin)

PLAY RECAP *********************************************************************
centos7                    : ok=7    changed=6    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```
