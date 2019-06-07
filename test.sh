#!/usr/bin/env bash

INIT_PATH="src/main/proto/"
PROTO_PATH="src/test/proto"
i=0
j=0
k=0
n=0




GOSUBPATHS="/src:/src/github.com/grpc-ecosystem/grpc-gateway/third_party/googleapis"
GOPATHLIST=""
OIFS=$IFS
IFS=':'
for GOBASEPATH in $GOPATH; do
    for GOSUBPATH in $GOSUBPATHS; do
    	if [ -e ${GOBASEPATH}${GOSUBPATH} ]; then
        	GOPATHLIST="${GOPATHLIST} -I${GOBASEPATH}${GOSUBPATH}"
        fi
    done
done
IFS=$OIFS

echo "GOPATHLIST="${GOPATHLIST}

#-I/Users/xueqiu/Downloads/mygo/src -I/Users/xueqiu/Downloads/mygo/src/github.com/grpc-ecosystem/grpc-gateway/third_party/googleapis

#遍历先拿到proto文件
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

a=`cat src/main/proto/crm.proto | grep "returns"`
b=rpc
c="("
strindex() {
  x="${1%%$2*}"
  [[ $x = $1 ]] && echo -1 || echo ${#x}
}
for lineContent in a
do
strindex "$lineContent" "$b"   # prints 0
strindex "$lineContent" "$c"    # prints 29
done

echo ${a:0:29}
echo ${a:5:24}
serviceName=${a:5:24}
echo $serviceName

#file_name是一个数组
file_name=`grep  "returns" -rl ${INIT_PATH}`

key_value="returns"
getline()
    {   declare -i nline
        cat -n $1|grep "${key_value}"|awk '{print $1}'
    }


for file in $file_name
do
nline=`getline ${file}`
sed -i "${nline}s/{}/option (google.api.http) = {post:\"/${serviceName}\" body:\"*\"};/g" $file
done



#对proto文件进行插桩
for (( i=0;i<${#file_name[@]};i++ ))
do
  file_name=${INIT_PATH}${file_name[i]}
  changeFile

done



for (( i=0;i<${#file_name[@]};i++ ))
do
  if [[ "${file_name[i]:0:4}"x != "test"x ]]
  then
#  rm -rf ${INIT_PATH}${file_name[i]}
  mv ${INIT_PATH}${file_name[i]} ${PROTO_PATH}
  else
  mv ${INIT_PATH}${file_name[i]} ${INIT_PATH}${file_name[i]:4}
  file_name2[j]=${file_name[i]:4}
  let j=${j}+1
  echo "filename$i:"${file_name[i]:4}
  fi
done

for (( i=0;i<${#file_name2[@]};i++ ))
do
  echo "filename$i="${file_name2[i]}
  #mkdir -p /Users/xueqiu/Downloads/mygo/src/xq/cmd/${file_name2[i]%.*}
  #$(echo $s1 | grep "${s2}")
  result=$(cat ${INIT_PATH}${file_name2[i]} | grep "import")
  if [[ "$result" != ""  ]]
  then
  mkdir -p /Users/xueqiu/Downloads/mygo/src/xq/cmd/${file_name2[i]%.*}
  # generate the gRPC code
  protoc -I$INIT_PATH -I. ${GOPATHLIST} --go_out=plugins=grpc:. ${INIT_PATH}${file_name2[i]}
  # generate the JSON interface code
  protoc -I$INIT_PATH -I. ${GOPATHLIST} --grpc-gateway_out=logtostderr=true:. ${INIT_PATH}${file_name2[i]}
  cp ${file_name2[i]%.*}.* /Users/xueqiu/Downloads/mygo/src/xq/cmd/${file_name2[i]%.*}/
  else
  mkdir -p /Users/xueqiu/Downloads/mygo/src/xq/cmd/pub
  protoc -I$INIT_PATH -I. ${GOPATHLIST} --go_out=plugins=grpc:. ${INIT_PATH}${file_name2[i]}
  cp ${file_name2[i]%.*}.* /Users/xueqiu/Downloads/mygo/src/xq/cmd/pub

  file_name3[k]=${file_name2[i]}
  let k=${k}+1
  fi

done

for (( j=0;j<${#file_name3[@]};j++ ))
do
    for (( i=0;i<${#file_name2[@]};i++ ))
    do
      result=$(cat ${INIT_PATH}${file_name2[i]} | grep "import")
      if [[ "$result" != ""  ]]
      then
      cp /Users/xueqiu/Downloads/mygo/src/xq/cmd/pub/${file_name3[j]%.*}.pb.go /Users/xueqiu/Downloads/mygo/src/xq/cmd/${file_name2[i]%.*}
      echo `grep "package ${file_name3[j]%.*}" -rl /Users/xueqiu/Downloads/mygo/src/xq/cmd/${file_name2[i]%.*}`
      pub_path=`grep "package ${file_name3[j]%.*}" -rl /Users/xueqiu/Downloads/mygo/src/xq/cmd/${file_name2[i]%.*}`
      sed -ie "s/package ${file_name3[j]%.*}/package ${file_name2[i]%.*}/g" ${pub_path}
      fi
    done
done


#for (( i=0;i<${#file_name2[@]};i++ ))
#do
#  result=$(cat ${INIT_PATH}${file_name2[i]} | grep "import")
#  if [[ "$result" != ""  ]]
#  then
#  cp /Users/xueqiu/Downloads/mygo/src/xq/cmd/*.go /Users/xueqiu/Downloads/mygo/src/xq/cmd/${file_name2[i]%.*}
#  echo `grep "package model" -rl /Users/xueqiu/Downloads/mygo/src/xq/cmd/${file_name2[i]%.*}`
#  pub_path=`grep "package model" -rl /Users/xueqiu/Downloads/mygo/src/xq/cmd/${file_name2[i]%.*}`
#  sed -ie "s/package model/package ${file_name2[i]%.*}/g" ${pub_path}
#  else
#  file_name3[k]=${file_name2[i]}
#  let k=${k}+1
#  fi
#done

echo "file_name3="${file_name3[@]}
for (( i=0;i<${#file_name3[@]};i++ ))
do
  for (( j=0;j<${#file_name2[@]};j++ ))
  do
  if [[ "${file_name3[i]}"x == "${file_name2[j]}"x ]]
  then
  echo "equal!!!!"
  unset file_name2[j]
  fi
  done
done
echo "file_name2="${file_name2[@]}
echo "file_name2 length="${#file_name2[@]}
for (( i=0;i<${#file_name2[@]}+1;i++ ))
do
  echo "file_name2[$i]="${file_name2[i]}
  if [[ "${file_name2[i]}" != "" ]]
  then
  file_name2_new[n]=${file_name2[i]}
  let n=${n}+1
  fi
done
echo "file_name2_new="${file_name2_new[@]}

for (( i=0;i<${#file_name2_new[@]};i++ ))
do
echo "file_name2_new[$i]="${file_name2_new[i]}
done

src_path="/Users/xueqiu/Downloads/mygo/src/xq"
proxy_path="/Users/xueqiu/Downloads/mygo/src/xq/proxy.go"

for (( i=0;i<${#file_name2_new[@]};i++ ))
do
  result1=$(grep -n "import" /Users/xueqiu/Downloads/mygo/src/xq/proxy.go)
  row1=${result1%:*}
  gsed -ie "${row1}a gw$((i+1))\"xq/cmd/${file_name2_new[i]%.*}\"" ${proxy_path}

  result2=$(grep -n "opts :=" /Users/xueqiu/Downloads/mygo/src/xq/proxy.go)
  echo "result2="$result2
  row2_tmp=${result2%:*}
  row2=${row2_tmp%:*}
  echo "row2="${row2}
#  err1:= gw1.RegisterCRMServiceHandlerFromEndpoint(ctx,mux,*crmEndpoint,opts)
#  typeset -u ${file_name2_new[i]%.*}
#  echo "file_name2_new[$i]%.*="${file_name2_new[i]%.*}
  UPPERCASE=$(echo ${file_name2_new[i]%.*} | tr '[a-z]' '[A-Z]')
  echo "======${row2}a err$((i+1)):=gw$((i+1)).Register${file_name2_new[i]%.*}ServiceHandlerFromEndpoint(ctx,mux,*crmEndpoint,opts)"
  gsed -ie "${row2}a err$((i+1)):=gw$((i+1)).Register${UPPERCASE}ServiceHandlerFromEndpoint(ctx,mux,*crmEndpoint,opts)" ${proxy_path}

done

mv *.go cmd/testcrm

find ${src_path} -name "*.goe" | xargs rm -rf

go build ${proxy_path}

