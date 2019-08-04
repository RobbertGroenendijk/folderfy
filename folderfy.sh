#!/bin/bash

## TEXT FORMATTING VARIABLES ##
BOLD=$(tput bold)
NORMAL=$(tput sgr0)
###############################

## SCRIPT SETUP ##
MY_PATH="`dirname \"$0\"`"
MY_PATH="`( cd \"$MY_PATH\" && pwd )`"
if [ -z "$MY_PATH" ] ; 
then
  # error; for some reason, the path is not accessible
  # to the script (e.g. permissions re-evaled after suid)
  exit 1  # fail
fi

TEMPLATE_PATH="$MY_PATH/.folderfy_templates"
if [ ! -d "$TEMPLATE_PATH" ]
then 
    mkdir ".folderfy_templates"
    MESSAGE="No location to save folderfy templates detected,"
    MESSAGE="${MESSAGE}.folderfy_templates folder has just been constructed at location; \n"
    MESSAGE="${MESSAGE}${MY_PATH} \n"
    MESSAGE="${MESSAGE}If needed this path can be found by using the 'folderfy list' command"
    echo $MESSAGE 
fi
##################

getInput() { # 1:prompt string /// 2:variable to save /// 3:checking function
    read -p "$2" "$1"

    if [ "${!1}" == "list" ] || [ "${!1}" == "List" ] || [ "${!1}" == "LIST" ]
    then
        printList
        getInput "$1" "$2" $3
    else
        if [ "$#" == 3 ]
        then
            $3 "$1" "$2" 
        fi
    fi
}
getConfirm() {
    read -p "$1" $2
    if [ "${!2}" != "Y" ] && [ "${!2}" != "y" ] && [ "${!2}" != "N" ] && [ "${!2}" != "n" ]
    then
        MESSAGE="'${!2}' is not a valid answer.\n"
        MESSAGE="${MESSAGE}Please answer with (Y/N)."
        echo $MESSAGE
        getConfirm "$1" $2 # Restate confirm
    fi
}
printList() {
    echo "Current available Folderfy templates: "
    for file in "$MY_PATH/.folderfy_templates/"*;
    do
        FILENAME=${file##*/}
        echo "- ${FILENAME%.*}"
    done
}
checkTemplates() {
    FOUND_TEMPLATE=false
        for file in "$MY_PATH/.folderfy_templates/"*;
        do
            FILENAME=${file##*/}
            if [ ${FILENAME%.*} == "${!1}" ]
            then
                FOUND_TEMPLATE=true
            fi
        done  

    if [ "$FOUND_TEMPLATE" = true ]
    then
        return 0
    else 
        return 255
    fi
}
checkPath() {
    if [ -z "${!1}" ]
    then
        echo "WARNING: No source path input, please fill in a valid path to a folder."

        if [ "$FLAGUSE" = false ]
        then
            getInput "$1" "$2" checkPath
        fi
    elif [ -f "${!1}" ]
    then
        NEW_DIRECTORY=$(dirname "${!1}")
        echo "WARNING: Path leads to a file."
        echo "The folder containing the file will be taken as path: $NEW_DIRECTORY"

        if [ "$FLAGUSE" = false ]
        then
            getConfirm "Do you want to continue? (Y/N) :" INPUT_CONFIRMATION

            if [ "$INPUT_CONFIRMATION" == "N" ] || [ "$INPUT_CONFIRMATION" == "n" ]
            then
                getInput "$1" "$2" checkPath
            fi 
        fi
    elif [ ! -d "${!1}" ] && [ ! -f "${!1}" ]
    then
        echo "WARNING: ${!1} is not a valid location, please fill in a valid location"

        if [ "$FLAGUSE" = false ]
        then
            getInput "$1" "$2" checkPath
        fi
    fi
}
checkAvailableName() {
    checkTemplates $1
    RETURN_VALUE=$?
    echo $RETURN_VALUE
    if [ "$RETURN_VALUE" -eq 255 ]
    then
        echo "WARNING: Could not find template with name '${!1}'"

        if [ "$FLAGUSE" = true ]
        then
            exit
        elif [ "$FLAGUSE" = false ]
        then
            printList
            getInput $1 "$2" checkAvailableName
        fi
    fi
    
}
checkPossibleName() {
    checkTemplates $1
    RETURN_VALUE=$?

    if [ "$RETURN_VALUE" -eq 0 ]
    then
        echo "WARNING: Template name '${!1}' already in use, please choose a different name."

        if [ "$FLAGUSE" = true ]
        then
            exit
        elif [ "$FLAGUSE" = false ]
        then
            getInput $1 "$2" checkPossibleName
        fi
    fi
}
importTemplate() { # 1:Template name 2:Path to directory
    cd $2
    TEMPLATE_FOLDER=${PWD##*/}
    cd .. ## Create zip in parent directory
    zip -r $1 $TEMPLATE_FOLDER

    cp ${1}.zip "$MY_PATH/.folderfy_templates/"
    rm -rf ${1}.zip
}
deployTemplate() {
    if [ -f "$2" ]
    then
        UNZIP_DIRECTORY=$(dirname "${2}")
    else
        UNZIP_DIRECTORY=$2
    fi
    unzip "$MY_PATH/.folderfy_templates/${1}.zip" -d "$UNZIP_DIRECTORY"
}
renameTemplate() {
    mv "$MY_PATH/.folderfy_templates/${1}.zip" "$MY_PATH/.folderfy_templates/${2}.zip"
    echo "Renamed template folder structure '${1}' >>> to >>> '${2}'."
}
deleteTemplate() {
    rm -rf "$MY_PATH/.folderfy_templates/${1}.zip"
    echo "Deleted template folder structure '${1}'."
}
usageInformation() {
    MESSAGE="${BOLD}Start folderfy by using one of the following arguments\n"
    MESSAGE="${MESSAGE}${NORMAL}- make (-m)\n"
    MESSAGE="${MESSAGE}- add\n"
    MESSAGE="${MESSAGE}- delete\n"
    MESSAGE="${MESSAGE}- update\n"
    MESSAGE="${MESSAGE}- rename\n"
    MESSAGE="${MESSAGE}- list\n"
    MESSAGE="${MESSAGE}By using these no-flag options Folderfy will guide you through the steps by itself."
    MESSAGE="${MESSAGE}Type -f to see Folderfy usage information containing flags."
    echo $MESSAGE
}
flagUsageInformation() {
    MESSAGE="${BOLD}Start folderfy by using one of the following flags\n"
    MESSAGE="${MESSAGE}${NORMAL}MAKE: -m <Template name> -p <Path to construct template>\n"
    MESSAGE="${MESSAGE}ADD: -a <Template name> -p <Path to folder to take as template>\n"
    MESSAGE="${MESSAGE}DELETE: -d <Template name to delete>\n"
    MESSAGE="${MESSAGE}UPDATE: -u <Template name to update> -p <Path to folder to take as template>\n"
    MESSAGE="${MESSAGE}RENAME: -r <Template name to rename> -n <New name for template>\n"
    MESSAGE="${MESSAGE}LIST: -l\n"
    echo $MESSAGE
}
runMake() {
    getInput MAKE_PATH "Path to directory to construct folder structure: " checkPath
    getInput MAKE_NAME "Type name of folder structure template to use (type LIST to see available templates): " checkAvailableName

    deployTemplate $MAKE_NAME "$MAKE_PATH"
}
runAdd() {
    getInput ADD_PATH "Path to directory to save as a template folder structure: " checkPath
    getInput PRESET_NAME "Name for current template folder structure (type LIST to see existing templates): "  checkPossibleName

    importTemplate $PRESET_NAME "$ADD_PATH"
}
runDelete() {
    getInput DELETE_NAME "Type name of template folder structure to delete (type LIST to see available templates): "  checkAvailableName

    getConfirm "Are you sure you want to delete template; '${DELETE_NAME}'? (Y/N) : " INPUT_CONFIRMATION

    if [ "$INPUT_CONFIRMATION" == "Y" ] || [ "$INPUT_CONFIRMATION" == "y" ]
    then
        deleteTemplate $DELETE_NAME
    elif [ "$INPUT_CONFIRMATION" == "N" ] || [ "$INPUT_CONFIRMATION" == "n" ]
    then
        echo "Folderfy will quit due to deleting process being aborted."
        exit
    fi
}
runUpdate() {
    getInput UPDATE_NAME "Type the name of the template folder structure you wish to update (type LIST to see available templates): " checkAvailableName
    getInput UPDATE_PATH "Path to directory you wish to save as an updated version of template '${UPDATE_NAME}': " checkPath

    getConfirm "Are you sure you want to update template; '${UPDATE_NAME}'? (Y/N) : " INPUT_CONFIRMATION

    if [ "$INPUT_CONFIRMATION" == "Y" ] || [ "$INPUT_CONFIRMATION" == "y" ]
    then
        deleteTemplate $UPDATE_NAME
        importTemplate $UPDATE_NAME "$UPDATE_PATH"
    elif [ "$INPUT_CONFIRMATION" == "N" ] || [ "$INPUT_CONFIRMATION" == "n" ]
    then
        echo "Folderfy will quit due to updating process being aborted."
        exit
    fi
}
runRename() {
    getInput RENAME_NAME "Type name of template folder structure to rename (type LIST to see available templates): " checkAvailableName
    getInput NEW_NAME "New name for template folder structure: " 

    getConfirm "Are you sure you want to rename template; '${RENAME_NAME}' to '${NEW_NAME}'? (Y/N) : " INPUT_CONFIRMATION

    if [ "$INPUT_CONFIRMATION" == "Y" ] || [ "$INPUT_CONFIRMATION" == "y" ]
    then
        renameTemplate $RENAME_NAME $NEW_NAME
    elif [ "$INPUT_CONFIRMATION" == "N" ] || [ "$INPUT_CONFIRMATION" == "n" ]
    then
        echo "Folderfy will quit due to renaming process being aborted."
        exit
    fi
}
runList() {
    printList
}

### ENTRY ###
if [ $# -eq 0 ]
then
    echo -e "Please supply an argument. Use -h for usage information, or -f for usage information containing flags."
else
    # Checking variables for flag handling
    makeFlag=false
    addFlag=false
    deleteFlag=false
    updateFlag=false
    renameflag=false
    FLAGCOUNT=0

    while getopts "hflm:a:d:u:r:p:n:" flag; do
    case "$flag" in
        h) usageInformation;;
        f) flagUsageInformation;;
        l) runList;;
        m) makeFlag=true
            fMAKE_NAME=$OPTARG
            FLAGCOUNT=$((FLAGCOUNT + 1));;
        a) addFlag=true
            fADD_NAME=$OPTARG
            FLAGCOUNT=$((FLAGCOUNT + 1));;
        d) deleteFlag=true
            fDELETE_NAME=$OPTARG
            FLAGCOUNT=$((FLAGCOUNT + 1));;
        u) updateFlag=true
            fUPDATE_NAME=$OPTARG
            FLAGCOUNT=$((FLAGCOUNT + 1));;
        r) renameFlag=true
            fRENAME_NAME=$OPTARG
            FLAGCOUNT=$((FLAGCOUNT + 1));;
        p) OPT_PATH=$OPTARG;;
        n) OPT_NEWNAME=$OPTARG;;
    esac
    done
    shift $((OPTIND -1))

    if [ "$FLAGCOUNT" -gt 1 ];
    then
        echo "Only use one job-defining flag (-m -a -d -u -r) at a time."
    elif [ "$makeFlag" = true ] || [ "$addFlag" = true ] ||  [ "$deleteFlag" = true ] || [ "$updateFlag" = true ] || [ "$renameFlag" = true ]
    then
        FLAGUSE=true # Did user use flags to init
        if [ "$makeFlag" = true ]
        then
            checkPath OPT_PATH
            checkAvailableName fMAKE_NAME
            deployTemplate $fMAKE_NAME "$OPT_PATH"
        elif [ "$addFlag" = true ]
        then 
            checkPath OPT_PATH
            checkPossibleName fADD_NAME
            importTemplate $fADD_NAME "$OPT_PATH"
        elif [ "$deleteFlag" = true ]
        then
            checkAvailableName fDELETE_NAME
            deleteTemplate $fDELETE_NAME
        elif [ "$updateFlag" = true ]
        then
            checkPath OPT_PATH
            checkAvailableName fUPDATE_NAME
            deleteTemplate $fUPDATE_NAME
            importTemplate $fUPDATE_NAME "$OPT_PATH"
        elif [ "$renameFlag" = true ]
        then
            checkAvailableName fRENAME_NAME
            checkPossibleName OPT_NEWNAME
            renameTemplate $fRENAME_NAME $OPT_NEWNAME
        fi
    else
        FLAGUSE=false # Did user use flags to init
        JOB=$1

        if [ "$JOB" == "make" ] || [ "$JOB" == "Make" ] || [ "$JOB" == "MAKE" ]
        then
            runMake
        elif [ "$JOB" == "add" ] || [ "$JOB" == "Add" ] || [ "$JOB" == "ADD" ]
        then
            runAdd
        elif [ "$JOB" == "delete" ] || [ "$JOB" == "Delete" ] || [ "$JOB" == "DELETE" ]
        then
            runDelete
        elif [ "$JOB" == "update" ] || [ "$JOB" == "Update" ] || [ "$JOB" == "UPDATE" ]
        then
            runUpdate
        elif [ "$JOB" == "rename" ] || [ "$JOB" == "Rename" ] || [ "$JOB" == "RENAME" ]
        then
            runRename
        elif [ "$JOB" == "list" ] || [ "$JOB" == "List" ] || [ "$JOB" == "LIST" ]
        then
            runList
        fi
    fi
fi

