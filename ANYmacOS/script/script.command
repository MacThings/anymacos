#!/bin/bash
#
#

ScriptHome=$(echo $HOME)
MY_PATH="`dirname \"$0\"`"
cd "$MY_PATH"
user=$( id -un )

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

if [ ! -d /private/tmp/anymacos ]; then
    mkdir /private/tmp/anymacos
fi

write_log=$( _helpDefaultRead "WriteLog" )

if [ "$write_log" = "1" ]; then
    exec 1>> "$HOME"/Desktop/anymacos.txt 2>&1
    set -x
fi

sys_language=$( defaults read -g AppleLocale )
download_path=$( _helpDefaultRead "Downloadpath" )
temp_path="/private/tmp/anymacos_$user"


hwspecs=$( system_profiler SPHardwareDataType )
osversion=$( sw_vers | grep ProductVersion | cut -d':' -f2 | xargs )
osbuild=$( sw_vers |tail -n1 | sed "s/.*://g" | xargs )

_helpDefaultWrite "OSVersion" "$osversion"
_helpDefaultWrite "OSBuild" "$osbuild"

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

function _check_user()
{
############ Prüft ob der User Adminrechte hat und das Passwort korrekt ist
    if [[ "$syslang" = "en" ]]; then
        string="The user you are currently logged in with does not have administrative rights. Please enter a user who has these rights."
    else
        string="Der User mit dem Du gerade angemeldet bist hat keine Administrativen Rechte. Bitte gib nun einen User an der diese Rechte hat."
    fi
    groups "$user" | grep -q -w admin
    if [ $? = 1 ]; then
        user=$(osascript -e "display dialog \"$string\" default answer \"$user\"" -e 'text returned of result')
    fi
######
    if [[ "$syslang" = "en" ]]; then
        string="Please enter your user password."
    else
        string="Gib hier Dein Benutzer-Passwort ein."
    fi
    password=$(osascript -e "display dialog \"$string\" default answer \"\" with hidden answer" -e 'text returned of result')
    if [[ "$syslang" = "en" ]]; then
        string="You have not entered a password! Try again."
    else
        string="Du hast kein Passwort eingegeben! Versuche es noch einmal."
    fi
    if [ ! -n "$password" ]; then
        osascript -e "display dialog \"$string\" buttons {\"OK\"}"
        exit 1
    fi
######
    if [[ "$syslang" = "en" ]]; then
        string="The user you are currently logged in with does not have administrative rights. Try again."
    else
        string="Der User mit dem Du gerade angemeldet bist hat keine Administrativen Rechte. Versuche es noch einmal."
    fi
    groups "$user" | grep -q -w admin
    if [ $? = 1 ]; then
        osascript -e "display dialog \"$string\" buttons {\"OK\"}"
        exit 1
    fi
######
    if [[ "$syslang" = "en" ]]; then
        string="The password you entered is not correct. Try again.."
    else
        string="Das eingegebene Password ist nicht korrekt. Versuche es noch einmal."
    fi
    
    dscl . auth "$user" "$password"
    
    if [ $? != 0 ]; then
        osascript -e "display dialog \"$string\" buttons {\"OK\"}"
        exit 1
    fi
####################################################################################

}

function _initial()
{
    if [ -d "$temp_path" ]; then
        rm "$temp_path"/*
    fi
}

function _get_selection()
{

    if [ -f "$temp_path"/selection ]; then
        rm "$temp_path"/selection
    fi
    
    ../bin/./aria2c https://www.sl-soft.de/extern/software/anymacos/seeds/selection -d "$temp_path"

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

    _check_user
    
    image_node=$( diskutil list Install-App | grep "disk image" | sed 's/\ .*//g' )
    osascript -e 'do shell script "sudo diskutil unmountDisk force '"'$image_node'"'" user name "'"$user"'" password "'"$password"'" with administrator privileges'
        
    image_node=$( diskutil list "Shared Support" | grep "disk image" | sed 's/\ .*//g' )
    osascript -e 'do shell script "sudo diskutil unmountDisk force '"'$image_node'"'" user name "'"$user"'" password "'"$password"'" with administrator privileges'
    
    _download_counter &
    
    choice=$( _helpDefaultRead "Choice" )
    parallel_downloads=$( _helpDefaultRead "ParaDL" )
    download_path=$( _helpDefaultRead "Downloadpath" )

    if [ ! -d "$download_path" ]; then
        mkdir "$download_path"
    fi
    
    if [ -f  "$download_path"/English.dist ]; then
        rm "$download_path"/English.dist
    fi
    
    rm "$temp_path"/files

    ../bin/./aria2c https://www.sl-soft.de/extern/software/anymacos/seeds/"$choice" -d "$temp_path" -o files

    cat "$temp_path"/files | grep -v "\.pkm" |grep -v "\.smd" |grep -v "\.msmd"|grep -v "\.mpkm" |grep -v "\.chunklist"| grep -v "\.dmg" | grep -v "\.plist"| grep -v "\.mpkg"| grep -v "MajorOSInfo.pkg"| grep -v "UpdateBrain.zip" > "$temp_path"/files2
    rm "$temp_path"/files
    mv "$temp_path"/files2 "$temp_path"/files

    touch "$download_path"/.anymacos_download
    while IFS= read -r line
    do
    kill_download=$( _helpDefaultRead "KillDL" )
    if [[ $kill_download = 1 ]]; then
        if [[ "$syslang" = "en" ]]; then
        string="Downloading aborted"
            else
        string="Download abgebrochen"
        fi

        _helpDefaultWrite "Statustext" "$string"

        exit
    fi

    checker=$( /usr/bin/curl -k -s -L -I "$line" )
    if [[ $checker != *"ength: 0"* ]] || [[ "$line" != *".smd" ]] || [[ "$line" != *".pkm" ]]; then
        line_progress=$( echo "$line" | sed 's/.*\///g' )

        if [[ "$syslang" = "en" ]]; then
        string="Downloading ..."
            else
        string="Dateitransfer ..."
        fi
        
        _helpDefaultWrite "Statustext" "$string"

        echo "$line_progress" >> "$download_path"/.anymacos_download
    
        dl_size=$( /usr/bin/curl -k -s -L -I "$line" | grep "ength:" | sed 's/.*th://g' | xargs | awk '{ byte =$1 /1024/1024; print byte " MB" }' | awk '{printf "%.0f\n", $1}' )
        if [[ "$dl_size" = "0" ]]; then
            dl_size=""
        fi
        _helpDefaultWrite "DLSize" "$dl_size"
        _helpDefaultWrite "DLFile" "$line_progress"
        
        killed=$( _helpDefaultRead "KillDL" )
        if [[ "$killed" != "1" ]]; then
            ../bin/./aria2c --file-allocation=none -c -q -x "$parallel_downloads" -d "$download_path" "$line"
        else
            exit
        fi
    fi
        
done < ""$temp_path"/files"

    _helpDefaultWrite "DLFile" ""

    echo English.dist >> "$download_path"/.anymacos_download
    cat "$download_path"/.anymacos_download | uniq > "$download_path"/.anymacos_download2
    rm "$download_path"/.anymacos_download
    mv "$download_path"/.anymacos_download2 "$download_path"/.anymacos_download

    kill_download=$( _helpDefaultRead "KillDL" )
    _helpDefaultWrite "Stop" "Yes"
    if [[ $kill_download = 1 ]]; then
        if [[ "$syslang" = "en" ]]; then
        string="Downloading aborted"
            else
        string="Download abgebrochen"
        fi
    
        _helpDefaultWrite "Statustext" "$string"

        exit
    fi

    if [[ "$syslang" = "en" ]]; then
        string="Creating Installer-Application ..."
    else
        string="Erzeuge Installer-Applikation ..."
    fi
    
    _helpDefaultWrite "Statustext" "$string"


    kill_download=$( _helpDefaultRead "KillDL" )
    if [[ $kill_download = 1 ]]; then
        _helpDefaultWrite "Stop" "Yes"
        if [[ "$syslang" = "en" ]]; then
        string="Downloading aborted"
            else
        string="Download abgebrochen"
        fi
    
        _helpDefaultWrite "Statustext" "$string"
        
        exit
    fi
    
    
        image_node=$( diskutil list Install-App | grep "disk image" | sed 's/\ .*//g' )
        osascript -e 'do shell script "sudo diskutil unmountDisk force '"'$image_node'"'" user name "'"$user"'" password "'"$password"'" with administrator privileges'
            
        image_node=$( diskutil list "Shared Support" | grep "disk image" | sed 's/\ .*//g' )
        osascript -e 'do shell script "sudo diskutil unmountDisk force '"'$image_node'"'" user name "'"$user"'" password "'"$password"'" with administrator privileges'
        
        unzip -o ../Install-App.zip -d "$download_path"
        open "$download_path"/Install-App.sparseimage
        
        sleep 3

        if [ -d /Volumes/Install-AppApplications ]; then
            osascript -e 'do shell script "sudo rm -r /Volumes/Install-AppApplications" user name "'"$user"'" password "'"$password"'" with administrator privileges'
        fi
    
        if [ -f "$download_path/InstallAssistant.pkg" ]; then
                osascript -e 'do shell script "sudo /usr/sbin/installer -pkg '"'$download_path'"'/InstallAssistant.pkg -target /Volumes/Install-App/" user name "'"$user"'" password "'"$password"'" with administrator privileges'
                installok="$?"
        else
            sed '/installation-check/d' "$download_path"/*English.dist > "$download_path"/English.dist
                osascript -e 'do shell script "sudo /usr/sbin/installer -pkg '"'$download_path'"'/English.dist -target /Volumes/Install-App/" user name "'"$user"'" password "'"$password"'" with administrator privileges'
                installok="$?"
        fi
    
        if [[ "$installok" = "0" ]]; then

            osascript -e 'do shell script "sudo mv /Volumes/Install-AppApplications/Install*.app/Contents/SharedSupport /Volumes/Install-App/Applications/Install*/Contents/" user name "'"$user"'" password "'"$password"'" with administrator privileges'
            osascript -e 'do shell script "sudo rm -r /Volumes/Install-AppApplications" user name "'"$user"'" password "'"$password"'" with administrator privileges'
            mv /Volumes/Install-App/Applications/Install*.app /Volumes/Install-App/
            rm -r /Volumes/Install-App/Library /Volumes/Install-App/Applications

            _helpDefaultWrite "InstallerAppDone" "Yes"
            if [[ "$syslang" = "en" ]]; then
                string="Done"
            else
                string="Fertig"
            fi
    
            _helpDefaultWrite "Statustext" "$string"
        else
            _helpDefaultWrite "InstallerAppDone" "No"
            
            
            if [[ "$syslang" = "en" ]]; then
                string="Creation failed! Please try again."
            else
                string="Erstellung fehlgeschlagen. Bitte versuche es erneut."
            fi
    
            _helpDefaultWrite "Statustext" "$string"

        fi
        
        image_node=$( diskutil list "Shared Support" | grep "disk image" | sed 's/\ .*//g' )
        osascript -e 'do shell script "sudo diskutil unmountDisk force '"'$image_node'"'" user name "'"$user"'" password "'"$password"'" with administrator privileges'
    exit
}


function _remove_downloads()
{

 if [ -f "$download_path"/.anymacos_download ]; then
        
        pkill -f aria2c
        
        if [[ "$syslang" = "en" ]]; then
            string="Cleaning Downloadfolder"
        else
            string="Bereinige Downloadordner"
        fi
        
        _helpDefaultWrite "Statustext" "$string"
        
        
        while IFS= read -r line
        do
            rm "$download_path"/"$line" 2> /dev/null
        done < ""$download_path"/.anymacos_download"
        rm "$download_path"/English.dist "$download_path"/*English.dist "$download_path"/InstallAssistant.pkg 2> /dev/null
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
        string="Done"
    else
        string="Fertig"
    fi
    
    _helpDefaultWrite "Statustext" "$string"
    
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

    if [ ! -f "$applicationpath/Contents/MacOS/InstallAssistant" ]; then
        _helpDefaultWrite "AppValid" "No"
        if [[ "$syslang" = "en" ]]; then
            echo -e "\n🚫 You selected a non valid Application! 🚫 Please choose another one."
        else
            echo -e "\n🚫 Die gewählte Applikation ist nicht gültig! 🚫 Bitte wähle eine Andere."
        fi
    else
        _helpDefaultWrite "AppValid" "Yes"
        if [[ "$syslang" = "en" ]]; then
            echo -e "\nYour App seems to be valid. 👍🏼 Let´s go and press \"Start\"."
        else
            echo -e "\nDie gewählte Applikation scheint gültig zu sein. 👍🏼 Dann lass uns loslegen und drücke auf \"Start\"."
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
        string="Please enter your Root Password to start the Process."
    else
        string="Bitte gib Dein Rootpasswort ein um den Prozess zu starten."
    fi
    
    _helpDefaultWrite "Statustext" "$string"

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



