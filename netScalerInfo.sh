#!/bin/bash

# File containing the list of VIP names
vip_list_file="vip_names.txt"

# Output file to store the extracted details in CSV format
output_file="vip_details.csv"

# Write CSV headers
echo "VIPNAME,IP,PORT,PROTOCOL,TYPE,BACKEND_SERVERS" > $output_file

# Function to extract details for a given VIP
extract_vip_details() {
    local vip_name=$1
    local vip_details
    local backend_servers=""
    local server_details
    local lb_flag="Service Name:"
    local cs_flag="LBVserver Name:"

    # Check if it's a load balancing virtual server
    vip_details=$(ssh -T user@netscaler "show lb vserver $vip_name" 2>/dev/null)
    if [[ $vip_details == *"Done"* ]]; then
        vip_type="Load Balancing"
        # Extract backend servers for load balancing virtual server
        server_details=$(ssh -T user@netscaler "show lb vserver $vip_name" | grep "$lb_flag")
        while IFS= read -r line; do
            backend_servers+=$(echo $line | awk '{print $3}')","
        done <<< "$server_details"
    else
        # Check if it's a content switching virtual server
        vip_details=$(ssh -T user@netscaler "show cs vserver $vip_name" 2>/dev/null)
        if [[ $vip_details == *"Done"* ]]; then
            vip_type="Content Switching"
            # Extract backend servers for content switching virtual server
            server_details=$(ssh -T user@netscaler "show cs vserver $vip_name" | grep "$cs_flag")
            while IFS= read -r line; do
                backend_servers+=$(echo $line | awk '{print $3}')","
            done <<< "$server_details"
        else
            echo "VIP $vip_name not found on NetScaler."
            return
        fi
    fi

    # Remove trailing comma from backend_servers
    backend_servers=${backend_servers%,}

    # Extract details from the output
    vip_ip=$(echo "$vip_details" | grep "IP Address:" | awk '{print $3}')
    vip_port=$(echo "$vip_details" | grep "Port:" | awk '{print $2}')
    vip_protocol=$(echo "$vip_details" | grep "Protocol:" | awk '{print $2}')

    # Write details to the CSV file
    echo "$vip_name,$vip_ip,$vip_port,$vip_protocol,$vip_type,\"$backend_servers\"" >> $output_file
}

# Clear previous output file content except for the header
> $output_file
echo "VIPNAME,IP,PORT,PROTOCOL,TYPE,BACKEND_SERVERS" > $output_file

# Loop through each VIP name in the list
while IFS= read -r vip_name; do
    extract_vip_details "$vip_name"
done < "$vip_list_file"

echo "Extraction complete. Details saved in $output_file."
