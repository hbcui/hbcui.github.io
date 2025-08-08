### 结果

把最后改动的程序放到服务器上，上午放上去，晚上9点多结束。下面是一些基本信息、统计的流数和流协议的分布情况。

```bash
(.venv) [root@datanode62 corpus]# tree /data1/chatPcap_data/processed/ -L 3
/data1/chatPcap_data/processed/
└── pcap_2022_03
    ├── csv
    │   ├── testing.csv
    │   ├── training.csv
    │   └── validation.csv
    └── target
        └── dataset_split.csv

3 directories, 4 files
```

```bash
(.venv) [root@datanode62 corpus]# du -sh /data1/chatPcap_data/processed/pcap_2022_03/* && ls -lh /data1/chatPcap_data/processed/pcap_2022_03/csv/
65G     /data1/chatPcap_data/processed/pcap_2022_03/csv
11M     /data1/chatPcap_data/processed/pcap_2022_03/target
total 65G
-rw-r--r-- 1 root root 24G Aug  7 21:22 testing.csv
-rw-r--r-- 1 root root 20G Aug  7 15:14 training.csv
-rw-r--r-- 1 root root 22G Aug  7 18:14 validation.csv
```

```bash
echo "=== 训练集协议分布 ===" && cut -d',' -f4 /data1/chatPcap_data/processed/pcap_2022_03/csv/training.csv | tail -n +2 | sort | uniq -c | sort -nr
=== 训练集协议分布 ===
1775881 TLS
 757051 HTTP
 190496 UNKNOWN
     89 HTTPS
     33 GTP-U
```

```bash
echo "=== 验证集协议分布 ===" && cut -d',' -f4 /data1/chatPcap_data/processed/pcap_2022_03/csv/validation.csv | tail -n +2 | sort | uniq -c | sort -nr
=== 验证集协议分布 ===
2027002 TLS
 865342 HTTP
 221493 UNKNOWN
    100 HTTPS
     39 GTP-U
```

```bash
echo "=== 测试集协议分布 ===" && cut -d',' -f4 /data1/chatPcap_data/processed/pcap_2022_03/csv/testing.csv | tail -n +2 | sort | uniq -c | sort -nr
=== 测试集协议分布 ===
2199218 TLS
 942724 HTTP
 242286 UNKNOWN
    104 HTTPS
     44 GTP-U
```

```bash
(.venv) [root@datanode62 corpus]# echo "=== 总体统计 ===" && echo "训练集总流数: $(($(wc -l < /data1/chatPcap_data/processed/pcap_2022_03/csv/training.csv) - 1))" && echo "验证集总流数: $(($(wc -l < /data1/chatPcap_data/processed/pcap_2022_03/csv/validation.csv) - 1))" && echo "测试集总流数: $(($(wc -l < /data1/chatPcap_data/processed/pcap_2022_03/csv/testing.csv) - 1))"
=== 总体统计 ===
训练集总流数: 2723550
验证集总流数: 3113976
测试集总流数: 3384376
```