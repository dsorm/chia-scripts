# Usage if not using interactive prompt: ./plot.sh {DIR FOR PLOT OUTPUT} {NUM OF K32 PLOTS}

OUTPUT="" # $1
NUM="" # $2

FARMER_KEY=
POOL_CONTRACT_ADDRESS=
TEMP_DRIVE=/data/chia-plot-nvme

df --si  | head -1 && df --si | tail -n +2 | sort -k 6 | grep /data/chia-plot
echo -e "\n"
if test -z "$1"
then
   read -e -p "Enter the output file destination (example: /data/chia-plot-1):" OUTPUT
else
	OUTPUT="$1"
fi

if test -z "$2"
then
   read -e -p "Enter the desired amount of K32 plots (108.9 GB in SI):" NUM
else
	NUM="$2"
fi

bladebit_cuda -n ${NUM} -f ${FARMER_KEY} -c ${POOL_CONTRACT_ADDRESS} -z 5 cudaplot -t1 ${TEMP_DRIVE} --disk-16 --check 10 ${OUTPUT}
BLADEBIT_EXIT_CODE=$?
echo "Plotting done, sending pushover notification..."
curl -s \
  --form-string "token=INSERT_PUSHOVER_TOKEN_HERE" \
  --form-string "user=INSERT_PUSHOVER_USER_HERE" \
  --form-string "message=${NUM} k32 plots to ${OUTPUT}, exit code ${BLADEBIT_EXIT_CODE}" \
  https://api.pushover.net/1/messages.json