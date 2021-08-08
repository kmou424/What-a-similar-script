# What-a-similar-script

#### 本锤人项目中用到的主要代码来自<a href="https://www.shuzhiduo.com/A/q4zVRBrlzK/" target="_blank">这篇文章</a>
#### 主要用到的库为gensim

## 使用方法:
### 1.配置环境:
```
apt-get install python3
git clone https://github.com/kmou424/What-a-similar-script
cd What-a-similar-script
pip install jieba gensim
```
### 2.执行对比
```
注:
代码中的f1和f2均作为被比较对象, f3为比较对象
将f3与f1、f2对比得到的相似度分别为第一行与第二行输出数据
输出数据格式为小数, 请自行运用数学知识将其转换为百分数
f1: 被抄袭者的脚本
f2: 验证数据有效性的参考脚本
f3: 抄袭者的脚本
```
```
1.执行源文件对比:
python3 test-源文件.py
输出结果:
0.7914875      (相似度约为79.15%)
0.00477405     (相似度约为0.48%)

此对比方式将 未被修改的源文件 进行对比
第一行输出数据: 被抄袭者 和 抄袭者 的脚本相似度对比
第二行输出数据: 被抄袭者 和 功能完全不同的由本人(仓库创建者)编写 的脚本对比(用于验证数据的有效性)

2.执行去中文化对比:
python3 test-去中文化.py
输出结果:
0.7324907      (相似度约为73.25%)
0.0016610312   (相似度约为0.17%)

此对比方式将 源文件去除所有中文字符后 进行对比
第一行输出数据: 被抄袭者 和 抄袭者 的脚本相似度对比
第二行输出数据: 被抄袭者 和 功能完全不同的由本人(仓库创建者)编写 的脚本对比(用于验证数据的有效性)
```

## 参考
#### 用到的所有文件来源: <a href="https://www.shuzhiduo.com/A/q4zVRBrlzK/" target="_blank">核心验证程序代码</a>
#### 被抄袭者脚本: <a href="https://github.com/YAWAsau/backup_script/blob/68648b4afa1bc73878072f1a41bbf07f740fb819/backup.sh" target="_blank">Here</a>
#### 抄袭者脚本: 由被抄袭者提供
#### 验证数据有效性的参考脚本: <a href="https://github.com/kmou424/toolbox/blob/fce66a3b7764ee8c95c43a8ceda016d91501cca2/video/compress_video_enhanced.sh" target="_blank">Here</a>
#### tips:若对数据抱有疑问请自行下载源代码进行本地运行验证
