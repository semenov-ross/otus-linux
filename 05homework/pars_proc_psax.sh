#!/bin/bash

out_fmt="%-8s%-8s%-5s%-8s%-100s\n"

printf "$out_fmt" PID TTY STAT TIME COMMAND

for pid in `ls /proc/ | grep "^[0-9]" | sort -n` ; do
        if [[ -a /proc/$pid/status ]]; then
            tty=`awk '{print $7}' /proc/$pid/stat`

            if [[ tty -eq 0 ]]; then
                tty="?"
            else
                tty=`ls -la /proc/$pid/fd/ | grep -m 1 'pts\|tty' | awk '{print $11}' | sed 's/\/*dev\///'`
                if [[ -z "$tty" ]]; then
                    tty="?"
                else
                    tty=`ls -la /proc/$pid/fd/ | grep -m 1 'pts\|tty' | awk '{print $11}' | sed 's/\/*dev\///'`
                fi
            fi

            main_stat=`cat /proc/$pid/status | awk '/State/{ print $2 }'`
            nice_stat=`cat /proc/$pid/stat | awk '{print $19}'`
            if [[ $nice_stat = 0 ]]; then
                nice_stat=""
            elif [[ $nice_stat -gt 0 ]]; then
                nice_stat="N"
            else
                nice_stat="<"
            fi

            lock_stat=`awk '/VmLck/{print $2}' /proc/$pid/status`
            if [[ $lock_stat -gt 0 ]]; then
                lock_stat="L"
            else
                lock_stat=""
            fi

            NSpid=`awk '/NSpid/{print $2}' /proc/$pid/status`
            NSsid=`awk '/NSsid/{print $2}' /proc/$pid/status`
            if [ $NSpid == $NSsid ]; then
                slid_stat="s"
            else
                slid_stat=""
            fi

            m_process=`awk '{print $20}' /proc/$pid/stat`
            if [[ $m_process > 1 ]]; then
                m_process="l"
            else
                m_process=""
            fi

            fg_stat=`awk '{print $8}' /proc/$pid/stat`
            if [[ $fg_stat == "-1" ]]; then
                fg_stat=""
            else
                fg_stat="+"
            fi

            stat="$main_stat""$nice_stat""$lock_stat""$slid_stat""$m_process""$fg_stat"

            utime=`awk '{ print $14 }' /proc/$pid/stat`
            stime=`awk '{ print $15 }' /proc/$pid/stat`
            tick=$((utime+stime))
            sec=$(($tick / 100))
            time=`date -u -d @${sec} +"%M:%S"`

            cmd=`tr -d '\0' < /proc/$pid/cmdline`
            if [ -z "$cmd" ]; then
                cmd="[`awk '/Name/{ print $2 }' /proc/$pid/status`]"
            else
                cmd=`tr -d '\0' < /proc/$pid/cmdline`
                cmd=`echo ${cmd:0:80}`
            fi

            printf "$out_fmt" $pid $tty $stat $time "$cmd"
        else
                continue
        fi
done
