The BERT architecture builds on top of Transformer. BERT use bidirectional transformer (both left-to-right and right-to-left direction) rather than dictional transformer (left-to-right direction).


```python
import os
import pandas as pd
import torch
import torch.distributed as dist
import torch.nn as nn
from torch.utils.data import DataLoader, Dataset
import numpy as np
from typing import List, Dict, Optional, Tuple
```

## Simple Data

元数据（Metadata）

* 作用：提供额外的上下文信息
* 处理方式：直接保存，不进行tokenization
* 用途：记录、分析、调试

训练数据（Training Data）

* 作用：直接输入模型进行学习
* 处理方式：tokenization、掩码、批处理
* 用途：模型训练和推理

| five_tuple | app_name | app_version | flow_data |
|-----------|-------------|----------|------------|
|(保留为元数据) | (转换为数字标签) | (保留为元数据) | (进入tokenization和掩码) |


```python
def create_sample_data():
    """根据真实流量数据创建示例数据文件"""
    sample_data = [
        {
            'five_tuple': '192.168.31.160:38268_39.136.197.119:443_TCP',
            'app_name': 'cn.emagsoftware.gamehall',
            'app_version': '3.48.1.1',
            'flow_data': '1603 0301 0102 0200 0001 0100 0001 01fc fc03 0303 039b 9bb5 b56a 6af7 f704 040b 0b3d 3da7 a769 691c 1c44 449c 9ca4 a4f6 f6f9 f9aa aa46 463a 3a9d 9dec ec9e 9e2c 2cd6 d671 7174 7440 404f 4f3d 3d76 7665 65e8 e806 0620 202c 2cbc bccc cc1e 1e66 66fe fe7e 7e83 83f7 f7c8 c8b8 b8fc fc27 2707 079e 9ebd bd8f 8fb9 b92d 2d6c 6cbe be51 51ca ca02 02f9 f9fd fda1 a1a4 a401 01b2 b258 58ac ac00 0020 201a 1a1a 1a13 1301 0113 1302 0213 1303 03c0 c02b 2bc0 c02f 2fc0 c02c 2cc0 c030 30cc cca9 a9cc cca8 a8c0 c013 13c0 c014 1400 009c 9c00 009d 9d00 002f 2f00 0035 3501 0100 0001 0193 939a 9a9a 9a00 0000 0000 0000 0000 0011 1100 000f 0f00 0000 000c 0c70 706c 6c75 7573 732e 2e6d 6d69 6967 6775 752e 2e63 636e 6e00 0017 1700 0000 00ff ff01 0100 0001 0100 0000 000a 0a00 000a 0a00 0008 085a 5a5a 5a00 001d 1d00 0017 1700 0018 1800 000b 0b00 0002 0201 0100 0000 0023 2300 0000 0000 0010 1000 000e 0e00 000c 0c02 0268 6832 3208 0868 6874 7474 7470 702f 2f31 312e 2e31 3100 0005 0500 0005 0501 0100 0000 0000 0000 0000 000d 0d00 0012 1200 0010 1004 0403 0308 0804 0404 0401 0105 0503 0308 0805 0505 0501 0108 0806 0606 0601 0100 0012 1200 0000 0000 0033 3300 002b 2b00 0029 295a 5a5a 5a00 0001 0100 0000 001d 1d00 0020 20ff ff9d 9d53 5371 71be be30 3036 3683 83d5 d510 1020 2003 0362 6271 71ab ab53 5341#1603 0301 0102 0200 0001 0100 0001 01fc fc03 0303 039b 9bb5 b56a 6af7 f704 040b 0b3d 3da7 a769 691c 1c44 449c 9ca4 a4f6 f6f9 f9aa aa46 463a 3a9d 9dec ec9e 9e2c 2cd6 d671 7174 7440 404f 4f3d 3d76 7665 65e8 e806 0620 202c 2cbc bccc cc1e 1e66 66fe fe7e 7e83 83f7 f7c8 c8b8 b8fc fc27 2707 079e 9ebd bd8f 8fb9 b92d 2d6c 6cbe be51 51ca ca02 02f9 f9fd fda1 a1a4 a401 01b2 b258 58ac ac00 0020 201a 1a1a 1a13 1301 0113 1302 0213 1303 03c0 c02b 2bc0 c02f 2fc0 c02c 2cc0 c030 30cc cca9 a9cc cca8 a8c0 c013 13c0 c014 1400 009c 9c00 009d 9d00 002f 2f00 0035 3501 0100 0001 0193 939a 9a9a 9a00 0000 0000 0000 0000 0011 1100 000f 0f00 0000 000c 0c70 706c 6c75 7573 732e 2e6d 6d69 6967 6775 752e 2e63 636e 6e00 0017 1700 0000 00ff ff01 0100 0001 0100 0000 000a 0a00 000a 0a00 0008 085a 5a5a 5a00 001d 1d00 0017 1700 0018 1800 000b 0b00 0002 0201 0100 0000 0023 2300 0000 0000 0010 1000 000e 0e00 000c 0c02 0268 6832 3208 0868 6874 7474 7470 702f 2f31 312e 2e31 3100 0005 0500 0005 0501 0100 0000 0000 0000 0000 000d 0d00 0012 1200 0010 1004 0403 0308 0804 0404 0401 0105 0503 0308 0805 0505 0501 0108 0806 0606 0601 0100 0012 1200 0000 0000 0033 3300 002b 2b00 0029 295a 5a5a 5a00 0001 0100 0000 001d 1d00 0020 20ff ff9d 9d53 5371 71be be30 3036 3683 83d5 d510 1020 2003 0362 6271 71ab ab53 5341#1603 0303 0300 007a 7a02 0200 0000 0076 7603 0303 033b 3b32 32e3 e363 638d 8d01 013e 3e19 19df df00 00c3 c38c 8c73 7396 96da da28 284b 4b09 0929 29be be42 4231 3195 95d6 d6db db23 23b5 b509 09c2 c234 34b5 b502 0220 202c 2cbc bccc cc1e 1e66 66fe fe7e 7e83 83f7 f7c8 c8b8 b8fc fc27 2707 079e 9ebd bd8f 8fb9 b92d 2d6c 6cbe be51 51ca ca02 02f9 f9fd fda1 a1a4 a401 01b2 b258 58ac ac13 1302 0200 0000 002e 2e00 002b 2b00 0002 0203 0304 0400 0033 3300 0024 2400 001d 1d00 0020 2026 2632 32f6 f6bf bf12 1233 3353 53d5 d576 7677 77ed ed7d 7deb eb86 861b 1bb4 b49b 9bcb cb3d 3d83 836c 6cf8 f8b6 b6d2 d2d2 d213 1370 70bf bf35 3530 309d 9d78 7814 1403 0303 0300 0001 0101 0117 1703 0303 0300 002a 2a82 824c 4c66 66cf cf01 01e2 e206 06ec ecba bab1 b18b 8b8b 8bd7 d7ac ac7b 7bcd cd7d 7dac ac4d 4d5b 5bf3 f3b7 b721 2122 2276 76ff ff56 5647 473c 3cf0 f090 901c 1c4a 4a1c 1c9b 9bdd ddcb cb7a 7af9 f984 8456 5687 8717 1703 0303 0310 102b 2bce ce3f 3fc8 c81c 1c67 673b 3b4e 4e27 2794 94b8 b838 381d 1df9 f9bc bc4e 4e08 0825 259b 9bae aed3 d376 76c4 c4c5 c57a 7a27 2728 28ff ffb2 b26d 6d5c 5ce1 e1ff ffcc ccb1 b197 973e 3e76 7660 608a 8a89 89b3 b3b7 b740 40ea ea48 48fa fa0e 0e5b 5bda da19 198b 8bfd fd75 75a1 a168 6839 39ca ca23 235a 5aef ef24 24bc bc2e 2ee7 e77f 7ff4 f4b4 b41b 1beb eb66 669a 9a10#275c 5c91 919a 9ab2 b22c 2c8d 8de2 e24b 4b18 18ef efe9 e9d9 d992 925c 5c87 87fc fcc9 c9b7 b7ca ca7c 7cbe be1b 1b3d 3df7 f789 894f 4f90 90e9 e9f3 f31a 1ac0 c015 15fc fca1 a182 82de de97 9721 216d 6d73 7389 8908 0898 98c1 c1c7 c721 2104 0434 34ad adde dee2 e23c 3c53 5391 9100 00d5 d58c 8cc0 c07f 7fe5 e593 9338 383d 3d8a 8a24 24ba baef ef7a 7aa5 a5c8 c8f9 f929 2946 46ab abe9 e991 91ee ee26 2634 3401 017d 7dbe beb8 b89c 9cfb fbcb cba6 a646 4605 0553 5353 5360 6092 9213 1311 114f 4fb0 b0d2 d201 01d7 d764 646b 6bb0 b055 551e 1ebd bd58 58a7 a760 608b 8bee ee81 81d3 d30a 0a5d 5dbb bb91 9165 65a6 a675 7581 816c 6ccc cc90 9077 7769 69b3 b352 52ca ca5c 5cd3 d3cb cbbe be0b 0b68 68fd fdc7 c75f 5ffa fa98 98a4 a486 868b 8b4c 4c9b 9b24 2450 5004 04f3 f31f 1fc6 c633 3306 0699 99c7 c736 36bf bf60 6093 9308 0816 1682 8282 8232 32ee ee43 4317 17ef efec ecb5 b5e4 e4e5 e5aa aa48 4833 33af af8a 8a62 6287 878d 8dd9 d931 31de de25 25bc bcc2 c2db db92 925f 5f25 251b 1b80 80de de7b 7b77 77b4 b4af af09 09c7 c7f9 f9fe fefa fafc fcd7 d72c 2c0e 0ec2 c27c 7c5b 5b6a 6aac ac13 1302 0200 00f4 f424 2462 62f6 f664 64a3 a398 9873 732c 2c9e 9edb db49 49a5 a561 612d 2d52 5206 060e 0e97 976f 6fcc cc74 7433 330d 0dd9 d913 1312 1242 42cc cc8b 8b7d 7d4b 4b4e 4e71 713e 3e49 4997 97fc fcda da48 48dd ddb5# 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000'
        },
        {
            'five_tuple': '112.25.106.104:443_192.168.31.25:40704_TCP',
            'app_name': 'cn.emagsoftware.gamehall',
            'app_version': '3.61.1.1',
            'flow_data': '1603 0301 0102 0200 0001 0100 0001 01fc fc03 0303 0388 88f5 f5ce ce21 2149 49a2 a219 19e0 e0e8 e8d6 d640 405a 5a0f 0f56 564c 4c4d 4db9 b9ff ff25 2536 36b2 b207 0774 7479 79e3 e31f 1f20 203b 3bc3 c356 56ff ffaa aa20 20d9 d90e 0e3b 3b33 3362 6211 1186 86a6 a678 781a 1a94 9465 65f5 f57d 7d94 94d3 d3d0 d08c 8c14 1450 5084 8422 2256 56ae aec1 c146 468d 8d75 7547 4796 96ce cef9 f900 001e 1e13 1301 0113 1302 0213 1303 03c0 c02b 2bc0 c02c 2ccc cca9 a9c0 c02f 2fc0 c030 30cc cca8 a8c0 c013 13c0 c014 1400 009c 9c00 009d 9d00 002f 2f00 0035 3501 0100 0001 0195 9500 0000 0000 0019 1900 0017 1700 0000 0014 1462 6265 6574 7461 6167 6761 616d 6d65 652e 2e6d 6d69 6967 6775 7566 6675 756e 6e2e 2e63 636f 6f6d 6d00 0017 1700 0000 00ff ff01 0100 0001 0100 0000 000a 0a00 0008 0800 0006 0600 001d 1d00 0017 1700 0018 1800 000b 0b00 0002 0201 0100 0000 0023 2300 0000 0000 0010 1000 000e 0e00 000c 0c02 0268 6832 3208 0868 6874 7474 7470 702f 2f31 312e 2e31 3100 0005 0500 0005 0501 0100 0000 0000 0000 0000 000d 0d00 0014 1400 0012 1204 0403 0308 0804 0404 0401 0105 0503 0308 0805 0505 0501 0108 0806 0606 0601 0102 0201 0100 0033 3300 0026 2600 0024 2400 001d 1d00 0020 2065 65a1 a1e7 e7a2 a280 806c 6c42 42c7 c793 936f 6f52 5233 339b 9b7a 7a38 3823 237e 7e0c 0c9c 9cfb fb06 06cc cc6f 6f18#1603 0303 0300 0056 5602 0200 0000 0052 5203 0303 0364 64e0 e0d5 d522 22e0 e0cc cc5e 5e05 0527 27d9 d95b 5b43 4340 40ea ea76 76e5 e5d2 d20d 0dd5 d52c 2cac acc7 c7d2 d278 7817 1799 9966 66fc fce5 e598 9894 941f 1f20 205c 5cea ea51 51b4 b451 5195 95be be5b 5b21 219d 9d8a 8a0d 0da5 a51c 1cdd dd13 132a 2a6f 6f37 37ee eee4 e4bc bcb2 b297 9708 0835 35ea ea66 66e1 e1ac ac0b 0b8b 8b00 009d 9d00 0000 000a 0a00 0000 0000 0000 0000 000b 0b00 0002 0201 0100 0016 1603 0303 030b 0bcd cd0b 0b00 000b 0bc9 c900 000b 0bc6 c600 0006 06a6 a630 3082 8206 06a2 a230 3082 8205 058a 8aa0 a003 0302 0201 0102 0202 0210 1001 01a0 a0f6 f6cc cc77 77bb bb9e 9e2f 2ff7 f7dd ddd9 d986 865d 5d5b 5bad adba ba30 300d 0d06 0609 092a 2a86 8648 4886 86f7 f70d 0d01 0101 010b 0b05 0500 0030 305b 5b31 310b 0b30 3009 0906 0603 0355 5504 0406 0613 1302 0255 5553 5331 3115 1530 3013 1306 0603 0355 5504 040a 0a13 130c 0c44 4469 6967 6769 6943 4365 6572 7274 7420 2049 496e 6e63 6331 3119 1930 3017 1706 0603 0355 5504 040b 0b13 1310 1077 7777 7777 772e 2e64 6469 6967 6769 6963 6365 6572 7274 742e 2e63 636f 6f6d 6d31 311a 1a30 3018 1806 0603 0355 5504 0403 0313 1311 1153 5365 6563 6375 7572 7265 6520 2053 5369 6974 7465 6520 2043 4341 4120 2047 4732 3230 301e 1e17 170d 0d32 3233 3330 3033 3331 3134 3430 3030#3046 4602 0221 2100 00b2 b26e 6e5c 5cc7 c77a 7a21 21ec ec55 55c9 c98a 8aa3 a34d 4df0 f060 605c 5c60 608d 8dfc fc36 366d 6d03 03fb fb02 0270 7066 66c9 c961 61fc fc10 100f 0f18 18b8 b802 0221 2100 00d3 d34f 4f75 7586 8635 3598 9833 33b8 b801 0131 31f5 f598 9826 2630 30aa aa4c 4cdd dd3e 3e19 19cf cfbd bdb4 b4e3 e3bf bf9b 9be0 e0c6 c68d 8da2 a29a 9a72 726c 6c30 300d 0d06 0609 092a 2a86 8648 4886 86f7 f70d 0d01 0101 010b 0b05 0500 0003 0382 8201 0101 0100 0032 3268 68ef ef29 2977 775e 5e0b 0b5d 5df4 f41f 1f3c 3cb8 b810 1004 04d2 d214 1414 1492 92c5 c5ce ce4f 4f97 9773 7383 83e7 e76e 6e87 87a8 a872 7230 3088 883b 3b0f 0fb1 b1f8 f878 78bc bcd3 d32e 2eb1 b1c9 c988 88ce ce96 9642 42cb cb8b 8be9 e9c5 c573 73ba ba52 52fc fc3d 3d88 88ed ed0d 0d89 898b 8b32 32aa aa4b 4bb9 b95e 5eca ca2f 2fd1 d192 9298 9869 691a 1a48 480a 0a61 61da da62 6246 46e5 e5a7 a77f 7f0a 0a65 650d 0dae aed5 d578 78f7 f788 888b 8bba ba73 73ac acc6 c6fb fb6d 6d5a 5a0c 0c64 6462 62cb cb20 20c1 c14a 4a76 76d0 d0d5 d576 766b 6b60 6024 2497 97d5 d519 1954 54f8 f892 9226 2620 20f6 f667 6737 3705 0541 4177 77a4 a447 4730 30db dbc6 c67a 7a6b 6b0f 0f3a 3aa1 a103 034e 4e62 6223 2356 569f 9f09 090c 0cde dee1 e1f1 f154 54d5 d5a6 a6f8 f828 289d 9d5a 5a95 95ae ae00 0018 1822 223f 3fa7 a7b3 b329 29e5 e509 0986 86dc#ddc4 c4a3 a38a 8abc bcee ee4d 4dfa fab9 b9c7 c758 5890 907a 7a6b 6b77 77c9 c951 5119 19fa fa7b 7b42 423e 3eac ac3c 3cca ca57 5756 565a 5a72 72fd fd95 95c7 c7f6 f647 472d 2d99 99b3 b36b 6bf6 f6e9 e9e0 e00c 0ce2 e206 06b0 b0ce ce88 88f9 f956 56fc fcab ab63 63e8 e802 02d0 d0cc cc08 082a 2aef ef43 43b2 b2b6 b64f 4f61 61b4 b4bb bba9 a905 0563 63ee eea6 a652 5243 4377 7728 2846 46a9 a9bf bf51 517d 7d0b 0bd6 d673 7351 515a 5ad4 d47c 7c17 1774 7414 1422 22a0 a093 93e2 e26d 6df3 f31a 1a62 6241 41cc cc63 637a 7a53 536c 6ceb ebf6 f6af af33 330a 0a12 1286 8670 701c 1c31 31ea eac8 c82e 2ef7 f744 448f 8f49 4982 82aa aaa2 a25c 5c7c 7c34 34ac ac82 82fc fc03 035b 5b8b 8bdc dc8a 8af2 f299 9971 712b 2b9b 9b27 2713 13a9 a9b4 b4a8 a8cd cd0c 0c22 2288 8847 47db dbf9 f9cc cc73 7363 63cd cd98 9868 68dc dcda da2e 2e92 9272 7222 22cb cb74 744f 4f64 6426 2674 7430 30e7 e782 826c 6c9d 9dd8 d8b1 b126 269b 9b83 834a 4a79 7974 746b 6b70 7054 5461 615c 5c30 30c5 c57e 7e92 9227 27f7 f770 707b 7b24 2416 1603 0303 0300 0004 040e 0e00 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000#1603 0303 0301 0106 0610 1000 0001 0102 0201 0100 005a 5ad7 d74b 4b23 23cd cdb0 b0bd bd2c 2c88 88f6 f6f2 f20e 0e7f 7f71 7160 6026 26f3 f3dd dd43 43eb ebab ab57 5725 2524 24fd fd1a 1ae0 e00f 0f62 6293 93c2 c25f 5fe9 e980 80d4 d479 79fb fba7 a7df df92 92b9 b929 298d 8d9f 9ff9 f982 82e9 e99d 9dfe fec1 c18f 8f07 07b3 b378 78fa fa3c 3c05 05e5 e539 3968 68ea eabb bb0b 0bd8 d8eb ebf3 f358 5862 6293 93db db0c 0c88 887e 7e18 1894 9457 5702 0226 2640 40b5 b549 4966 662b 2b48 488c 8cdf df91 9162 6205 0512 120a 0a9e 9e4a 4abf bf2a 2a70 7002 02d3 d3b5 b528 28b7 b7cb cbb2 b2a5 a556 56c0 c003 0338 3810 101c 1c38 3833 33ce cea4 a4d2 d277 77fa fac2 c2d7 d70c 0c12 127c 7cc7 c730 30c1 c12d 2d72 7231 31eb eb6f 6f42 42d4 d423 23e8 e8d0 d01b 1bb9 b993 93bb bbe9 e94c 4cd5 d5e6 e6d9 d975 75f6 f640 40a8 a8af af92 928c 8c00 0035 3511 1106 06e5 e587 8782 828d 8d93 9302 0280 8062 62e0 e0ec ec41 41a4 a4b0 b044 4495 95a6 a60a 0aff ffa7 a742 4234 3467 67a3 a35d 5dac ac86 8624 24ec ec27 270a 0a03 0392 9276 76d8 d84f 4f8f 8fe9 e9d7 d7f9 f9cd cd89 8923 23e4 e4a6 a6b5 b5ab ab97 97f1 f14d 4d70 70ef ef23 233c 3c51 516e 6e71 710b 0b18 1822 2259 592c 2c1e 1ee3 e34b 4b05 0524 2471 714a 4a09 09f8 f889 8923 234b 4bec ec70 70c0 c084 849e 9e36 3657 57fe fe1b 1b9e 9e71 71aa aaa3 a364 64d7 d796 963c 3c52'
        }
    ]
    
    # 创建 DataFrame 并保存
    df = pd.DataFrame(sample_data)
    df.to_csv('sample_traffic_data.csv', index=False)
    print("示例数据已保存到 sample_traffic_data.csv")
    return 'sample_traffic_data.csv'
```


```python
# 演示数据处理流程
print("=== 流量数据预训练处理演示 ===\n")

# 1. 创建示例数据
data_path = create_sample_data()
print(data_path)
```

    === 流量数据预训练处理演示 ===
    
    示例数据已保存到 sample_traffic_data.csv
    sample_traffic_data.csv


## 词表编号

SimpleTokenizer 词表大小是21，原因如下：

* 特殊标记：5个（[PAD], [UNK], [CLS], [SEP], [MASK]）
    * [UNK] 是 unknown token（未知标记）的缩写。当分词器（tokenizer）遇到词表中没有的内容时，会用 [UNK] 代替，表示“未登录词”或“无法识别的token”。在你的 SimpleTokenizer 里，如果输入的十六进制字符串不是 00~ff 或特殊标记，就会被编码为 [UNK] 对应的ID（即1）。
* 十六进制字符串：16个（0 ~ f，即0~15）

$$16 + 5 = 21$$


```python
#!/usr/bin/env python3
"""
流量数据预训练处理示例
基于 run_pretrain.py 的数据处理流程
"""

import os
import pandas as pd
import torch
import torch.distributed as dist
from torch.utils.data import DataLoader
import numpy as np
from typing import List, Dict, Optional, Tuple

# 模拟 tokenizer 类
class SimpleTokenizer:
    """简化的 tokenizer，用于演示"""
    
    def __init__(self):
        # 创建词汇表：十六进制字符 + 特殊标记
        self.vocab = {}
        self.id_to_token = {}
        
        # 添加特殊标记
        special_tokens = ['[PAD]', '[UNK]', '[CLS]', '[SEP]', '[MASK]']
        for i, token in enumerate(special_tokens):
            self.vocab[token] = i
            self.id_to_token[i] = token
        
        # 添加十六进制字符 (0-f)
        hex_chars = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f']
        for i, char in enumerate(hex_chars):
            self.vocab[char] = i + len(special_tokens)
            self.id_to_token[i + len(special_tokens)] = char
        
        self.pad_token_id = self.vocab['[PAD]']
        self.unk_token_id = self.vocab['[UNK]']
        self.cls_token_id = self.vocab['[CLS]']
        self.sep_token_id = self.vocab['[SEP]']
        self.mask_token_id = self.vocab['[MASK]']
    
    def encode(self, hex_string: str) -> List[int]:
        """将十六进制字符串编码为 token IDs"""
        # 分割十六进制字符串
        hex_parts = hex_string.split()
        tokens = []
        
        for part in hex_parts:
            # 将4位十六进制字符串拆分为1位一组
            if len(part) == 4:
                # 例如: "1603" -> ["1", "6", "0", "3"]
                for char in part:
                    if char in self.vocab:
                        tokens.append(self.vocab[char])
                    else:
                        tokens.append(self.unk_token_id)
            else:
                # 如果已经是1位，直接处理
                if part in self.vocab:
                    tokens.append(self.vocab[part])
                else:
                    tokens.append(self.unk_token_id)
        
        return tokens
    
    def decode(self, token_ids: List[int]) -> str:
        """将 token IDs 解码为十六进制字符串"""
        tokens = [self.id_to_token.get(tid, '[UNK]') for tid in token_ids]
        
        # 将1位token重新组合成4位
        result = []
        i = 0
        while i < len(tokens):
            if (i + 3 < len(tokens) and 
                tokens[i] not in ['[PAD]', '[UNK]', '[CLS]', '[SEP]', '[MASK]'] and
                tokens[i+1] not in ['[PAD]', '[UNK]', '[CLS]', '[SEP]', '[MASK]'] and
                tokens[i+2] not in ['[PAD]', '[UNK]', '[CLS]', '[SEP]', '[MASK]'] and
                tokens[i+3] not in ['[PAD]', '[UNK]', '[CLS]', '[SEP]', '[MASK]']):
                # 组合四个1位token为4位
                result.append(tokens[i] + tokens[i+1] + tokens[i+2] + tokens[i+3])
                i += 4
            else:
                # 特殊token或单个token
                result.append(tokens[i])
                i += 1
        
        return ' '.join(result)
    
    def __len__(self):
        return len(self.vocab)
    
    def test_tokenizer(self):
        """测试tokenizer的功能"""
        print("=== SimpleTokenizer 测试 ===")
        print(f"词汇表大小: {len(self.vocab)}")
        print(f"特殊标记: CLS={self.cls_token_id}, SEP={self.sep_token_id}, MASK={self.mask_token_id}, PAD={self.pad_token_id}, UNK={self.unk_token_id}")
        print(f"词汇表前10个token: {list(self.vocab.items())[:10]}")
        print(f"十六进制字符: {[self.id_to_token[i] for i in range(5, 21)]}")
        
        # 测试单个字符
        test_chars = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f']
        for char in test_chars:
            print(f"字符 '{char}' in vocab: {char in self.vocab}, ID: {self.vocab.get(char, 'N/A')}")
        
        # 测试编码解码
        test_cases = [
            "1603 0301 0102",
            "abcd ef01",
            "0000 1111"
        ]
        
        for test_hex in test_cases:
            test_tokens = self.encode(test_hex)
            decoded = self.decode(test_tokens)
            print(f"测试: '{test_hex}' -> {test_tokens} -> '{decoded}'")
        
        print("=== 测试完成 ===\n")


```


```python
    # 3. 显示原始数据
    print("原始数据:")
    raw_data = pd.read_csv(data_path)
    for i, (idx, row) in enumerate(raw_data.iterrows()):
        print(f"\n--- 原始行 {i + 1} ---")
        print(f"five_tuple: {row['five_tuple']}")
        print(f"app_name: {row['app_name']}")
        print(f"app_version: {row['app_version']}")
        print(f"flow_data长度: {len(str(row['flow_data']))} 字符")
        print(f"flow_data前100字符: {str(row['flow_data'])[:100]}...")
        print(f"flow_data后100字符: ...{str(row['flow_data'])[-100:]}")
    
```

    原始数据:
    
    --- 原始行 1 ---
    five_tuple: 192.168.31.160:38268_39.136.197.119:443_TCP
    app_name: cn.emagsoftware.gamehall
    app_version: 3.48.1.1
    flow_data长度: 6400 字符
    flow_data前100字符: 1603 0301 0102 0200 0001 0100 0001 01fc fc03 0303 039b 9bb5 b56a 6af7 f704 040b 0b3d 3da7 a769 691c ...
    flow_data后100字符: ... 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000
    
    --- 原始行 2 ---
    five_tuple: 112.25.106.104:443_192.168.31.25:40704_TCP
    app_name: cn.emagsoftware.gamehall
    app_version: 3.61.1.1
    flow_data长度: 6399 字符
    flow_data前100字符: 1603 0301 0102 0200 0001 0100 0001 01fc fc03 0303 0388 88f5 f5ce ce21 2149 49a2 a219 19e0 e0e8 e8d6 ...
    flow_data后100字符: ... 8923 234b 4bec ec70 70c0 c084 849e 9e36 3657 57fe fe1b 1b9e 9e71 71aa aaa3 a364 64d7 d796 963c 3c52



```python
# 2. 初始化 tokenizer
tokenizer = SimpleTokenizer() # SimpleTokenizer Class

print(f"Tokenizer 词汇表大小: {len(tokenizer)}")
# class SimpleTokenizer: 
#       def __len__(self):
#             return len(self.vocab)

print(f"特殊标记: CLS={tokenizer.cls_token_id}, SEP={tokenizer.sep_token_id}, MASK={tokenizer.mask_token_id}, PAD={tokenizer.pad_token_id}, UNK={tokenizer.unk_token_id}\n")
```

    Tokenizer 词汇表大小: 21
    特殊标记: CLS=2, SEP=3, MASK=4, PAD=0, UNK=1
    



```python
# 测试tokenizer
tokenizer.test_tokenizer()
```

    === SimpleTokenizer 测试 ===
    词汇表大小: 21
    特殊标记: CLS=2, SEP=3, MASK=4, PAD=0, UNK=1
    词汇表前10个token: [('[PAD]', 0), ('[UNK]', 1), ('[CLS]', 2), ('[SEP]', 3), ('[MASK]', 4), ('0', 5), ('1', 6), ('2', 7), ('3', 8), ('4', 9)]
    十六进制字符: ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f']
    字符 '0' in vocab: True, ID: 5
    字符 '1' in vocab: True, ID: 6
    字符 '2' in vocab: True, ID: 7
    字符 '3' in vocab: True, ID: 8
    字符 '4' in vocab: True, ID: 9
    字符 '5' in vocab: True, ID: 10
    字符 '6' in vocab: True, ID: 11
    字符 '7' in vocab: True, ID: 12
    字符 '8' in vocab: True, ID: 13
    字符 '9' in vocab: True, ID: 14
    字符 'a' in vocab: True, ID: 15
    字符 'b' in vocab: True, ID: 16
    字符 'c' in vocab: True, ID: 17
    字符 'd' in vocab: True, ID: 18
    字符 'e' in vocab: True, ID: 19
    字符 'f' in vocab: True, ID: 20
    测试: '1603 0301 0102' -> [6, 11, 5, 8, 5, 8, 5, 6, 5, 6, 5, 7] -> '1603 0301 0102'
    测试: 'abcd ef01' -> [15, 16, 17, 18, 19, 20, 5, 6] -> 'abcd ef01'
    测试: '0000 1111' -> [5, 5, 5, 5, 6, 6, 6, 6] -> '0000 1111'
    === 测试完成 ===
    


## Embedding (嵌入)

BERT use three embeddings to compute the input representations.

* Token Embedding: Generally it is called Word embedding. It uses the predefined vector space to represent each token as 300 dimension vectors. The vectors also encodes the sematic meaning of among the words.
* Segment embeddings: Skip-thoughts extends skip-grams model from word embeddings to sentence embeddings. Instead of predicting context by surroundings word, Skip-thoughts predict target sentence by surroundings sentence. Typical example is using previous sentence and next sentence to predict current sentence. Deep down it is a neural network having three parts
* Position Embedding: Transformer has no way of knowing the relative position of each word. It would be exactly like randomly shuffling the input sentence. So the positional embeddings let the model learn the actual sequential ordering of the input sentence (which something like an LSTM gets for free). You can go to that linkd


```python
class TokenEmbedding:
    """Token Embedding 演示类"""
    
    def __init__(self, vocab_size: int, hidden_size: int = 768, pad_token_id: int = 0):
        self.vocab_size = vocab_size
        self.hidden_size = hidden_size
        self.pad_token_id = pad_token_id
        
        # 创建 embedding 层
        self.embedding = nn.Embedding(vocab_size, hidden_size, padding_idx=pad_token_id)
        
        # 初始化权重（模拟BERT的初始化）
        self._init_weights()
    
    def _init_weights(self):
        """初始化embedding权重"""
        # 使用正态分布初始化
        nn.init.normal_(self.embedding.weight, mean=0.0, std=0.02)
        # 将padding token的embedding设为0
        if self.pad_token_id is not None:
            with torch.no_grad():
                self.embedding.weight[self.pad_token_id].fill_(0)
    
    def forward(self, input_ids: torch.Tensor) -> torch.Tensor:
        """将token IDs转换为embeddings"""
        # input_ids: [batch_size, seq_len]
        # 返回: [batch_size, seq_len, hidden_size]
        return self.embedding(input_ids)
    
    def get_embedding_for_token(self, token_id: int) -> torch.Tensor:
        """获取特定token的embedding"""
        return self.embedding(torch.tensor([token_id]))
    
    def get_embedding_stats(self) -> Dict:
        """获取embedding统计信息"""
        with torch.no_grad():
            weights = self.embedding.weight
            return {
                'mean': weights.mean().item(),
                'std': weights.std().item(),
                'min': weights.min().item(),
                'max': weights.max().item(),
                'shape': list(weights.shape)
            }
    
    def visualize_embeddings(self, tokenizer, sample_tokens: Optional[List[str]] = None):
        """可视化一些token的embeddings"""
        if sample_tokens is None:
            sample_tokens = ['[CLS]', '[SEP]', '[MASK]', '1', '6', '0', '3', 'a', 'f']
        
        print("=== Token Embedding 可视化 ===")
        print(f"Embedding维度: {self.hidden_size}")
        print(f"词汇表大小: {self.vocab_size}")
        
        # 显示统计信息
        stats = self.get_embedding_stats()
        print(f"Embedding权重统计:")
        print(f"  均值: {stats['mean']:.4f}")
        print(f"  标准差: {stats['std']:.4f}")
        print(f"  最小值: {stats['min']:.4f}")
        print(f"  最大值: {stats['max']:.4f}")
        
        # 显示样本token的embedding
        print(f"\n样本Token Embeddings:")
        for token in sample_tokens:
            if token in tokenizer.vocab:
                token_id = tokenizer.vocab[token]
                embedding = self.get_embedding_for_token(token_id)
                print(f"  '{token}' (ID: {token_id}):")
                print(f"    形状: {list(embedding.shape)}")
                print(f"    前5个值: {embedding[0, :5].tolist()}")
                print(f"    均值: {embedding.mean().item():.4f}")
                print(f"    标准差: {embedding.std().item():.4f}")
            else:
                print(f"  '{token}': 不在词汇表中")
        
        print("=== 可视化完成 ===\n")

class PositionalEmbedding:
    """位置编码演示类"""
    
    def __init__(self, max_position: int = 512, hidden_size: int = 768):
        self.max_position = max_position
        self.hidden_size = hidden_size
        self.embedding = nn.Embedding(max_position, hidden_size)
        self._init_weights()
    
    def _init_weights(self):
        """初始化位置编码权重"""
        nn.init.normal_(self.embedding.weight, mean=0.0, std=0.02)
    
    def forward(self, position_ids: torch.Tensor) -> torch.Tensor:
        """获取位置编码"""
        return self.embedding(position_ids)
    
    def get_position_embeddings(self, seq_len: int) -> torch.Tensor:
        """获取序列的位置编码"""
        position_ids = torch.arange(seq_len, dtype=torch.long)
        return self.forward(position_ids)

class BertEmbeddingsDemo:
    """BERT Embeddings 完整演示类"""
    
    def __init__(self, tokenizer, hidden_size: int = 768, max_position: int = 512):
        self.tokenizer = tokenizer
        self.hidden_size = hidden_size
        
        # 创建各种embedding层
        self.token_embedding = TokenEmbedding(
            vocab_size=len(tokenizer), 
            hidden_size=hidden_size, 
            pad_token_id=tokenizer.pad_token_id
        )
        self.position_embedding = PositionalEmbedding(
            max_position=max_position, 
            hidden_size=hidden_size
        )
        self.token_type_embedding = nn.Embedding(2, hidden_size)  # 简化为2种类型
        
        # Layer Norm 和 Dropout
        self.layer_norm = nn.LayerNorm(hidden_size)
        self.dropout = nn.Dropout(0.1)
    
    def forward(self, input_ids: torch.Tensor, attention_mask: Optional[torch.Tensor] = None) -> torch.Tensor:
        """完整的BERT embedding前向传播"""
        batch_size, seq_len = input_ids.shape
        
        # 1. Token Embeddings
        token_embeddings = self.token_embedding.forward(input_ids)
        
        # 2. Position Embeddings
        position_ids = torch.arange(seq_len, dtype=torch.long, device=input_ids.device)
        position_ids = position_ids.unsqueeze(0).expand(batch_size, -1)
        position_embeddings = self.position_embedding.forward(position_ids)
        
        # 3. Token Type Embeddings (简化为全0)
        token_type_ids = torch.zeros_like(input_ids)
        token_type_embeddings = self.token_type_embedding(token_type_ids)
        
        # 4. 组合所有embeddings
        embeddings = token_embeddings + position_embeddings + token_type_embeddings
        
        # 5. Layer Norm 和 Dropout
        embeddings = self.layer_norm(embeddings)
        embeddings = self.dropout(embeddings)
        
        return embeddings
    
    def demonstrate_embedding_process(self, input_ids: torch.Tensor, attention_mask: Optional[torch.Tensor] = None):
        """演示embedding处理过程"""
        print("=== BERT Embedding 处理演示 ===")
        print(f"输入形状: {input_ids.shape}")
        
        # 逐步演示
        batch_size, seq_len = input_ids.shape
        
        # 1. Token Embeddings
        token_embeddings = self.token_embedding.forward(input_ids)
        print(f"1. Token Embeddings 形状: {token_embeddings.shape}")
        print(f"   Token Embeddings 统计: 均值={token_embeddings.mean().item():.4f}, 标准差={token_embeddings.std().item():.4f}")
        
        # 2. Position Embeddings
        position_ids = torch.arange(seq_len, dtype=torch.long, device=input_ids.device)
        position_ids = position_ids.unsqueeze(0).expand(batch_size, -1)
        position_embeddings = self.position_embedding.forward(position_ids)
        print(f"2. Position Embeddings 形状: {position_embeddings.shape}")
        print(f"   Position Embeddings 统计: 均值={position_embeddings.mean().item():.4f}, 标准差={position_embeddings.std().item():.4f}")
        
        # 3. Token Type Embeddings
        token_type_ids = torch.zeros_like(input_ids)
        token_type_embeddings = self.token_type_embedding(token_type_ids)
        print(f"3. Token Type Embeddings 形状: {token_type_embeddings.shape}")
        
        # 4. 组合
        combined_embeddings = token_embeddings + position_embeddings + token_type_embeddings
        print(f"4. 组合后 Embeddings 形状: {combined_embeddings.shape}")
        print(f"   组合后统计: 均值={combined_embeddings.mean().item():.4f}, 标准差={combined_embeddings.std().item():.4f}")
        
        # 5. Layer Norm 和 Dropout
        final_embeddings = self.layer_norm(combined_embeddings)
        final_embeddings = self.dropout(final_embeddings)
        print(f"5. 最终 Embeddings 形状: {final_embeddings.shape}")
        print(f"   最终统计: 均值={final_embeddings.mean().item():.4f}, 标准差={final_embeddings.std().item():.4f}")
        
        # 显示第一个样本的详细信息
        print(f"\n第一个样本的详细信息:")
        print(f"  输入 tokens: {input_ids[0].tolist()}")
        print(f"  对应的 token 名称: {[self.tokenizer.id_to_token.get(tid.item(), 'UNK') for tid in input_ids[0]]}")
        print(f"  第一个 token embedding (前10维): {final_embeddings[0, 0, :10].tolist()}")
        
        print("=== Embedding 处理演示完成 ===\n")
        
        return final_embeddings
```


```python
    # 3. 演示 Token Embedding
    print("=== Token Embedding 演示 ===")
    token_embedding = TokenEmbedding(
        vocab_size=len(tokenizer), 
        hidden_size=128,  # 使用较小的维度便于演示
        pad_token_id=tokenizer.pad_token_id
    )
```

    === Token Embedding 演示 ===



```python
# Token ID → Token Embedding 的映射关系
token_id = 5        # token '1' 的ID
embedding_vector = token_embedding.embedding(torch.tensor([token_id]))
embedding_vector    # embedding_vector.shape: [1, 768]  # 768维向量
```




    tensor([[ 1.3597e-02,  1.1993e-02, -1.3055e-03, -4.0236e-03,  3.3891e-02,
             -1.9526e-02,  1.2526e-02, -4.0531e-02, -3.9913e-04,  2.3525e-02,
             -2.7102e-02, -1.0587e-03, -1.2770e-02, -1.7081e-02, -4.8275e-02,
             -1.0529e-02,  4.5000e-03, -5.5578e-03,  1.2202e-02,  2.7480e-02,
              1.3794e-02, -2.5760e-03,  3.0860e-03, -3.0330e-02,  1.3400e-02,
             -1.0526e-02, -1.1095e-02,  7.0557e-03, -4.0849e-03, -6.8112e-03,
              1.8017e-02, -1.4958e-02,  1.7749e-02,  1.9008e-02,  8.8755e-03,
             -4.0226e-03, -7.0381e-03,  4.0890e-02,  3.2083e-02, -5.9451e-02,
              4.0509e-02, -9.1059e-03,  1.6285e-02,  2.2349e-02, -8.7191e-03,
             -2.2029e-02, -2.4041e-02,  1.1249e-02,  8.7969e-03,  8.2217e-03,
              1.1106e-02, -1.4858e-02,  1.3810e-02, -1.9749e-02,  1.3278e-02,
             -3.3966e-02,  7.8470e-03, -2.5535e-02, -2.1753e-02, -3.6565e-02,
             -3.7137e-02, -5.1432e-03,  1.5927e-03, -2.7202e-02, -3.1729e-02,
              1.8066e-02,  4.0602e-02,  8.1602e-03,  1.6898e-02,  4.5866e-03,
              5.1453e-03,  3.0655e-02, -1.0338e-02, -2.4910e-02, -8.6422e-03,
             -2.6698e-02, -1.0195e-02,  2.0978e-02, -1.0129e-02,  6.7908e-03,
             -6.5558e-03,  7.8937e-03,  8.6692e-03,  2.3195e-02,  1.9046e-02,
             -7.5006e-03, -1.2138e-02,  4.2771e-03, -3.9014e-02, -7.2233e-03,
              9.3955e-03, -4.0692e-03,  9.7693e-03, -9.3506e-04,  1.6822e-04,
             -3.6521e-05, -2.6446e-02,  1.2017e-02, -2.0073e-02,  1.2951e-02,
             -8.4408e-03,  2.3039e-02, -1.0592e-02,  2.1516e-04,  2.5329e-03,
              3.2850e-02, -2.8468e-02,  3.6656e-03, -5.4265e-04,  6.0467e-03,
              1.9686e-02, -4.0874e-02, -7.2435e-03, -3.8327e-02,  1.9717e-02,
              1.3141e-02,  1.9041e-02, -1.7723e-02, -1.5442e-02, -2.1205e-02,
              1.0405e-03, -6.8431e-03, -1.2546e-02, -1.7879e-02, -1.3622e-02,
              6.4272e-03,  1.3321e-02,  2.3792e-02]], grad_fn=<EmbeddingBackward0>)




```python

    
    # 可视化embedding
    token_embedding.visualize_embeddings(tokenizer)
    
    # 4. 演示完整的BERT Embeddings
    print("=== 完整BERT Embeddings演示 ===")
    bert_embeddings = BertEmbeddingsDemo(
        tokenizer=tokenizer,
        hidden_size=128,  # 使用较小的维度便于演示
        max_position=256
    )
```

    === Token Embedding 可视化 ===
    Embedding维度: 128
    词汇表大小: 21
    Embedding权重统计:
      均值: -0.0003
      标准差: 0.0192
      最小值: -0.0662
      最大值: 0.0660
    
    样本Token Embeddings:
      '[CLS]' (ID: 2):
        形状: [1, 128]
        前5个值: [-0.016489120200276375, -0.0012087548384442925, -0.014348193071782589, 0.009048991836607456, -0.016189221292734146]
        均值: 0.0012
        标准差: 0.0189
      '[SEP]' (ID: 3):
        形状: [1, 128]
        前5个值: [-0.0070264749228954315, -0.004042921122163534, 0.000322408159263432, -0.00806682649999857, -0.02545778639614582]
        均值: 0.0005
        标准差: 0.0188
      '[MASK]' (ID: 4):
        形状: [1, 128]
        前5个值: [-0.02075047977268696, -0.030798381194472313, 0.006987348664551973, -0.0146317845210433, 6.119085446698591e-05]
        均值: -0.0023
        标准差: 0.0203
      '1' (ID: 6):
        形状: [1, 128]
        前5个值: [0.022533442825078964, 0.00350399361923337, 0.00553987268358469, -0.008525019511580467, 0.02241688035428524]
        均值: -0.0013
        标准差: 0.0214
      '6' (ID: 11):
        形状: [1, 128]
        前5个值: [0.004815234802663326, -0.01425110176205635, -0.011377450078725815, 0.007831798866391182, -0.007128358818590641]
        均值: -0.0033
        标准差: 0.0190
      '0' (ID: 5):
        形状: [1, 128]
        前5个值: [-0.03613375872373581, -0.01023374404758215, -0.04490449279546738, -0.018779775127768517, -0.005926243029534817]
        均值: -0.0026
        标准差: 0.0201
      '3' (ID: 8):
        形状: [1, 128]
        前5个值: [0.0023791450075805187, 0.01444057933986187, -0.014764247462153435, -0.026111546903848648, 0.027188913896679878]
        均值: 0.0016
        标准差: 0.0213
      'a' (ID: 15):
        形状: [1, 128]
        前5个值: [-0.011117612011730671, -0.003973823506385088, 0.01814347505569458, 0.06599470227956772, 0.0033407306764274836]
        均值: -0.0011
        标准差: 0.0195
      'f' (ID: 20):
        形状: [1, 128]
        前5个值: [-0.03118945099413395, 0.009017803706228733, 0.03993191942572594, -0.02980174496769905, 0.018057838082313538]
        均值: 0.0010
        标准差: 0.0198
    === 可视化完成 ===
    
    === 完整BERT Embeddings演示 ===


## 数据集

### Flow Mode（流模式）

特点：

* 保持完整的流量会话结构
* 将所有包按顺序连接成一个长序列
* 适合学习整个会话的上下文关系

### Packet Mode（包模式）

特点：

* 将每个包独立处理
* 将长包切分成固定长度的子包 (sub-packet)
* 适合学习单个包的特征

```
[CLS] + 实际流量数据 + [SEP] + [PAD]填充
 1个   +    N个      +  1个   + (254-N)个
```


```python
class TrafficDataset(Dataset):
    """流量数据集类，模拟 SignalDataset 的核心功能"""
    
    def __init__(self, data_path: str, tokenizer, maxlen: int = 512, sequence_mode: str = 'packet'):
        self.tokenizer = tokenizer
        self.maxlen = maxlen
        self.sequence_mode = sequence_mode
        
        # 读取数据
        self.data = pd.read_csv(data_path)
        print(f"加载数据: {len(self.data)} 条记录")
        
        # 处理数据
        self.examples, self.labels, self.procedure_mapping = self._process_data()
        
    def _process_data(self):
        """处理流量数据"""
        examples = []
        labels = []
        procedure_names = set()
        
        for idx, row in self.data.iterrows():
            five_tuple = str(row['five_tuple'])
            app_name = str(row['app_name'])
            flow_data = str(row['flow_data'])
            
            # 收集应用名称
            procedure_names.add(app_name)
            
            # 按 # 分割流量数据得到多个包
            packets = [
                p.strip() for p in flow_data.split('#')
                if p.strip() != '0000' and p.strip() != ''
            ]
            
            if self.sequence_mode == 'packet':
                # packet 模式：将每个包切分成子包
                max_tokens = self.maxlen - 2  # 减去 CLS 和 SEP
                
                for packet in packets:
                    # 编码包数据
                    packet_tokens = self.tokenizer.encode(packet)
                    
                    # 切分子包
                    subpackets = []
                    for i in range(0, len(packet_tokens), max_tokens):
                        subpacket = packet_tokens[i:i + max_tokens]
                        if len(subpacket) > 0:
                            subpackets.append(subpacket)
                    
                    # 添加到数据集
                    examples.extend(subpackets)
                    labels.extend([app_name] * len(subpackets))
            
            elif self.sequence_mode == 'flow':
                # flow 模式：保持完整的流结构
                flow_tokens = []
                for packet in packets:
                    packet_tokens = self.tokenizer.encode(packet)
                    flow_tokens.extend(packet_tokens)
                
                # 如果流太长，截断
                if len(flow_tokens) > self.maxlen - 2:
                    flow_tokens = flow_tokens[:self.maxlen - 2]
                
                examples.append(flow_tokens)
                labels.append(app_name)
        
        # 创建标签映射
        procedure_mapping = {name: idx for idx, name in enumerate(sorted(procedure_names))}
        
        # 转换标签为数字
        numeric_labels = [procedure_mapping[label] for label in labels]
        
        print(f"处理完成: {len(examples)} 个样本, {len(procedure_mapping)} 个应用类别")
        print(f"应用类别: {list(procedure_mapping.keys())}")
        
        return examples, numeric_labels, procedure_mapping
    
    def __len__(self):
        return len(self.examples)
    
    def __getitem__(self, idx):
        tokens = self.examples[idx]
        label = self.labels[idx]
        
        # 添加 CLS 和 SEP 标记
        tokens = [self.tokenizer.cls_token_id] + tokens + [self.tokenizer.sep_token_id]
        
        # 填充到固定长度
        if len(tokens) < self.maxlen:
            tokens += [self.tokenizer.pad_token_id] * (self.maxlen - len(tokens))
        else:
            tokens = tokens[:self.maxlen]
        
        return {
            'input_ids': torch.tensor(tokens, dtype=torch.long),
            'attention_mask': torch.tensor([1 if t != self.tokenizer.pad_token_id else 0 for t in tokens], dtype=torch.long),
            'labels': torch.tensor(label, dtype=torch.long)
        }
```


```python

# 3. 创建数据集
print("创建数据集...")
dataset = TrafficDataset(
    data_path=data_path,
    tokenizer=tokenizer,
    maxlen=256,  # 较小的序列长度用于演示
    sequence_mode='packet'  # 使用 packet 模式
)


```

    创建数据集...
    加载数据: 2 条记录
    处理完成: 50 个样本, 1 个应用类别
    应用类别: ['cn.emagsoftware.gamehall']


## 批处理和掩码训练

### Batch

Batch（批次）：

* 单个样本：一个流量数据包或子包
* Batch：多个样本组成的一组，一起输入模型训练
* Batch Size：每个批次包含的样本数量

总样本数：50个
批次大小：2个样本/批次

$$50 ÷ 2 = 25\text{个批次} $$

### Mask and Attention Mask

The “Attention Mask” is simply an array of 1s and 0s indicating which tokens are padding and which aren’t . This mask tells the “Self-Attention” mechanism in BERT not to incorporate these PAD tokens into its interpretation of the sentence.

* 作用： 控制Transformer的注意力机制
* 目的： 告诉模型哪些位置需要关注，哪些位置忽略

```
# 没有注意力掩码：
说话内容 = ["你好", "今天天气不错", "PAD", "PAD", "PAD"]
# 你试图理解所有声音，包括无意义的"PAD"

# 有注意力掩码：
说话内容 = ["你好", "今天天气不错", "PAD", "PAD", "PAD"]
注意力 = [1, 1, 0, 0, 0]  # 只关注前两句话
# 你只关注有意义的内容，忽略噪音
```


```python
class SimpleDataCollator:
    """简化的数据收集器，用于批处理"""
    
    def __init__(self, tokenizer, mask_percent: float = 0.15):
        self.tokenizer = tokenizer
        self.mask_percent = mask_percent
    
    def __call__(self, batch):
        # 收集批次数据
        input_ids = torch.stack([item['input_ids'] for item in batch])
        attention_mask = torch.stack([item['attention_mask'] for item in batch])
        labels = torch.stack([item['labels'] for item in batch])
        
        # 创建 MLM 标签
        mlm_labels = input_ids.clone()
        
        # 随机掩码
        for i in range(input_ids.size(0)):
            for j in range(input_ids.size(1)):
                if (attention_mask[i, j] == 1 and 
                    input_ids[i, j] not in [self.tokenizer.cls_token_id, self.tokenizer.sep_token_id, self.tokenizer.pad_token_id] and
                    np.random.random() < self.mask_percent):
                    
                    # 80% 概率用 [MASK] 替换
                    if np.random.random() < 0.8:
                        input_ids[i, j] = self.tokenizer.mask_token_id
                    # 10% 概率用随机 token 替换
                    elif np.random.random() < 0.5:
                        input_ids[i, j] = np.random.randint(5, len(self.tokenizer))
                    # 10% 概率保持不变
                    else:
                        pass
                else:
                    mlm_labels[i, j] = -100  # 忽略这些位置
        
        return {
            'input_ids': input_ids,
            'attention_mask': attention_mask,
            'labels': labels,
            'mlm_labels': mlm_labels
        }
```


```python
# 4. 创建数据收集器
collator = SimpleDataCollator(tokenizer, mask_percent=0.15)

# 5. 创建数据加载器
dataloader = DataLoader(
    dataset,
    batch_size=2,
    shuffle=True,
    collate_fn=collator
)
```


```python
len(dataloader)
```




    25



输入: [batch_size, seq_len] (token IDs)
    ↓
┌─────────────────────────────────────┐
│ 1. Embedding层 (BertEmbeddings)     │ ← Embedding
│    - Token Embedding                │
│    - Position Embedding             │
│    - Token Type Embedding           │
│    - Layer Norm + Dropout           │
└─────────────────────────────────────┘
    ↓
┌─────────────────────────────────────┐
│ 2. Transformer层 (BertEncoder)      │ ← Transformer
│    - Layer 0: Self-Attention        │
│    - Layer 1: Self-Attention        │
│    - Layer 2: Self-Attention        │
│    - ...                            │
│    - Layer N: Self-Attention        │
└─────────────────────────────────────┘
    ↓
┌─────────────────────────────────────┐
│ 3. Pooling层 (BertPooler)           │ ← 可选的池化
│    - 取[CLS]位置的输出               │
│    - 线性变换 + Tanh激活             │
└─────────────────────────────────────┘
    ↓
输出: [batch_size, hidden_size]


```python
# 6. 演示数据处理
print("处理批次数据...")
for batch_idx, batch in enumerate(dataloader):
    print(f"\n--- 批次 {batch_idx + 1} ---")
    
    input_ids = batch['input_ids']
    attention_mask = batch['attention_mask']
    labels = batch['labels']
    mlm_labels = batch['mlm_labels']
    
    print(f"输入形状: {input_ids.shape}")
    print(f"注意力掩码形状: {attention_mask.shape}")
    print(f"应用标签: {labels.tolist()}")
    
    # 显示所有样本的详细信息
    for sample_idx in range(input_ids.size(0)):
        print(f"\n=== 样本 {sample_idx + 1} ===")
        print(f"应用标签: {labels[sample_idx].item()}")
        print(f"应用名称: {list(dataset.procedure_mapping.keys())[labels[sample_idx].item()]}")
        
        # 显示输入 tokens
        print(f"输入 tokens (前30个): {input_ids[sample_idx][:30].tolist()}")
        print(f"注意力掩码 (前30个): {attention_mask[sample_idx][:30].tolist()}")
        print(f"MLM 标签 (前30个): {mlm_labels[sample_idx][:30].tolist()}")
   
        # 解码显示原始数据
        original_tokens = []
        for i, token_id in enumerate(input_ids[sample_idx]):
            if attention_mask[sample_idx][i] == 1 and token_id not in [tokenizer.cls_token_id, tokenizer.sep_token_id, tokenizer.pad_token_id]:
                original_tokens.append(tokenizer.id_to_token[token_id.item()])
        
        print(f"原始十六进制数据 (前20个): {original_tokens[:20]}")
        print(f"原始十六进制数据 (后20个): {original_tokens[-20:] if len(original_tokens) > 20 else original_tokens}")
        print(f"总token数: {len(original_tokens)}")
        
        # 显示掩码统计
        mask_count = (input_ids[sample_idx] == tokenizer.mask_token_id).sum().item()
        print(f"掩码token数量: {mask_count}")
        
        # 显示特殊token位置
        cls_pos = (input_ids[sample_idx] == tokenizer.cls_token_id).nonzero(as_tuple=True)[0]
        sep_pos = (input_ids[sample_idx] == tokenizer.sep_token_id).nonzero(as_tuple=True)[0]
        print(f"CLS token位置: {cls_pos.tolist()}")
        print(f"SEP token位置: {sep_pos.tolist()}")
    
    # 处理所有批次
    #if batch_idx >= 2:  # 限制显示前3个批次，避免输出过多
    #    print(f"\n... 还有更多批次，为简洁起见只显示前3个批次")
    #    break
        
        # 演示embedding处理（只对第一个批次）
    if batch_idx == 0:
            print(f"\n=== 演示Embedding处理 ===")
            # 使用第一个样本进行embedding演示
            sample_input_ids = input_ids[0:1]  # 取第一个样本
            sample_attention_mask = attention_mask[0:1]
            
            # 演示完整的BERT embedding过程
            final_embeddings = bert_embeddings.demonstrate_embedding_process(
                sample_input_ids, 
                sample_attention_mask
            )
            
            print(f"Embedding输出形状: {final_embeddings.shape}")
            print(f"这是BERT模型的第一层输出，接下来会进入Transformer层进行进一步处理")
        
    # 处理所有批次
    if batch_idx >= 2:  # 限制显示前3个批次，避免输出过多
            print(f"\n... 还有更多批次，为简洁起见只显示前3个批次")
            break
print(f"\n=== 处理完成 ===")
print(f"总样本数: {len(dataset)}")
print(f"应用类别数: {len(dataset.procedure_mapping)}")
print(f"应用类别映射: {dataset.procedure_mapping}")

# 统计所有批次的信息
print(f"\n=== 批次统计 ===")
total_batches = 0
total_samples = 0
total_masks = 0

for batch_idx, batch in enumerate(dataloader):
    total_batches += 1
    batch_size = batch['input_ids'].size(0)
    total_samples += batch_size
    batch_masks = (batch['input_ids'] == tokenizer.mask_token_id).sum().item()
    total_masks += batch_masks
    
    #if batch_idx < 3:  # 只显示前3个批次的详细信息
    #    print(f"批次 {batch_idx + 1}: {batch_size} 样本, {batch_masks} 掩码")

print(f"总批次数: {total_batches}")
print(f"总样本数: {total_samples}")
print(f"总掩码数: {total_masks}")
print(f"平均每样本掩码数: {total_masks / total_samples:.2f}")

```

    处理批次数据...
    
    --- 批次 1 ---
    输入形状: torch.Size([2, 256])
    注意力掩码形状: torch.Size([2, 256])
    应用标签: [0, 0]
    
    === 样本 1 ===
    应用标签: 0
    应用名称: cn.emagsoftware.gamehall
    输入 tokens (前30个): [2, 12, 5, 11, 17, 11, 17, 12, 4, 12, 10, 12, 8, 4, 8, 7, 19, 7, 19, 11, 18, 11, 5, 11, 14, 9, 14, 11, 12, 11]
    注意力掩码 (前30个): [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
    MLM 标签 (前30个): [-100, -100, -100, -100, -100, -100, -100, -100, 10, -100, -100, -100, -100, 12, -100, -100, -100, -100, -100, -100, -100, -100, 18, -100, -100, 11, -100, -100, -100, -100]
    原始十六进制数据 (前20个): ['7', '0', '6', 'c', '6', 'c', '7', '[MASK]', '7', '5', '7', '3', '[MASK]', '3', '2', 'e', '2', 'e', '6', 'd']
    原始十六进制数据 (后20个): ['[MASK]', 'f', '2', 'f', '3', '1', '3', '1', '2', 'e', '2', 'e', '3', '1', '3', '[MASK]', '0', '0', '0', '0']
    总token数: 254
    掩码token数量: 31
    CLS token位置: [0]
    SEP token位置: [255]
    
    === 样本 2 ===
    应用标签: 0
    应用名称: cn.emagsoftware.gamehall
    输入 tokens (前30个): [2, 20, 4, 4, 7, 17, 7, 18, 12, 18, 12, 5, 17, 5, 17, 4, 7, 6, 7, 12, 17, 12, 17, 17, 12, 17, 12, 8, 5, 8]
    注意力掩码 (前30个): [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
    MLM 标签 (前30个): [-100, -100, 15, 17, -100, -100, -100, -100, -100, -100, -100, -100, -100, -100, 17, 6, -100, -100, -100, -100, -100, -100, -100, -100, -100, -100, -100, -100, -100, -100]
    原始十六进制数据 (前20个): ['f', '[MASK]', '[MASK]', '2', 'c', '2', 'd', '7', 'd', '7', '0', 'c', '0', 'c', '[MASK]', '2', '1', '2', '7', 'c']
    原始十六进制数据 (后20个): ['3', '4', '3', '4', 'a', '7', '[MASK]', '7', '[MASK]', '3', 'a', '3', '5', 'd', '5', 'd', 'a', 'c', '[MASK]', 'c']
    总token数: 254
    掩码token数量: 32
    CLS token位置: [0]
    SEP token位置: [255]
    
    === 演示Embedding处理 ===
    === BERT Embedding 处理演示 ===
    输入形状: torch.Size([1, 256])
    1. Token Embeddings 形状: torch.Size([1, 256, 128])
       Token Embeddings 统计: 均值=0.0014, 标准差=0.0203
    2. Position Embeddings 形状: torch.Size([1, 256, 128])
       Position Embeddings 统计: 均值=-0.0001, 标准差=0.0201
    3. Token Type Embeddings 形状: torch.Size([1, 256, 128])
    4. 组合后 Embeddings 形状: torch.Size([1, 256, 128])
       组合后统计: 均值=-0.0522, 标准差=0.9792
    5. 最终 Embeddings 形状: torch.Size([1, 256, 128])
       最终统计: 均值=0.0028, 标准差=1.0515
    
    第一个样本的详细信息:
      输入 tokens: [2, 12, 5, 11, 17, 11, 17, 12, 4, 12, 10, 12, 8, 4, 8, 7, 19, 7, 19, 11, 18, 11, 5, 11, 14, 9, 14, 11, 12, 11, 4, 12, 10, 4, 10, 7, 19, 7, 19, 11, 8, 11, 8, 4, 10, 11, 19, 5, 5, 5, 4, 6, 12, 6, 4, 5, 5, 5, 5, 5, 5, 5, 5, 20, 20, 20, 20, 4, 4, 4, 6, 5, 5, 5, 5, 5, 6, 5, 4, 5, 5, 5, 4, 4, 5, 5, 5, 5, 4, 5, 15, 5, 5, 10, 4, 5, 15, 4, 15, 5, 5, 5, 5, 5, 13, 5, 13, 10, 15, 10, 15, 10, 15, 10, 15, 9, 5, 5, 5, 4, 18, 6, 18, 4, 5, 5, 5, 6, 12, 6, 12, 5, 5, 5, 5, 6, 13, 6, 13, 5, 5, 5, 5, 5, 4, 5, 16, 5, 5, 4, 5, 5, 7, 5, 7, 5, 6, 5, 6, 5, 5, 5, 5, 5, 5, 5, 5, 7, 8, 4, 8, 5, 6, 5, 5, 4, 5, 5, 5, 5, 5, 5, 5, 6, 5, 6, 5, 5, 5, 5, 5, 4, 19, 5, 19, 4, 5, 5, 5, 14, 17, 4, 17, 5, 7, 4, 7, 11, 4, 11, 13, 4, 7, 8, 7, 5, 13, 4, 13, 11, 13, 11, 13, 12, 9, 12, 9, 12, 9, 12, 9, 18, 5, 12, 5, 4, 20, 7, 20, 8, 6, 8, 6, 7, 19, 7, 19, 8, 6, 8, 4, 5, 5, 5, 5, 3]
      对应的 token 名称: ['[CLS]', '7', '0', '6', 'c', '6', 'c', '7', '[MASK]', '7', '5', '7', '3', '[MASK]', '3', '2', 'e', '2', 'e', '6', 'd', '6', '0', '6', '9', '4', '9', '6', '7', '6', '[MASK]', '7', '5', '[MASK]', '5', '2', 'e', '2', 'e', '6', '3', '6', '3', '[MASK]', '5', '6', 'e', '0', '0', '0', '[MASK]', '1', '7', '1', '[MASK]', '0', '0', '0', '0', '0', '0', '0', '0', 'f', 'f', 'f', 'f', '[MASK]', '[MASK]', '[MASK]', '1', '0', '0', '0', '0', '0', '1', '0', '[MASK]', '0', '0', '0', '[MASK]', '[MASK]', '0', '0', '0', '0', '[MASK]', '0', 'a', '0', '0', '5', '[MASK]', '0', 'a', '[MASK]', 'a', '0', '0', '0', '0', '0', '8', '0', '8', '5', 'a', '5', 'a', '5', 'a', '5', 'a', '4', '0', '0', '0', '[MASK]', 'd', '1', 'd', '[MASK]', '0', '0', '0', '1', '7', '1', '7', '0', '0', '0', '0', '1', '8', '1', '8', '0', '0', '0', '0', '0', '[MASK]', '0', 'b', '0', '0', '[MASK]', '0', '0', '2', '0', '2', '0', '1', '0', '1', '0', '0', '0', '0', '0', '0', '0', '0', '2', '3', '[MASK]', '3', '0', '1', '0', '0', '[MASK]', '0', '0', '0', '0', '0', '0', '0', '1', '0', '1', '0', '0', '0', '0', '0', '[MASK]', 'e', '0', 'e', '[MASK]', '0', '0', '0', '9', 'c', '[MASK]', 'c', '0', '2', '[MASK]', '2', '6', '[MASK]', '6', '8', '[MASK]', '2', '3', '2', '0', '8', '[MASK]', '8', '6', '8', '6', '8', '7', '4', '7', '4', '7', '4', '7', '4', 'd', '0', '7', '0', '[MASK]', 'f', '2', 'f', '3', '1', '3', '1', '2', 'e', '2', 'e', '3', '1', '3', '[MASK]', '0', '0', '0', '0', '[SEP]']
      第一个 token embedding (前10维): [-1.1277025938034058, -0.27551332116127014, 2.1395206451416016, 0.7658417820930481, 0.4172292947769165, 2.102085828781128, -1.3303418159484863, 1.0312297344207764, -0.0, 0.9620087742805481]
    === Embedding 处理演示完成 ===
    
    Embedding输出形状: torch.Size([1, 256, 128])
    这是BERT模型的第一层输出，接下来会进入Transformer层进行进一步处理
    
    --- 批次 2 ---
    输入形状: torch.Size([2, 256])
    注意力掩码形状: torch.Size([2, 256])
    应用标签: [0, 0]
    
    === 样本 1 ===
    应用标签: 0
    应用名称: cn.emagsoftware.gamehall
    输入 tokens (前30个): [2, 7, 12, 10, 17, 4, 4, 14, 6, 14, 6, 14, 15, 14, 15, 16, 7, 16, 7, 7, 17, 7, 4, 13, 18, 13, 18, 19, 7, 19]
    注意力掩码 (前30个): [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
    MLM 标签 (前30个): [-100, -100, -100, -100, 17, 10, 17, -100, -100, -100, -100, -100, -100, -100, -100, -100, -100, -100, -100, 7, -100, -100, 17, -100, -100, -100, -100, -100, -100, -100]
    原始十六进制数据 (前20个): ['2', '7', '5', 'c', '[MASK]', '[MASK]', '9', '1', '9', '1', '9', 'a', '9', 'a', 'b', '2', 'b', '2', '2', 'c']
    原始十六进制数据 (后20个): ['7', 'f', '[MASK]', 'f', 'e', '5', 'e', '5', '9', '[MASK]', '9', '3', '3', '8', '[MASK]', '8', '3', 'd', '3', 'd']
    总token数: 254
    掩码token数量: 35
    CLS token位置: [0]
    SEP token位置: [255]
    
    === 样本 2 ===
    应用标签: 0
    应用名称: cn.emagsoftware.gamehall
    输入 tokens (前30个): [2, 5, 10, 5, 10, 5, 5, 5, 5, 5, 10, 5, 4, 5, 6, 5, 6, 5, 5, 4, 4, 5, 5, 5, 5, 4, 4, 5, 4, 5]
    注意力掩码 (前30个): [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
    MLM 标签 (前30个): [-100, -100, -100, -100, -100, -100, -100, -100, -100, -100, -100, -100, 10, -100, -100, -100, -100, -100, -100, 5, 5, -100, -100, -100, -100, 5, 5, -100, 5, -100]
    原始十六进制数据 (前20个): ['0', '5', '0', '5', '0', '0', '0', '0', '0', '5', '0', '[MASK]', '0', '1', '0', '1', '0', '0', '[MASK]', '[MASK]']
    原始十六进制数据 (后20个): ['1', '0', '2', '0', '2', '0', '0', '3', '0', '3', '6', '2', '6', '2', '7', '1', '7', '9', 'a', 'b']
    总token数: 254
    掩码token数量: 31
    CLS token位置: [0]
    SEP token位置: [255]
    
    --- 批次 3 ---
    输入形状: torch.Size([2, 256])
    注意力掩码形状: torch.Size([2, 256])
    应用标签: [0, 0]
    
    === 样本 1 ===
    应用标签: 0
    应用名称: cn.emagsoftware.gamehall
    输入 tokens (前30个): [2, 6, 9, 5, 8, 5, 8, 5, 8, 5, 8, 5, 5, 4, 5, 5, 6, 5, 6, 5, 6, 5, 6, 6, 12, 6, 12, 5, 8, 5]
    注意力掩码 (前30个): [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
    MLM 标签 (前30个): [-100, -100, -100, -100, -100, -100, -100, -100, -100, -100, -100, -100, -100, 5, -100, -100, -100, -100, -100, -100, -100, -100, -100, -100, -100, -100, -100, -100, -100, -100]
    原始十六进制数据 (前20个): ['1', '4', '0', '3', '0', '3', '0', '3', '0', '3', '0', '0', '[MASK]', '0', '0', '1', '0', '1', '0', '1']
    原始十六进制数据 (后20个): ['3', '[MASK]', '[MASK]', 'f', 'c', '8', 'c', '8', '1', 'c', '1', '[MASK]', '[MASK]', '7', '6', '[MASK]', '3', 'b', '3', 'b']
    总token数: 254
    掩码token数量: 39
    CLS token位置: [0]
    SEP token位置: [255]
    
    === 样本 2 ===
    应用标签: 0
    应用名称: cn.emagsoftware.gamehall
    输入 tokens (前30个): [2, 14, 7, 4, 4, 7, 4, 7, 12, 20, 12, 20, 12, 4, 5, 12, 5, 12, 16, 12, 16, 7, 9, 7, 4, 6, 4, 6, 11, 5]
    注意力掩码 (前30个): [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
    MLM 标签 (前30个): [-100, -100, -100, 14, 7, -100, 12, -100, -100, -100, -100, -100, -100, 12, -100, -100, -100, -100, -100, -100, -100, -100, -100, -100, 9, -100, 11, -100, -100, -100]
    原始十六进制数据 (前20个): ['9', '2', '[MASK]', '[MASK]', '2', '[MASK]', '2', '7', 'f', '7', 'f', '7', '[MASK]', '0', '7', '0', '7', 'b', '7', 'b']
    原始十六进制数据 (后20个): ['0', '[MASK]', '0', '0', '0', '0', '0', '0', '[MASK]', '0', '0', '0', '0', '0', '0', '[MASK]', '0', '[MASK]', '0', '0']
    总token数: 254
    掩码token数量: 30
    CLS token位置: [0]
    SEP token位置: [255]
    
    ... 还有更多批次，为简洁起见只显示前3个批次
    
    === 处理完成 ===
    总样本数: 50
    应用类别数: 1
    应用类别映射: {'cn.emagsoftware.gamehall': 0}
    
    === 批次统计 ===
    总批次数: 25
    总样本数: 50
    总掩码数: 1175
    平均每样本掩码数: 23.50

