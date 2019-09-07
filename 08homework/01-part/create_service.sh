#!/bin/bash
cp /vagrant/pars_log.service /vagrant/pars_log.timer /usr/lib/systemd/system/
cp /vagrant/pars_log.sysconfig /etc/sysconfig/pars_log

systemctl daemon-reload
systemctl enable pars_log.timer
systemctl start pars_log.timer
