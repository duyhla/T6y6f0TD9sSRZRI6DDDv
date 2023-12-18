#!/bin/bash

#KEY=$1
responsentn=`https GET https://cax.piccadilly.autonity.org/api/orderbooks/NTN-USD/quote API-Key:$KEY`
responseatn=`https GET https://cax.piccadilly.autonity.org/api/orderbooks/ATN-USD/quote API-Key:$KEY`

echo "$responsentn" > ./latestpricingntn
echo "$responseatn" > ./latestpricingatn

RAWNTN=$responsentn
RAWATN=$responseatn
PRICENTN=`echo $RAWNTN | jq -r ".ask_price"`
PRICEATN=`echo $RAWATN | jq -r ".ask_price"`

echo Current Ask Pricing NTN: $PRICENTN
echo Current Ask Pricing ATN: $PRICEATN

sleep 5
buyatn=`https POST https://cax.piccadilly.autonity.org/api/orders/ API-Key:$KEY pair=ATN-USD side=bid price=$PRICEATN  amount=10`

echo Buy ATN: $buyatn
sleep 5

buyntn=`https POST https://cax.piccadilly.autonity.org/api/orders/ API-Key:$KEY pair=NTN-USD side=bid price=$PRICENTN  amount=10`

echo Buy NTN: $buyntn

sleep 5

withdrawsatn=`https POST https://cax.piccadilly.autonity.org/api/withdraws/ API-Key:$KEY symbol=ATN amount=10`

echo Withdraw ATN: $withdrawsatn

sleep 5

withrawsntn=`https POST https://cax.piccadilly.autonity.org/api/withdraws/ API-Key:$KEY symbol=NTN amount=10`

echo Withdraw NTN: $withdrawsatn

sleep 10

accountbalanceatn=`aut account balance`
accountbalancentn=`aut account balance --ntn`

echo Balance ATN after withdraw: $accountbalanceatn

echo Balance NTN after withdraw: $accountbalancentn

IFS=';'

while read -ra lines; do
    for line in "${lines[@]}"; do
        echo "Processing address: $line"

        password='set-your-pass-wallet'

        echo "Executing sent NTN..."
        docker exec -i aut_client /root/.local/bin/aut tx make --to "$line" --value 1 --ntn |
            docker exec -i aut_client /root/.local/bin/aut tx sign --password "$password" - |
            docker exec -i aut_client /root/.local/bin/aut tx send -
        first_command_exit_code=$?
        echo "Exit code sent NTN: $first_command_exit_code"
        sleep 5

        # Second command
        echo "Executing sent ATN..."
        docker exec -i aut_client /root/.local/bin/aut tx make --to "$line" --value 1 |
            docker exec -i aut_client /root/.local/bin/aut tx sign --password "$password" - |
            docker exec -i aut_client /root/.local/bin/aut tx send -
        second_command_exit_code=$?
        echo "Exit code sent ATN: $second_command_exit_code"
        sleep 5
    done
done < "./recipient_address.txt"

accountbalanceatnafter=`aut account balance`
accountbalancentnafter=`aut account balance --ntn`

echo Balance ATN after send: $accountbalanceatnafter

echo Balance NTN after send: $accountbalancentnafter
