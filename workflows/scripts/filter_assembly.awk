#! /usr/bin/awk -f 
# " && 
BEGIN{ FS="\t"; OFS="\t" } 
# NR==2{
#     print $1
# }
NR>2 && 
$5=="reference genome" && 
$11=="latest" && 
$25 ~ /bacteria|archaea/ && 
$20!="na" {
    print $1 
}
