#!/usr/bin/env bash

# 变量名
# system name pass key port debian_sources_CN debian_sources_ALL ubuntu_sources_CN ubuntu_sources_ALL debian_secSources_CN debian_secSources_ALL CFIP debian_netmode debian_DHCP_IPv4 debian_DHCP_IPv6 debian_DNS debian_static_IP debian_static_gateway4 debian_static_gateway6 CN

system=debian
name=user
pass=$(echo $RANDOM | md5sum | cut -d " " -f1) 
unset key
port=$((RANDOM * 8 % 55535 + 10000))
debian_sources_CN=mirrors.tencent.com
debian_sources_ALL=deb.debian.org
ubuntu_sources_CN=mirrors.tencent.com
ubuntu_sources_ALL=archive.ubuntu.com
debian_secSources_CN=mirrors.tencent.com
debian_secSources_ALL=security.debian.org
CFIP=false
debian_netmode=DHCP
debian_DHCP_IPv4=true
debian_DHCP_IPv6=true
debian_DNS="1.1.1.1 2606:4700::1111"
readarray -t debian_static_IP < <(ip addr | awk '/inet/ {print $2}' | grep -v 127\.0\.0\.1 | grep -v ::1)
debian_static_gateway4=$(ip route | awk '/default/ {print $3}')
debian_static_gateway6=$(ip -6 -o route show | awk '/default/ {print $3}')
CN=false

touch ./env.sh
source ./env.sh

info(){
    local vName tip isNul default
    echo -e "\n\n\n\n----------------------------------------------------------------"
    vName=$1
    tip=$2
    isNul=$3
    default=$4
    while true
    do
        echo "You are setting the value of $vName."
        echo "$tip"
        if [ "$default" ]
        then
            echo "The default value of $vName is \"$default\"."
        fi
        echo "Please confirm by pressing enter after inputting the value."
        read -r tmp
        if [ "$tmp" ]
        then
            echo "You have entered \"$tmp\"."
            break
        else
            if [ "$default" ]
            then
                echo "Utilize the default value \"$default\"."
                tmp="$default"
                break
            else
                if [ "$isNul" == true ]
                then
                    echo "This option utilizes a null value."
                    break
                else
                    echo -e "\n\n========This value cannot be left blank.========"
                fi
            fi
        fi
    done
}

gOut(){
    echo "I'm sorry, I cannot proceed as your input is invalid."
    exit "$1"
}

info System "Would you prefer to install Ubuntu 20.04 or Debian 12? [u/d]" false "$system"
if [ "$tmp" == u ] || [ "$tmp" == ubuntu ]
then
    system=ubuntu
fi
if [ "$tmp" == d ] || [ "$tmp" == debian ]
then
    system=debian
fi
if [ "$tmp" != u ] && [ "$tmp" != d ] && [ "$tmp" != ubuntu ] && [ "$tmp" != debian ]
then
    gOut 1
fi

info "login name" "The name used for logging into the system cannot be root." false "$name"
if [ "$tmp" == root ]
then
    gOut 1
fi
name="$tmp"

info "Password" "The password entered when using the sudo command." false "$pass"
pass="$tmp"

info "Public key" "When logging into the server, the public key is used by the server to authenticate the user's identity." false "$key"
key="$tmp"

info "SSH Port" "The port on which the SSH service is listening." false "$port"
if [ "$tmp" -lt 1 ] || [ "$tmp" -gt 65535 ]
then
    gOut 1
fi

info "CFIP" "Allow Cloudflare to access your 443 port using the TCP protocol." false "$CFIP"
if [ "$tmp" == true ] || [ "$tmp" == t ]
then
    CFIP=true
else
    CFIP=false
fi

info "CN" "Is this server located in China?" false "$CN"
if [ "$tmp" == true ] || [ "$tmp" == t ]
then
    CN=true
else
    CN=false
fi

if [ "$system" == ubuntu ]
then
    if [ "$CN" == true ]
    then
        tmp="$ubuntu_sources_CN"
    else
        tmp="$ubuntu_sources_ALL"
    fi
    info "APT software repository" "It refers to the APT software repository, and I am unsure how to elaborate on it." false "$tmp"
    ubuntu_sources="$tmp"
fi

if [ "$system" == debian ]
then
    if [ "$CN" == true ]
    then
        tmp="$debian_sources_CN"
    else
        tmp="$debian_sources_ALL"
    fi
    info "APT software repository" "It refers to the APT software repository, and I am unsure how to elaborate on it." false "$tmp"
    debian_sources="$tmp"

    if [ "$CN" == true ]
    then
        tmp="$debian_secSources_CN"
    else
        tmp="$debian_secSources_ALL"
    fi
    info "Secure APT software repository" "The security update repository for Debian will be the platform where security updates are released." false "$tmp"
    debian_secSources="$tmp"

    info "NetMode" "Is the server capable of acquiring an IP address through DHCP? [d/DHCP/s/static]" false "$debian_netmode"
    if [ "$tmp" == d ] || [ "$tmp" == DHCP ]
    then
        debian_netmode=DHCP
    else
        debian_netmode=static
    fi

    if [ "$debian_netmode" == DHCP ]
    then
        info "DHCPv4" "Enable DHCP for IPv4. [t/f]" false "$debian_DHCP_IPv4"
        if [ "$tmp" == true ] || [ "$tmp" == t ]
        then
            debian_DHCP_IPv4=true
        else
            debian_DHCP_IPv4=false
        fi

        info "DHCPv4" "Enable DHCP for IPv6. [t/f]" false "$debian_DHCP_IPv6"
        if [ "$tmp" == true ] || [ "$tmp" == t ]
        then
            debian_DHCP_IPv6=true
        else
            debian_DHCP_IPv6=false
        fi

        if [ "$debian_DHCP_IPv4" == false ] && [ "$debian_DHCP_IPv6" == false ]
        then
            echo "Failure to enable either DHCPv4 or DHCPv6 during configuration will result in the inability to connect to the server via SSH after reinstallation."
            gOut 1
        fi
    fi

    if [ "$debian_netmode" == static ]
    then
        info "IP" "The IP address of the server. Please separate multiple IP addresses with spaces (including both IPv4 and IPv6). Such as [1.1.1.1/32 2606:4700::1111/128]" false "${debian_static_IP[*]}"
        debian_static_IP=( "$tmp" )

        unset tmp
        info "IPv4 Gateway" "All IPv4 traffic will be routed to the gateway." true "$debian_static_gateway4"
        if [ "$tmp" ]
        then
            debian_static_gateway4="$tmp"
        fi

        unset tmp
        info "IPv6 Gateway" "All IPv6 traffic will be routed to the gateway." true "$debian_static_gateway6"
        if [ "$tmp" ]
        then
            debian_static_gateway6="$tmp"
        fi

        if ! [ "$debian_static_gateway4" ] && ! [ "$debian_static_gateway6" ]
        then
            echo "It is imperative that you set up either an IPv4 or an IPv6 gateway, as not doing so will render your server unable to connect to the network."
            gOut 1
        fi
    fi

    info "DNS" "Please separate multiple IP addresses with spaces (including both IPv4 and IPv6)." false "$debian_DNS"
    debian_DNS="$tmp"
fi

if [ "$system" == debian ]
then
    if [ "$debian_netmode" == DHCP ]
    then
        tmp=$(echo "apt install wget -y && bash <(wget --no-check-certificate -qO- 'https://raw.githubusercontent.com/AsenHu/Note/main/debianSet.sh') $name $pass bookworm $debian_sources $debian_secSources $CFIP '$key' $port $debian_netmode $debian_DHCP_IPv4 $debian_DHCP_IPv6 $debian_DNS" |base64 |tr -d "\n")
        bash <(wget --no-check-certificate -qO- 'https://raw.githubusercontent.com/MoeClub/Note/master/InstallNET.sh') -d 12 -v 64 -a --mirror "http://$debian_sources/debian/" -cmd "$tmp"
    fi

    if [ "$debian_netmode" == static ]
    then
        tmp=$(echo "apt install wget -y && bash <(wget --no-check-certificate -qO- 'https://raw.githubusercontent.com/AsenHu/Note/main/debianSet.sh') $name $pass bookworm $debian_sources $debian_secSources $CFIP '$key' $port $debian_netmode ${debian_static_IP[*]} $debian_static_gateway4 $debian_static_gateway6 $debian_DNS" |base64 |tr -d "\n")
        bash <(wget --no-check-certificate -qO- 'https://raw.githubusercontent.com/MoeClub/Note/master/InstallNET.sh') -d 12 -v 64 -a --mirror "http://$debian_sources/debian/" -cmd "$tmp"
    fi
fi

if [ "$system" == ubuntu ]
then
    tmp=$(echo "apt install wget -y && bash <(wget --no-check-certificate -qO- 'https://raw.githubusercontent.com/AsenHu/Note/main/ubuntuSet.sh') $name $pass focal $ubuntu_sources $CFIP '$key' $port" |base64 |tr -d "\n")
    bash <(wget --no-check-certificate -qO- 'https://raw.githubusercontent.com/MoeClub/Note/master/InstallNET.sh') -u 20.04 -v 64 -a --mirror "http://$ubuntu_sources/ubuntu/" -cmd "$tmp"
fi
