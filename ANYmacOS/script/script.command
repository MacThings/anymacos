#!/bin/bash

ScriptHome=$(echo $HOME)
MY_PATH="`dirname \"$0\"`"
cd "$MY_PATH"
cd ../bin

function _download_counter()
{
    ./anymacos _download_counter
}

function _initial()
{
    ./anymacos _initial
}

function _remove_temp()
{
    ./anymacos _remove_temp
}

function _check_seed()
{
    ./anymacos _check_seed
}

function _select_seed_all()
{
    ./anymacos _select_seed_all
}

function _select_seed_customer()
{
    ./anymacos _select_seed_customer
}

function _select_seed_developer()
{
    ./anymacos _select_seed_developer
}

function _select_seed_public()
{
    ./anymacos _select_seed_public
}

function _setseed()
{
    ./anymacos _setseed
}

function _download_macos()
{
    ./anymacos _download_macos
}

function _kill_aria()
{
    ./anymacos _kill_aria
    for KILLPID in `ps ax | grep 'aria' | awk ' { print $1;}'`; do
        kill -term $KILLPID;
    done
}

function _get_drives()
{
    ./anymacos _get_drives
}

function _get_drive_info()
{
    ./anymacos _get_drive_info
}

function _check_if_valid()
{
    ./anymacos _check_if_valid
}

function _start_installer_creation()
{
   ./anymacos _start_installer_creation
}

function _abort_installer_creation()
{
   ./anymacos _abort_installer_creation
}

function _start_onephase_installer()
{
    ./anymacos _start_onephase_installer
}

function _remove_downloads()
{
    ./anymacos _remove_downloads &
}

function _open_utilities()
{
    ./anymacos _open_utilities
}

$1
