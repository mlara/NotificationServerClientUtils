#!/bin/bash

URLNV="wss://uapush-nv.srv.openwebdevice.com"
URLMR="wss://uapush-mr.srv.openwebdevice.com"
URLPROD="wss://ua.push.tefdigital.com"
TMPDIR="."
PATHMOVIL="/system/b2g/defaults/pref/"
FICHERO="user.js"

usage(){
	echo "USAGE: "$0" [NV|MR|PROD]" >&2
	echo -e "\t without parameters It tell you where are you pointing at the moment" >&2
	echo -e "\t with parameter, change your mobile config to point to your choice" >&2
	echo -e "\n\tERROR CODE: -1 usage error -2 consult error -3 put error" >&2
}

getServidorAlQueApunta(){
	valorActual=`adb wait-for-device && adb shell cat /system/b2g/defaults/pref/user.js | grep services\.push\.serverURL | sed 's/.*\"\([^\"]\+\)\".*/\1/'`
	echo -n "El dispositivo que está conectado actualmente apunta a: "
	if [ ${valorActual}"Z" == ${URLNV}"Z" ];then
		echo -ne "\t[NV] Next Version "
	elif [ ${valorActual}"Z" == ${URLMR}"Z" ];then
		echo -ne "\t[MR] Mirror "
	elif [ ${valorActual}"Z" == ${URLPROD}"Z" ];then
		echo -ne "\t[PROD] Producción "
	else
		echo -e "\n\nError, valor no esperado en el teléfono: "$valorActual >&2
		exit -2
	fi
	echo $valorActual

}

setServidorAlQueApunta(){
	PETICION=$1
	urlAux=""
	if [ $PETICION == "NV" ];then
		urlAux=$URLNV
	elif [ $PETICION == "MR" ];then
		urlAux=$URLMR
	elif [ $PETICION == "PROD" ];then
		urlAux=$URLPROD
	else
		echo -e "\n\nError, valor no esperado al realizar el set del servidor: "$PETICION >&2
		usage
		exit -3
	fi

	adb wait-for-device && adb remount >/dev/null 2>&1 
	adb wait-for-device && adb pull ${PATHMOVIL}${FICHERO} $TMPDIR >/dev/null 2>&1 
	# le cambio los "/" por "\/" que el sed se pone pijo
	cat ${TMPDIR}"/user.js" | sed 's/pref(\"services\.push\.serverURL\", \".*\");/pref(\"services\.push\.serverURL\", \"'${urlAux//\//\\\/}'\");/' > ${TMPDIR}"/user.js.AUX"
	adb push ${TMPDIR}"/user.js.AUX" ${PATHMOVIL}${FICHERO} >/dev/null 2>&1 
	# limpio los temporales
	rm ${TMPDIR}"/user.js" ${TMPDIR}"/user.js.AUX"
	# reinicio para aplicar los cambios
	adb reboot
}

if [ $# -gt 1 ];then
	usage
	exit -1
fi

echo -e "\nAntes de empezar, nos aseguramos de que tenemos el móvil conectado, si tarda demasiado, revisa el \"remote debbuging\" del teléfono\n"
adb wait-for-device

if [ $# == 0 ];then
	getServidorAlQueApunta
else
	setServidorAlQueApunta $1
	getServidorAlQueApunta
fi

exit 0
