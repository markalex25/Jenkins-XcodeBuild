#!/bin/sh

echo "~~~~~~~~~~~~~~~~开始执行脚本~~~~~~~~~~~~~~~~"

####################################################################
#工程名
PROJECTNAME="LessoMall"
#需要编译的 targetName
SCHEME_NAME="Yos"
SCHEME_NAME_ARR=("Yos" "YosReady" "YosTestSc" "YosTestAld" "YosDevWen" "YosDevLang")
#ADHOC
#证书名#描述文件
ADHOCCODE_SIGN_IDENTITY="iPhone Developer"
ADHOCPROVISIONING_PROFILE_NAME=""

#AppStore证书名#描述文件
APPSTORECODE_SIGN_IDENTITY="iPhone Developer"
APPSTOREADHOCPROVISIONING_PROFILE_NAME=""

#是否是工作空间
ISWORKSPACE=true

#是否clean项目
ISCLEARNPROJECT=false

#证书名
CODE_SIGN_IDENTITY=${ADHOCCODE_SIGN_IDENTITY}
#描述文件
PROVISIONING_PROFILE_NAME=${ADHOCPROVISIONING_PROFILE_NAME}

#取版本号
VERSION_STR=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' ./XcodebuildConfig/info.plist)
#取build值
BUILD_STR=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' ./XcodebuildConfig/info.plist)

#开始时间
beginTime=`date +%s`
DATE=`date '+%Y-%m-%d-%T'`

#编译模式 工程默认有 Debug Release 
CONFIGURATION_TARGET=Release
#编译路径
BUILDPATH=release/${PROJECTNAME}_ver${VERSION_STR}_${BUILD_STR}_${DATE}
#archivePath
ARCHIVEPATH=${BUILDPATH}/${SCHEME_NAME}/${SCHEME_NAME}.xcarchive
#输出的ipa目录
IPAPATH=${BUILDPATH}/${SCHEME_NAME}


#导出ipa 所需plist
ADHOCExportOptionsPlist=./XcodebuildConfig/ADHOCExportOptionsPlist.plist
AppStoreExportOptionsPlist=./XcodebuildConfig/AppStoreExportOptionsPlist.plist
ExportOptionsPlist=${ADHOCExportOptionsPlist}

#是否上传蒲公英
UPLOADPGYER=false
####################################################################

:<<!
  method=1
  #判读用户是否有输入 
  if [ -n "$method" ]
  then
    if [ "$method" = "1" ]
    then 
    CODE_SIGN_IDENTITY=${ADHOCCODE_SIGN_IDENTITY}
    PROVISIONING_PROFILE_NAME=${ADHOCPROVISIONING_PROFILE_NAME}
    ExportOptionsPlist=${ADHOCExportOptionsPlist}
    elif [ "$method" = "2" ]
    then
    CODE_SIGN_IDENTITY=${APPSTORECODE_SIGN_IDENTITY}
    PROVISIONING_PROFILE_NAME=${APPSTOREADHOCPROVISIONING_PROFILE_NAME}
    ExportOptionsPlist=${AppStoreExportOptionsPlist}
    else
    echo "参数无效...."
    exit 1
    fi
  else
    ExportOptionsPlist=${ADHOCExportOptionsPlist}
  fi
  
  para=1
  if [ -n "$para" ]
  then
    if [ "$para" = "1" ]
    then 
    UPLOADPGYER=false
    elif [ "$para" = "2" ]
    then
    UPLOADPGYER=true
    else
    echo "参数无效...."
    exit 1
    fi
  else
    UPLOADPGYER=false
  fi
!

#遍历Scheme的名称
for SCHEME_NAME in ${SCHEME_NAME_ARR[@]}; do
  ARCHIVEPATH=${BUILDPATH}/${SCHEME_NAME}/${SCHEME_NAME}.xcarchive
  IPAPATH=${BUILDPATH}/${SCHEME_NAME}
  #修改info.plist文件
  /usr/libexec/PlistBuddy -c 'Set :CFBundleShortVersionString '${VERSION_STR}'' ./Plist/${SCHEME_NAME}.plist
  /usr/libexec/PlistBuddy -c 'Set :CFBundleVersion '${BUILD_STR}'' ./Plist/${SCHEME_NAME}.plist
  
  echo "~~~~~~~~~~~~~~~~开始编译~~~~~~~~~~~~~~~~~~~"
  if [ $ISWORKSPACE = true ]
  then
    if [ $ISCLEARNPROJECT = true ]
    then
      # 清理 避免出现一些莫名的错误
      xcodebuild clean 
      -workspace ${PROJECTNAME}.xcworkspace \
      -configuration ${CONFIGURATION} \
      -alltargets
    fi
    
    # CocoaPod
    pod install
    
    # 开始构建
    xcodebuild archive \
    -workspace ${PROJECTNAME}.xcworkspace \
    -scheme ${SCHEME_NAME} \
    -archivePath ${ARCHIVEPATH} \
    -configuration ${CONFIGURATION_TARGET} \
    CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY}" \
    PROVISIONING_PROFILE="${PROVISIONING_PROFILE_NAME}"
  else
    if [ $ISCLEARNPROJECT = true ]
    then
      # 清理 避免出现一些莫名的错误
      xcodebuild clean 
      -project ${PROJECTNAME}.xcodeproj \
      -configuration ${CONFIGURATION} \
      -alltargets
    fi
    
    # 开始构建
    xcodebuild archive 
    -project ${PROJECTNAME}.xcodeproj \
    -scheme ${SCHEME_NAME} \
    -archivePath ${ARCHIVEPATH} \
    -configuration ${CONFIGURATION_TARGET} \
    CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY}" \
    PROVISIONING_PROFILE="${PROVISIONING_PROFILE_NAME}"
  fi
  
  echo "~~~~~~~~~~~~~~~~检查是否构建成功~~~~~~~~~~~~~~~~~~~"
  # xcarchive 实际是一个文件夹不是一个文件所以使用 -d 判断
  if [ -d "$ARCHIVEPATH" ]
  then
    echo "构建成功......"
  else
    echo "构建失败......"
    rm -rf $BUILDPATH
    exit 1
  fi
  endTime=`date +%s`
  ArchiveTime="构建时间$[ endTime - beginTime ]秒"
  
  
  echo "~~~~~~~~~~~~~~~~导出ipa~~~~~~~~~~~~~~~~~~~"
  beginTime=`date +%s`
  
  xcodebuild \
  -exportArchive \
  -archivePath ${ARCHIVEPATH} \
  -exportOptionsPlist ${ExportOptionsPlist} \
  -exportPath ${IPAPATH}
  
  echo "~~~~~~~~~~~~~~~~检查是否成功导出ipa~~~~~~~~~~~~~~~~~~~"
  IPAPATH=${IPAPATH}/${SCHEME_NAME}.ipa
  if [ -f "$IPAPATH" ]
  then
  # 复制文件到FTPShare
  cp -rf release/* /Users/markalex25/Documents/FTPShare
  echo "导出ipa成功......"
  else
  echo "导出ipa失败......"
  # 结束时间
  endTime=`date +%s`
  echo "$ArchiveTime"
  echo "导出ipa时间$[ endTime - beginTime ]秒"
  exit 1
  fi
  
  endTime=`date +%s`
  ExportTime="导出ipa时间$[ endTime - beginTime ]秒"
  
  # 上传蒲公英 
  if [ $UPLOADPGYER = true ]
  then
    echo "~~~~~~~~~~~~~~~~上传ipa到蒲公英~~~~~~~~~~~~~~~~~~~"
    curl -F "file=@$IPAPATH" \
    -F "uKey=xxxxx" \
    -F "_api_key=xxxx" \
    -F "password=xxxxx" \
    -F "isPublishToPublic=xxxx" \
    https://www.pgyer.com/apiv1/app/upload --verbose
  
    if [ $? = 0 ]
    then
    echo "~~~~~~~~~~~~~~~~上传蒲公英成功~~~~~~~~~~~~~~~~~~~"
    else
    echo "~~~~~~~~~~~~~~~~上传蒲公英失败~~~~~~~~~~~~~~~~~~~"
    fi
  fi
  
  echo "~~~~~~~~~~~~~~~~配置信息~~~~~~~~~~~~~~~~~~~"
  echo "开始执行脚本时间: ${DATE}"
  echo "编译模式: ${CONFIGURATION_TARGET}"
  echo "导出ipa配置: ${ExportOptionsPlist}"
  echo "打包文件路径: ${ARCHIVEPATH}"
  echo "导出ipa路径: ${IPAPATH}"
  echo "$ArchiveTime"
  echo "$ExportTime"
done
open $BUILDPATH
exit 0

