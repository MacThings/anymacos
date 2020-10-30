#!/bin/bash

ScriptHome=$(echo $HOME)
MY_PATH="`dirname \"$0\"`"
cd "$MY_PATH"
cd ../bin

function _download_counter()
{
    ./treeswitcher _download_counter
}

function _initial()
{
    ./treeswitcher _initial
}

function _check_seed()
{
    ./treeswitcher _check_seed
}

function _select_macos()
{
    ./treeswitcher _select_macos
}

function _setseed()
{
    ./treeswitcher _setseed
}

function _download_macos()
{
    ./treeswitcher _download_macos
}

function _kill_aria()
{
    ./treeswitcher _kill_aria
    for KILLPID in `ps ax | grep 'aria' | awk ' { print $1;}'`; do
        kill -term $KILLPID;
    done
}

function _get_drives()
{
    ./treeswitcher _get_drives
}

function _get_drive_info()
{
    ./treeswitcher _get_drive_info
}

function _check_if_valid()
{
    ./treeswitcher _check_if_valid
}

function _start_installer_creation()
{
   ./treeswitcher _start_installer_creation
}

function _abort_installer_creation()
{
   ./treeswitcher _abort_installer_creation
}

function _start_onephase_installer()
{
    ./treeswitcher _start_onephase_installer
}

function _remove_downloads()
{
    ./treeswitcher _remove_downloads
}

$1
