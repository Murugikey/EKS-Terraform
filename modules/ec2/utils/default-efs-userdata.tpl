    export EFS_MOUNT_PATH=${EFS_MOUNT_PATH}
    export EFS_DNS=${EFS_DNS}

    sudo mkdir $EFS_MOUNT_PATH

    sudo echo "$EFS_DNS:/ $EFS_MOUNT_PATH nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport,_netdev 0 0" >> /etc/fstab

    sudo mount -a

    cd $EFS_MOUNT_PATH

    ls -al

    sudo chmod go+rw .

    touch test-file.txt 

    ls -al