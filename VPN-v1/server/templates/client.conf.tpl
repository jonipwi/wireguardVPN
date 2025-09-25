[Interface]
PrivateKey=${CLIENT_PRIVATE_KEY}
Address=${CLIENT_ADDRESS}/32
DNS=${DNS}
${WG_MTU_LINE}

[Peer]
PublicKey=${SERVER_PUBLIC_KEY}
AllowedIPs=${CLIENT_ALLOWED_IPS}
Endpoint=${SERVER_HOST}:${WG_PORT}
PersistentKeepalive=${PERSISTENT_KEEPALIVE}
