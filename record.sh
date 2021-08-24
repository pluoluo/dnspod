#!/bin/bash
####获取API信息####
token=$(sed 's/"/\n/g' ./config | sed -n '2p')                                         #DNSPOD密钥  
sub_domain=$(sed 's/"/\n/g' ./config | sed -n '5p')                                    #主机记录名
domain=$(curl -X POST https://dnsapi.cn/Domain.List -d 'login_token='$token'&format=json'\ | python -m json.tool | grep "\"id\"" | grep -Eo '[0-9]{1,8}')                  #获取domain_id
record=$(curl -k 'https://dnsapi.cn/Record.List' -d 'login_token='$token'&format=json&domain_id='$domain'' | sed 's/}/\n/g' | grep "\"$sub_domain\"" | sed 's/,/\n/g' | grep "\"id\"" | grep -Eo '[0-9]{1,9}')		#获取record_id
echo -e 'domain_id='$domain'\nrecord_id='$record'\nsub_domain='$sub_domain > ./$sub_domain							#存档备用
exit 0
