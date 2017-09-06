# Jenkins-XcodeBuild
##描述:
Shell脚本执行XcodeBuild的clean, build, archive 和 export ipa文件等操作.

脚本中包含循环对多个不同的scheme打包.

脚本中包含获取info.plist的Version 和 Bundle,然后赋值对不同target的info.plist.

脚本中包含复制文件到指定的FTPShare(FTP共享文件夹).(Jenkins可以配置上传到指定的FTP服务器)

脚本中包含上传到蒲公英的功能.

##使用:

Jenkins自行配置好gitlab仓库路径和验证,webhook回调触发任务等.

Jenkins的构建添加步骤"Execute Shell",把jenkins.sh的代码粘贴进去,根据你的项目可以自行对代码做相应调整.

项目中请复制XcodebuildConfig文件到项目根目录中.

各个target的info.plist重命名,并自行修改xxx.xcodeproj下project.pbxproj关联.(本人把所有info.plist放到Plist/下, 命名和target一致).


##结语:

如果对您有帮助,请给一下star.谢谢!