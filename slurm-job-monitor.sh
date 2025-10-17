#!/bin/bash
function help_page(){
    echo -e "h\thelp page"
    echo -e "J\tjob page"
    echo -e "N\tnode page"
    echo -e "S\tinformation of all node"
    echo -e "F\tfind a single node information"
    echo -e "j\tnext row"
    echo -e "k\tprevious row"
    echo -e "q\tquit"
}

function show_single_node(){
    yhcontrol show node
}

function select_node(){
    yhcontrol show node | gawk -v name="$1\$" 'BEGIN{RS="";FS="[ \n]+"} {if ($1 ~ name ) print $0}'
}

function show_node(){
    yhcontrol show node | gawk 'BEGIN{
                                    RS="";FS="[ \n]+";
				    print "Node\tAlloc CPU\tTotal CPU\tPartitions"
			    }
			    {
				    sub(/^NodeName=/,"",$1);
				    sub(/^CPUAlloc=/,"",$4);
				    sub(/^CPUTot=/,"",$5);
				    for (i=1; i<NF; i++){
					    if ( $i ~ /^Partition/ ){
					    	sub(/Partitions=/,"",$i)
						break
					    } 
				    }
				    print $1 "\t" $4 "\t" $5 "\t" $i
			    }'
}

function show_job(){
    yhqueue
}

function refresh(){
    local output=''
    local rows=$(tput lines)

    output=$(eval "$refresh_cmd")
    
    
    local number=$(echo -e "$output" | wc -l)
    
    if [ $n -gt $number ]
    then
	    n=$number
    fi
    
    rows=$(($rows + $n - 3))

    clear
    date
    echo -e  "$output" | sed -n "${n},${rows}p" | gawk 'BEGIN{
                                                             RS="";
							     FS="\n";
							}
							{
							     for (i=1; i<NF; i++){
							         print $i
							     }
							     printf "%s", $NF
							}'

    if [ "$state" == 'input' ]
    then
        printf "\n%s\t%s" "$input_echo" "$input_str"
    else
	printf "\nplease press h for help"
    fi
}

function read_key(){
    local old_ifs=$IFS
    IFS=
    read  -t 1 -n 1 -s input
    local input_state=$?
    IFS=$old_ifs


    if [ "$state" == "input" ]
    then
	if [ -n "$input" ] || [ "$input" == " " ] 
	then
	    case $input in
		$'\b' | $'\x7f')
		    input_str=${input_str%?}
		    ;;
		$'\e')
		    state='normal'
		    input_str=''
		    input_echo=''
		    ;;
		*)
                    input_str="${input_str}${input}"
		    ;;
            esac
        elif [ $input_state -eq 0 ]
	then
	    state='normal'
	    case "$input_echo" in
		"Select Node:")
	            refresh_cmd="select_node \"${input_str}\""
		    ;;
		"Shell Command:")
		    echo $input_str
		    sleep 2
		    refresh_cmd="sh -c \"${input_str}\""
		    ;;
            esac
	    n=1
	    input_str=''
	    input_echo=''
        fi
	return 
    fi

    case $input in
	"q")
	    state='quit'
	    ;;
        "N")
	    refresh_cmd='show_node'
	    n=1
	    ;;
	"J")
	    refresh_cmd='show_job'
	    n=1
	    ;;
	"S")
	    refresh_cmd='show_single_node'
	    n=1
	    ;;
	"F")
	    state='input'
	    input_echo="Select Node:"
	    ;;
        "R")
	    state='input'
	    input_echo="Shell Command:"
	    ;;
        "j")
	    n=$((n + 1))
	    ;;
	"k")
	    if [ $n -gt 1 ]
	    then
	        n=$(($n - 1))
	    fi
	    ;;
	"h")
	    refresh_cmd='help_page'
    esac
}

function init(){
    trap "tput rmcup" EXIT
    tput smcup

    n=1
    state='normal'
    refresh_cmd='show_node'
    input_str=''
    input_echo=''
    input_parameter=''
}

init
while true
do
    refresh
    read_key

    if [ $state == 'quit' ]
    then
        break
    fi

done
