README下游任务涉诈二分类（0/1：normal/defraud）的微调训练。

## 设计思路

1. 第一步（已完成）：预训练模型bge对原始数据进行“特征提取”，已经得到深层表征，后面不动这里，和下游任务的二分类头拆开，相当于经典机器学习的特征工程；  
2. 第二步（当前流程）：基于这些固定特征，训练一个专门的模型bert融合数据和时间特征mlp来完成下游分类，这个模型仅从头学习分类器的权重，前面特征提取编码器的部分相当于冻结了。  

## 改善措施

1. 时间特征的选择：`feature_types = ['HourOfDay', 'DayOfWeek', 'MonthOfYear', 'DayOfMonth', 'WeekOfYear', 'SeasonOfYear']`
2. 早停条件更加谨慎
3. 标签平滑 `criterion = nn.CrossEntropyLoss(label_smoothing=0.1)`

## 结果

### 训练日志

下面是训练日志截断最后一部分的内容。

```
.............
.............
========== Epoch 39/300 ==========
Epoch 39 Training: 100%|██████████| 908/908 [05:01<00:00,  3.01it/s]
Train - Loss: 0.2421, Accuracy: 0.9808
Epoch 39 Val: 100%|██████████| 223/223 [00:23<00:00,  9.35it/s]
Val - Loss: 0.2998, Accuracy: 0.9533, F1: 0.9534
Classification Report:
              precision    recall  f1-score   support

           0     0.9728    0.9529    0.9627      2249
           1     0.9215    0.9540    0.9375      1304

    accuracy                         0.9533      3553
   macro avg     0.9471    0.9534    0.9501      3553
weighted avg     0.9539    0.9533    0.9534      3553

早停触发，在第 39 轮停止训练
训练完成，最佳验证F1 Score: 0.9628
模型和日志保存在: output_model_finetune/finetune_20250901_083417
```

### 可视化（tensorboard）

Train/BatchLoss
tag: Train/BatchLoss

![]({{ "assets/images/2025-09-02/train1.png" | relative_url }})

Train/EpochAccuracy
tag: Train/EpochAccuracy

![]({{ "assets/images/2025-09-02/train2.png" | relative_url }})

Train/EpochLoss
tag: Train/EpochLoss

![]({{ "assets/images/2025-09-02/train3.png" | relative_url }})

Train/LearningRate
tag: Train/LearningRate

![]({{ "assets/images/2025-09-02/train4.png" | relative_url }})

Val/EpochAccuracy
tag: Val/EpochAccuracy

![]({{ "assets/images/2025-09-02/val1.png" | relative_url }})


Val/EpochLoss
tag: Val/EpochLoss

![]({{ "assets/images/2025-09-02/val2.png" | relative_url }})



Val/F1Score
tag: Val/F1Score

![]({{ "assets/images/2025-09-02/val3.png" | relative_url }})


Val/Precision
tag: Val/Precision

![]({{ "assets/images/2025-09-02/val4.png" | relative_url }})

Val/Recall
tag: Val/Recall

![]({{ "assets/images/2025-09-02/val5.png" | relative_url }})





