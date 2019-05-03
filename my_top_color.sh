#!/bin/bash

function my_ps_color
{
    pid_array=`ls /proc | grep -E '^[0-9]+$'`
    clock_ticks=$(getconf CLK_TCK)
    total_memory=$( grep -Po '(?<=MemTotal:\s{8})(\d+)' /proc/meminfo )

    cat /dev/null > .data.ps

    for pid in $pid_array
    do
        if [ -r /proc/$pid/stat ]
        then
            stat_array=( `cat /proc/$pid/stat` )
            uptime_array=( `cat /proc/uptime` )
            statm_array=( `cat /proc/$pid/statm` )
            comm=$( cut -f1 -d'/' /proc/$pid/comm )
            user_id=$( grep -Po '(?<=Uid:\s)(\d+)' /proc/$pid/status )

            user=$( id -nu $user_id )
            uptime=${uptime_array[0]}

            state=${stat_array[2]}
            ppid=${stat_array[3]}
            tty_nr=${stat_array[6]}
            priority=${stat_array[17]}
            nice=${stat_array[18]}

            utime=${stat_array[13]}
            stime=${stat_array[14]}
            cutime=${stat_array[15]}
            cstime=${stat_array[16]}
            num_threads=${stat_array[19]}
            starttime=${stat_array[21]}

            total_time=$(( $utime + $stime ))
            #Waited-for children's CPU time spent in user and kernel code
#           total_time=$(( $total_time + $cutime + $cstime ))
            seconds=$( awk 'BEGIN {print ( '$uptime' - ('$starttime' / '$clock_ticks') )}' )
            cpu_usage=$( awk 'BEGIN {print ( 100 * (('$total_time' / '$clock_ticks') / '$seconds') )}' )

            resident=${statm_array[1]}
            data_and_stack=${statm_array[5]}
            memory_usage=$( awk 'BEGIN {print( (('$resident' + '$data_and_stack' ) * 100) / '$total_memory'  )}' )

            printf "%d;%d;%s;%d;%-d;%s;%s;%.2f;%.2f;%s\n" $pid $ppid $user $priority $nice $state $num_threads $memory_usage $cpu_usage $comm >> .data.ps

        fi
    done

    clear
    printf "\e[30;107m%-6s %-6s %-10s %-4s %-3s %-6s %-4s %-7s %-7s %-18s\e[0m\n" "PID" "PPID" "USER" "PR" "NI" "STATE" "THR" "%MEM" "%CPU" "COMMAND"

    while IFS=';' read -r f1 f2 f3 f4 f5 f6 f7 f8 f9 f10
    do
        printf "%-6d %-6d %-10s %-4d %-5d " $f1 $f2 $f3 $f4 $f5

        if [ $f6 == "S" ]
        then
            printf "%-4s " $f6
        elif [ $f6 == "R" ]
        then
            printf "\e[1;32m%-4s\e[0m " $f6
        else
            printf "\e[1;31m%-4s\e[0m " $f6
        fi

        printf "%-4u " $f7

        printf "%-7.2f " $f8
#        if (( $(awk 'BEGIN {print ('$f8'< 3)}') )) #$(echo "$f8 < 0.5" |bc -l)
#        then
#            printf "%-7.2f " $f8
#        elif (( $(awk 'BEGIN {print ('$f8'< 6)}') )) #$(echo "$f8 < 5.0" |bc -l)
#        then
#            printf "\e[1;33m%-7.2f\e[0m " $f8
#        else
#            printf "\e[1;31m%-7.2f\e[0m " $f8
#        fi

        if (( $(awk 'BEGIN {print ('$f8'< 0.5)}') )) #$(echo "$f8 < 0.5" |bc -l)
        then
            printf "%-7.2f " $f9
        elif (( $(awk 'BEGIN {print ('$f8'< 5)}') )) #$(echo "$f8 < 5.0" |bc -l)
        then
            printf "\e[1;33m%-7.2f\e[0m " $f9
        else
            printf "\e[1;31m%-7.2f\e[0m " $f9
        fi

        printf "%-18s\n" $f10
    done < <(sort -t";" -nr -k9 .data.ps | head -$1)
}

while true
do

    terminal_height=$(tput lines)
    lines=$( awk 'BEGIN {print ( '$terminal_height' - 2 )}' )
    my_ps_color $lines
#    break
#    sleep 0.7

done



