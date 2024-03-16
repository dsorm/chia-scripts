MOUNTPOINT_ROOT=/data/chia-plot
USER=dsorm
GROUP=dsorm

lsblk

echo -e "\n"
read -e -p "Which drive to partition? (example /dev/sdc): " selected_drive

#if test -b "$selected_drive"
#then
#	echo "Drive found";
#else
#	echo "Drive not found, exiting"
#	exit
#fi

echo " ----- MOUNTPOINT PREFIX RELATED FSTAB ENTRIES -----"
grep "$MOUNTPOINT_ROOT" /etc/fstab
echo " ---------------------------------------------------"

read -e -p "The mountpoint prefix is $MOUNTPOINT_ROOT, type the rest of the new mountpoint's name: $MOUNTPOINT_ROOT" input
MOUNTPOINT="$MOUNTPOINT_ROOT$input"

read -e -p "Are you sure you want to erase all content on $selected_drive? (y/n): " answer

if [[ $answer == 'y' ]]
then
	echo "Formatting..."
else
	echo "Bye"
	exit
fi

echo "," | sudo sfdisk $selected_drive --label gpt

sudo mkfs -t ext4 "${selected_drive}1"
sudo mkdir $MOUNTPOINT

echo "Writing record to fstab..."
UUID="$(sudo blkid -s UUID -o value ${selected_drive}1)"

if [[ "$UUID" = "" ]]
then
	echo "Something went wrong"
	exit
fi

echo "UUID=\"$UUID\"    $MOUNTPOINT	ext4    nofail   0    0" | sudo tee -a /etc/fstab

sudo systemctl daemon-reload
sudo mount -a
sudo chown -P ${USER}:${GROUP} $MOUNTPOINT

echo -e "\n"
lsblk | grep $MOUNTPOINT
echo "Done. The fstab entry was created, and the drive is now mounted at $MOUNTPOINT"