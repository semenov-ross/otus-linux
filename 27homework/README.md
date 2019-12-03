## Почта: SMTP, IMAP, POP3.  

При запуске vagrant up при помощи сценария ansible [provisioning/playbook.yml](provisioning/playbook.yml) создаётся 
виртуальная машина mailServer, на которой установлен postfix и dovecot.
```console
Current machine states:

mailServer                running (virtualbox)
```

Конфигурация postfix:
```console
config_directory = /etc/postfix
queue_directory = /var/spool/postfix
command_directory = /usr/sbin
daemon_directory = /usr/libexec/postfix
data_directory = /var/lib/postfix
mail_owner = postfix
mail_spool_directory = /var/spool/mail
inet_interfaces = all
inet_protocols = all
mydestination = $myhostname, localhost.$mydomain, localhost
unknown_local_recipient_reject_code = 550
alias_maps = hash:/etc/aliases
alias_database = hash:/etc/aliases
debug_peer_level = 2
sendmail_path = /usr/sbin/sendmail.postfix
newaliases_path = /usr/bin/newaliases.postfix
mailq_path = /usr/bin/mailq.postfix
setgid_group = postdrop
html_directory = no
manpage_directory = /usr/share/man
sample_directory = /usr/share/doc/postfix-2.10.1/samples
readme_directory = /usr/share/doc/postfix-2.10.1/README_FILES
```

Конфигурация dovecot:
```console
disable_plaintext_auth = no 
first_valid_uid = 1000
mail_access_groups = mail
mail_location = mbox:~/mail:INBOX=/var/mail/%u
mbox_write_locks = fcntl
namespace inbox {
  inbox = yes
  location = 
  mailbox Drafts {
    special_use = \Drafts
  }
  mailbox Junk {
    special_use = \Junk
  }
  mailbox Sent {
    special_use = \Sent
  }
  mailbox "Sent Messages" {
    special_use = \Sent
  }
  mailbox Trash {
    special_use = \Trash
  }
  prefix = 
}
passdb {
  driver = pam
}
ssl = no
userdb {
  driver = passwd
}
```
Порт 25 гостевой машины проброшен на порт 1025, а порт 110 гостевой машины проброшен на 1110:
```console
ss -lpnut | grep 1025 | column -t
tcp  LISTEN  0  10  0.0.0.0:1025  0.0.0.0:*  users:(("VBoxHeadless",pid=25978,fd=21))

ss -lpnut | grep 1110 | column -t
tcp  LISTEN  0  10  0.0.0.0:1110  0.0.0.0:*  users:(("VBoxHeadless",pid=25978,fd=22))
```

Отправляем почту с хоста на виртуалку:
```console
telnet 127.0.0.1 1025
Trying 127.0.0.1...
Connected to 127.0.0.1.
Escape character is '^]'.
220 mailServer.localdomain ESMTP Postfix
helo localdomain
250 mailServer.localdomain
mail from:root
250 2.1.0 Ok
rcpt to:otus
250 2.1.5 Ok
data
354 End data with <CR><LF>.<CR><LF>
Hi, otus!
How are you?
.
250 2.0.0 Ok: queued as 3D53055
quit
221 2.0.0 Bye
Connection closed by foreign host.
```

Получаем почту:
```console
telnet 127.0.0.1 1110
Trying 127.0.0.1...
Connected to 127.0.0.1.
Escape character is '^]'.
+OK Dovecot ready.
user otus
+OK
pass otus
+OK Logged in.
list
+OK 1 messages:
1 295
.
retr 1
+OK 295 octets
Return-Path: <root@mailServer.localdomain>
X-Original-To: otus
Delivered-To: otus@mailServer.localdomain
Received: from localdomain (gateway [10.0.2.2])
        by mailServer.localdomain (Postfix) with SMTP id 3D53055
        for <otus>; Tue,  3 Dec 2019 17:32:55 +0000 (UTC)

Hi, otus!
How are you?
.
dele 1
+OK Marked to be deleted.
quit
+OK Logging out, messages deleted.
Connection closed by foreign host.
```
