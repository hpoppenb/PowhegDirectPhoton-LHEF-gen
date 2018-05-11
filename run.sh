#!/bin/bash

# First compile the pwhg_main executable in the ../ directory

if [ ! $# -eq 7 ]
then
    echo "Usage: $0 0/1 0/1 0/1 0/1 0/1 0/1 [number of cores used]"
    echo "       where 0 or 1 indicates if stage 1 2 3 4 5 6 is to be started." # 1,2,3 grids; 4 events; 5 scale var; 6 pdf var
    exit 1
else
    stage1=$1
    stage2=$2
    stage3=$3
    stage4=$4
    stage5=$5
    stage6=$6
fi

> timings.txt

PRG=$PWD/../pwhg_main
INPUT=powheg.input-save
xgriditer=4
ncores=$7

# no of PDF error sets
ERRSETS=100

echo -n 'Running stages '
if [ $stage1 -eq 1 ]
then
    echo -n '1 '
fi
if [ $stage2 -eq 1 ]
then
    echo -n '2 '
fi
if [ $stage3 -eq 1 ]
then
    echo -n '3 '
fi
if [ $stage4 -eq 1 ]
then
    echo -n '4 '
fi
if [ $stage5 -eq 1 ]
then
    echo -n '5 '
fi
echo
if [ $stage6 -eq 1 ]
then
    echo -n '6 '
fi
echo


if [ $stage1 -eq 1 ] 
then
    echo "stage 1: grids"
    # two stages of importance sampling grid calculation
    for igrid in `seq 1 $xgriditer`
    do
    	(echo -n st1 xg$igrid ' ' ; date ) >> timings.txt

    	cat $INPUT | sed "s/xgriditeration.*/xgriditeration $igrid/ ; s/parallelstage.*/parallelstage 1/" > powheg.input

    	for i in `seq 1 $ncores`
    	do
	    echo $i | $PRG > run-st1-xg$igrid-$i.log 2>&1 &    
    	done
    	wait

    done
fi

if [ $stage2 -eq 1 ]
then
    echo "stage 2: upper bounding function for inclusive cross section"
    # compute NLO and upper bounding envelope for underlying born configurations
    cat $INPUT | sed 's/parallelstage.*/parallelstage 2/' > powheg.input
    (echo -n st2 ' ' ; date ) >> timings.txt
    for i in `seq 1 $ncores`
    do
    	echo $i | $PRG > run-st2-$i.log 2>&1 &
    done
    wait
fi

if [ $stage3 -eq 1 ]
then
    echo "stage 3: upper bounding function for radiation"
    # compute upper bounding coefficients for radiation
    cat $INPUT | sed 's/parallelstage.*/parallelstage 3/' > powheg.input
    (echo -n st3 ' ' ; date ) >> timings.txt
    for i in `seq 1 $ncores`
    do
    	echo $i | $PRG > run-st3-$i.log 2>&1 &
    done
    wait
fi

if [ $stage4 -eq 1 ]
then
    echo "stage 4: event generation"
    # generate events 
    cat $INPUT | sed 's/parallelstage.*/parallelstage 4/' > powheg.input
    (echo -n st4 ' ' ; date ) >> timings.txt
    for i in `seq 1 $ncores`
    do
    	echo $i | $PRG > run-st4-$i.log 2>&1 &
    done
    wait
fi

if [ $stage5 -eq 1 ]
then
    echo "stage 5: reweight scale variations"
    for m in 0.5 1.0 2.0
    do
	for n in 0.5 1.0 2.0
	do
	    mn=$(echo "$m/$n" | bc)
	    nm=$(echo "$n/$m" | bc)
	    if [ $mn -eq 2 -o $nm -eq 2 -o "$m" = "$n" -a "$m" != "1.0" ]
	    then
		# reweight events
		cat $INPUT | sed "s/.*renscfact.*/renscfact ${m}d0/ ; s/.*facscfact.*/facscfact ${n}d0/" > powheg.input
		sed -i 's/parallelstage.*/parallelstage 4/ ; s/lhrwgt_id.*/lhrwgt_id '"'"'scales'${m}${n}''"'"'/ ; s/lhrwgt_descr.*/lhrwgt_descr '"'"'MUR'${m}' MUF'${n}''"'"'/' powheg.input
		echo >> powheg.input
		echo 'compute_rwgt 1' >> powheg.input
		echo >> powheg.input
		(echo -n rwgt ' ' ; date ) >> timings.txt
		for i in `seq 1 $ncores`
		do
    		    case $i in
    			?) ch=000$i ;;
    			??) ch=00$i ;;
    			???) ch=0$i ;;
    			????) ch=$i ;;
    		    esac
    		    (echo $i ; echo pwgevents-${ch}.lhe ) | $PRG > run-rwgt-scl${m}${n}-$i.log 2>&1 &
		done
		wait
		for i in `seq 1 $ncores`
		do
    		    case $i in
    			?) ch=000$i ;;
    			??) ch=00$i ;;
    			???) ch=0$i ;;
    			????) ch=$i ;;
    		    esac
    		    mv pwgevents-rwgt-${ch}.lhe pwgevents-${ch}.lhe
		done
		wait
	    fi
	done
    done
fi


if [ $stage6 -eq 1 ]
then
    echo "stage 6: reweight PDF variations (PDFs equal for a and b)"
    # get current PDF sets
    PDF=$(grep lhans1 powheg.input-save | sed 's/lhans1 \+\([0-9]\+\).*/\1/')
    for m in $(seq $(( $PDF + 1 )) $(( $PDF + $ERRSETS )))
    do
	# reweight events
	cat $INPUT | sed "s/lhans1.*/lhans1 ${m}/ ; s/lhans2.*/lhans2 ${m}/" > powheg.input
	sed -i 's/parallelstage.*/parallelstage 4/ ; s/lhrwgt_id.*/lhrwgt_id '"'"'PDF'${m}''"'"'/ ; s/lhrwgt_descr.*/lhrwgt_descr '"'"'PDF '${m}''"'"'/' powheg.input
	echo >> powheg.input
	echo 'compute_rwgt 1' >> powheg.input
	echo >> powheg.input
	(echo -n rwgt ' ' ; date ) >> timings.txt
	for i in `seq 1 $ncores`
	do
    	    case $i in
    		?) ch=000$i ;;
    		??) ch=00$i ;;
    		???) ch=0$i ;;
    		????) ch=$i ;;
    	    esac
    	    (echo $i ; echo pwgevents-${ch}.lhe ) | $PRG > run-rwgt-pdf${m}${n}-$i.log 2>&1 &
	done
	wait
	for i in `seq 1 $ncores`
	do
    	    case $i in
    		?) ch=000$i ;;
    		??) ch=00$i ;;
    		???) ch=0$i ;;
    		????) ch=$i ;;
    	    esac
    	    mv pwgevents-rwgt-${ch}.lhe pwgevents-${ch}.lhe
	done
	wait
    done
fi


(echo -n end ' ' ; date ) >> timings.txt

echo Finished.
