## 流量数据的取得（简要了解，不涉及这部分）

从HDFS（分布式文件系统）集群下载pcap包。

## 流量数据的预处理（简要了解，不涉及这部分）

把pcap数据按照对应的app_name，按照如下规则，处理成中间csv数据：

* 将pcap数据按对应app_name，根据相关规则处理成中间csv文件。相关规则描述——截断数据包头部仅保存payload部分的前256字节，然后基于五元组信息拼接成完整流量。
* 将生成的中间csv文件数据，payload数据按照Bigram分词方式生成预训练所需的csv文件。

## 服务器环境重启

环境已重启，重启后登陆方式改为IP+端口登录，密码不变。(8卡)重新配置`~/.ssh/config`文件。

```bash
ssh server-83
```

## 新的脚本

现在有两个模式，一个是packet模式，一个是flow模式，这个模式在sh文件那里可以看到。3种数据处理方法，一个是no_patch的，就是上次跑通的那个，另外两个是patch的。

`traffic_new`是把三个数据处理方法总结到了一个脚本上。

```bash
CUDA_VISIBLE_DEVICES=1 OMP_NUM_THREADS=1 torchrun --nproc_per_node=1 --master_port=29560 scripts/pretrain/run_pretrain.py \
    .................
    --dataset_dir "/mnt/tenant-home_speed/encoder_hlf_yjh/traffic/dataset/train_dataset"     \
    --train_dir "packet_all256" \
    --test_dir "packet_all256" \
    --train_dataset_file_list  "test_random_50_5000.csv"  \
    --test_dataset_file_list "test_random_50_5000.csv"  \
    --mixed_dataset_file "test_random_50_5000.csv" \
    --sequence_mode 'flow' \ 
    .................
    --vocab_dir "/mnt/tenant-home_speed/encoder_hlf_yjh/cui-hb/A80030132_Traffic_llm/tokenizer/idpi.vocab"  \
    --data_method  "MLP_Embedding_patch"
```

### 运行

目前没有执行权限，先赋予权限再运行。

```bash
chmod +x ./shell/run_pretrain_train.sh && ./shell/run_pretrain_train.sh
```

### 日志

09:08:50 -> 09:29:01

```
[INFO] [2025-07-11 09:08:50,027] [log_support:log_message]: [line:99] [INFO] Reconstructing vocab dict...
[INFO] [2025-07-11 09:08:50,203] [log_support:log_message]: [line:99] [INFO] Building model...
[INFO] [2025-07-11 09:08:50,203] [log_support:log_message]: [line:99] [INFO] Initializing model architecture...
[INFO] [2025-07-11 09:08:51,892] [log_support:log_message]: [line:99] [INFO] Moving model to GPU...
[INFO] [2025-07-11 09:08:52,015] [log_support:log_message]: [line:99] [INFO] Wrapping model with DDP...
[INFO] [2025-07-11 09:08:52,458] [log_support:log_message]: [line:99] ┌════════════════════════════════════════════════════════════┐
│                      STAGE-1 TRAINING                      │
├════════════════════════════════════════════════════════════┤
│                      Stage Parameters                      │
│────────────────────────────────────────────────────────────│
│ Sequence Length    │      256                              │
│ World Size         │        1                              │
│ Batch Size         │    2,048                              │
│ Micro Batch        │        2                              │
│ Num Epochs         │      3.0                              │
└════════════════════════════════════════════════════════════┘

[INFO] [2025-07-11 09:08:52,814] [log_support:log_message]: [line:99] [INFO] Loading stage-training dataset from: ".../packet_all256/test_random_50_5000.csv"...
[INFO] [2025-07-11 09:08:57,486] [log_support:log_message]: [line:99] [INFO] Loading stage-testing dataset from: ".../packet_all256/test_random_50_5000.csv"...
[INFO] [2025-07-11 09:09:02,462] [log_support:log_message]: [line:99] ┌────────────────────────────────────────────────────────────┐
│                   TRAINING CONFIGURATION                   │
├────────────────────────────────────────────────────────────┤
│                        Environment                         │
│────────────────────────────────────────────────────────────│
│ World Size           │        1                            │
│ Sequence Mode        │     flow                            │
│ Keep Tail            │    False                            │
├────────────────────────────────────────────────────────────┤
│                       Training steps                       │
│────────────────────────────────────────────────────────────│
│ Max Steps            │       26                            │
│ Warmup Steps         │        2                            │
│ Annealing Steps      │       23                            │
│ Gradient Accum Steps │    1,024                            │
├────────────────────────────────────────────────────────────┤
│                       Train Dataset                        │
│────────────────────────────────────────────────────────────│
│ Total Samples        │   18,092                            │
│ Samples per GPU      │   18,092                            │
│ Mini Batch Size      │        2                            │
│ Batches per GPU      │    9,046                            │
│ Global Batch Size    │    2,048                            │
│ Dropped Samples      │        0                            │
└────────────────────────────────────────────────────────────┘
[INFO] [2025-07-11 09:09:49,439] [log_support:log_message]: [line:99] >>> Train     Stage: 1   Step: 1/26   MLM-Loss: 5.6946   MLM-Acc: 0.0032   MLM-Top10: 0.0335   MLM-All-Tokens: 0.0036   MLM-F1: 0.0019
[INFO] [2025-07-11 09:09:49,533] [log_support:log_message]: [line:99] >>> Test      Stage: 1   Step: 1/26   MLM-Loss: 6.0101   MLM-Acc: 0.0000   MLM-Top10: 0.0312   MLM-All-Tokens: 0.0027   MLM-F1: 0.0000
[INFO] [2025-07-11 09:09:51,604] [log_support:log_message]: [line:99] Best model updated: /mnt/tenant-home_speed/encoder_hlf_yjh/cui-hb/exp-277/checkpoints/best.pth
[INFO] [2025-07-11 09:10:37,955] [log_support:log_message]: [line:99] >>> Train     Stage: 1   Step: 2/26   MLM-Loss: 6.0146   MLM-Acc: 0.0024   MLM-Top10: 0.0244   MLM-All-Tokens: 0.0024   MLM-F1: 0.0015
[INFO] [2025-07-11 09:10:37,982] [log_support:log_message]: [line:99] >>> Test      Stage: 1   Step: 2/26   MLM-Loss: 6.1090   MLM-Acc: 0.0000   MLM-Top10: 0.0182   MLM-All-Tokens: 0.0020   MLM-F1: 0.0000
[INFO] [2025-07-11 09:11:25,073] [log_support:log_message]: [line:99] >>> Train     Stage: 1   Step: 3/26   MLM-Loss: 5.9974   MLM-Acc: 0.0023   MLM-Top10: 0.0244   MLM-All-Tokens: 0.0025   MLM-F1: 0.0014
[INFO] [2025-07-11 09:11:25,099] [log_support:log_message]: [line:99] >>> Test      Stage: 1   Step: 3/26   MLM-Loss: 5.3308   MLM-Acc: 0.1458   MLM-Top10: 0.2188   MLM-All-Tokens: 0.1949   MLM-F1: 0.0050
[INFO] [2025-07-11 09:11:28,745] [log_support:log_message]: [line:99] Best model updated: /mnt/tenant-home_speed/encoder_hlf_yjh/cui-hb/exp-277/checkpoints/best.pth
[INFO] [2025-07-11 09:12:14,760] [log_support:log_message]: [line:99] >>> Train     Stage: 1   Step: 4/26   MLM-Loss: 5.1868   MLM-Acc: 0.1695   MLM-Top10: 0.3156   MLM-All-Tokens: 0.1553   MLM-F1: 0.0024
[INFO] [2025-07-11 09:12:14,786] [log_support:log_message]: [line:99] >>> Test      Stage: 1   Step: 4/26   MLM-Loss: 4.1238   MLM-Acc: 0.5443   MLM-Top10: 0.5625   MLM-All-Tokens: 0.4398   MLM-F1: 0.0069
[INFO] [2025-07-11 09:12:16,870] [log_support:log_message]: [line:99] Best model updated: /mnt/tenant-home_speed/encoder_hlf_yjh/cui-hb/exp-277/checkpoints/best.pth
[INFO] [2025-07-11 09:13:02,871] [log_support:log_message]: [line:99] >>> Train     Stage: 1   Step: 5/26   MLM-Loss: 4.6905   MLM-Acc: 0.3599   MLM-Top10: 0.3847   MLM-All-Tokens: 0.3609   MLM-F1: 0.0021
[INFO] [2025-07-11 09:13:02,898] [log_support:log_message]: [line:99] >>> Test      Stage: 1   Step: 5/26   MLM-Loss: 3.6487   MLM-Acc: 0.5521   MLM-Top10: 0.5781   MLM-All-Tokens: 0.4785   MLM-F1: 0.0069
[INFO] [2025-07-11 09:13:04,959] [log_support:log_message]: [line:99] Best model updated: /mnt/tenant-home_speed/encoder_hlf_yjh/cui-hb/exp-277/checkpoints/best.pth
[INFO] [2025-07-11 09:13:50,830] [log_support:log_message]: [line:99] >>> Train     Stage: 1   Step: 6/26   MLM-Loss: 5.1213   MLM-Acc: 0.3569   MLM-Top10: 0.3959   MLM-All-Tokens: 0.3542   MLM-F1: 0.0020
[INFO] [2025-07-11 09:13:50,857] [log_support:log_message]: [line:99] >>> Test      Stage: 1   Step: 6/26   MLM-Loss: 4.9013   MLM-Acc: 0.2839   MLM-Top10: 0.3281   MLM-All-Tokens: 0.2754   MLM-F1: 0.0030
[INFO] [2025-07-11 09:14:36,736] [log_support:log_message]: [line:99] >>> Train     Stage: 1   Step: 7/26   MLM-Loss: 4.7087   MLM-Acc: 0.3511   MLM-Top10: 0.3925   MLM-All-Tokens: 0.3516   MLM-F1: 0.0020
[INFO] [2025-07-11 09:14:36,763] [log_support:log_message]: [line:99] >>> Test      Stage: 1   Step: 7/26   MLM-Loss: 4.6489   MLM-Acc: 0.2708   MLM-Top10: 0.3255   MLM-All-Tokens: 0.2555   MLM-F1: 0.0025
[INFO] [2025-07-11 09:15:23,666] [log_support:log_message]: [line:99] >>> Train     Stage: 1   Step: 8/26   MLM-Loss: 4.1798   MLM-Acc: 0.3524   MLM-Top10: 0.4234   MLM-All-Tokens: 0.3530   MLM-F1: 0.0020
[INFO] [2025-07-11 09:15:23,693] [log_support:log_message]: [line:99] >>> Test      Stage: 1   Step: 8/26   MLM-Loss: 4.5889   MLM-Acc: 0.2604   MLM-Top10: 0.3880   MLM-All-Tokens: 0.2754   MLM-F1: 0.0032
[INFO] [2025-07-11 09:16:48,018] [log_support:log_message]: [line:99] >>> Train     Stage: 1   Step: 9/26   MLM-Loss: 4.2300   MLM-Acc: 0.3443   MLM-Top10: 0.4309   MLM-All-Tokens: 0.3462   MLM-F1: 0.0020
[INFO] [2025-07-11 09:16:48,045] [log_support:log_message]: [line:99] >>> Test      Stage: 1   Step: 9/26   MLM-Loss: 3.6477   MLM-Acc: 0.4479   MLM-Top10: 0.5182   MLM-All-Tokens: 0.4227   MLM-F1: 0.0049
[INFO] [2025-07-11 09:17:34,041] [log_support:log_message]: [line:99] >>> Train     Stage: 1   Step: 10/26   MLM-Loss: 4.0715   MLM-Acc: 0.3583   MLM-Top10: 0.4502   MLM-All-Tokens: 0.3588   MLM-F1: 0.0021
[INFO] [2025-07-11 09:17:34,068] [log_support:log_message]: [line:99] >>> Test      Stage: 1   Step: 10/26   MLM-Loss: 3.2273   MLM-Acc: 0.5573   MLM-Top10: 0.6224   MLM-All-Tokens: 0.4785   MLM-F1: 0.0072
[INFO] [2025-07-11 09:17:38,405] [log_support:log_message]: [line:99] Best model updated: /mnt/tenant-home_speed/encoder_hlf_yjh/cui-hb/exp-277/checkpoints/best.pth
[INFO] [2025-07-11 09:18:23,888] [log_support:log_message]: [line:99] >>> Train     Stage: 1   Step: 11/26   MLM-Loss: 4.0818   MLM-Acc: 0.3583   MLM-Top10: 0.4525   MLM-All-Tokens: 0.3561   MLM-F1: 0.0021
[INFO] [2025-07-11 09:18:23,915] [log_support:log_message]: [line:99] >>> Test      Stage: 1   Step: 11/26   MLM-Loss: 3.2877   MLM-Acc: 0.5260   MLM-Top10: 0.5964   MLM-All-Tokens: 0.6070   MLM-F1: 0.0063
[INFO] [2025-07-11 09:19:09,377] [log_support:log_message]: [line:99] >>> Train     Stage: 1   Step: 12/26   MLM-Loss: 4.0873   MLM-Acc: 0.3540   MLM-Top10: 0.4512   MLM-All-Tokens: 0.3541   MLM-F1: 0.0020
[INFO] [2025-07-11 09:19:09,404] [log_support:log_message]: [line:99] >>> Test      Stage: 1   Step: 12/26   MLM-Loss: 4.2562   MLM-Acc: 0.3125   MLM-Top10: 0.4193   MLM-All-Tokens: 0.3926   MLM-F1: 0.0034
[INFO] [2025-07-11 09:19:56,475] [log_support:log_message]: [line:99] >>> Train     Stage: 1   Step: 13/26   MLM-Loss: 4.0895   MLM-Acc: 0.3529   MLM-Top10: 0.4486   MLM-All-Tokens: 0.3525   MLM-F1: 0.0020
[INFO] [2025-07-11 09:19:56,503] [log_support:log_message]: [line:99] >>> Test      Stage: 1   Step: 13/26   MLM-Loss: 5.2196   MLM-Acc: 0.1797   MLM-Top10: 0.2214   MLM-All-Tokens: 0.1879   MLM-F1: 0.0017
[INFO] [2025-07-11 09:20:42,447] [log_support:log_message]: [line:99] >>> Train     Stage: 1   Step: 14/26   MLM-Loss: 4.1051   MLM-Acc: 0.3477   MLM-Top10: 0.4458   MLM-All-Tokens: 0.3464   MLM-F1: 0.0020
[INFO] [2025-07-11 09:20:42,474] [log_support:log_message]: [line:99] >>> Test      Stage: 1   Step: 14/26   MLM-Loss: 5.0729   MLM-Acc: 0.1198   MLM-Top10: 0.2812   MLM-All-Tokens: 0.1648   MLM-F1: 0.0014
[INFO] [2025-07-11 09:21:28,478] [log_support:log_message]: [line:99] >>> Train     Stage: 1   Step: 15/26   MLM-Loss: 4.0718   MLM-Acc: 0.3555   MLM-Top10: 0.4503   MLM-All-Tokens: 0.3586   MLM-F1: 0.0020
[INFO] [2025-07-11 09:21:28,505] [log_support:log_message]: [line:99] >>> Test      Stage: 1   Step: 15/26   MLM-Loss: 4.2083   MLM-Acc: 0.3672   MLM-Top10: 0.4219   MLM-All-Tokens: 0.4273   MLM-F1: 0.0036
[INFO] [2025-07-11 09:22:14,101] [log_support:log_message]: [line:99] >>> Train     Stage: 1   Step: 16/26   MLM-Loss: 4.0530   MLM-Acc: 0.3596   MLM-Top10: 0.4541   MLM-All-Tokens: 0.3575   MLM-F1: 0.0021
[INFO] [2025-07-11 09:22:14,127] [log_support:log_message]: [line:99] >>> Test      Stage: 1   Step: 16/26   MLM-Loss: 1.9467   MLM-Acc: 0.7943   MLM-Top10: 0.8203   MLM-All-Tokens: 0.8391   MLM-F1: 0.0153
[INFO] [2025-07-11 09:22:15,641] [log_support:log_message]: [line:99] Best model updated: /mnt/tenant-home_speed/encoder_hlf_yjh/cui-hb/exp-277/checkpoints/best.pth
[INFO] [2025-07-11 09:23:39,272] [log_support:log_message]: [line:99] >>> Train     Stage: 1   Step: 17/26   MLM-Loss: 4.0981   MLM-Acc: 0.3497   MLM-Top10: 0.4448   MLM-All-Tokens: 0.3506   MLM-F1: 0.0020
[INFO] [2025-07-11 09:23:39,300] [log_support:log_message]: [line:99] >>> Test      Stage: 1   Step: 17/26   MLM-Loss: 4.0441   MLM-Acc: 0.3750   MLM-Top10: 0.4297   MLM-All-Tokens: 0.3668   MLM-F1: 0.0038
[INFO] [2025-07-11 09:24:24,901] [log_support:log_message]: [line:99] >>> Train     Stage: 1   Step: 18/26   MLM-Loss: 4.0099   MLM-Acc: 0.3659   MLM-Top10: 0.4605   MLM-All-Tokens: 0.3635   MLM-F1: 0.0021
[INFO] [2025-07-11 09:24:24,929] [log_support:log_message]: [line:99] >>> Test      Stage: 1   Step: 18/26   MLM-Loss: 4.3703   MLM-Acc: 0.3177   MLM-Top10: 0.3880   MLM-All-Tokens: 0.2723   MLM-F1: 0.0030
[INFO] [2025-07-11 09:25:10,960] [log_support:log_message]: [line:99] >>> Train     Stage: 1   Step: 19/26   MLM-Loss: 4.0832   MLM-Acc: 0.3517   MLM-Top10: 0.4469   MLM-All-Tokens: 0.3486   MLM-F1: 0.0020
[INFO] [2025-07-11 09:25:10,987] [log_support:log_message]: [line:99] >>> Test      Stage: 1   Step: 19/26   MLM-Loss: 4.9282   MLM-Acc: 0.1953   MLM-Top10: 0.2943   MLM-All-Tokens: 0.2438   MLM-F1: 0.0020
[INFO] [2025-07-11 09:25:56,662] [log_support:log_message]: [line:99] >>> Train     Stage: 1   Step: 20/26   MLM-Loss: 4.0701   MLM-Acc: 0.3536   MLM-Top10: 0.4502   MLM-All-Tokens: 0.3560   MLM-F1: 0.0020
[INFO] [2025-07-11 09:25:56,688] [log_support:log_message]: [line:99] >>> Test      Stage: 1   Step: 20/26   MLM-Loss: 4.0201   MLM-Acc: 0.3828   MLM-Top10: 0.4479   MLM-All-Tokens: 0.3949   MLM-F1: 0.0040
[INFO] [2025-07-11 09:26:42,882] [log_support:log_message]: [line:99] >>> Train     Stage: 1   Step: 21/26   MLM-Loss: 4.0483   MLM-Acc: 0.3576   MLM-Top10: 0.4539   MLM-All-Tokens: 0.3563   MLM-F1: 0.0020
[INFO] [2025-07-11 09:26:42,908] [log_support:log_message]: [line:99] >>> Test      Stage: 1   Step: 21/26   MLM-Loss: 3.7508   MLM-Acc: 0.3333   MLM-Top10: 0.6224   MLM-All-Tokens: 0.4469   MLM-F1: 0.0086
[INFO] [2025-07-11 09:27:29,933] [log_support:log_message]: [line:99] >>> Train     Stage: 1   Step: 22/26   MLM-Loss: 4.1093   MLM-Acc: 0.3443   MLM-Top10: 0.4430   MLM-All-Tokens: 0.3458   MLM-F1: 0.0020
[INFO] [2025-07-11 09:27:29,960] [log_support:log_message]: [line:99] >>> Test      Stage: 1   Step: 22/26   MLM-Loss: 3.8846   MLM-Acc: 0.3958   MLM-Top10: 0.4661   MLM-All-Tokens: 0.2258   MLM-F1: 0.0042
[INFO] [2025-07-11 09:28:15,723] [log_support:log_message]: [line:99] >>> Train     Stage: 1   Step: 23/26   MLM-Loss: 4.0854   MLM-Acc: 0.3505   MLM-Top10: 0.4468   MLM-All-Tokens: 0.3532   MLM-F1: 0.0020
[INFO] [2025-07-11 09:28:15,749] [log_support:log_message]: [line:99] >>> Test      Stage: 1   Step: 23/26   MLM-Loss: 2.6609   MLM-Acc: 0.6302   MLM-Top10: 0.7266   MLM-All-Tokens: 0.6531   MLM-F1: 0.0109
[INFO] [2025-07-11 09:29:01,560] [log_support:log_message]: [line:99] >>> Train     Stage: 1   Step: 24/26   MLM-Loss: 4.0630   MLM-Acc: 0.3534   MLM-Top10: 0.4510   MLM-All-Tokens: 0.3525   MLM-F1: 0.0020
[INFO] [2025-07-11 09:29:01,588] [log_support:log_message]: [line:99] >>> Test      Stage: 1   Step: 24/26   MLM-Loss: 4.4665   MLM-Acc: 0.2917   MLM-Top10: 0.3724   MLM-All-Tokens: 0.2184   MLM-F1: 0.0030
```