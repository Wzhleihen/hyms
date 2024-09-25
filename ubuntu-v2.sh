#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH


ROOTPASS='123'

sudo_pass(){
	sudo echo -e "$ROOTPASS\n$ROOTPASS" | sudo password root 
}

#颜色变量文件
color () {
    RES_COL=60
    MOVE_TO_COL="echo -en \\033[${RES_COL}G"
    SETCOLOR_SUCCESS="echo -en \\033[1;32m"  #绿色
    SETCOLOR_FAILURE="echo -en \\033[1;31m"  #红色
    SETCOLOR_WARNING="echo -en \\033[1;33m"  #黄色
    SETCOLOR_NORMAL="echo -en \E[0m"
    echo -n "$1" && $MOVE_TO_COL
    echo -n "["
    if [ $2 = "success" -o $2 = "0" ] ;then
        ${SETCOLOR_SUCCESS}
        echo -n $"  OK  "    
    elif [ $2 = "failure" -o $2 = "1"  ] ;then 
        ${SETCOLOR_FAILURE}
        echo -n $"FAILED"
    else
        ${SETCOLOR_WARNING}
        echo -n $"WARNING"
    fi
    ${SETCOLOR_NORMAL}
    echo -n "]"
    echo 
}

set_time() {
	ln -sf /usr/share/zoneinfo/Asia/Shanghai  /etc/localtime
    # 备份原始文件
    cp /etc/systemd/timesyncd.conf /etc/systemd/timesyncd.conf.bak

    # 修改配置文件
cat > /etc/systemd/timesyncd.conf << 'EOF'
[Time]
NTP=ntp.aliyun.com
PollIntervalMinSec=300
PollIntervalMaxSec=600
EOF

    # 重新启动时间同步服务
    timedatectl set-ntp true 
    if systemctl restart systemd-timesyncd; then
        color "时间同步配置已成功生效。" success
    else
        color "错误：无法重新启动时间同步服务。" failure
        # 如果发生错误，还原原始配置文件
        cp /etc/systemd/timesyncd.conf.bak /etc/systemd/timesyncd.conf
    fi
}



mirrors_sources(){
	color "配置基础软件源"
    cp /etc/apt/sources.list /etc/apt/sources.list.bak
    cat > /etc/apt/sources.list << EOF
# 默认注释了源码镜像以提高 apt update 速度，如有需要可自行取消注释
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy main restricted universe multiverse
deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-updates main restricted universe multiverse
deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-updates main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-backports main restricted universe multiverse
deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-backports main restricted universe multiverse

# 以下安全更新软件源包含了官方源与镜像站配置，如有需要可自行修改注释切换
#deb http://security.ubuntu.com/ubuntu/ jammy-security main restricted universe multiverse
#deb-src http://security.ubuntu.com/ubuntu/ jammy-security main restricted universe multiverse

# 预发布软件源，不建议启用
# deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-proposed main restricted universe multiverse
# deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-proposed main restricted universe multiverse
EOF

	apt update; apt -y purge needrestart ;apt -y install  iproute2 ntpdate tcpdump telnet  nfs-kernel-server nfs-common   libpcre3   gcc openssh-server lrzsz tree openssl libssl-dev  libpcre3-dev zlib1g-dev traceroute iotop unzip zip net-tools
	color "配置基础软件源" success
}



vim_style(){
	cp /etc/vim/vimrc /etc/vim/vimrc.bak
	cat >> /etc/vim/vimrc << 'EOF'
"保存.vimrc文件时自动重启加载，即让此文件立即生效
autocmd BufWritePost \$MYVIMRC source \$MYVIMRC
"TAB长度
set tabstop=2
"输入tab制表符时，自动替换成空格
set expandtab
"设置自动缩进长度为2空格
set shiftwidth=2
"搜索到最后匹配的位置后,再次搜索不回到第一个匹配处
set nowrapscan

""定义函数SetTitle，自动插入文件头
autocmd BufNewFile *.sh exec ":call SetTitle()"
func SetTitle()
    if expand("%:e") == 'sh'
    call setline(1,"#!/bin/bash")
    call setline(2,"#")
    call setline(3,"#********************************************************************")
    call setline(4,"#Date:              ".strftime("%Y-%m-%d"))
    call setline(5,"#FileName           ".expand("%"))
    call setline(6,"#Description        The test script")
    call setline(7,"#Copyright (C):     ".strftime("%Y")." All rights reserved")
    call setline(8,"#********************************************************************")
    call setline(9,"PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin")
    call setline(10,"export PATH")
    call setline(11,"")
    endif
endfunc
"新建文件后，自动定位到文件末尾
autocmd BufNewFile * normal G
"自动补全括号引号
:inoremap ( ()<ESC>i
:inoremap ) <c-r>=ClosePair(')')<CR>
:inoremap { {}<ESC>i
:inoremap } <c-r>=ClosePair('}')<CR>
:inoremap [ []<ESC>i
:inoremap ] <c-r>=ClosePair(']')<CR>
:inoremap " ""<ESC>i
:inoremap ' ''<ESC>i
:inoremap < <><ESC>i
:inoremap > <c-r>=ClosePair('>')<CR>
function! ClosePair(char)
    if getline('.')[col('.') - 1] == a:char
        return "\<Right>"
    else
        return a:char
    endif
endfunction 
EOF

color "vim修改完成！" success
}


set_host(){
	echo '"PS1="\[\e[1;34m\]\u\[\e[0m\]@\[\e[1;31m\]\h\[\e[0m\]:\[\e[1;32m\]\w\[\e[0m\]\\$ "' >> /root/.bashrc && source /root/.bashrc 
	sudo sed -i.bak 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
	sed -ie "/UseDNS/s/yes/no/g;/UseDNS/s/#//g;/^GSSAPI/s/yes/no/g" /etc/ssh/sshd_config 
	sed -ie '35,41{s/^#[[:space:]]*//}' /etc/bash.bashrc && source /etc/bash.bashrc 
	echo 'export HISTTIMEFORMAT="%Y-%m-%d %T "' >> /etc/bash.bashrc && source /etc/bash.bashrc
	# 修改 netplan 配置
    sed -i "s/ens33/eth0/" /etc/netplan/00-installer-config.yaml

    # 修改 GRUB 配置
    sed -i 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="net.ifnames=0 biosdevname=0"/' /etc/default/grub
    update-grub

    # 重启系统
    sudo reboot
	
}

sudo_pass
set_time
mirrors_sources
vim_style
set_host
