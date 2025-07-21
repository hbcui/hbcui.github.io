# 第一阶段完善

### 阶段1

#### 主流程控制脚本传参

`run.sh`不要使用字符串类型的生成格式传递到py！！！

```bash
        --use_tokenizer 'false' \
        --payload_mode 'with_header'
```

修改简化像下面这样。

```bash
        --payload_header
        # --use_tokenizer
```

对应的传递内容在`one_click.py`和`stage1_traffic_pcap_download_and_process.py`中也要改。使用boolean类型。action='store_true' 或 action='store_false'。

* action='store_true'：加参数为 True，不加为 False
* action='store_false'：加参数为 False，不加为 True
* 不要使用type=bool，无论传--use_tokenizer false还是--use_tokenizer true，只要有参数，传到Py里面boolean里都是True，因为bool('false') == True。

```python
    parser.add_argument("--use_tokenizer", action='store_true', default=False, help="flowData是否使用tokenizer")
    parser.add_argument("--payload_header", action='store_true', default=True, help="是否保存带头部的payload")
  
    ................
    # tokenizer =  'Bigram' # 默认使用Bigram tokenizer，现在默认可以不使用tokenizer，在run.sh中设置 --use_tokenizer false。
    # 根据参数决定是否使用tokenizer
    if args.use_tokenizer:
        tokenizer_ = 'Bigram'
    else:
        tokenizer_ = 'raw_bytes'
```

#### 可选是否包含头部的payload

增加payload_mode，下面是在`stage1_traffic_pcap_download_and_process.py`中的修改。

```python
def parse_pcap(app_pcap_list, save_path, payload_mode='payload'):
    ......................
                try:
                    response_data = parse_packet(buf, payload_mode=payload_mode)
                except Exception as e:

def create_run(path, save_path, payload_mode='payload'):
    ...............

if __name__ == "__main__":
    '''
    eg.
        hdfs_base_path = '/data1/scrawl/pcap'
        local_base_path = '/data1/traffic_data/pcap'
        target_base_path = '/data1/traffic_data/pcap_split'
        save_path_pcap = '/data1/traffic_data/filter_processed_pcap'
        save_path_csv = '/data1/traffic_data/filter_processed_csv'
    '''
    # 参数输入解析
    ...............................
    parser.add_argument("--payload_mode", type=str, default='payload', help="payload保存模式: payload(只保存payload) 或 with_header(保存带头部的payload)")
    args = parser.parse_args()

    ##### step 1: 流量数据下载
    .................
        create_run(target_base_path, save_path_pcap, args.payload_mode)
```

修改`processing/parse_pacp.py`支持两种模式。在`parse_packet`增加参数`payload_mode`并在调用时传递。

```python
# 新增：添加payload_mode参数
def parse_packet(packet, payload_mode='payload'):
  .................
    # =================== 初步解析数据包，考虑是否剔除头部，获得payload ========================== #
    # 根据配置获取payload字节
    save_data = ''
    if payload_header:
        # 只保存IP头部+传输层头部+payload（不含Ethernet头）
        save_data = ip.pack().hex()
    else:
        # 只保存payload
        save_data = trans_layer.data.hex()
```

最后修改一下控制流程的脚本文件`run.sh`。在最后一行增加`--payload_header`。

```bash
case $SCRIPT_TYPE in
    "stage1")
        echo "Running stage1: traffic pcap download and process..."
        # If in MacOS, use python3; if in Linux, use python, if in Windows, use python.
        # 新增：use_tokenizer 'false'， 默认不使用tokenizer
        # 新增：添加payload_mode参数，默认保存payload
        python stage1_traffic_pcap_download_and_process.py \
        --hdfs_base_path '/data1/scrawl/pcap' \
        --local_base_path '/home/10354278/下载/pcap' \
        --target_base_path '/home/10354278/下载/data_processed/target' \
        --save_path_pcap '/home/10354278/下载/data_processed/pcap' \
        --save_path_csv '/home/10354278/下载/data_processed/csv' \
        --payload_header
        # --use_tokenizer
        ;;
```

验证结果。运行`run.sh`第一阶段：

```bash
./run.sh stage1
```

查看CSV数据, 从ip头部开始。符合要求！！

```
five_tuple,app_name,app_version,protocol,flow_len,packet_num,flow_data
192.168.0.3:53265_211.152.118.11:80_TCP,WeChat,1.1.1,HTTP,603,2,4500018b1d5640008006d1c7c0a80003d398760b............
```

#### 解析五元组流的协议（注意这里主要应用层，不是传输层协议）

首先，解析**应用层**的协议。有2种方法：

* 特征加上端口方案
* 集成库(性能差)
    * nDPI（C库，支持Python绑定）：自动识别数百种协议，准确率高
    * libprotoident（C库）：基于payload和统计特征自动识别
    * pyshark（基于Wireshark）：能用Wireshark的协议解析能力

下面是产生的csv新增第四列：`protocol`。

```
five_tuple,app_name,app_version,protocol,flow_len,packet_num,flow_data
221.177.16.132:2152_221.177.16.227:2152_UDP,WeChat,1.1.1,GTP-U,1341,9,450000644f7800003e115047ddb110e3ddb11
```

详细的端口和特征规则看新创建的解析器`processing/protocol_parser.py`。

```python
......
class ProtocolParser:
    def __init__(self):
        # 只保留常规协议端口
        self.port_protocols = {
            21: 'FTP', 22: 'SSH', 23: 'TELNET', 25: 'SMTP', 53: 'DNS',
            80: 'HTTP', 110: 'POP3', 143: 'IMAP', 443: 'HTTPS', 993: 'IMAPS',
            995: 'POP3S', 8080: 'HTTP', 8443: 'HTTPS'
        }
        # 只保留常规协议特征
        self.protocol_patterns = {
            'HTTP': [b'GET ', b'POST ', b'PUT ', b'DELETE ', b'HEAD ', b'HTTP/'],
            'HTTPS': [b'\x16\x03', b'\x17\x03'],
            'FTP': [b'USER ', b'PASS ', b'QUIT ', b'220 ', b'331 '],
            'SMTP': [b'HELO ', b'MAIL ', b'RCPT ', b'DATA ', b'220 ', b'250 '],
            'POP3': [b'USER ', b'PASS ', b'QUIT ', b'+OK ', b'-ERR '],
            'IMAP': [b'LOGIN ', b'SELECT ', b'FETCH ', b'* OK ', b'* NO '],
            'DNS': [b'\x00\x01', b'\x00\x02', b'\x00\x05', b'\x00\x06'],
            'SSH': [b'SSH-'],
            'TELNET': [b'\xff\xfd', b'\xff\xfe', b'\xff\xff'],
        }
......
```

之后，在`processing/parse_pcap.py`原有解析基础上加入上面的新解析器。

```python
        # ========== 使用新的协议解析器解析应用层协议 ==========
        app_layer = 'UNKNOWN'
        try:
            # 首先尝试根据端口检测协议
            app_layer = protocol_parser.detect_protocol_by_port(port_dst)
            if app_layer == 'UNKNOWN' or app_layer is None:
                app_layer = protocol_parser.detect_protocol_by_port(port_src)
            # 如果端口检测失败，尝试根据payload检测
            if app_layer == 'UNKNOWN' or app_layer is None:
                app_layer = protocol_parser.detect_protocol_by_payload(trans_layer.data)
            # 如果还是UNKNOWN，使用原有的解析方法作为备选
            if app_layer == 'UNKNOWN':
                if protocol == 'UDP':
                    app_layer = parse_dns(trans_layer.data)
                else:
                    app_layer, sni = parse_tcp_payload(trans_layer.data)
        except Exception as e:
            # 如果新解析器出错，使用原有方法
            if protocol == 'UDP':
                app_layer = parse_dns(trans_layer.data)
            else:
                app_layer, sni = parse_tcp_payload(trans_layer.data)
```

#### 数据集划分

修改`./stage1_traffic_pcap_download_and_process.py`里代码为每个数据集（训练/验证/评测）创建了带时间戳的子目录。目的是CSV文件保存在 csv/训练、csv/验证、csv/评测 这三个文件夹中，但是不要带时间戳的子目录。

办法是只需要把`save_path_csv`的`{datatime_str}`去掉。其他的暂时不动。

```python
        # save_path_csv = f'{args.save_path_csv}/{folder}/{datetime_str}'
        # 修改：CSV文件保存在csv/训练、csv/验证、csv/评测目录下，不创建时间戳子目录
        save_path_csv = f'{args.save_path_csv}/{folder}'
        os.makedirs(save_path_csv, exist_ok=True)
```

验证数据集划分的结构。现在简化了。

```
(.venv) [10354278@LIN-82D624853E4 corpus_path]$ tree data_processed/csv
data_processed/csv
├── 训练
│   └── training.csv
├── 评测
│   └── testing.csv
└── 验证
    └── validation.csv

3 directories, 3 files
```
