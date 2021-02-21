#!/bin/bash

function _helpDefaultWrite()
{
    VAL=$1
    local VAL1=$2

    if [ ! -z "$VAL" ] || [ ! -z "$VAL1" ]; then
        defaults write "${ScriptHome}/Library/Preferences/anymacos.slsoft.de.plist" "$VAL" "$VAL1"
    fi
}

function _helpDefaultRead()
{
    VAL=$1

    if [ ! -z "$VAL" ]; then
        defaults read "${ScriptHome}/Library/Preferences/anymacos.slsoft.de.plist" "$VAL"
    fi
}


function _helpDefaultDelete()
{
    VAL=$1

    if [ ! -z "$VAL" ]; then
        defaults delete "${ScriptHome}/Library/Preferences/anymacos.slsoft.de.plist" "$VAL"
    fi
}

function _check_arch
{

    check_arch=$( sysctl -a | grep hw.optional | grep "x86_64" )
    if [[ "$check_arch" = "" ]]; then
        _helpDefaultWrite "Arch" "Apple"
    else
        _helpDefaultWrite "Arch" "Intel"
    fi

}

function _check_sip
{
    sipcheck1=$( csrutil status | grep "Kext Signing" | sed "s/.*\://g" | xargs )
    sipcheck2=$( csrutil status | grep "System Integrity Protection status" | sed -e "s/.*\://g" -e "s/\ (.*//g" -e "s/\.//g" | xargs )
    if [[ $sipcheck1 = "disabled" ]]; then
        sipcheck="disabled"
    elif [[ $sipcheck2 = "disabled" ]]; then
        sipcheck="disabled"
    fi

    if [[ $sipcheck != "disabled" ]]; then
        _helpDefaultWrite "SIP" "On"
    else
        _helpDefaultWrite "SIP" "Off"
    fi
}

ScriptHome=$(echo $HOME)
MY_PATH="`dirname \"$0\"`"
cd "$MY_PATH"

if [ ! -d /private/tmp/anymacos ]; then
    mkdir /private/tmp/anymacos
fi

_check_sip

sys_language=$( defaults read -g AppleLocale )
download_path=$( _helpDefaultRead "Downloadpath" )
temp_path="/private/tmp/anymacos"
seed_choice=$( _helpDefaultRead "CurrentSeed" )
#seedcatalog_path="/System/Library/PrivateFrameworks/Seeding.framework/Versions/Current/Resources/SeedCatalogs.plist"

hwspecs=$( system_profiler SPHardwareDataType )
osversion=$( sw_vers | grep ProductVersion | cut -d':' -f2 | xargs )
osbuild=$( sw_vers |tail -n1 | sed "s/.*://g" | xargs )
#modelname=$( echo -e "$hwspecs" | grep "Model Name:" | sed "s/.*://g" | xargs )
#modelid=$( echo -e "$hwspecs" | grep "Model Identifier:" | sed "s/.*://g" | xargs )
#cputype=$( echo -e "$hwspecs" | grep "Processor Name:" | sed "s/.*://g" | xargs )

_helpDefaultWrite "OSVersion" "$osversion"
_helpDefaultWrite "OSBuild" "$osbuild"
#_helpDefaultWrite "Modelname" "$modelname"
#_helpDefaultWrite "ModelID" "$modelid"
#_helpDefaultWrite "CPUType" "$cputype"

_helpDefaultWrite "KillDL" "0"

if [[ $sys_language = de* ]]; then
    syslang="de"
    _helpDefaultWrite "Language" "de"
else
    syslang="en"
    _helpDefaultWrite "Language" "en"
fi

#========================= Language Detection =========================#
function _languageselect()
{
    if [[ $lan2 = de* ]]; then
    export LC_ALL=de_DE
    language="de"
    else
    export LC_ALL=en_EN
    language="en"
    fi
    if [ ! -d "$temp_path" ]; then
        mkdir "$temp_path"
    fi
    cat ../bashstrings/$language.bashstrings > ${temp_path}/locale.tmp
    source ${temp_path}/locale.tmp
}


function _initial()
{
    if [ -d "$temp_path" ]; then
        rm "$temp_path"/*  2> /dev/null
    fi
}

function _check_seed()
{

    seed=$( _helpDefaultRead "CurrentSeed" )
    if [[ $seed = "" ]]; then
        seed=$( osascript -e 'do shell script "sudo /System/Library/PrivateFrameworks/Seeding.framework/Resources/seedutil current |grep \"Currently enrolled in\" |sed \"s/.*: //g\"" with administrator privileges' )
    fi

    if [[ $seed = *null* ]]; then
        _helpDefaultWrite "CurrentSeed" "Unenroll"
    else
        if [[ $seed != "" ]]; then
            _helpDefaultWrite "CurrentSeed" "$seed"
        fi
    fi
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
    
    _helpDefaultDelete "NewSeed"
}

function _select_seed_all()
{
    mkdir "$temp_path" 2> /dev/null
    curl https://www.sl-soft.de/extern/software/anymacos/seeds/selection > "$temp_path"/selection
    _helpDefaultWrite "Statustext" "$statustext"
}

function _select_seed_customer()
{
    mkdir "$temp_path" 2> /dev/null
    curl https://www.sl-soft.de/extern/software/anymacos/seeds/selection_customerseed > "$temp_path"/selection
    _helpDefaultWrite "Statustext" "$statustext"
}

function _select_seed_developer()
{
    mkdir "$temp_path" 2> /dev/null
    curl https://www.sl-soft.de/extern/software/anymacos/seeds/selection_beta > "$temp_path"/selection
    _helpDefaultWrite "Statustext" "$statustext"
}

function _select_seed_public()
{
    mkdir "$temp_path" 2> /dev/null
    curl https://www.sl-soft.de/extern/software/anymacos/seeds/selection_seed > "$temp_path"/selection
    _helpDefaultWrite "Statustext" "$statustext"
}

function _download_counter()
{
        TAB=$(printf '\t')
       
        until [[ $stop_loop = "1" ]]
        do
            stop_it=$( _helpDefaultRead "Stop" )
            if [[ "$stop_it" = "Yes" ]]; then
                stop_loop="1"
            fi
            file_downloading=$( _helpDefaultRead "DLFile" )
            file_done=$( du -hm "$download_path"/"$file_downloading" | sed "s/${TAB}.*//g" |xargs )
            if [[ "$file_done" = "0" ]]; then
                file_done=""
            fi
            filesize=$( _helpDefaultRead "DLSize" )
            if [[ "$file_done" -gt "$filesize" ]]; then
                file_done="$filesize"
            fi
            _helpDefaultWrite "DLDone" "$file_done"
            percent=$( echo $(( file_done*100/filesize )) )
            if [[ "$percent" -gt "100" ]]; then
                percent="100"
            fi
            _helpDefaultWrite "DLProgress" "$percent"

            sleep 0.5
done
}

function _download_macos()
{
    _download_counter &
    
    sip_status=$( _helpDefaultRead "SIP" )
    choice=$( _helpDefaultRead "Choice" )
    arch=$( _helpDefaultRead "Arch" )
    parallel_downloads=$( _helpDefaultRead "ParaDL" )
    download_path=$( _helpDefaultRead "Downloadpath" )

    if [ ! -d "$download_path" ]; then
        mkdir "$download_path"
    fi
    
    rm "$temp_path"/files
    
    curl https://www.sl-soft.de/extern/software/anymacos/seeds/"$choice" > "$temp_path"/files

    touch "$download_path"/.anymacos_download
    while IFS= read -r line
    do
    kill_download=$( _helpDefaultRead "KillDL" )
    if [[ $kill_download = 1 ]]; then
        if [[ "$syslang" = "en" ]]; then
            _helpDefaultWrite "Statustext" "Downloading aborted"
        else
            _helpDefaultWrite "Statustext" "Download abgebrochen"
        fi
        exit
    fi

    checker=$( /usr/bin/curl -s -L -I "$line" )
    if [[ $checker != *"ength: 0"* ]]; then
        line_progress=$( echo "$line" | sed 's/.*\///g' )
        if [[ "$syslang" = "en" ]]; then
            _helpDefaultWrite "Statustext" "Downloading ..."
        else
            _helpDefaultWrite "Statustext" "Dateitransfer ..."
        fi
        echo "$line_progress" >> "$download_path"/.anymacos_download
    
        dl_size=$( /usr/bin/curl -s -L -I "$line" | grep "ength:" | sed 's/.*th://g' | xargs | awk '{ byte =$1 /1024/1024; print byte " MB" }' | awk '{printf "%.0f\n", $1}' )
        if [[ "$dl_size" = "0" ]]; then
            dl_size=""
        fi
        _helpDefaultWrite "DLSize" "$dl_size"
        _helpDefaultWrite "DLFile" "$line_progress"
        
        killed=$( _helpDefaultRead "KillDL" )
        if [[ "$killed" != "1" ]]; then
            if [[ "$arch" = "Intel" ]]; then
                ../bin/./aria2c --file-allocation=none -c -q -x "$parallel_downloads" -d "$download_path" "$line"
            else
                ../bin/./aria2c_arm64 --file-allocation=none -c -q -x "$parallel_downloads" -d "$download_path" "$line"
            fi
        else
            exit
        fi
    fi
    
        
done < ""$temp_path"/files"

    echo English.dist >> "$download_path"/.anymacos_download

    kill_download=$( _helpDefaultRead "KillDL" )
    _helpDefaultWrite "Stop" "Yes"
    if [[ $kill_download = 1 ]]; then
        if [[ "$syslang" = "en" ]]; then
            _helpDefaultWrite "Statustext" "Downloading aborted"
        else
            _helpDefaultWrite "Statustext" "Download abgebrochen"
        fi
        exit
    fi

    if [[ "$sip_status" = "Off" ]]; then
        if [[ "$syslang" = "en" ]]; then
            _helpDefaultWrite "Statustext" "Creating Installer-Application ..."
        else
            _helpDefaultWrite "Statustext" "Erzeuge Installer-Application ..."
        fi
    fi

    kill_download=$( _helpDefaultRead "KillDL" )
    if [[ $kill_download = 1 ]]; then
        _helpDefaultWrite "Stop" "Yes"
        if [[ "$syslang" = "en" ]]; then
            _helpDefaultWrite "Statustext" "Downloading aborted"
        else
            _helpDefaultWrite "Statustext" "Download abgebrochen"
        fi
        exit
    fi
    
    ### Checks if BigSur is downloading ###
    
    #if [[ "$sip_status" = "Off" ]]; then
        if [ -f "$download_path/InstallAssistant.pkg" ]; then
            if [[ "$sip_status" = "Off" ]]; then
                osascript -e 'do shell script "sudo /usr/sbin/installer -pkg '"'$download_path'"'/InstallAssistant.pkg -target /" with administrator privileges'
                installok="$?"
                
            else
                open "$download_path"/InstallAssistant.pkg
                BACK_PID=$( pgrep "Installer" )
                while kill -0 $BACK_PID ; do
                    sleep 1
                done
                installok="$?"
            fi
        else
            sed '/installation-check/d' "$download_path"/*English.dist > "$download_path"/English.dist
            if [[ "$sip_status" = "Off" ]]; then
                osascript -e 'do shell script "sudo /usr/sbin/installer -pkg '"'$download_path'"'/English.dist -target /" with administrator privileges'
                installok="$?"
            fi
        fi
    
        if [[ "$installok" = "0" ]]; then
                _helpDefaultWrite "InstallerAppDone" "Yes"
            if [[ "$syslang" = "en" ]]; then
                _helpDefaultWrite "Statustext" "Done"
            else
                _helpDefaultWrite "Statustext" "Fertig"
            fi
        else
            _helpDefaultWrite "InstallerAppDone" "No"
            if [[ "$syslang" = "en" ]]; then
                _helpDefaultWrite "Statustext" "Creation failed! Please try again."
            else
                _helpDefaultWrite "Statustext" "Erstellung fehlgeschlagen. Bitte versuche es erneut."
            fi
        fi
    #fi
    exit
}


function _remove_downloads()
{

 if [ -f "$download_path"/.anymacos_download ]; then
        if [[ "$syslang" = "en" ]]; then
            _helpDefaultWrite "Statustext" "Cleaning Downloadfolder"
        else
            _helpDefaultWrite "Statustext" "Bereinige Downloadordner"
        fi
        while IFS= read -r line
        do
            rm "$download_path"/"$line" 2> /dev/null
        done < ""$download_path"/.anymacos_download"
        rm "$download_path"/*English.dist "$download_path"/InstallAssistant.pkg 2> /dev/null
        rm "$download_path"/*.aria2 2> /dev/null
        rm "$download_path"/.anymacos_download
        
    fi

}

function _remove_temp()
{

    rm -f /private/tmp/anymacos/files

}
function _kill_aria()
{


    
# for KILLPID in `ps ax | grep 'script.command _download_os' | awk ' { print $1;}'`; do
#        kill -term $KILLPID;
#    done
    if [[ "$syslang" = "en" ]]; then
        _helpDefaultWrite "Statustext" "Done"
    else
        _helpDefaultWrite "Statustext" "Fertig"
    fi
    
    bash kill.command &

    exit



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
    cat "$temp_path"/volumes2 |grep -v "install_app" > "$temp_path"/volumes

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

function _check_if_valid()
{

    applicationpath=$( _helpDefaultRead "Applicationpath" )

    if [[ "$syslang" = "en" ]]; then
        echo -e "Checking if your Application is valid ...\n"
    else
        echo -e "Es wird geprüft ob die gewählte Applikation gültig ist ...\n"
    fi

    if [ ! -f "$applicationpath/Contents/Info.plist" ]; then
        _helpDefaultWrite "AppValid" "No"
        if [[ "$syslang" = "en" ]]; then
            echo "You selected a non valid Application! ☝🏼 Please choose another one."
        else
            echo "Die gewählte Applikation ist nicht gültig! ☝🏼 Bitte wähle eine Andere."
        fi
    else
        _helpDefaultWrite "AppValid" "Yes"
        if [[ "$syslang" = "en" ]]; then
            echo "Your App seems to be valid. 👍🏼 Let´s go and press \"Start\"."
        else
            echo "Die gewählte Applikation scheint gültig zu sein. 👍🏼 Dann lass uns loslegen und drücke auf \"Start\"."
        fi
    fi

}

function _start_installer_creation()
{
    targetvolume=$( _helpDefaultRead "DRMntPoint" )
    targetvolumename=$( echo "$targetvolume" |sed 's/.*\///g' )
    applicationpath=$( _helpDefaultRead "Applicationpath" )

    if [[ $applicationpath = "" ]]; then
        if [[ "$syslang" = "en" ]]; then
            echo "You did not set an Installer Application. Please select one and try again."
        else
            echo "Es wurde noch keine Installer Applikation ausgewählt. Bitte wähle eine aus und versuche es erneut."
        fi
        exit
    fi

    if [[ "$syslang" = "en" ]]; then
        _helpDefaultWrite "Statustext" "Please enter your Root Password to start the Process."
    else
        _helpDefaultWrite "Statustext" "Bitte gib Dein Rootpasswort ein um den Prozess zu starten."
    fi

    diskutil eraseVolume JHFS+ "$targetvolumename" "$targetvolume"

    osascript -e 'do shell script "sudo '"'$applicationpath'"''"'/Contents/Resources/createinstallmedia'"' --volume '"'$targetvolume'"' --applicationpath '"'$applicationpath'"' --nointeraction" with administrator privileges'
}

function _abort_installer_creation()
{
        pkill  -f anymacos
        exit
        osascript -e 'do shell script "sudo pkill createinstallmedia eraseVolume noverify && kill -kill '"'$onephasepid'"'" with administrator privileges'
}

function _open_utilities()
{
    open -a "/System/Applications/Utilities/Disk Utility.app/Contents/MacOS/Disk Utility"
    if [[ "$?" != "0" ]]; then
        open -a "/Applications/Utilities/Disk Utility.app/Contents/MacOS/Disk Utility"
    fi
}

$1



