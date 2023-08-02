#!/bin/bash
# Скрипт проверки температуры NVIDIA-карт и экстренной перезагрузки при перегреве

# function RND {
#     echo $(shuf -i 1-7 -n 1)
# }

function Get_GPUs_temp {
    local temps=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits)
    # local temp=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits)
    # temps=${temp}$'\n'$((temp+$(RND)))$'\n'$((temp+$(RND)))$'\n'$((temp+$(RND)))$'\n'$((temp+$(RND)))$'\n'$((temp+$(RND)))
    echo "$temps"
}


IFS=$'\n'
gpus_temp_src=$(Get_GPUs_temp)
gpus_count=$(wc -l <<< "$gpus_temp_src")

bad_temp_count=0
for count in $(seq 1 $((gpus_count-1)))
    do
        bad_temp_count=$bad_temp_count$'\n0'
    done
bad_temp_count=($bad_temp_count)

gpus_temp=($gpus_temp_src)

sleep 300

while true
    do
        source nvgpu_tempmon.conf
        gpus_temp_prev=($gpus_temp_src)
        gpus_temp_src=$(Get_GPUs_temp)
        gpus_temp=($gpus_temp_src)
        new_bad_temp_count=""
        for count in $(seq 0 $((gpus_count-1)))
            do
                checking_gpu_temp=${gpus_temp[$count]}
                checking_gpu_temp_prev=${gpus_temp_prev[$count]}
                checking_bad_temp_count=${bad_temp_count[$count]}
                if  [ $checking_gpu_temp_prev -le $bad_temp ]
                    then
                        checking_bad_temp_count=0
                fi
                if [ $checking_gpu_temp -gt $bad_temp ]
                    then
                        checking_bad_temp_count=$((checking_bad_temp_count+1))
                    else
                        checking_bad_temp_count=0
                fi
                new_bad_temp_count=$new_bad_temp_count$'\n'$checking_bad_temp_count
                if  [ $checking_bad_temp_count -ge $checks_trigger ]
                    then
                        shutdown -P +$shutdown_timeout
                        exit 0
                fi
            done
        bad_temp_count=($new_bad_temp_count)
        # echo $new_bad_temp_count
    sleep $sleep_time
    done
