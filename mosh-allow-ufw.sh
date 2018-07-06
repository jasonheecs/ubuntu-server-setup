#!/bin/bash

# Load active ports
PORTS=`lsof -i | grep mosh-serv | cut -f2 -d":"`
STATUS=`sudo ufw status`

# Add Rules for new ports
for PORT in $PORTS; do

    echo $STATUS | grep "$PORT/udp" > /dev/null
    if [ $? -gt 0 ]; then
        echo "Allowing new port $PORT"
        sudo ufw allow $PORT/udp > /dev/null
    fi
done

# Remove closed ports
PORTS=`sudo ufw status | grep "^60.../udp" | cut -f1 -d"/" | sort | uniq`
OPEN=`lsof -i | grep mosh-serv`

for PORT in $PORTS; do

    echo $OPEN | grep $PORT > /dev/null
    if [ $? -gt 0 ]; then
        echo "Removing closed port $PORT."
        sudo ufw delete allow $PORT/udp > /dev/null
    fi
done
