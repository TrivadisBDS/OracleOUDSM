#!/bin/bash
# ----------------------------------------------------------------------
# Trivadis AG, Infrastructure Managed Services
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# ----------------------------------------------------------------------
# Name.......: install_database.sh 
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2017.12.04
# Revision...: 
# Purpose....: Helper script to install Oracle database binaries 
# Notes......: tbd.
# Reference..: --
# License....: Licensed under the Universal Permissive License v 1.0 as 
#              shown at http://oss.oracle.com/licenses/upl.
# ----------------------------------------------------------------------
# Modified...:
# see git revision history for more information on changes/updates
# ----------------------------------------------------------------------

# - Environment Variables ----------------------------------------------
# - Set default values for environment variables if not yet defined. 
# ----------------------------------------------------------------------
# OUD Software and Patchs
DEFAULT_FMW_OUD_PKG="p26270957_122130_Generic.zip"
DEFAULT_FMW_PKG="p26269885_122130_Generic.zip"
DEFAULT_WLS_PATCH=""
DEFAULT_OUD_PATCH=""
ORACLE_HOME=${ORACLE_BASE}/product/${ORACLE_HOME_NAME}
ORAREPO=${ORAREPO:-"orarepo"}
# - EOF Environment Variables -------------------------------------------

# Get the package and psu's from cli
FMW_OUD_PKG=${1:-${DEFAULT_FMW_OUD_PKG}}
FMW_OUD_PKG_LOG=$(basename ${FMW_OUD_PKG} .zip).log
FMW_PKG=${2:-${DEFAULT_FMW_PKG}}
FMW_PKG_LOG=$(basename ${FMW_PKG} .zip).log
WLS_PATCH=${3:-${DEFAULT_WLS_PATCH}}
OUD_PATCH=${4:-${DEFAULT_OUD_PATCH}}
SLIM=${5:-"FALSE"}

# - Install FMW / Weblogic binaries -------------------------------------
# Get the oracle binaries if they are not there yet  orarepo
if [ ! -s "${DOWNLOAD}/${FMW_PKG}" ]; then
    echo "download ${DOWNLOAD}/${FMW_PKG} from orarepo"
    curl -f http://${ORAREPO}/${FMW_PKG} -o ${DOWNLOAD}/${FMW_PKG}
else 
    echo "use local copy of ${DOWNLOAD}/${FMW_PKG}"
fi

# unpack OUD binary package
cd ${DOWNLOAD}
$JAVA_HOME/bin/jar xvf ${FMW_PKG} >${FMW_PKG_LOG}

if [ $? -ne 0 ]; then
    echo "unable to extract file ${FMW_PKG}"
    exit 1
fi

# the jar file name from the logfile
FMW_JAR=$(grep -i jar ${FMW_PKG_LOG} |cut -d' ' -f3| tr -d " ")

# Install FMW / Weblogic binaries
$JAVA_HOME/bin/java -jar ${DOWNLOAD}/${FMW_JAR} -silent \
        -responseFile ${DOWNLOAD}/install.rsp \
        -invPtrLoc ${DOWNLOAD}/oraInst.loc \
        -ignoreSysPrereqs -force \
        -novalidation ORACLE_HOME=${ORACLE_HOME} \
        INSTALL_TYPE="WebLogic Server"

# clean up
rm -rf ${DOWNLOAD}/${FMW_PKG} \
       ${DOWNLOAD}/${FMW_PKG_LOG} \
       ${DOWNLOAD}/${FMW_JAR}

# - Install WLS Patch / PSU --------------------------------------------
if [ -n ${WLS_PATCH} ]; then
    for i in $(echo "${WLS_PATCH}"|sed s/\,/\ /g); do
        WLS_PSU=${i}
        WLS_PSU_ID=$(echo $WLS_PSU| sed -E 's/p([[:digit:]]+).*/\1/')
        echo "Install WLS Patch / PSU ${WLS_PSU_ID}"
        # Get the latest database RU if it is not there yet
        if [ ! -s "${DOWNLOAD}/${WLS_PSU}" ]; then
            echo "download ${DOWNLOAD}/${WLS_PSU} from orarepo"
            curl -f http://${ORAREPO}/${WLS_PSU} -o ${DOWNLOAD}/${WLS_PSU}
        else
            echo "use local copy of ${DOWNLOAD}/${WLS_PSU}"
        fi

        # unzip WLS PSU
        cd ${DOWNLOAD}
        $JAVA_HOME/bin/jar xvf ${WLS_PSU}

        # install WLS PSU
        cd ${WLS_PSU_ID}
        ${ORACLE_HOME}/OPatch/opatch apply -silent

        # clean up
        rm -rf ${DOWNLOAD}/${WLS_PSU} \
               ${DOWNLOAD}/${WLS_PSU_ID}
    done
else
    echo "No Weblogic Patch / PSU specified"
fi

# - Install OUD binaries -----------------------------------------------
# Get the oracle binaries if they are not there yet  orarepo
if [ ! -s "${DOWNLOAD}/${FMW_OUD_PKG}" ]; then
    echo "download ${DOWNLOAD}/${FMW_OUD_PKG} from orarepo"
    curl -f http://${ORAREPO}/${FMW_OUD_PKG} -o ${DOWNLOAD}/${FMW_OUD_PKG}
else 
    echo "use local copy of ${DOWNLOAD}/${FMW_OUD_PKG}"
fi

# unpack OUD binary package
cd ${DOWNLOAD}
$JAVA_HOME/bin/jar xvf ${FMW_OUD_PKG} >${FMW_OUD_PKG_LOG}

if [ $? -ne 0 ]; then
    echo "unable to extract file ${FMW_OUD_PKG}"
    exit 1
fi

# the jar file name from the logfile
FMW_OUD_JAR=$(grep -i jar ${FMW_OUD_PKG_LOG} |cut -d' ' -f3| tr -d " ")

# Install OUD binaries
$JAVA_HOME/bin/java -jar ${DOWNLOAD}/$FMW_OUD_JAR -silent \
        -responseFile ${DOWNLOAD}/install.rsp \
        -invPtrLoc ${DOWNLOAD}/oraInst.loc \
        -ignoreSysPrereqs -force \
        -novalidation ORACLE_HOME=${ORACLE_HOME} \
         INSTALL_TYPE="Collocated Oracle Unified Directory Server (Managed through WebLogic server)"

# clean up
rm -rf ${DOWNLOAD}/${FMW_OUD_PKG} \
       ${DOWNLOAD}/${FMW_OUD_PKG_LOG} \
       ${DOWNLOAD}/${FMW_OUD_JAR}

# - Install OUD Patch / PSU --------------------------------------------
if [ -n ${OUD_PATCH} ]; then
    for i in $(echo "${OUD_PATCH}"|sed s/\,/\ /g); do
        OUD_PSU=${i}
        OUD_PSU_ID=$(echo $OUD_PSU| sed -E 's/p([[:digit:]]+).*/\1/')
        echo "Install Oracle Patch / PSU ${OUD_PSU_ID}"
        # Get the latest database RU if it is not there yet
        if [ ! -s "${DOWNLOAD}/${OUD_PSU}" ]; then
            echo "download ${DOWNLOAD}/${OUD_PSU} from orarepo"
            curl -f http://${ORAREPO}/${OUD_PSU} -o ${DOWNLOAD}/${OUD_PSU}
        else
            echo "use local copy of ${DOWNLOAD}/${OUD_PSU}"
        fi

        # unzip OUD PSU
        cd ${DOWNLOAD}
        $JAVA_HOME/bin/jar xvf ${OUD_PSU}

        # install OUD PSU
        cd ${OUD_PSU_ID}
        ${ORACLE_HOME}/OPatch/opatch apply -silent

        # clean up
        rm -rf ${DOWNLOAD}/${OUD_PSU} \
               ${DOWNLOAD}/${OUD_PSU_ID}
    done
else
    echo "No OUD Patch / PSU specified"
fi

# - Install OUD binaries -----------------------------------------------
# Get the oracle binaries if they are not there yet  orarepo
if [ ! -s "${DOWNLOAD}/${FMW_OUD_PKG}" ]; then
    echo "download ${DOWNLOAD}/${FMW_OUD_PKG} from orarepo"
    curl -f http://${ORAREPO}/${FMW_OUD_PKG} -o ${DOWNLOAD}/${FMW_OUD_PKG}
else 
    echo "use local copy of ${DOWNLOAD}/${FMW_OUD_PKG}"
fi

# unpack OUD binary package
cd ${DOWNLOAD}
$JAVA_HOME/bin/jar xvf ${FMW_OUD_PKG} >${FMW_OUD_PKG_LOG}

if [ $? -ne 0 ]; then
    echo "unable to extract file ${FMW_OUD_PKG}"
    exit 1
fi

# the jar file name from the logfile
FMW_OUD_JAR=$(grep -i jar ${FMW_OUD_PKG_LOG} |cut -d' ' -f3| tr -d " ")

# Install OUD binaries
$JAVA_HOME/bin/java -jar ${DOWNLOAD}/$FMW_OUD_JAR -silent \
        -responseFile ${DOWNLOAD}/install.rsp \
        -invPtrLoc ${DOWNLOAD}/oraInst.loc \
        -ignoreSysPrereqs -force \
        -novalidation ORACLE_HOME=${ORACLE_HOME}

# clean up
rm -rf ${DOWNLOAD}/${FMW_OUD_PKG} \
       ${DOWNLOAD}/${FMW_OUD_PKG_LOG} \
       ${DOWNLOAD}/${FMW_OUD_JAR}

# - Install OUD Patch / PSU --------------------------------------------
if [ -n ${OUD_PATCH} ]; then
    for i in $(echo "${OUD_PATCH}"|sed s/\,/\ /g); do
        OUD_PSU=${i}
        OUD_PSU_ID=$(echo $OUD_PSU| sed -E 's/p([[:digit:]]+).*/\1/')
        echo "Install Oracle Patch / PSU ${OUD_PSU_ID}"
        # Get the latest database RU if it is not there yet
        if [ ! -s "${DOWNLOAD}/${OUD_PSU}" ]; then
            echo "download ${DOWNLOAD}/${OUD_PSU} from orarepo"
            curl -f http://${ORAREPO}/${OUD_PSU} -o ${DOWNLOAD}/${OUD_PSU}
        else
            echo "use local copy of ${DOWNLOAD}/${OUD_PSU}"
        fi

        # unzip OUD PSU
        cd ${DOWNLOAD}
        $JAVA_HOME/bin/jar xvf ${DOWNLOAD}/${OUD_PSU}

        # install OUD PSU
        cd ${OUD_PSU_ID}
        ${ORACLE_HOME}/OPatch/opatch apply -silent

        # clean up
        rm -rf ${DOWNLOAD}/${OUD_PSU} \
               ${DOWNLOAD}/${OUD_PSU_ID}
    done
else
    echo "No Oracle Patch / PSU specified"
fi
# - final clean up -----------------------------------------------------
# Remove not needed components
# tbd
# remove patch storage
rm -rf ${ORACLE_HOME}/.patch_storage
# OUI backup
rm -rf ${ORACLE_HOME}/inventory/backup/*
# Temp location
rm -rf ${DOWNLOAD}/*
rm -rf /tmp/OraInstall*

if [ "${SLIM}" = "TRUE" ]; then
    # remove inventory
    rm -rf ${ORACLE_HOME}/inventory
    # remove oui
    rm -rf ${ORACLE_HOME}/oui
    # remove OPatch
    rm -rf ${ORACLE_HOME}/OPatch
    rm -rf ${DOWNLOAD}/*
    rm -rf /tmp/OraInstall*
fi
# --- EOF --------------------------------------------------------------