#!/bin/bash


#-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#                       Introduction
#-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

# This script is made for a specific use-case i.e. to monitor the swarm quorum. So a docker swarm quorum is formed when there are more than half managers are up and woking.
# So this script returns Status 'Ok' when the all the managers are healthy and working, 'Warning' when any of the manager is unhealthy, And 'Critical' when more than half of the managers are unhealthy.
# In this script we have used 'docker node ls' command to know the status of the managers from any node. So if it is a worker node where we run  this script, then it returns 'Ok' as on woker node we cann't get the status of any node.

#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#                       License
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

#     This plugin monitors the docker swarm quorum.
#     Copyright (C) 2018  Sushanto Halder

#     This program is free software: you can redistribute it and/or modify
#     it under the terms of the GNU General Public License as published by
#     the Free Software Foundation, either version 3 of the License, or
#     (at your option) any later version.

#     This program is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU General Public License for more details.

#     You should have received a copy of the GNU General Public License
#     along with this program.  If not, see <https://www.gnu.org/licenses/>.


#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

# updated by smiotke 2020-04-28 to support worker checks too
# modified by Adam Rocha 2020-08-05

#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

worker=( $( docker node ls | grep -v ENGINE | grep -v Ready ) )

# 'docker node ls' provides the status of manager nodes. It exits with exit code 2 if the swarm is unhealthy.
array=( $(docker node ls --format \{\{.ManagerStatus\}\}) )

if [ $? -gt 0 ]; then
    echo "CRITICAL - Swarm is Unhealthy (not in quorum)"
    exit 2
else
    reqStatus='Leader'
    altStatus='Reachable'
    fg=0
        for element in "${array[@]}"; do
            if [[ "$element" == "$reqStatus" || "$element" == "$altStatus" ]]; then
                # increases the value of fg by one each time it encounters a reachable manager or the leader.
                fg=$((fg+1))
            fi
        done
    # n is the number of manager nodes in the swarm quorum.
# Use if salting # {% raw -%}
    n=${#array[@]}
# Use is salting # {% endraw -%}
    if [ "$n" -gt "$fg" ]; then
        n=$((n/2))
            if [ "$fg" -gt "$n" ];
            then
                # if any of the manager is down then it returns critical because we need to know if a manager is down
                echo "CRITICAL - Some manager is down"
                exit 2
            else
                # if more than half of the managers are unhealthy, then it shows that the swarm cluster is in Critical state.
                echo "CRITICAL - Swarm is Unhealthy (not in quorum)"
                exit 2
            fi
    elif [ "$worker" ]; then
        echo "CRITICAL - Swarm Workers are not healthy"
        exit 2
    else
        echo "OK - Swarm is Healthy, and in quorum"
        exit 0
    fi
fi
