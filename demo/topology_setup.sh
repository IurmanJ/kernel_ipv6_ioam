#!/bin/bash
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit
fi

################################################################################
#                                                                              #
#                            Topology configuration                            #
#                                                                              #
################################################################################

n_nodes=3
declare -A NODES=(

  # NODE 0 #

  [0]="athos"
  [${NODES[0]}_ioam6_id]="1"

  [${NODES[0]}_n_ifs]=1
  [${NODES[0]}_if0]="h_${NODES[0]}"
  [${NODES[0]}_if0_mac]="2e:fe:7c:b0:c7:72"
  [${NODES[0]}_if0_ip6]="db01::1"
  [${NODES[0]}_if0_ip6_mask]="${NODES[${NODES[0]}_if0_ip6]}/64"
  [${NODES[0]}_if0_ioam6_id]="11"

  [${NODES[0]}_n_schemas]=1
  [${NODES[0]}_schema0]="7"
  [${NODES[0]}_schema0_data]="anything that should be automatically 4n-aligned!!"

  [${NODES[0]}_n_namespaces]=1
  [${NODES[0]}_namespace0]="123"
  [${NODES[0]}_namespace0_data]="0xdeadbeefcafedeca"
  [${NODES[0]}_namespace0_schema]="${NODES[${NODES[0]}_schema0]}"

  # NODE 1 #

  [1]="porthos"
  [${NODES[1]}_ioam6_id]="2"
  [${NODES[1]}_ip6_fwd]=true

  [${NODES[1]}_n_ifs]=2
  [${NODES[1]}_if0]="h_${NODES[1]}1"
  [${NODES[1]}_if0_mac]="2e:fe:7c:b0:c7:73"
  [${NODES[1]}_if0_ip6]="db01::2"
  [${NODES[1]}_if0_ip6_mask]="${NODES[${NODES[1]}_if0_ip6]}/64"
  [${NODES[1]}_if0_ioam6_id]="21"
  [${NODES[1]}_if0_ioam6_enabled]=true
  [${NODES[1]}_if1]="h_${NODES[1]}2"
  [${NODES[1]}_if1_mac]="2e:fe:7c:b0:c7:74"
  [${NODES[1]}_if1_ip6]="db02::1"
  [${NODES[1]}_if1_ip6_mask]="${NODES[${NODES[1]}_if1_ip6]}/64"
  [${NODES[1]}_if1_ioam6_id]="22"

  [${NODES[1]}_n_namespaces]=1
  [${NODES[1]}_namespace0]="123"

  # NODE 2 #

  [2]="aramis"
  [${NODES[2]}_ioam6_id]="3"

  [${NODES[2]}_n_ifs]=1
  [${NODES[2]}_if0]="h_${NODES[2]}"
  [${NODES[2]}_if0_mac]="2e:fe:7c:b0:c7:75"
  [${NODES[2]}_if0_ip6]="db02::2"
  [${NODES[2]}_if0_ip6_mask]="${NODES[${NODES[2]}_if0_ip6]}/64"
  [${NODES[2]}_if0_ioam6_id]="31"
  [${NODES[2]}_if0_ioam6_enabled]=true

  [${NODES[2]}_n_namespaces]=1
  [${NODES[2]}_namespace0]="123"

  # PER-NODE ROUTES #

  [${NODES[0]}_n_routes]=1
  [${NODES[0]}_route0]="${NODES[${NODES[2]}_if0_ip6_mask]}"
  [${NODES[0]}_route0_via]="${NODES[${NODES[1]}_if0_ip6]}"
  [${NODES[0]}_route0_dev]="${NODES[${NODES[0]}_if0]}"
  [${NODES[0]}_route0_encap]="ioam6 trace type 0xf00000 ns 123 size 48"

  [${NODES[2]}_n_routes]=1
  [${NODES[2]}_route0]="${NODES[${NODES[0]}_if0_ip6_mask]}"
  [${NODES[2]}_route0_via]="${NODES[${NODES[1]}_if1_ip6]}"
  [${NODES[2]}_route0_dev]="${NODES[${NODES[2]}_if0]}"

)

n_links=2
declare -A LINKS=(
  [link0_from_cname]="${NODES[0]}"
  [link0_from_ifname]="${NODES[${NODES[0]}_if0]}"
  [link0_to_cname]="${NODES[1]}"
  [link0_to_ifname]="${NODES[${NODES[1]}_if0]}"

  [link1_from_cname]="${NODES[1]}"
  [link1_from_ifname]="${NODES[${NODES[1]}_if1]}"
  [link1_to_cname]="${NODES[2]}"
  [link1_to_ifname]="${NODES[${NODES[2]}_if0]}"
)


################################################################################
#                                                                              #
#                                 Functions                                    #
#                                                                              #
################################################################################

function print_n_char() {
  v=$(printf "%-${2}s" "$1")
  echo "${v// /*}"
}

function setup_containers() {
  for n in $(seq 0 $(( n_nodes - 1 ))); do
    __setup_container "${NODES[$n]}"
  done
}

function __setup_container() {
  cname=$1

  print_n_char "*" $(( ${#cname} + 4 ))
  echo "* $cname *"
  print_n_char "*" $(( ${#cname} + 4 ))

  __create_container "$cname"
  __run_container "$cname"
  __install_container "$cname"

  echo ""
}

function __create_container() {
  echo -n "Create... "
  lxc-create -n $1 -t ubuntu &> /dev/null
  [ $? = 0 ] && echo "OK" || { echo "ERROR"; exit 1; }
}

function __run_container() {
  echo -n "Run... "
  lxc-start -n $1 -d &> /dev/null
  [ $? = 0 ] && echo "OK" || { echo "ERROR"; exit 1; }
}

function __install_container() {
  echo -n "Install (1/4)... "
  sleep 5
  lxc-attach -n $1 -- bash -c "apt update" &> /dev/null
  [ $? = 0 ] && echo "OK" || { echo "ERROR"; exit 1; }

  echo -n "Install (2/4)... "
  lxc-attach -n $1 -- bash -c "apt install -y tcpdump bison flex git wget" &> /dev/null
  [ $? = 0 ] && echo "OK" || { echo "ERROR"; exit 1; }

  echo -n "Install (3/4)... "
  lxc-attach -n $1 -- bash -c "apt install -y libmnl-dev libcap-dev libelf-dev libdb-dev pkg-config" &> /dev/null
  [ $? = 0 ] && echo "OK" || { echo "ERROR"; exit 1; }

  echo -n "Install (4/4)... "
  lxc-attach -n $1 -- bash -c "cd /home/ubuntu && git clone https://github.com/iurmanj/kernel_ipv6_ioam.git && mv kernel_ipv6_ioam/iproute2/*.patch . && rm -rf kernel_ipv6_ioam && wget https://mirrors.edge.kernel.org/pub/linux/utils/net/iproute2/iproute2-5.10.0.tar.xz && tar -Jxf iproute2-5.10.0.tar.xz && cd iproute2-5.10.0 && patch -p1 < ../#1.patch && patch -p1 < ../#2.patch && make && make install && cd .. && rm -rf iproute2-5.10.0 && rm iproute2-5.10.0.tar.xz && rm *.patch" &> /dev/null
  [ $? = 0 ] && echo "OK" || { echo "ERROR"; exit 1; }
}

function setup_links() {
  echo "Configure links..."

  if [ -n $LINKS ]; then
    for n in $(seq 0 $(( n_links - 1))); do
      __setup_link "${LINKS[link${n}_from_cname]}" "${LINKS[link${n}_from_ifname]}" "${LINKS[link${n}_to_cname]}" "${LINKS[link${n}_to_ifname]}"
    done
    echo ""
  fi
}

function __setup_link() {
  from_cname=$1
  from_cname_if=$2
  to_cname=$3
  to_cname_if=$4

  if [ -n $from_cname ] && [ -n $from_cname_if ] && [ -n $to_cname ] && [ -n $to_cname_if ] && container_exists "$from_cname" && container_exists "$to_cname"; then
    pid_from=$(lxc-info -n $from_cname | grep "PID:" | awk '{print $2}')
    pid_to=$(lxc-info -n $to_cname | grep "PID:" | awk '{print $2}')

    echo -n " - from $from_cname.$from_cname_if to $to_cname.$to_cname_if... "

    ip link add name $from_cname_if type veth peer name $to_cname_if &> /dev/null
    [ $? != 0 ] && { echo "ERROR"; exit 1; }

    ip link set netns $pid_from dev $from_cname_if &> /dev/null
    [ $? != 0 ] && { echo "ERROR"; exit 1; }

    ip link set netns $pid_to dev $to_cname_if &> /dev/null
    [ $? != 0 ] && { echo "ERROR"; exit 1; }

    nsenter -t $pid_from -n ifconfig $from_cname_if up &> /dev/null
    [ $? != 0 ] && { echo "ERROR"; exit 1; }

    nsenter -t $pid_to -n ifconfig $to_cname_if up &> /dev/null
    [ $? != 0 ] && { echo "ERROR"; exit 1; }

    echo "OK"
  fi
}

function configure_containers() {
  if [ -n $NODES ]; then
    for n in $(seq 0 $(( n_nodes - 1 ))); do
      echo -n "Configuration of ${NODES[$n]}... "
      __configure_container "${NODES[$n]}"
      __configure_interfaces "${NODES[$n]}"
      __configure_routes "${NODES[$n]}"
      echo "OK"
    done
    echo ""
  fi
}

function __configure_container() {
  [ ${NODES[${1}_ip6_fwd]+xxx} ] && lxc-attach -n $1 -- bash -c "sysctl -w net.ipv6.conf.all.forwarding=1" &> /dev/null || true
  [ $? != 0 ] && { echo "ERROR"; exit 1; }

  [ ${NODES[${1}_ioam6_id]+xxx} ] && lxc-attach -n $1 -- bash -c "sysctl -w net.ipv6.ioam6_id=${NODES[${1}_ioam6_id]}" &> /dev/null || true
  [ $? != 0 ] && { echo "ERROR"; exit 1; }

  if [ ${NODES[${1}_n_schemas]+xxx} ]; then
    for i in $(seq 0 $(( ${NODES[${1}_n_schemas]} - 1 ))); do
      lxc-attach -n $1 -- bash -c "ip ioam schema add ${NODES[${1}_schema$i]} \"${NODES[${1}_schema${i}_data]}\"" &> /dev/null
      [ $? != 0 ] && { echo "ERROR"; exit 1; }
    done
  fi

  if [ ${NODES[${1}_n_namespaces]+xxx} ]; then
    for i in $(seq 0 $(( ${NODES[${1}_n_namespaces]} - 1 ))); do
      lxc-attach -n $1 -- bash -c "ip ioam namespace add ${NODES[${1}_namespace$i]} ${NODES[${1}_namespace${i}_data]}" &> /dev/null
      [ $? != 0 ] && { echo "ERROR"; exit 1; }

      [ ${NODES[${1}_namespace${i}_schema]+xxx} ] && lxc-attach -n $1 -- bash -c "ip ioam namespace set ${NODES[${1}_namespace$i]} schema ${NODES[${1}_namespace${i}_schema]}" &> /dev/null || true
      [ $? != 0 ] && { echo "ERROR"; exit 1; }
    done
  fi
}

function __configure_interfaces() {
  if [ ${NODES[${1}_n_ifs]+xxx} ]; then
    for i in $(seq 0 $(( ${NODES[${1}_n_ifs]} - 1 ))); do
      lxc-attach -n $1 -- bash -c "ip link set dev ${NODES[${1}_if$i]} address ${NODES[${1}_if${i}_mac]} && ip -6 address add ${NODES[${1}_if${i}_ip6_mask]} dev ${NODES[${1}_if$i]}" &> /dev/null
      [ $? != 0 ] && { echo "ERROR"; exit 1; }

      [ ${NODES[${1}_if${i}_ioam6_id]+xxx} ] && lxc-attach -n $1 -- bash -c "sysctl -w net.ipv6.conf.${NODES[${1}_if$i]}.ioam6_id=${NODES[${1}_if${i}_ioam6_id]}" &> /dev/null || true
      [ $? != 0 ] && { echo "ERROR"; exit 1; }

      [ ${NODES[${1}_if${i}_ioam6_enabled]+xxx} ] && lxc-attach -n $1 -- bash -c "sysctl -w net.ipv6.conf.${NODES[${1}_if$i]}.ioam6_enabled=1" &> /dev/null || true
      [ $? != 0 ] && { echo "ERROR"; exit 1; }
    done
  fi
}

function __configure_routes() {
  if [ ${NODES[${1}_n_routes]+xxx} ]; then
    for i in $(seq 0 $(( ${NODES[${1}_n_routes]} - 1 ))); do
      route="ip -6 route add ${NODES[${1}_route$i]}"
      [ ${NODES[${1}_route${i}_encap]+xxx} ] && route=$route" encap "${NODES[${1}_route${i}_encap]}
      [ ${NODES[${1}_route${i}_via]+xxx} ] && route=$route" via "${NODES[${1}_route${i}_via]}
      route=$route" dev "${NODES[${1}_route${i}_dev]}

      lxc-attach -n $1 -- bash -c "$route" &> /dev/null
      [ $? != 0 ] && { echo "ERROR"; exit 1; }
    done
  fi
}

function container_exists() {
  lxc-info -n $1 &> /dev/null
  [ $? = 0 ]
}


################################################################################
#                                                                              #
#                                 Entry point                                  #
#                                                                              #
################################################################################
must_exit=false

if [ -n $NODES ]; then
  for n in $(seq 0 $(( n_nodes - 1 ))); do
    container_exists "${NODES[$n]}" && { echo "${NODES[$n]} container already exists"; must_exit=true; }
  done
fi
[ "$must_exit" = "true" ] && exit

setup_containers
setup_links
configure_containers

echo "DONE. Have fun :-)"

