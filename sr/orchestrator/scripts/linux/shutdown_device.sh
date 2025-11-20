#!/bin/bash
echo "shutdown device in 30s"
sleep 30s
echo 'sr123' | sudo -S shutdown +0
#java -Djava.library.path=/usr/lib/jni -jar TestMicro_new.jar "\$SHUTDOWN\$" > log.txt 2>&1 &