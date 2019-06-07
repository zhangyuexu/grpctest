#!/bin/bash

INIT_PATH="src/main/proto/"

function read_dir(){

for file in `ls $1`
do
 if [ -d $1"/"$file ] #注意此处之间一定要加上空格，否则会报错
 then
 read_dir $1"/"$file
 else
 #file_path= $1"/"$file #在此处处理文件即可
 file_name[${i}]=$file
 let i=${i}+1
 fi
done
}

read_dir $INIT_PATH
echo ${file_name[@]}

n=0
for (( i=0;i<${#file_name[@]};i++ ))
do
result=$(cat ${INIT_PATH}${file_name[i]} | grep "service")
if [[ "$result" != "" ]]
then
file_name2[$n]=${file_name[i]}
let n=$n+1
fi
done


b=rpc
c="("
d="{"
e="}"
strindex() {
  x="${1%%$2*}"
  [[ $x = $1 ]] && echo -1 || echo ${#x}
}

#先得到特定行，然后拿服务名serviceName
j=0
for (( i=0;i<${#file_name2[@]};i++ ))
do
while read line
do
result=$(echo $line | grep "returns")
if [[ "$result" != "" ]]
then
    line_contents[$j]=$line
    let j=${j}+1

    begin=$(strindex "${line}" "$b")
    end=$(strindex "${line}" "$c")
    serviceName=${line:$(expr $begin + 5):$(expr $end - 5)}
    begin2=$(strindex "${line}" "$d")
    end2=$(strindex "${line}" "$e")
    #echo "begin2="$begin2
    #echo "end2"=$end2
    line_content_new=${line:0:$end2}"option (google.api.http) = {post:\"\/${serviceName}\" body:\"*\"};}"
    echo $line_content_new
    sed -ie "s/$line/$line_content_new/g" ${INIT_PATH}${file_name2[$i]}

fi
done < ${INIT_PATH}${file_name2[$i]}

done

for (( i=0;i<${#file_name2[@]};i++ ))
do
result1=$(grep -n "import" ${INIT_PATH}${file_name2[$i]})
row1=${result1%:*}
gsed -ie "${row1}a import \"google\/api\/annotations.proto\";" ${INIT_PATH}${file_name2[$i]}
echo "row1="$row1
done

find ${INIT_PATH} -name "*.protoe" | xargs rm -rf

#b=rpc
#c="("
#d="{"
#e="}"
#strindex() {
#  x="${1%%$2*}"
#  [[ $x = $1 ]] && echo -1 || echo ${#x}
#}
#
#for (( i=0;i<${#line_contents[@]};i++ ))
#do
#echo ${line_contents[i]}
#begin=$(strindex "${line_contents[i]}" "$b")
#end=$(strindex "${line_contents[i]}" "$c")
#serviceName[$m]=${line_contents[i]:$(expr $begin + 5):$(expr $end - 5)}
#let m=${m}+1
#begin2=$(strindex "${line_contents[i]}" "$d")
#end2=$(strindex "${line_contents[i]}" "$e")
##echo "begin2="$begin2
##echo "end2"=$end2
#line_content_new=${line_contents[$i]:0:$end2}"option (google.api.http) = {post:\"/${serviceName[$i]}\" body:\"*\"};}"
#echo $line_content_new
#done
#
#for (( i=0;i<${#serviceName[@]};i++ ))
#do
#echo ${serviceName[i]}
#done


#key_value="service"
#getline()
#{   declare -i nline
#    cat -n $1|grep "${key_value}"|awk '{print $1}'
#}
#
#for key in ${!mymap[*]};do
#    echo ${mymap[$key]}
#
#    #删除
#    sed -ie '/returns/d' $key
#    lineNum=`getline ${INIT_PATH}${file_name[i]}`
#    echo "lineNum="$lineNum
#    gsed -ie "${lineNum}a $line_content_new" $key
#done