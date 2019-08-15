#!/bin/bash

function _helpDefaultWrite()
{
VAL=$1
local VAL1=$2

if [ ! -z "$VAL" ] || [ ! -z "$VAL1" ]; then
    defaults write "${ScriptHome}/Library/Preferences/com.slsoft.treeswitcher.plist" "$VAL" "$VAL1"
fi
}

function _helpDefaultRead()
{
VAL=$1

if [ ! -z "$VAL" ]; then
    defaults read "${ScriptHome}/Library/Preferences/com.slsoft.treeswitcher.plist" "$VAL"
fi
}

ScriptHome=$(echo $HOME)
MY_PATH="`dirname \"$0\"`"
cd "$MY_PATH"

download_path=$( _helpDefaultRead "Downloadpath" )
temp_path="/private/tmp/treeswitcher"
sparseimage_path=$( _helpDefaultRead "Imagepath" )
seed_choice=$( _helpDefaultRead "CurrentSeed" )
seedcatalog_path="/System/Library/PrivateFrameworks/Seeding.framework/Versions/Current/Resources/SeedCatalogs.plist"
sucatalog="seed.sucatalog"
volume_name=$( _helpDefaultRead "Volumename" )

hwspecs=$( system_profiler SPHardwareDataType )
osversion=$( sw_vers | grep ProductVersion | cut -d':' -f2 | xargs )
osbuild=$( sw_vers |tail -n1 | sed "s/.*://g" | xargs )
modelname=$( echo -e "$hwspecs" | grep "Model Name:" | sed "s/.*://g" | xargs )
modelid=$( echo -e "$hwspecs" | grep "Model Identifier:" | sed "s/.*://g" | xargs )
cputype=$( echo -e "$hwspecs" | grep "Processor Name:" | sed "s/.*://g" | xargs )

_helpDefaultWrite "OSVersion" "$osversion"
_helpDefaultWrite "OSBuild" "$osbuild"
_helpDefaultWrite "Modelname" "$modelname"
_helpDefaultWrite "ModelID" "$modelid"
_helpDefaultWrite "CPUType" "$cputype"

function _initial()
{

    if [ -d "$temp_path" ]; then
        rm "$temp_path"/*  2> /dev/null
    fi

    #if [ -d "$download_path" ]; then
    #rm "$download_path"/*  2> /dev/null
    #fi

    #if [ -d "$sparseimage_path" ]; then
    #diskutil eject /Volumes/"$volume_name" 2> /dev/null
    #rm "$sparseimage_path"/*sparse*  2> /dev/null
    #fi

}

function _helpDefaultDelete()
{
    VAL=$1

    if [ ! -z "$VAL" ]; then
    defaults delete "${ScriptHome}/Library/Preferences/com.slsoft.treeswitcher.plist" "$VAL"
    fi
}

function _check_seed()
{
    seed=$( _helpDefaultRead "CurrentSeed" )
    if [[ $seed = "" ]]; then
        seed=$( osascript -e 'do shell script "sudo /System/Library/PrivateFrameworks/Seeding.framework/Resources/seedutil current |grep \"Currently enrolled in\" |sed \"s/.*: //g\"" with administrator privileges' )
    fi

    if [[ $seed != "" ]]; then
        _helpDefaultWrite "CurrentSeed" "$seed"
    fi

    #seed=$( _helpDefaultRead "CurrentSeed" )
    #echo "You are using $seed at the Moment."

}

function _setseed()
{

    seed=$( _helpDefaultRead "NewSeed" )

    if [[ $seed = "Customer" ]]; then
        osascript -e 'do shell script "sudo /System/Library/PrivateFrameworks/Seeding.framework/Resources/seedutil enroll CustomerSeed" with administrator privileges'
        if [[ $? = "0" ]]; then
            _helpDefaultWrite "CurrentSeed" "CustomerSeed"
        fi
    fi
    if [[ $seed = "Developer" ]]; then
        osascript -e 'do shell script "sudo /System/Library/PrivateFrameworks/Seeding.framework/Resources/seedutil enroll DeveloperSeed" with administrator privileges'
            if [[ $? = "0" ]]; then
                _helpDefaultWrite "CurrentSeed" "DeveloperSeed"
            fi
    fi
    if [[ $seed = "Public" ]]; then
        osascript -e 'do shell script "sudo /System/Library/PrivateFrameworks/Seeding.framework/Resources/seedutil enroll PublicSeed" with administrator privileges'
            if [[ $? = "0" ]]; then
            _helpDefaultWrite "CurrentSeed" "PublicSeed"
            fi
    fi
    if [[ $seed = "Unenroll" ]]; then
        osascript -e 'do shell script "sudo /System/Library/PrivateFrameworks/Seeding.framework/Resources/seedutil unenroll" with administrator privileges'
            if [[ $? = "0" ]]; then
            _helpDefaultWrite "CurrentSeed" "Unenroll"
            fi
    fi
}

function _select_macos()
{

    mkdir "$sparseimage_path" 2> /dev/null
    mkdir "$download_path" 2> /dev/null
    mkdir "$temp_path" 2> /dev/null

    if [[ $seed_choice = "CustomerSeed" ]]; then
        seed_url=$( ../bin/./PlistBuddy -c "Print CustomerSeed" "$seedcatalog_path" )
        curl -s "$seed_url" |gunzip -c > "$temp_path"/"$sucatalog"
    fi
    if [[ $seed_choice = "DeveloperSeed" ]]; then
        seed_url=$( ../bin/./PlistBuddy -c "Print DeveloperSeed" "$seedcatalog_path" )
        curl -s "$seed_url" |gunzip -c > "$temp_path"/"$sucatalog"
    fi
    if [[ $seed_choice = "PublicSeed" ]]; then
        seed_url=$( ../bin/./PlistBuddy -c "Print PublicSeed" "$seedcatalog_path" )
        curl -s "$seed_url" |gunzip -c > "$temp_path"/"$sucatalog"
    fi

    seed_ids=$( cat "$temp_path"/seed.sucatalog |grep InstallESDDmg.*pkg\< |cut -d/ -f8,8 )
    echo "$seed_ids" > "$temp_path"/seed_ids

    if [ -f "$temp_path"/selection ]; then
        rm "$temp_path"/selection
    fi

    while IFS= read -r line; do
        seed_url=$( ../bin/./PlistBuddy -c "Print Products:$line" "$temp_path"/"$sucatalog" |grep "English.dist" | sed 's/.*=\ //g' )
        curl -s "$seed_url" | sed '1,/auxinfo/d' > "$temp_path"/seedfiles
        build=$( ../bin/./PlistBuddy -c "Print BUILD" "$temp_path"/seedfiles )
        version=$( ../bin/./PlistBuddy -c "Print VERSION" "$temp_path"/seedfiles )
        count=$( echo -n $version | wc -c )
        if [ $count == 5 ]; then
            version="$version.0"
        fi
        echo -e "$version - ($build)" >> "$temp_path"/selection
        echo -e "$seed_url" >> "$temp_path"/selection_urls
    done <<< "$seed_ids"

    perl -e 'truncate $ARGV[0], ((-s $ARGV[0]) - 1)' "$temp_path"/selection

    _helpDefaultWrite "Statustext" "Ready..."
}

function _download_macos()
{

    choice=$( _helpDefaultRead "Choice" )
    choice=$( grep -n "$choice" "$temp_path"/selection | head -n 1 | cut -d: -f1 )
    Imagesize=$( _helpDefaultRead "Imagesize" |sed 's/,.*//' )
    Imagename=$( _helpDefaultRead "Imagename" )
    Imagepath=$( _helpDefaultRead "Imagepath" |sed 's/\ /\\\\\ /g' )
    parallel_downloads=$( _helpDefaultRead "ParaDL" )



    if [ -f "$download_path"/.downloaded_files ]; then
        _helpDefaultWrite "Statustext" "Cleaning Downloadfolder"
        while IFS= read -r line
        do
            rm "$download_path"/"$line" 2> /dev/null
        done < ""$download_path"/.downloaded_files"
        rm "$download_path"/*English.dist 2> /dev/null
        rm "$download_path"/.downloaded_files
    fi

if [[ $choice != "" ]] && [[ $choice != "0" ]]; then
    seed_url=$( sed -n "$choice"'p' < "$temp_path"/selection_urls )
    curl -s "$seed_url" -o "$temp_path"/sucatalog

    cat "$temp_path"/sucatalog |grep pkg-ref |sed -e 's/.*">//g' -e '/[0-9]/d' -e 's/<.*//g' >> "$temp_path"/selection_files
    cat -n "$temp_path"/selection_files | sort -uk2 | sort -nk1 | cut -f2- |uniq -u > "$temp_path"/selection_files2

    seed_url=$( cat "$temp_path"/selection_urls |sed -n "$choice"'p' |sed 's![^/]*$!!' )

    touch "$download_path"/.downloaded_files

    while IFS= read -r line
    do
    kill_download=$( _helpDefaultRead "KillDL" )
    if [[ $kill_download = 1 ]]; then
        _helpDefaultWrite "Statustext" "Downloading aborted"
        exit
    fi
    _helpDefaultWrite "Statustext" "Downloading: $line"
    echo "$line" >> "$download_path"/.downloaded_files
../bin/./aria2c -q -x "$parallel_downloads" --file-allocation=none -d "$download_path" "$seed_url""$line"

    done < ""$temp_path"/selection_files2"

    cat "$temp_path"/selection_files2 |grep pkg |sed 's/pkg/pkm/g' > "$temp_path"/selection_files3

    while IFS= read -r line
    do
    kill_download=$( _helpDefaultRead "KillDL" )
    if [[ $kill_download = 1 ]]; then
        _helpDefaultWrite "Statustext" "Downloading aborted"
        exit
    fi
    _helpDefaultWrite "Statustext" "Downloading: $line"
    echo "$line" >> "$download_path"/.downloaded_files
../bin/./aria2c -q -x "$parallel_downloads" --file-allocation=none -d "$download_path" "$seed_url""$line"
    done < ""$temp_path"/selection_files3"

    cat "$temp_path"/selection_files3 |sed 's/pkm/smd/g' > "$temp_path"/selection_files4

    while IFS= read -r line
    do
    kill_download=$( _helpDefaultRead "KillDL" )
    if [[ $kill_download = 1 ]]; then
        _helpDefaultWrite "Statustext" "Downloading aborted"
        exit
    fi
    _helpDefaultWrite "Statustext" "Downloading: $line"
    echo "$line" >> "$download_path"/.downloaded_files
../bin/./aria2c -q -x "$parallel_downloads" --file-allocation=none -d "$download_path" "$seed_url""$line"
    done < ""$temp_path"/selection_files4"

    seed_id=$( sed -n "$choice"'p' < "$temp_path"/seed_ids )

    curl -f -s "$seed_url""$seed_id".English.dist -o "$download_path"/"$seed_id".English.dist

    kill_download=$( _helpDefaultRead "KillDL" )
    if [[ $kill_download = 1 ]]; then
        _helpDefaultWrite "Statustext" "Downloading aborted"
    exit
    fi

    if [ -d /Volumes/"$volume_name" ]; then
        _helpDefaultWrite "Statustext" "Removing previous Sparseimage."
        diskutil unmountDisk force /Volumes/"$volume_name" 2> /dev/null
        rm  "$sparseimage_path"/"$Imagename".sparseimage
    fi

    if [ -f "$sparseimage_path"/"$Imagename".sparseimage ]; then
        rm  "$sparseimage_path"/"$Imagename".sparseimage
    fi

    _helpDefaultWrite "Statustext" "Creating Sparseimage"

    /usr/bin/hdiutil create -size "$Imagesize"g -fs HFS+ -volname "$volume_name" -type SPARSE "$sparseimage_path"/"$Imagename" 2> /dev/null
    _helpDefaultWrite "Statustext" "Mounting Sparseimage"
    open "$sparseimage_path"/"$Imagename".sparseimage
    _helpDefaultWrite "Statustext" "Creating Installer-Application."

    kill_download=$( _helpDefaultRead "KillDL" )
    if [[ $kill_download = 1 ]]; then
        _helpDefaultWrite "Statustext" "Downloading aborted"
        exit
    fi

    osascript -e 'do shell script "sudo /usr/sbin/installer -pkg '"'$download_path'"'/*English.dist -target /Volumes/'"'$volume_name'"'" with administrator privileges'
    installok="$?"
    if [ ! -f /Volumes/"$volume_name"/Applications/*insta*/Contents/SharedSupport/AppleD* ]; then
        cp "$download_path"/AppleD* /Volumes/"$volume_name"/Applications/*nstall*/Contents/SharedSupport/.
    fi
    if [ ! -f /Volumes/"$volume_name"/Applications/*insta*/Contents/SharedSupport/BaseS* ]; then
        cp "$download_path"/BaseS* /Volumes/"$volume_name"/Applications/*nstall*/Contents/SharedSupport/.
    fi
    if [[ "$installok" = "0" ]]; then
        _helpDefaultWrite "Statustext" "Done!"
    else
        _helpDefaultWrite "Statustext" "Creation failed! Please try again."
    fi
else
    _helpDefaultWrite "Statustext" "Error! Nothing selected."
fi

}

function _kill_aria()
{

    #if [ -d "$temp_path" ]; then
    #rm "$temp_path"/*  2> /dev/null
    #fi

    #if [ -d "$download_path" ]; then
    #rm "$download_path"/*  2> /dev/null
    #fi

    for KILLPID in `ps ax | grep 'script.command _download_os' | awk ' { print $1;}'`; do
        kill -kill $KILLPID;
    done
    for KILLPID in `ps ax | grep 'aria' | awk ' { print $1;}'`; do
        kill -kill $KILLPID;
    done

    #if [ -d "$sparseimage_path" ]; then
    #diskutil eject /Volumes/"$volume_name" 2> /dev/null
    #rm "$sparseimage_path"/*sparse*  2> /dev/null
    #fi

    for KILLPID in `ps ax | grep 'treeswitcher' | awk ' { print $1;}'`; do
        kill -kill $KILLPID;
    done

}

###### Create Mediainstall Section ######

function _get_drives()
{

    if [ -f "$temp_path"/volumes ]; then
        rm "$temp_path"/volumes*
    fi

    df -h | grep /dev/disk\*s\* | sed 's/.*Volumes/\/Volumes/' | grep Volumes | sed 's/\/Volumes\///g' > "$temp_path"/volumes

    while IFS= read -r line
    do
        diskinfo=$( diskutil info "/Volumes/$line" |grep "File System Personality" |sed 's/.*://g' |xargs )
        if [[ $diskinfo = *HFS* ]]; then
            echo "$line" >> "$temp_path"/volumes2
        fi
    done < ""$temp_path"/volumes"

    rm "$temp_path"/volumes 2> /dev/null
    cat "$temp_path"/volumes2 |grep -v "$volume_name" |grep -v "install_app" > "$temp_path"/volumes

    perl -e 'truncate $ARGV[0], ((-s $ARGV[0]) - 1)' "$temp_path"/volumes  2> /dev/null

    emptycheck=$( cat "$temp_path"/volumes )

    if [[ $emptycheck = "" ]]; then
        rm "$temp_path"/volumes*
    fi

}

function _get_drive_info()
{

    driveinfo=$( _helpDefaultRead "DriveInfo" )
    diskutil info "$driveinfo" > "$temp_path"/driveinfo
    driveinfo=$( cat "$temp_path"/driveinfo )

    dr_vol_name=$( echo "$driveinfo" |grep "Volume Name" |sed 's/.*://g' |xargs )
    dr_part_type=$( echo "$driveinfo" |grep "Partition Type" |sed 's/.*://g' |xargs )
    dr_file_sys=$( echo "$driveinfo" |grep "File System Personality" |sed 's/.*://g' |xargs )
    dr_dev_loc=$( echo "$driveinfo" |grep "Device Location" |sed 's/.*://g' |xargs )
    dr_tot_space=$( echo "$driveinfo" |grep "Volume Total Space" |sed -e 's/.*://g' -e 's/(.*//g' |xargs )
    dr_free_space=$( echo "$driveinfo" |grep "Volume Free Space" |sed -e 's/.*://g' -e 's/(.*//g' |xargs )
    dr_mnt_point=$( echo "$driveinfo" |grep "Mount Point" |sed -e 's/.*://g' -e 's/(.*//g' |xargs )

    _helpDefaultWrite "DRVolName" "$dr_vol_name"
    _helpDefaultWrite "DRPartType" "$dr_part_type"
    _helpDefaultWrite "DRFileSys" "$dr_file_sys"
    _helpDefaultWrite "DRDevLoc" "$dr_dev_loc"
    _helpDefaultWrite "DRTotSpace" "$dr_tot_space"
    _helpDefaultWrite "DRFreeSpace" "$dr_free_space"
    _helpDefaultWrite "DRMntPoint" "$dr_mnt_point"

}

function _start_installer_creation()
{
    targetvolume=$( _helpDefaultRead "DRMntPoint" )
    applicationpath=$( _helpDefaultRead "Applicationpath" )

    if [[ $applicationpath = "" ]]; then
        echo "You did not set an Installer Application. Please select one and try again."
    exit
    fi

    osascript -e 'do shell script "sudo '"'$applicationpath'"''"'/Contents/Resources/createinstallmedia'"' --volume '"'$targetvolume'"' --applicationpath '"'$applicationpath'"' --nointeraction" with administrator privileges'
}

function _abort_installer_creation()
{
    onephasepid=$( _helpDefaultRead "OnePhaseInstallPID" )
    if [ $onephasepid = 1 ]; then
        diskutil unmountDisk force /Volumes/app_install 2> /dev/null
        pkill treeswitcher
    else
        pkill treeswitcher
        osascript -e 'do shell script "sudo pkill createinstallmedia eraseVolume noverify && kill -kill '"'$onephasepid'"'" with administrator privileges'
    fi
}

function _start_onephase_installer()
{

    _helpDefaultWrite "OnePhaseInstallPID" "$$"

    target_volume=$( _helpDefaultRead "DRMntPoint" )
    new_target_volume="macBoot"
    installesd_path=$( find "/Volumes/$volume_name/" -name "*nstall*dmg" |sed 's/\/\//\//g' )
    hdiutil attach "$installesd_path" -noverify -nobrowse -mountpoint /Volumes/install_app

    diskutil eraseVolume JHFS+ "$new_target_volume" "$target_volume"
    #asr restore -source "$download_path/BaseSystem.dmg" -target "/Volumes/$new_target_volume" -noprompt -noverify -erase
    osascript -e 'do shell script "sudo asr restore -source '"'$download_path'"''"'/BaseSystem.dmg'"' -target '"'/Volumes/'"''"'$new_target_volume'"' -noprompt -noverify -erase" with administrator privileges'

    if [ -d "/Volumes/OS X Base System" ]; then
        basedmgdir="OS X Base System"
    else
        basedmgdir="macOS Base System"
    fi

    rm "/Volumes/$basedmgdir/System/Installation/Packages"
    cp -rp /Volumes/install_app/Packages "/Volumes/$basedmgdir/System/Installation/"

    cp -rp "$download_path/BaseSystem.chunklist" "/Volumes/$basedmgdir/BaseSystem.chunklist"
    cp -rp "$download_path/BaseSystem.dmg" "/Volumes/$basedmgdir/BaseSystem.dmg"
    hdiutil detach /Volumes/install_app
    hdiutil detach "/Volumes/$basedmgdir/"

}


function _reset_settings()
{
    tsroot=$( pwd | sed "s/\/Tree.*//g" )
    pid=$( ps |grep Treeswitcher |sed 's/tty.*//g' |xargs )

    echo "rm ~/Library/Preferences/com.slsoft.treeswitcher.plist" > "$temp_path"/tsrestarter
    echo "rm -r ~/Library/Caches/com.slsoft.treeswitcher" >> "$temp_path"/tsrestarter
    echo "kill -term $pid" >> /tmp/kurestarter
    echo "osascript -e 'tell application \"Treeswitcher\" to quit'" >> "$temp_path"/tsrestarter
    echo "sleep 1" >> "$temp_path"/tsrestarter
    echo "open \"$tsroot\"/Treeswitcher.app" >> "$temp_path"/tsrestarter
    echo "rm $temp_path/tsrestarter" >> "$temp_path"/tsrestarter
    bash "$temp_path"/tsrestarter

}

$1



