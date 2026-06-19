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

gantt_labels=()
gantt_times=()

queue_updation() {
  local max_proc_index=$1
  local zero_index=-1
  local i

  for (( i=0; i<n; i++ )); do
    if (( zero_index == -1 && queue[i] == 0 )); then
      zero_index=$i
    fi
  done

  if (( zero_index == -1 )); then
    return
  fi

  queue[$zero_index]=$(( max_proc_index + 1 ))
}

check_new_arrival() {
  local timer=$1
  local j
  local new_arrival=0

  if (( timer <= arrival_time[n-1] )); then
    for (( j=max_proc_index+1; j<n; j++ )); do
      if (( arrival_time[j] <= timer )); then
        if (( max_proc_index < j )); then
          max_proc_index=$j
          new_arrival=1
        fi
      fi
    done

    if (( new_arrival == 1 )); then
      queue_updation $max_proc_index
    fi
  fi
}

queue_maintainence() {
  local i

  for (( i=0; i<n-1; i++ )); do
    if (( queue[i+1] != 0 )); then
      local dum_q="${queue[i]}"
      queue[i]="${queue[i+1]}"
      queue[i+1]="$dum_q"
    fi
  done
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
  local i j k
  local timer=0
  local ctr
  local flag idle new_arrival
  local -a temp_burst=()
  local -a complete=()

  for (( i=0; i<n; i++ )); do
    temp_burst+=(${burst_time[i]})
    complete+=(0)
    queue+=(0)
    completion_time+=(0)
  done

  while (( timer < arrival_time[0] )); do
    (( timer++ ))
  done
  queue[0]=1

  flag=0
  while (( flag == 0 )); do

    flag=1
    for (( i=0; i<n; i++ )); do
      if (( temp_burst[i] != 0 )); then
        flag=0
      fi
    done

    if (( flag == 0 )); then
      
      for (( i=0; i<n; i++ )); do
        if (( queue[i] != 0 )); then

          ctr=0
          while (( ctr < tq && temp_burst[queue[0]-1] > 0 )); do
            (( temp_burst[queue[0]-1]-- ))
            (( timer++ ))
            (( ctr++ ))

            gantt_labels+=("${processes[queue[0]-1]}")
            gantt_times+=("$timer")

            check_new_arrival $timer
          done

          if (( temp_burst[queue[0]-1] == 0 && complete[queue[0]-1] == 0 )); then
            completion_time[queue[0]-1]=$timer
            complete[queue[0]-1]=1
          fi

          idle=1
          if (( queue[n-1] == 0 )); then
            for (( k=0; k<n; k++ )); do
              if (( queue[k] != 0 && complete[queue[k]-1] == 0 )); then
                idle=0
              fi
            done
          else
            idle=0
          fi

          if (( idle == 1 )); then
            (( timer++ ))
            check_new_arrival $timer
          fi

          queue_maintainence
        fi
      done
    fi
  done
}

find_turnaround_time() {
  local i
  local dum_ct dum_at dum_tat

  for (( i=0; i<n; i++ )); do
    dum_ct="${completion_time[i]}"
    dum_at="${arrival_time[i]}"
    dum_tat=$(( dum_ct - dum_at ))
    turnaround_time+=($dum_tat)
  done
}

find_waiting_time() {
  local i
  local dum_tat dum_bt dum_wt

  for (( i=0; i<n; i++ )); do
    dum_tat="${turnaround_time[i]}"
    dum_bt="${burst_time[i]}"
    dum_wt=$(( dum_tat - dum_bt ))
    waiting_time+=($dum_wt)
  done
}

find_average_time() {
  local i
  local dum_tat dum_wt

  for (( i=0; i<n; i++ )); do
    dum_tat="${turnaround_time[i]}"
    dum_wt="${waiting_time[i]}"
    total_tat=$(( total_tat + dum_tat ))
    total_wt=$(( total_wt + dum_wt ))
  done

  avg_tat=$(echo "scale=2; $total_tat / $n" | bc)
  avg_wt=$(echo "scale=2; $total_wt / $n" | bc)
}

create_file() {
  sort_by_arrival
  find_completion_time
  find_turnaround_time
  find_waiting_time
  find_average_time

  local i
  local filename=$1

  echo "${columns[*]}" | tr ' ' ',' > "$filename"
  for (( i=0; i<n; i++ )); do
    echo "${processes[i]},${arrival_time[i]},${burst_time[i]},${completion_time[i]},${turnaround_time[i]},${waiting_time[i]}" >> "$filename"
  done
  echo ",,,,Avg: $avg_tat,Avg: $avg_wt" >> "$filename"

  # Gantt chart: collapse consecutive duplicate labels for readability
  echo "Gantt Chart:" >> "$filename"
  local prev="" gantt_p_row="," gantt_t_row="0"
  for (( i=0; i<${#gantt_labels[@]}; i++ )); do
    local lbl="${gantt_labels[i]}"
    local t="${gantt_times[i]}"
    if [[ "$lbl" != "$prev" ]]; then
      gantt_p_row+=",$lbl"
      gantt_t_row+=",$t"
      prev="$lbl"
    else
      # Same process continued — just update the end time of this slice
      gantt_t_row="${gantt_t_row%,*},$t"
    fi
  done
  echo "$gantt_p_row" >> "$filename"
  echo "$gantt_t_row" >> "$filename"
}

max_proc_index=0
queue=()

read -p "Enter a total number of processes (maximum 6): " n

for (( i=0; i<n; i++ )); do
  processes+=("P$((i+1))")
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

read -p "Enter the Time Quantum: " tq

read -p "Enter a filename to see the results of the Round Robin Scheduling: " filename

create_file "$filename.csv"
