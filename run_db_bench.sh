#!/bin/bash
#set -x
KB=$((1024))
MB=$(($KB*1024))
GB=$(($MB*1024))
# APP_PREFIX=sudo
APP_PREFIX="numactl --cpunodebind=0 --membind=0"
export TEST_TMPDIR=/mnt/pmem0.1/pmemdir

db_path=$(pwd)
db_bench=$db_path/out-static
db_include=$db_path/include
ycsb_path=$db_path/ycsbc

sata_path=/tmp/pm_test
ssd_path=/media/nvme/pm_test
pm_path=/mnt/pmem0.1/pm_test
# leveldb_path=/tmp/leveldb-wzh
leveldb_path=$pm_path
output_path=$db_path/output
output_file=$output_path/result.out

# export CPLUS_INCLUDE_PATH=$db_path/include:$CPLUS_INCLUDE_PATH
# export LIBRARY_PATH=$db_path/out-static:$LIBRARY_PATH

benchmarks="overwrite,readrandom,readseq,stats"
# benchmarks2="fillseqNofresh,readrandom,readseq,stats"
ycsb_input=1KB_ALL

num_thread=1
value_size=1024
num_kvs=$((10*$MB))
write_buffer_size=$((64*$MB))
max_file_size=$((128*$MB))
pm_size=$((200*$GB))
use_pm=1
throughput=0
db_disk=$pm_path
db_mem=$pm_path

#DRAM buffer size in MB
export DRAMBUFFSZ=64
#NVM buffer size in MB
export NVMBUFFSZ=$((32 * 1024))

WRITE80G_8GNVM_1K_FLUSHSSD() {
    db_disk=$ssd_path
    value_size=$((1*$KB))
    num_kvs=$((80*$GB / $value_size))
    NVMBUFFSZ=$((8*1024))
}
WRITE80G_16GNVM_1K_FLUSHSSD() {
    db_disk=$ssd_path
    value_size=$((1*$KB))
    num_kvs=$((80*$GB / $value_size))
    NVMBUFFSZ=$((16*1024))
}
WRITE80G_32GNVM_1K_FLUSHSSD() {
    db_disk=$ssd_path
    value_size=$((1*$KB))
    num_kvs=$((80*$GB / $value_size))
    NVMBUFFSZ=$((32*1024))
}
WRITE80G_64GNVM_1K_FLUSHSSD() {
    db_disk=$ssd_path
    value_size=$((1*$KB))
    num_kvs=$((80*$GB / $value_size))
    NVMBUFFSZ=$((64*1024))
}
WRITE80G_8GNVM_4K_FLUSHSSD() {
    db_disk=$ssd_path
    value_size=$((4*$KB))
    num_kvs=$((80*$GB / $value_size))
    NVMBUFFSZ=$((8*1024))
}
WRITE80G_16GNVM_4K_FLUSHSSD() {
    db_disk=$ssd_path
    value_size=$((4*$KB))
    num_kvs=$((80*$GB / $value_size))
    NVMBUFFSZ=$((16*1024))
}
WRITE80G_32GNVM_4K_FLUSHSSD() {
    db_disk=$ssd_path
    value_size=$((4*$KB))
    num_kvs=$((80*$GB / $value_size))
    NVMBUFFSZ=$((32*1024))
}
WRITE80G_64GNVM_4K_FLUSHSSD() {
    db_disk=$ssd_path
    value_size=$((4*$KB))
    num_kvs=$((80*$GB / $value_size))
    NVMBUFFSZ=$((64*1024))
}
WRITE80G-256B() {
    value_size=$((256))
    num_kvs=$((80*$GB / $value_size))
}
WRITE80G() {
    value_size=$((1*$KB))
    num_kvs=$((80*$GB / $value_size))
}
WRITE80G-4K() {
    value_size=$((4*$KB))
    num_kvs=$((80*$GB / $value_size))
}
WRITE80G-16K() {
    value_size=$((16*$KB))
    num_kvs=$((80*$GB / $value_size))
}
WRITE80G-64K() {
    value_size=$((64*$KB))
    num_kvs=$((80*$GB / $value_size))
}
WRITE80G-1KB-THROUGHPUT() {
    value_size=$((1*$KB))
    num_kvs=$((80*$GB / $value_size))
    throughput=1
}
WRITE80G-4KB-THROUGHPUT() {
    value_size=$((4*$KB))
    num_kvs=$((80*$GB / $value_size))
    throughput=1
}
RUN_DB_BENCH() {
    CLEAN_DB
    if [ -f "$output_file" ]; then
        rm $output_file
        echo "delete output_file: $output_file"
    fi
    parameters="
                --benchmarks=$benchmarks \
                --threads=$num_thread \
                --num=$num_kvs \
                --value_size=$value_size \
                --num_levels=2 \
                --write_buffer_size=$DRAMBUFFSZ \
                --nvm_buffer_size=$NVMBUFFSZ \
                --db_disk=$db_disk \
                --db_mem=$db_mem \
                --throughput=$throughput
                "

    # parameters="--benchmarks=$benchmarks \
    #             --num=$num_kvs \
    #             --value_size=$value_size \
    #             --write_buffer_size=$write_buffer_size \
    #             --max_file_size=$max_file_size \
    #             --pm_size=$pm_size \
    #             --pm_path=$pm_path \
    #             --db=$leveldb_path \
    #             --bucket_nums=$bucket_nums \
    #             --use_pm=$use_pm \
    #             --threads=$num_thread \
    #             --flush_ssd=$flush_ssd
    #             "
    cmd="$APP_PREFIX $db_bench/db_bench $parameters >> $output_file"
    echo $cmd >> $output_file
    echo $cmd
    eval $cmd
}

RUN_YCSB(){
    CLEAN_DB
    if [ -f "$output_file" ]; then
        rm $output_file
        echo "delete output_file: $output_file"
    fi
    cmd="$APP_PREFIX $ycsb_path/ycsbc $ycsb_path/input/$ycsb_input >> $output_file"
    echo $cmd >> $output_file
    echo $cmd
    eval $cmd
}

CLEAN_DB() {
  if [ -z "$db_mem" ]
  then
        echo "PM path empty."
        exit
  fi
  if [ -z "$db_disk" ]
  then
        echo "DB path empty."
        exit
  fi
  rm -rf ${db_disk:?}/*
  rm -rf ${db_mem:?}/*
#   mkdir -p $pm_path
}

SET_OUTPUT_PATH() {
    if [ ! -d "$output_path" ]; then
        # 如果目录不存在，则创建目录
        mkdir $output_path
        echo "Created output_path: $output_path"
    fi
    # else
    #     # 如果目录已存在，则清空目录下的所有文件
    #     rm -rf "${output_path:?}/"*
    #     echo "Cleared output_path: $output_path"
    # fi
    # touch $output_file
    # echo "Created file: $output_file"
}

MAKE() {
  cd $db_path
  make -j8
  cd $ycsb_path
  #make clean
  make
  cd ..
}

DB_BENCH_TEST() {
    echo "------------db_bench------------"
    benchmarks="fillrandom,readrandom,stats"
    echo "------256B random write/read-----"
    output_file=$output_path/Rnd_NVM_256B
    WRITE80G-256B
    RUN_DB_BENCH

    echo "------1KB random write/read-----"
    output_file=$output_path/Rnd_NVM_1K
    WRITE80G
    RUN_DB_BENCH

    echo "------4KB random write/read-----"
    output_file=$output_path/Rnd_NVM_4K
    WRITE80G-4K
    RUN_DB_BENCH

    echo "------16KB random write/read-----"
    output_file=$output_path/Rnd_NVM_16K
    WRITE80G-16K
    RUN_DB_BENCH

    echo "------64KB random write/read-----"
    output_file=$output_path/Rnd_NVM_64K
    WRITE80G-64K
    RUN_DB_BENCH


    benchmarks="fillseq,readseq,stats"
    echo "------256B random write/read-----"
    output_file=$output_path/Seq_NVM_256B
    WRITE80G-256B
    RUN_DB_BENCH

    echo "------1KB sequential write/read-----"
    output_file=$output_path/Seq_NVM_1K
    WRITE80G
    RUN_DB_BENCH

    echo "------4KB sequential write/read-----"
    output_file=$output_path/Seq_NVM_4K
    WRITE80G-4K
    RUN_DB_BENCH

    echo "------16KB sequential write/read-----"
    output_file=$output_path/Seq_NVM_16K
    WRITE80G-16K
    RUN_DB_BENCH

    echo "------64KB sequential write/read-----"
    output_file=$output_path/Seq_NVM_64K
    WRITE80G-64K
    RUN_DB_BENCH

    CLEAN_DB
}

DB_BENCH_TEST_FLUSHSSD() {
    echo "----------db_bench_flushssd----------"
    benchmarks="fillrandom,readrandom,stats"
    echo "---8GNVM--1KB random write/read---"
    output_file=$output_path/NVM8G_Rnd_1K
    WRITE80G_8GNVM_1K_FLUSHSSD
    RUN_DB_BENCH

    echo "---16GNVM--1KB random write/read---"
    output_file=$output_path/NVM16G_Rnd_1K
    WRITE80G_16GNVM_1K_FLUSHSSD
    RUN_DB_BENCH

    echo "---32GNVM--1KB random write/read---"
    output_file=$output_path/NVM32G_Rnd_1K
    WRITE80G_32GNVM_1K_FLUSHSSD
    RUN_DB_BENCH

    echo "---64GNVM--1KB random write/read---"
    output_file=$output_path/NVM64G_Rnd_1K
    WRITE80G_64GNVM_1K_FLUSHSSD
    RUN_DB_BENCH


    benchmarks="fillseq,readseq,stats"
    echo "---8GNVM--1KB seq write/read---"
    output_file=$output_path/NVM8G_Seq_1K
    WRITE80G_8GNVM_1K_FLUSHSSD
    RUN_DB_BENCH

    echo "---16GNVM--1KB seq write/read---"
    output_file=$output_path/NVM16G_Seq_1K
    WRITE80G_16GNVM_1K_FLUSHSSD
    RUN_DB_BENCH

    echo "---32GNVM--1KB seq write/read---"
    output_file=$output_path/NVM32G_Seq_1K
    WRITE80G_32GNVM_1K_FLUSHSSD
    RUN_DB_BENCH

    echo "---64GNVM--1KB seq write/read---"
    output_file=$output_path/NVM64G_Seq_1K
    WRITE80G_64GNVM_1K_FLUSHSSD
    RUN_DB_BENCH

    db_disk=$pm_path
    CLEAN_DB
}

DB_BENCH_TEST_FLUSHSSD_4K() {
    echo "----------db_bench_flushssd----------"
    benchmarks="fillrandom,readrandom,stats"
    echo "---8GNVM--4Kb random write/read---"
    output_file=$output_path/NVM8G_Rnd_4K
    WRITE80G_8GNVM_4K_FLUSHSSD
    RUN_DB_BENCH

    echo "---16GNVM--4Kb random write/read---"
    output_file=$output_path/NVM16G_Rnd_4K
    WRITE80G_16GNVM_4K_FLUSHSSD
    RUN_DB_BENCH

    echo "---32GNVM--4Kb random write/read---"
    output_file=$output_path/NVM32G_Rnd_4K
    WRITE80G_32GNVM_4K_FLUSHSSD
    RUN_DB_BENCH

    echo "---64GNVM--4Kb random write/read---"
    output_file=$output_path/NVM64G_Rnd_4K
    WRITE80G_64GNVM_4K_FLUSHSSD
    RUN_DB_BENCH


    benchmarks="fillseq,readseq,stats"
    echo "---8GNVM--4Kb seq write/read---"
    output_file=$output_path/NVM8G_Seq_4K
    WRITE80G_8GNVM_4K_FLUSHSSD
    RUN_DB_BENCH

    echo "---16GNVM--4Kb seq write/read---"
    output_file=$output_path/NVM16G_Seq_4K
    WRITE80G_16GNVM_4K_FLUSHSSD
    RUN_DB_BENCH

    echo "---32GNVM--4Kb seq write/read---"
    output_file=$output_path/NVM32G_Seq_4K
    WRITE80G_32GNVM_4K_FLUSHSSD
    RUN_DB_BENCH

    echo "---64GNVM--4Kb seq write/read---"
    output_file=$output_path/NVM64G_Seq_4K
    WRITE80G_64GNVM_4K_FLUSHSSD
    RUN_DB_BENCH

    db_disk=$pm_path
    CLEAN_DB
}

YCSB_TEST(){
    cd $ycsb_path
    echo "------------YCSB------------"
    echo "-----1KB YCSB performance-----"
    output_file=$output_path/YCSB_1KB
    ycsb_input=1KB_ALL
    RUN_YCSB

    echo "-----4KB YCSB performance-----"
    output_file=$output_path/YCSB_4KB
    ycsb_input=4KB_ALL
    RUN_YCSB
    cd ..
}

YCSB_TEST_LATENCY(){
    cd $ycsb_path
    echo "------------YCSB------------"
    echo "-----1KB YCSB latency-----"
    output_file=$output_path/YCSB_1KB_Latency
    ycsb_input=1KB_ALL_Latency
    RUN_YCSB

    echo "-----4KB YCSB latency-----"
    output_file=$output_path/YCSB_4KB_Latency
    ycsb_input=4KB_ALL_Latency
    RUN_YCSB
    cd ..
}

YCSB_TEST_SSD(){
    cd $ycsb_path
    db_disk=$ssd_path

    # echo "------------YCSB------------"
    # echo "-----1KB YCSB SSD-----"
    # output_file=$output_path/YCSB_1KB_SSD
    # ycsb_input=1KB_ALL_SSD
    # RUN_YCSB

    echo "-----4KB YCSB SSD-----"
    output_file=$output_path/YCSB_4KB_SSD
    ycsb_input=4KB_ALL_SSD
    RUN_YCSB
    
    db_disk=$pm_path
    cd ..
}

DB_BENCH_THROUGHPUT() {
    echo "------------db_bench------------"
    benchmarks="fillrandom,stats"

    echo "------1K random write/read-----"
    output_file=$output_path/Throughput_Rnd_NVM_1KB
    WRITE80G-1KB-THROUGHPUT
    RUN_DB_BENCH

    echo "------4K random write/read-----"
    output_file=$output_path/Throughput_Rnd_NVM_4KB
    WRITE80G-4KB-THROUGHPUT
    RUN_DB_BENCH
    throughput=0

    CLEAN_DB
}

DATA_SIZE_ANALYSIS(){
    echo "------data size analysis-------"
    benchmarks="fillrandom,readrandom,stats"
    value_size=$((1*$KB))
    db_disk=$ssd_path

    # echo "---- 40GB 8GNVM----"
    # output_file=$output_path/data_40G
    # NVMBUFFSZ=$((8*1024))
    # write_buffer_size=$((64*$MB))
    # num_kvs=$((40*$GB / $value_size))
    # RUN_DB_BENCH

    # echo "---- 80GB 16GNVM----"
    # output_file=$output_path/data_80G
    # NVMBUFFSZ=$((16*1024))
    # write_buffer_size=$((64*$MB))
    # num_kvs=$((80*$GB / $value_size))
    # RUN_DB_BENCH

    # echo "---- 120GB 24GNVM----"
    # output_file=$output_path/data_120G
    # NVMBUFFSZ=$((24*1024))
    # write_buffer_size=$((64*$MB))
    # num_kvs=$((120*$GB / $value_size))
    # RUN_DB_BENCH

    # echo "---- 160GB 32GNVM----"
    # output_file=$output_path/data_160G
    # NVMBUFFSZ=$((32*1024))
    # write_buffer_size=$((64*$MB))
    # num_kvs=$((160*$GB / $value_size))
    # RUN_DB_BENCH

    echo "---- 200GB 40GNVM----"
    output_file=$output_path/data_200G
    NVMBUFFSZ=$((40*1024))
    write_buffer_size=$((64*$MB))
    num_kvs=$((200*$GB / $value_size))
    RUN_DB_BENCH

    NVMBUFFSZ=$((32*$GB))
    db_disk=$pm_path
}

SMALL_VALUE_TEST(){
    echo "------data size analysis-------"
    benchmarks="fillrandom,readrandom,stats"
    num_kvs=$((100*$MB))
    db_disk=$pm_path

    echo "---- key100M_8B----"
    output_file=$output_path/key100M_8B
    value_size=$((8))
    RUN_DB_BENCH

    echo "---- key100M_32B----"
    output_file=$output_path/key100M_32B
    value_size=$((32))
    RUN_DB_BENCH

    echo "---- key100M_128B----"
    output_file=$output_path/key100M_128B
    value_size=$((128))
    RUN_DB_BENCH

    NVMBUFFSZ=$((32*$GB))
    db_disk=$pm_path
}

MAKE
SET_OUTPUT_PATH

# echo "chapter 4.1"
# DB_BENCH_TEST
# DB_BENCH_THROUGHPUT
# SMALL_VALUE_TEST

# echo "chapter 4.2"
# YCSB_TEST
# YCSB_TEST_LATENCY

echo "chapter 4.3"
DB_BENCH_TEST_FLUSHSSD
# DB_BENCH_TEST_FLUSHSSD_4K
YCSB_TEST_SSD
DATA_SIZE_ANALYSIS

CLEAN_DB

# sudo cp build/libleveldb.a /usr/local/lib/
# sudo cp -r include/leveldb /usr/local/include/
# -exec break __sanitizer::Die