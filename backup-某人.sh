backup_mode=lz4
txt=/sdcard/Apkname.txt
Start() {
    print "####################################"
    print "#                        数据备份APP V3.0版本                         #"
    print "#                      Script: By @IOIC_古人云                        #"
    print "#                   该版本仅可用于'数据备份APP'                    #"
    print "####################################"
    [[ $(id -u) -ne 0 ]] && echo "未获取到完整的su;su: inaccessible or not found" && exit 1
    if [[ ! $(getenforce) == Permissive ]]; then
         echo "#-------selinux状态:严格-------#"
         echo "警告:软件本身需要Selinux的支持(宽容)，如因系统原因无法进行宽容您的Selinux，恢复可能出现问题，严格的Selinux当前正处于测试阶段，如出现问题请进入软件内反馈群进行反馈。"
         Selinux_result=1
    elif [[ ! $(getenforce) == Enforcing ]]; then
         echo "#-------selinux状态:宽容-------#"
         Selinux_result=0
    elif [[ ! $(getenforce) == Disabled ]]; then
         echo "#-------selinux状态:禁用-------#"
         Selinux_result=0
    else
         echo "#-------selinux状态:未知的状态-------#"
    fi
}
return_result() {
    if [[ $? == 0 ]]; then
		echo "$1 成功"
		statu=1
	else
		echo "$1 失败，请检查自身原因或联系开发者"
		statu=0
	fi
}
##备份模式二进制##
lz4 () {
	tar -cPpf - "$2" 2>/dev/null | pv -terb > $1
}
zstd_nd () {
	tar -cPpf - "$2" 2>/dev/null | pv -terb | zstd -r -T0 -0 -q >$1
}
##结束二进制##
auto_pre() {
    if [[ $backup_mode == "lz4" ]]; then
        lz4 $1 $2    
    elif [[ $backup_mode == "zstd" ]]; then
        zstd_nd $1 $2
    else
        echo "未知的备份模式!"
        exit 0
    fi
}
change_mode() {
    if [[ $backup_mode == "lz4" ]]; then
        backup_mode=zstd
    elif [[ $backup_mode == "zstd" ]]; then
        backup_mode=lz4
    else
        echo "未知的备份模式!"
        exit 0
    fi
}
Backup_data() {
    echo "[ 开始备份 {$apkname} 的 Android/data 数据 ]"
	if [[ -d /sdcard/Android/data/$package ]]; then
        echo "发现 {$apkname} 的 Android/data 数据，开始备份"
        [[ ! -d $Backup/$package ]] && mkdir -p "$Backup/$package"
        auto_pre "$Backup/$package/$package-data.tar.$backup_mode" /sdcard/Android/data/$package
        return_result "备份 {$apkname} 的 Android/data 数据"
        if [[ $statu == 0 ]]; then
            echo "默认备份方式备份失败，正在更换备份方式...."
            change_mode
            auto_pre "$Backup/$package/$package-data.tar.$backup_mode" /sdcard/Android/data/$package
            return_result "备份 {$apkname} 的 Android/data 数据"
        fi
    else
        echo "{$apkname} 不存在 Android/data 数据，跳过备份"
    fi
}
Backup_obb() {
    echo "[ 开始备份 {$apkname} 的 Android/obb 数据 ]"
	if [[ -d /sdcard/Android/obb/$package ]]; then
        echo "发现 {$apkname} 的 Android/obb 数据，开始备份"
        [[ ! -d $Backup/$package ]] && mkdir -p "$Backup/$package"
        auto_pre "$Backup/$package/$package-obb.tar.$backup_mode" /sdcard/Android/obb/$package
        return_result "备份 {$apkname} 的 Android/obb 数据"
        if [[ $statu == 0 ]]; then
            echo "默认备份方式备份失败，正在更换备份方式...."
            change_mode
            auto_pre "$Backup/$package/$package-obb.tar.$backup_mode" /sdcard/Android/obb/$package
            return_result "备份 {$apkname} 的 Android/obb 数据"
        fi
    else
        echo "{$apkname} 不存在 Android/obb 数据，跳过备份"
    fi
}
Backup_user() {
    echo "[ 开始备份${apkname} 的 user 数据 ]"
		if [[ -d /data/user/0/$package && -n 1 ]]; then
		    echo "发现 {$apkname} 的 user 数据，开始备份"
		    [[ ! -d $Backup/$package ]] && mkdir -p "$Backup/$package"
            auto_pre "$Backup/$package/$package-user.tar.$backup_mode" "/data/user/0/$package"
            return_result "备份 {$apkname} 的 user 数据"
            if [[ $statu == 0 ]]; then
                echo "默认备份方式备份失败，正在更换备份方式...."
                change_mode
                auto_pre "$Backup/$package/$package-user.tar.$backup_mode" "/data/user/0/$package"
                return_result "备份 {$apkname} 的 user 数据"
            fi
		else
		    echo "{$apkname} 不存在 user 数据，跳过备份"
		fi
}
Backup_apk() {
    [[ ! -d $Backup ]] && mkdir -p "$Backup"
	[[ ! -d $Backup/$package ]] && mkdir -p "$Backup/$package"
	cd $Backup/$package
	#备份apk
	echo "[ 开始备份${apkname} 的 APK 文件 ]"
	[[ -z $(cat $Backup/name.txt | grep -v "#" | sed -e '/^$/d' | grep -w "$package" | head -1) ]] && echo "$apkname  $package" >>$Backup/name.txt
	[[ -z $(cat $Backup/bename.txt | grep -v "#" | sed -e '/^$/d' | grep -w "$package" | head -1) ]] && echo "$apkname  $package" >>$Backup/bename.txt
	echo "[ 发现 {$apkname} 有 $(pm path "$package" | cut -f2 -d ':' | wc -l) 个Apk ]"
	if [[ $(pm path "$package" | cut -f2 -d ':' | wc -l) == 1 ]]; then
	    echo "{${apkname}} 为常规apk，开始执行备份...."
		apkpath=$(pm path "$package" | cut -f2 -d ':')
        cd ${apkpath%/*}
        apk_name_1=${apkpath##*/}
        echo "${apk_name_1}" >$Backup/$package/filename.txt
        auto_pre "$Backup/$package/$package-apk.tar.$backup_mode" "$apk_name_1"
        return_result "备份 {$apkname} 的 apk 文件"
        if [[ $statu == 0 ]]; then
            echo "默认备份方式备份失败，正在更换备份方式...."
            change_mode
            auto_pre "$Backup/$package/$package-apk.tar.$backup_mode" "$apk_name_1"
            return_result "备份 {$apkname} 的 apk 文件"
        fi
	else
	    echo "{${apkname}} 为split apk(分包apk)，开始执行备份...."
		cp -r $(pm path "$package" | cut -f2 -d ':') "$Backup/$package"
		return_result "备份 {$apkname} 的 apk 文件"
	fi
}
[[ ! -d /data/user/0/com.icio.bei/files/tools ]] && echo "/data/user/0/com.icio.bei/files/tools目录遗失" && exit 1
# Load Settings Variables
. /data/user/0/com.icio.bei/files/tools/bin.sh
Start

[[ ! -d $Backup ]] && mkdir -p "$Backup"
[[ ! -e $Backup/name.txt ]] && echo "#数据备份  com.icio.bei" >$Backup/name.txt
[[ ! -e $Backup/bename.txt ]] && echo "#数据备份  com.icio.bei" >$Backup/bename.txt

num=$(cat $txt | grep -v "#" | sed -e '/^$/d' | sed -n '$=')
[[ "${num}" == "" ]] && echo "出现错误:未选择应用或读取失败！" && exit 0
i=1
used_time() {
    used_time=$(($2-$1))
    hour=$(($used_time/3600))
    minute=$(($used_time%3600/60))
    second=$(($used_time%3600%60))
    [[ $hour == "0" ]] && [[ $minute == "0" ]] && used_time=$second"秒"
    [[ $hour == "0" ]] && [[ $minute != "0" ]] && used_time=$minute"分"$second"秒"
    [[ $hour != "0" ]] && used_time=$hour"时"$minute"分"$second"秒"
}
size(){
    size=$(ls -l "$1" | awk '{sum += $5} END {print sum}')
    [[ $(echo $size | awk '{printf("%.0f",$1)}') -lt "1024" ]] && size=$(echo $size | awk '{printf("%.0f",$1)}')"B"
    [[ $(echo $size | awk '{printf("%.0f",$1/1024)}') -lt "1024" ]] && [[ $(echo $size | awk '{printf("%.0f",$1/1024)}') -ge "1" ]] && size=$(echo $size | awk '{printf("%.2f",$1/1024)}')"KB"
    [[ $(echo $size | awk '{printf("%.0f",$1/1024/1024)}') -lt "1024" ]] && [[ $(echo $size | awk '{printf("%.0f",$1/1024/1024)}') -ge "1" ]] && size=$(echo $size | awk '{printf("%.2f",$1/1024/1024)}')"MB"
    [[ $(echo $size | awk '{printf("%.0f",$1/1024/1024/1024)}') -lt "1024" ]] && [[ $(echo $size | awk '{printf("%.0f",$1/1024/1024/1024)}') -ge "1" ]] && size=$(echo $size | awk '{printf("%.2f",$1/1024/1024/1024)}')"GB"
}
first_start_time=$(date +%s -D "$(date +"%Y-%m-%d %H:%M:%S")")
while [[ $i -le $num ]]; do    
    start_time=$(date +%s -D "$(date +"%Y-%m-%d %H:%M:%S")")
   	apkname=$(cat $txt | grep -v "#" | sed -e '/^$/d' | sed -n "${i}p" | awk '{print $1}')
   	package=$(cat $txt | grep -v "#" | sed -e '/^$/d' | sed -n "${i}p" | awk '{print $2}')
    [[ "${package}" == "" ]] && echo "出现错误:读取应用数据出错！" && exit 0
    apk_version=$(pm dump ${package}  2>/dev/null | grep -m 1 versionName | sed -n 's/.*=//p')
    echo "正在备份第 ${i}/${num} 个应用：{$apkname}-V${apk_version}，剩余 $(($num - $i)) 个应用"
    if [[ "${apk_version}" == "" ]]; then
        echo "出现错误:应用未安装，无法进行备份！"
    else
        am force-stop ${package}
        [[ $package == com.tencent.mobileqq ]] && echo "QQ可能恢復备份失败或是丢失聊天记录，请自行用你信赖的软件备份" || [[ $package == com.tencent.mm ]] && echo "WeChat 可能恢復备份失败或是丢失聊天记录，请自行用你信赖的软件备份" || [[ $package == com.tencent.tim ]] && echo "TIM可能恢復备份失败或是丢失聊天记录，请自行用你信赖的软件备份"
        Backup_apk && Backup_data && Backup_obb && Backup_user
        end_time=$(date +%s -D "$(date +"%Y-%m-%d %H:%M:%S")")
        used_time $start_time $end_time
        size ${Backup}/${package}
        alone_size=$size
        echo "备份 {${apkname}} 全部数据 :"
        echo "用时：${used_time}"
        echo "占用：${alone_size}"
    fi
    echo "progress:[${i}/${num}] finished！\n\n\n"
    let i++
done
first_end_time=$(date +%s -D "$(date +"%Y-%m-%d %H:%M:%S")")
used_time $first_start_time $first_end_time
echo "批量备份数据结束:"
echo "用时：${used_time}"
echo "占用：$(du -sh "${Backup}" | awk '{print $1}')"
echo "路径：${Backup}"
echo "脚本运行结束，如对备份结果有疑问请加入反馈群反馈"