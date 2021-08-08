backup_mode=lz4
txt=/sdcard/Apkname.txt
Start() {
    print "####################################"
    print "#                        APP V3.0                         #"
    print "#                      Script: By @IOIC_                        #"
    print "#                   'APP'                    #"
    print "####################################"
    [[ $(id -u) -ne 0 ]] && echo "su;su: inaccessible or not found" && exit 1
    if [[ ! $(getenforce) == Permissive ]]; then
         echo "#-------selinux:-------#"
         echo ":Selinux()SelinuxSelinux"
         Selinux_result=1
    elif [[ ! $(getenforce) == Enforcing ]]; then
         echo "#-------selinux:-------#"
         Selinux_result=0
    elif [[ ! $(getenforce) == Disabled ]]; then
         echo "#-------selinux:-------#"
         Selinux_result=0
    else
         echo "#-------selinux:-------#"
    fi
}
return_result() {
    if [[ $? == 0 ]]; then
		echo "$1 "
		statu=1
	else
		echo "$1 "
		statu=0
	fi
}
####
lz4 () {
	tar -cPpf - "$2" 2>/dev/null | pv -terb > $1
}
zstd_nd () {
	tar -cPpf - "$2" 2>/dev/null | pv -terb | zstd -r -T0 -0 -q >$1
}
####
auto_pre() {
    if [[ $backup_mode == "lz4" ]]; then
        lz4 $1 $2    
    elif [[ $backup_mode == "zstd" ]]; then
        zstd_nd $1 $2
    else
        echo "!"
        exit 0
    fi
}
change_mode() {
    if [[ $backup_mode == "lz4" ]]; then
        backup_mode=zstd
    elif [[ $backup_mode == "zstd" ]]; then
        backup_mode=lz4
    else
        echo "!"
        exit 0
    fi
}
Backup_data() {
    echo "[  {$apkname}  Android/data  ]"
	if [[ -d /sdcard/Android/data/$package ]]; then
        echo " {$apkname}  Android/data "
        [[ ! -d $Backup/$package ]] && mkdir -p "$Backup/$package"
        auto_pre "$Backup/$package/$package-data.tar.$backup_mode" /sdcard/Android/data/$package
        return_result " {$apkname}  Android/data "
        if [[ $statu == 0 ]]; then
            echo "...."
            change_mode
            auto_pre "$Backup/$package/$package-data.tar.$backup_mode" /sdcard/Android/data/$package
            return_result " {$apkname}  Android/data "
        fi
    else
        echo "{$apkname}  Android/data "
    fi
}
Backup_obb() {
    echo "[  {$apkname}  Android/obb  ]"
	if [[ -d /sdcard/Android/obb/$package ]]; then
        echo " {$apkname}  Android/obb "
        [[ ! -d $Backup/$package ]] && mkdir -p "$Backup/$package"
        auto_pre "$Backup/$package/$package-obb.tar.$backup_mode" /sdcard/Android/obb/$package
        return_result " {$apkname}  Android/obb "
        if [[ $statu == 0 ]]; then
            echo "...."
            change_mode
            auto_pre "$Backup/$package/$package-obb.tar.$backup_mode" /sdcard/Android/obb/$package
            return_result " {$apkname}  Android/obb "
        fi
    else
        echo "{$apkname}  Android/obb "
    fi
}
Backup_user() {
    echo "[ ${apkname}  user  ]"
		if [[ -d /data/user/0/$package && -n 1 ]]; then
		    echo " {$apkname}  user "
		    [[ ! -d $Backup/$package ]] && mkdir -p "$Backup/$package"
            auto_pre "$Backup/$package/$package-user.tar.$backup_mode" "/data/user/0/$package"
            return_result " {$apkname}  user "
            if [[ $statu == 0 ]]; then
                echo "...."
                change_mode
                auto_pre "$Backup/$package/$package-user.tar.$backup_mode" "/data/user/0/$package"
                return_result " {$apkname}  user "
            fi
		else
		    echo "{$apkname}  user "
		fi
}
Backup_apk() {
    [[ ! -d $Backup ]] && mkdir -p "$Backup"
	[[ ! -d $Backup/$package ]] && mkdir -p "$Backup/$package"
	cd $Backup/$package
	#apk
	echo "[ ${apkname}  APK  ]"
	[[ -z $(cat $Backup/name.txt | grep -v "#" | sed -e '/^$/d' | grep -w "$package" | head -1) ]] && echo "$apkname  $package" >>$Backup/name.txt
	[[ -z $(cat $Backup/bename.txt | grep -v "#" | sed -e '/^$/d' | grep -w "$package" | head -1) ]] && echo "$apkname  $package" >>$Backup/bename.txt
	echo "[  {$apkname}  $(pm path "$package" | cut -f2 -d ':' | wc -l) Apk ]"
	if [[ $(pm path "$package" | cut -f2 -d ':' | wc -l) == 1 ]]; then
	    echo "{${apkname}} apk...."
		apkpath=$(pm path "$package" | cut -f2 -d ':')
        cd ${apkpath%/*}
        apk_name_1=${apkpath##*/}
        echo "${apk_name_1}" >$Backup/$package/filename.txt
        auto_pre "$Backup/$package/$package-apk.tar.$backup_mode" "$apk_name_1"
        return_result " {$apkname}  apk "
        if [[ $statu == 0 ]]; then
            echo "...."
            change_mode
            auto_pre "$Backup/$package/$package-apk.tar.$backup_mode" "$apk_name_1"
            return_result " {$apkname}  apk "
        fi
	else
	    echo "{${apkname}} split apk(apk)...."
		cp -r $(pm path "$package" | cut -f2 -d ':') "$Backup/$package"
		return_result " {$apkname}  apk "
	fi
}
[[ ! -d /data/user/0/com.icio.bei/files/tools ]] && echo "/data/user/0/com.icio.bei/files/tools" && exit 1
# Load Settings Variables
. /data/user/0/com.icio.bei/files/tools/bin.sh
Start

[[ ! -d $Backup ]] && mkdir -p "$Backup"
[[ ! -e $Backup/name.txt ]] && echo "#  com.icio.bei" >$Backup/name.txt
[[ ! -e $Backup/bename.txt ]] && echo "#  com.icio.bei" >$Backup/bename.txt

num=$(cat $txt | grep -v "#" | sed -e '/^$/d' | sed -n '$=')
[[ "${num}" == "" ]] && echo ":" && exit 0
i=1
used_time() {
    used_time=$(($2-$1))
    hour=$(($used_time/3600))
    minute=$(($used_time%3600/60))
    second=$(($used_time%3600%60))
    [[ $hour == "0" ]] && [[ $minute == "0" ]] && used_time=$second""
    [[ $hour == "0" ]] && [[ $minute != "0" ]] && used_time=$minute""$second""
    [[ $hour != "0" ]] && used_time=$hour""$minute""$second""
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
    [[ "${package}" == "" ]] && echo ":" && exit 0
    apk_version=$(pm dump ${package}  2>/dev/null | grep -m 1 versionName | sed -n 's/.*=//p')
    echo " ${i}/${num} {$apkname}-V${apk_version} $(($num - $i)) "
    if [[ "${apk_version}" == "" ]]; then
        echo ":"
    else
        am force-stop ${package}
        [[ $package == com.tencent.mobileqq ]] && echo "QQ" || [[ $package == com.tencent.mm ]] && echo "WeChat " || [[ $package == com.tencent.tim ]] && echo "TIM"
        Backup_apk && Backup_data && Backup_obb && Backup_user
        end_time=$(date +%s -D "$(date +"%Y-%m-%d %H:%M:%S")")
        used_time $start_time $end_time
        size ${Backup}/${package}
        alone_size=$size
        echo " {${apkname}}  :"
        echo "${used_time}"
        echo "${alone_size}"
    fi
    echo "progress:[${i}/${num}] finished\n\n\n"
    let i++
done
first_end_time=$(date +%s -D "$(date +"%Y-%m-%d %H:%M:%S")")
used_time $first_start_time $first_end_time
echo ":"
echo "${used_time}"
echo "$(du -sh "${Backup}" | awk '{print $1}')"
echo "${Backup}"
echo ""
