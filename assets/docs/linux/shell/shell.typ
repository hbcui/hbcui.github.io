= Disk Space

`du` 和 `df` 是 Linux/Unix 系统中常用的磁盘空间管理命令：

== `du` (Disk Usage)
- 作用：显示目录或文件的磁盘使用空间
- 常用选项：
  - `-s`：只显示总计（summary）
  - `-h`：以人类可读格式显示（如 KB、MB、GB）
- 示例：
  ```bash
  du -sh /data1/traffic_data/pcap_2022_03
  ```
  显示 `/data1/traffic_data/pcap_2022_03` 目录的总大小

== `df` (Disk Free)
- 作用：显示文件系统的磁盘空间使用情况
- 常用选项：
  - `-h`：以人类可读格式显示
- 示例：
  ```bash
  df -h /data1/cuihb
  ```
  显示 `/data1/cuihb` 所在文件系统的空间使用情况