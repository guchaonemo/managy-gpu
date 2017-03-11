#!/usr/bin/bash

######################################################
#
# File Name:    taskflow.sh
#
# Function:     流程控制模块，通过配置文件，控制多个任务的运行。支持自动重试、错误忽略、发送邮件等功能。
#
# Usage:        source taskflow.sh，依赖于globals.sh, log.sh
#
# Input:        任务列表文件结构：任务执行目录 任务执行命令（命令中可包含空格），每个任务一行
#
# Output:       none
#
# Author: guchao
#
# Create Time:    2016-12-05 16:18:10
#
######################################################

# TODO: 并行化任务执行
OK=0
ERR=1

# 工作目录
WORK_PATH=$(cd "$(dirname "$0")"; pwd)

# 是否在一个任务执行失败后停止整个流程，0不停止，1停止
EXIT_ON_ERROR=0

# 是否发送失败状态邮件
SEND_EMAIL=1

# 最大重试次数
MAX_RETRY_NUM=3

# 重试之间等待的时间，单位：秒
RETRY_GAP=20

# 任务执行之间的等待时间，单位：秒
TASK_GAP=0

FilePAth='/home/guchao'
# 存放空闲的GPU编号

USED_GPUS=${FilePAth}/USED_GPUS
ALL_GPUS=${FilePAth}/ALL_GPUS
######################################################
#
# Function:   判断哪个GPU空闲
#
# Params:
#           TASK_DIR: 任务执行目录，在执行命令前，会先cd到这个目录中
#           TASK_CMD: 任务执行命令，命令中可以包含空格
#
# Return:   $OK, $ERR
#
######################################################
function Empty_Gpu()
{
    running=`nvidia-smi | grep -A 10 'PID' | tail -n +3 | head -n -1| awk '{print $2}'`
    rm -rf ${USED_GPUS}
    if [ ! -f ${USED_GPUS} ]; then
        echo 'USED GPUS' >${USED_GPUS}
    fi

    for arg in ${running};do
        if [[ ${arg} =~ ^[0-9]+$ ]]
           then
             echo ${arg} >>${USED_GPUS}
        fi
    done
    Unsed_GPU=`grep -F -v -f ${USED_GPUS} ${ALL_GPUS}`
    echo ${Unsed_GPU}
}

function main ()
{     COMMONDFILE=$1
      while read -r line ;do 
        i=0
        while [ "$i" -eq "0" ];do
              sleep 15
              Unsed_GPU=`Empty_Gpu`
              for each in ${Unsed_GPU};do
                  ((i=i+1))
              done
              if [ "$i" -gt "0" ];then
                  break
              fi
        done
        for each in ${Unsed_GPU};do
        #     line=`echo -n ${line} | tr -d `
             echo "${line}${each}"
             `${line}  ${each}`&
        #    echo     "${line}${each}"
        #    echo  -e "The Promgram is excuting on ${line} GPU ${each}"
            break
        done
    done < ${COMMONDFILE}
}
main $@
