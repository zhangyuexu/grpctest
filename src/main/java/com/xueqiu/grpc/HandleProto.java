package com.xueqiu.grpc;

import java.io.*;

public class HandleProto {
    public static void main(String[] args) throws Exception{

        String dir = "src/main/proto";
        String imcontent = "import \"google/api/annotations.proto\";";

        addContent(dir,imcontent);

    }
    //同一个文件不支持同时读写
    public static void addContent(String dir,String imcontent) throws Exception{
        File dirFile = new File(dir);
        File[] files = dirFile.listFiles();
        for(File file : files){
            if(file.isDirectory()){
                addContent(file.getPath(),imcontent);
            }else {
                FileReader fr = new FileReader(file);
                BufferedReader bufferedReader = new BufferedReader(fr);
                //System.out.println( file.getName()+"======"+file.getParent()+"===="+file.getPath());
                Writer writer = new FileWriter(new File(file.getParent()+"/test"+file.getName()));
                String line = bufferedReader.readLine();

                //insertCon(file.getPath(),imcontent,line.indexOf(";")+2);

                while (line != null){
                    if(line.contains("rpc") && line.contains("returns")){
                        if((line.indexOf("(")) != -1){
                            String serviceName = line.substring(line.indexOf("rpc")+4,line.indexOf("("));
                            System.out.println(serviceName);

                            String content = "option (google.api.http) = {post:\"/"+serviceName.trim()+"\""+" body:\"*\"};";
                            writer.write(line.substring(0, line.indexOf("{")+1)+content+"}\r\n");
                            line = bufferedReader.readLine();
                        }
                    }
                    if(line.contains("import")){
                        writer.write(line+"\r\n"+imcontent);
                    }
                    else {
                        writer.write(line+"\r\n");
                    }
                    line = bufferedReader.readLine();
                }
                bufferedReader.close();
                fr.close();
                writer.close();

            }
        }
    }

    //插入内容的具体实现方法
    public static void insertCon(String dir, String content, long position){

        RandomAccessFile raf = null;

        try {

            raf = new RandomAccessFile(dir, "rw"); //将随机存取文件流连接到文件，访问方式设置为可读可写
            raf.seek(position); //指定插入的位置

            //先将插入点后面的内容保存起来
            StringBuffer sb = new StringBuffer();
            byte[] b = new byte[100];
            int len;
            while( (len=raf.read(b)) != -1 ) {
                sb.append( new String(b, 0, len) );
            }

            raf.seek(position); //重新设置插入位置
            raf.write( content.getBytes() ); //插入指定内容
            raf.write( sb.toString().getBytes() ); //恢复插入点后面的内容

        } catch (IOException e) {

            e.printStackTrace();

        } finally {

            //关闭随机存取文件流
            try {
                raf.close();
            } catch (IOException e) {
                e.printStackTrace();
            }
        }

    }
}


