# CORPUS_README

## Prerequisites

开始之前，首先，配置好Py的环境。Global/venv都可以，建议使用后者。我使用的就是虚拟环境，libraries和modules请看同目录下面的`requirements.txt`。建议直接使用Py自带的pip包管理器下载。

```
pip install -r requirements.txt
```

然后，了解我修改后的目录的结构。

```
corpus/
├── one_click.py # 一键运行自动完成全部流程
├── processing/ # 数据处理相关脚本目录
│   ├── parse_pacp.py # pcap包解析相关函数
│   ├── test_get_apps_name.py # 获取应用名的测试脚本
│   ├── tokenizer_/ # 分词器相关代码目录
│   │   └── tokenizer.py # 分词器实现
│   └── traffic_data_csv2csv.py # pcap转csv及csv处理脚本
├── run.sh # 主运行脚本
├── stage1...py  # 阶段1：下载pcap并预处理
├── stage2...py # 阶段2：流量数据统计
├── traffic_data_split.py # 数据集划分脚本
├── utils.py # 工具函数
├── requirements.txt  # Python依赖包列表
├── README.md # 项目说明文档
└── server_credentials.yaml # 服务器账号密码信息
```

## 流程设计

### 第一步：~~从HDFS集群下载pcap包~~/直接从本地获得pcap

\[可忽略\]工具路径：97:/data1/1_ldz/流量大模型/raw_traffic_data/get_raw_traffic/get_raw_traffic_from_hdfs.py  
\[可忽略\]工具描述：从HDFS集群上多进程下载pcap包，保存的结构同集群上存放形式一样  

### 第二步：流量数据预处理  

工具路径：97:/data1/1_ldz/流量大模型/raw_traffic_data_process/_run_youhua.py  
工具描述：  

1. 将pcap数据按对应app_name，根据相关规则处理成中间csv文件。相关规则描述——截断数据包头部仅保留payload部分的前256字节，然后基于五元组信息拼接成完整流量。  
2. 将生成的中间csv文件数据，payload数据按照Bigram分词方式生成预训练所需的csv文件。

### 注意

* hdfs下载，可选，若已经下载到本地可以不需要重新下载
* 基于本地pcap数据的处理，所有pcap的名称，路径保存起来，还需要划分训练及验证测试集，以csv格式进行保存（新增）
* 所有pcap数据提取的payload或者带头部信息的payload，不需要进行token化，以原始字节流形式保存csv 

## PCAP

### 连接服务器

首先，请看同目录下面的`./server_credentials.yaml`获取服务器的username/password。

通过10.234.9.95，跳转到服务器75：192.168.66.75。              
PCAP files在75机器的路径：
`/data1/llm_pcap_process/traffic_data/pcap`

![server 10.234.9.95](./images/one_click.py.png)

![server 192.168.66.75](./images/2025-07-14_11-33.png)

发现数据在这个路径下面。

```bash
[root@datanode75 ~]# cd /data1/llm_pcap_process/traffic_data/pcap
[root@datanode75 pcap]# ls
2023-01-01  2023-01-09  2023-01-30  2023-02-15  2023-02-23  2023-03-03  2023-03-11  2023-03-19  2023-03-27  2023-04-04
2023-01-02  2023-01-10  2023-01-31  2023-02-16  2023-02-24  2023-03-04  2023-03-12  2023-03-20  2023-03-28  2023-04-06
2023-01-03  2023-01-11  2023-02-01  2023-02-17  2023-02-25  2023-03-05  2023-03-13  2023-03-21  2023-03-29  2023-04-07
2023-01-04  2023-01-12  2023-02-02  2023-02-18  2023-02-26  2023-03-06  2023-03-14  2023-03-22  2023-03-30  2023-04-10
2023-01-05  2023-01-13  2023-02-03  2023-02-19  2023-02-27  2023-03-07  2023-03-15  2023-03-23  2023-03-31  2023-04-11
2023-01-06  2023-01-17  2023-02-04  2023-02-20  2023-02-28  2023-03-08  2023-03-16  2023-03-24  2023-04-01  2023-04-12
2023-01-07  2023-01-28  2023-02-09  2023-02-21  2023-03-01  2023-03-09  2023-03-17  2023-03-25  2023-04-02  2023-04-13
2023-01-08  2023-01-29  2023-02-14  2023-02-22  2023-03-02  2023-03-10  2023-03-18  2023-03-26  2023-04-03  2023-04-14
```

查看folder size。发现过大。

```bash
[root@datanode75 pcap]# du -sh /data1/llm_pcap_process/traffic_data/pcap
1009G   /data1/llm_pcap_process/traffic_data/pcap
```

先用目录下第一个`2023-01-01`试看。还是太大，今天中午跟下午应该下载不完。

```bash
[root@datanode75 pcap]# du -sh /data1/llm_pcap_process/traffic_data/pcap/2023-01-01
24G     /data1/llm_pcap_process/traffic_data/pcap/2023-01-01
```

决定先用这个`/data1/llm_pcap_process/traffic_data/pcap/2023-01-01/com.tencent.tmgp.xxyg`。

```bash
[root@datanode75 pcap]# du -sh /data1/llm_pcap_process/traffic_data/pcap/2023-01-01/com.tencent.tmgp.xxyg
493M    /data1/llm_pcap_process/traffic_data/pcap/2023-01-01/com.tencent.tmgp.xxyg
```

### HDFS集群下载

暂时在`stage1`中注释掉HDFS这部分内容。使用本地数据。

### 下载到本地

SCP工具不能直接下载PCAP到本地。

```bash
[10354278@LIN-82D624853E4 ~]$ scp -r root@192.168.66.75:/data1/llm_pcap_process/traffic_data/pcap /home/10354278/下载
ssh: connect to host 192.168.66.75 port 22: Connection timed out
```

因为有跳板机，加 `-o ProxyJump=...`

```bash
scp -r -o ProxyJump=root@10.234.9.95 root@192.168.66.75:/data1/llm_pcap_process/traffic_dta/pcap /home/10354278/下载
```
![download](./images/2025-07-14_11-41.png)

## Shell脚本

### 用法

给予权限。

```bash
chmod +x run.sh
```

脚本命令行，如果不带参数，

```bash
./run.sh
```

返回用法：
* 第一阶段
* 第二阶段
* “一键式”流程，自动完成所有数据处理步骤而无需手动分步执行。

```
Usage: ./run.sh {stage1|stage2|one_click}
  stage1: Run stage1_traffic_pcap_download_and_process.py
  stage2: Run stage2_traffic_corpus_statistic_single_node.py
  one_click: Run one_click.py
```

### 路径参数

注意python的alias和路径。根据自己的global路径或者虚拟环境和alias设置填写`python`，`python3`，`python3.6`，`python3.7`，`python3.8`，`python3.9`等等。

```bash
case $SCRIPT_TYPE in
    "stage1")
        ........................
        # If in MacOS, use python3; if in Linux, use python, if in Windows, use python.
        python stage1_traffic_pcap_download_and_process.py \
        ........................
    "stage2")
        ........................
        # If in MacOS, use python3; if in Linux, use python, if in Windows, use python.
        python stage2_traffic_corpus_statistic_single_node.py \
        ........................
    "one_click")
        echo "Running one_click: all stages..."
        # If in MacOS, use python3; if in Linux, use python, if in Windows, use python.
        python one_click.py \
        ........................
esac
```

修改路径，hdfs对应的可以不动。

```
case $SCRIPT_TYPE in
    "stage1")
        ......
        --hdfs_base_path '/data1/scrawl/pcap' \
        --local_base_path '/home/10354278/下载/pcap' \
        --target_base_path '/home/10354278/下载/data_processed/target' \
        --save_path_pcap '/home/10354278/下载/data_processed/pcap' \
        --save_path_csv '/home/10354278/下载/data_processed/csv'
```

## Py实现

`ValueError: invalid tcpdump header`数据损坏或存在其他问题。待解决。

```
(.venv) [10354278@LIN-82D624853E4 corpus]$ ./run.sh stage1
Running stage1: traffic pcap download and process...
目标文件层级结构创建完毕！
文件划分完毕！
源文件路径已删除！
1
hanging 2023-01-01:   0%|                                                                       | 0/8 [00:00<?, ?it/s]
concurrent.futures.process._RemoteTraceback: 
"""
Traceback (most recent call last):
  File "stage1_traffic_pcap_download_and_process.py", line 149, in parse_pcap
    pcap = dpkt.pcap.Reader(pcap_f)
  File "/home/10354278/文档/Assignments/corpus/.venv/lib64/python3.8/site-packages/dpkt/pcap.py", line 328, in __init__
    raise ValueError('invalid tcpdump header')
ValueError: invalid tcpdump header
```