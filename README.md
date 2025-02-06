# LinuxServerScripts
Linux 服务器脚本

# stat.sh
服务器信息统计转发，目前转发渠道有 Telegram Bot，已在 Debian 11 上面测试通过。
可以添加定时任务执行：
```bash
sudo chmod +x stat.sh
# 手动测试脚本
bash stat.sh
# 配置定时任务
sudo crontab -e
```
10分钟发送一次，添加以下内容：
```bash
*/10 * * * * bash /path/to/your/stat.sh
```