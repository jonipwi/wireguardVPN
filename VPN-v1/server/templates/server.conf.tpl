[Interface]
Address=${WG_ADDRESS}
ListenPort=${WG_PORT}
PrivateKey=${SERVER_PRIVATE_KEY}
${WG_MTU_LINE}

# NAT and forwarding
PostUp=iptables -t nat -A POSTROUTING -o ${EXTERNAL_INTERFACE} -j MASQUERADE
PostUp=iptables -A FORWARD -i %i -j ACCEPT
PostUp=iptables -A FORWARD -o %i -j ACCEPT
${EXTRA_POST_UP_LINES}
PostDown=iptables -t nat -D POSTROUTING -o ${EXTERNAL_INTERFACE} -j MASQUERADE
PostDown=iptables -D FORWARD -i %i -j ACCEPT
PostDown=iptables -D FORWARD -o %i -j ACCEPT
${EXTRA_POST_DOWN_LINES}

# Peers appended below
