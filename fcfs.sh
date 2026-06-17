#!/bin/bash

columns=(pid at bt ct tat wt)
processes=()
arrival_time=()
burst_time=()
completion_time=()
turnaround_time=()
waiting_time=()
total_tat=0
total_wt=0
avg_tat=0
avg_wt=0

create_file() {
  sort_by_arrival
  find_completion_time
  find_turnaround_time
  find_waiting_time
  find_average_time

  local i
  local delimited_p
  local filename=$1

  echo "${columns[*]}" | tr ' ' ',' > "$filename"
  for (( i=0; i<n; i++ )); do
    echo "${processes[i]},${arrival_time[i]},${burst_time[i]},${completion_time[i]},${turnaround_time[i]},${waiting_time[i]}" >> "$filename"
  done
  echo ",,,,Avg: $avg_tat,Avg: $avg_wt" >> "$filename"

  echo "Gantt Chart:" >> "$filename"
  delimited_p=($(echo "${processes[*]}" | tr ' ' ','))
  echo ",$delimited_p" >> "$filename"
  delimited_ct=($(echo "${completion_time[*]}" | tr ' ' ','))
  echo "0,$delimited_ct" >> "$filename"
}

sort_by_arrival() {
  local i j
  local dum_p dum_at dum_bt

  for (( i=0; i<n-1; i++ )); do
    for (( j=0; j<n-i-1; j++ )); do
      if (( arrival_time[j] > arrival_time[j+1] )); then
        dum_p="${processes[j]}"
        processes[j]="${processes[j+1]}"
        processes[j+1]="$dum_p"

        dum_at="${arrival_time[j]}"
        arrival_time[j]="${arrival_time[j+1]}"
        arrival_time[j+1]="$dum_at"

        dum_bt="${burst_time[j]}"
        burst_time[j]="${burst_time[j+1]}"
        burst_time[j+1]="$dum_bt"
      fi
    done
  done
}

find_completion_time() {
  local -a start_time=()
  local i
  local dum_st dum_bt dum_ct

  for (( i=0; i<n; i++ )); do
    if [ $i -eq 0 ]; then
      arrival=arrival_time[i]
      start_time+=($arrival)
    else
      dum_st="${completion_time[i-1]}"
    fi
    dum_bt="${burst_time[i]}"
    dum_ct=$((dum_bt + dum_st))
    completion_time+=($dum_ct)
  done
}

find_turnaround_time() {
  local i
  local dum_ct dum_at dum_tat


  for (( i=0; i<n; i++ )); do
    dum_ct="${completion_time[i]}"
    dum_at="${arrival_time[i]}"
    dum_tat=$(($dum_ct - $dum_at))
    turnaround_time+=($dum_tat)
  done
}

find_waiting_time() {
  local i
  local dum_tat dum_bt dum_wt

  for (( i=0; i<n; i++ )); do
    dum_tat="${turnaround_time[i]}"
    dum_bt="${burst_time[i]}"
    dum_wt=$(($dum_tat - $dum_bt))
    waiting_time+=($dum_wt)
  done
}

find_average_time() {
  local dum_tat dum_wt

  for (( i=0; i<n; i++ )); do
    dum_tat="${turnaround_time[i]}"
    dum_wt="${waiting_time[i]}"
    total_tat=$(($total_tat + $dum_tat))
    total_wt=$(($total_wt + $dum_wt))
  done

  avg_tat=$(echo "scale=2; $total_tat / $n" | bc)
  avg_wt=$(echo "scale=2; $total_wt / $n" | bc)
}

read -p "Enter a total number of processes (maximum 6): " n

for (( i=0; i<n; i++ )); do
  process="P$((i+1))"
  processes+=($process)
done

echo "Enter the Process' Arrival Time"
for (( i=0; i<n; i++ )); do
  read -p "P$((i+1)): " t
  arrival_time+=($t)
done
echo "Enter the Process' Burst Time"
for (( i=0; i<n; i++ )); do
  read -p "P$((i+1)): " t
  burst_time+=($t)
done

read -p "Enter a filename to see the results of the FCFS Scheduling: " filename

create_file "$filename.csv"
























