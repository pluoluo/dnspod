#!/bin/bash
###   脚本绝对路径
SOURCE="$0"
while [ -h "$SOURCE"  ]; do # 解析 $SOURCE 脚本真实路径而非软链接
    path="$( cd -P "$( dirname "$SOURCE"  )" && pwd  )"
    SOURCE="$(readlink "$SOURCE")"
    [[ $SOURCE != /*  ]] && SOURCE="$path/$SOURCE" 
done
path="$( cd -P "$( dirname "$SOURCE"  )" && pwd  )"                               #脚本绝对路径
cd $path							#以下使用相对路径
###API信息
# token文件保存位置
token_file="./config"
if [ ! -f "$token_file" ];then
	echo "没有config文件，创建后重试"
	exit 0
fi
token=$(sed 's/"/\n/g' $token_file | sed -n '2p')                                      #DNSPOD密钥  
sub_domain=$(sed 's/"/\n/g' $token_file | sed -n '5p')                                    #主机记录名

# 监测日志保存位置
log_file="./$sub_domain.log"
if [ ! -f "$log_file" ];then
	touch "$log_file"
fi
# 变动前的公网 IP 保存位置
ip_file="./$sub_domain.ip.log"

##################  功能定义  ####################
ipv6=''
update=""

#日志
log() {
    if [ "$1" ]; then
	echo  "[$(date)] - $1" >> $log_file
    fi
}

####API信息验证####
####检查API文件,没有则生成文件#####
record_file='./'$sub_domain
check_config() {
if [ -f $record_file ]; then
	echo "已配置文件，检查继续."	
else
    echo "没有API文件，现在获取"
    log "没有API文件，现在获取"
    ./record.sh
fi
}

######判断API获取是否有误#####
check_api() {
		sub_test=$(sed 's/=/\n/g' ./$sub_domain | sed -n '6p')
		if [ "$sub_test" == "$sub_domain" ];then
			echo "域名主机记录正确，检查继续."
            domain=$(sed 's/=/\n/g' ./$sub_domain | sed -n '2p')
			if [[ $domain =~ [0-9]{8} ]];then
				echo "已有domain信息，检查继续." 
				record=$(sed 's/=/\n/g' ./$sub_domain | sed -n '4p')
				if [[ $record =~ [0-9]{9} ]];then
					record=$(sed 's/=/\n/g' ./$sub_domain | sed -n '4p')
					echo "已有record信息，现在继续"
				else
					echo "record信息有误，请通过record.sh重新获取"
					log "record信息有误，请通过record.sh重新获取"
					exit 0
				fi
			else 
				echo "domain信息有误，请通过record.sh重新获取"
				log "domain信息有误，请通过record.sh重新获取"
				exit 0
			fi
		else
			echo "域名主机记录不匹配，请重新设置后运行record.sh"
			log "域名主机记录不匹配，请重新设置后运行record.sh"
			exit 0
		fi
}

#判断IP是否变化，不变化则结束程序
check_ip_change() {
    if [ -f $ip_file ]; then
        old_ip=$(cat $ip_file)
        if [ "$ipv6" == "$old_ip" ]; then
            echo "IP has not changed."
            log "IP has not changed."
            exit 0
        fi
    fi
}

#更新 DNS 记录
update_dns() {
  update=$(curl -X POST https://dnsapi.cn/Record.Modify -d 'login_token='$token'&format=json&domain_id='$domain'&record_id='$record'&sub_domain='$sub_domain'&value='$ipv6'&record_type=AAAA&record_line=%e9%bb%98%e8%ae%a4')
  }
  
###################  脚本主体  ###################
log "Script start."

# 获取Ipv6地址
ipv6=$(ip addr show|grep -v deprecated|grep -A1 'inet6 [^f:]'|sed -nr ':a;N;s#^ +inet6 ([a-f0-9:]+)/.+? scope global .*?valid_lft ([0-9]+sec) .*#\2 \1#p;ta'|sort -nr|head -n1|cut -d' ' -f2)

#判断是否成功获取到IP
if [ "$ipv6" == "" ]; then
    echo "Can not get IP address.Please check your network connection."
    log "Can not get IP address.Please check your network connection."
    exit 0
fi

#检查信息完整
check_config
check_api												#

#检查IP是否变化
check_ip_change

#更新 DNS 记录
update_dns

#判断是否成功
test="u6210"
if [[ $update == *$test* ]]; then
    echo "$ipv6" > $ip_file
    log "$record_name IP changed to: $ipv6"
    echo "$record_name IP changed to: $ipv6"
else
    log "API UPDATE FAILED. DUMPING RESULTS:\n$update"
    echo -e "API UPDATE FAILED. DUMPING RESULTS:\n$update"
    exit 0
fi
 exit 0
