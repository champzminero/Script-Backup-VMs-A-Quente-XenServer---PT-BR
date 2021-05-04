#!/bin/bash
#
#       Script para Backup de VM a Quente
#       Valido para maquinas individuais e é preciso fixar o nome da VM nessa variavel vmname=. Ex:vmname=Linux
#       O NOME PRECISA SER EXATAMENTE COMO ESTA NO XENCENTER!
#
#***********************************************************************************************

#NOME DA VM A SER FEITO O BACKUP
vmname=

#***********************************************************************************************

storagebkp=                                             #SR local do Xen
dhvm=`date +%S%d%m%Y`                                   #DATA E HORA COMPLETA DOS PROCESSOS
dir=/var/log/backup/vms/bkp-$vmname.log                 #DIRETORIO DO LOG
ano=`date +%d%m%Y`                                      #ANO VIGENTE
p_montagem="/mnt/VM"                                    #PONTO DE MONTAGEM LOCAL

#***********************************************************************************************

echo >> $dir
echo " ------------------------------------------------------------------------------" >> $dir
echo " [***] Script de Backup VM XenServer [***]" >> $dir
echo " Iniciando backup da VM $vmname em `date +%d-%m-%Y` " >> $dir
echo " ------------------------------------------------------------------------------" >> $dir
sleep 2


echo " Criando pasta para armazenamento de backup da VM" >> $dir
mkdir $p_montagem/$vmname > /dev/null 2>&1
if [ $? -eq 0 ]
then
        echo "  [Ok] Diretorio Criado!" >> $dir
else
        echo "  [..] Diretorio já existente. Continuando processo..." >> $dir
fi


data=`date +%c`
echo >> $dir
echo " 1- Criando Snapshot em ${data}" >> $dir
if [ $? -eq 0 ]
then
        idvm=$(tail -n1 temp_${vmname}.txt)
        echo "  [Ok] Snapshot criado - UUID:$idvm" >> $dir
else
        echo "  [Erro!] Aconteceu algo de errado! Verifique o log em $dir"
        echo "  Causa:" >> $dir
        cat temp_${vmname}.txt >> $dir
exit 1
fi


sleep 5


data=`date +%c` >> $dir
echo >> $dir
echo " 2- Convertendo Snapshot em Template em ${data}" >> $dir
xe template-param-set is-a-template=false uuid=$idvm > temp_${vmname}.txt 2>&1
if [ $? -eq 0 ]
then
        echo "  [Ok] Template convertido" >> $dir
else
        echo "  [Erro!] Aconteceu algo de errado!" >> $dir
        echo "  Causa:" >> $dir
        cat temp_${vmname}.txt >> $dir
        xe vm-uninstall uuid=$idvm force=true >> /dev/null
exit 1
fi



data=`date +%c` >> $dir
echo >> $dir
echo " 3- Convertendo Template em VM  em ${data}" >> $dir
xe vm-copy vm=${vmname}_${ano} sr-uuid=$storagebkp new-name-label=${vmname}_$dhvm > temp_${vmname}.txt 2>&1
if [ $? -eq 0 ]
then
        cvvm=$(tail -n1 temp_${vmname}.txt)
        echo "  [Ok] Template convertido em VM" >> $dir
else
        echo "  [Error] Aconteceu algo de errado! Verifique o log em $dir" >> $dir
        echo "  Causa:" >> $dir
        cat temp_${vmname}.txt >> $dir
        xe vm-uninstall uuid=$idvm force=true >> /dev/null
exit 1
fi




data=`date +%c` >> $dir
echo >> $dir
echo " 4- Exportando VM para SR em ${data}" >> $dir
xe vm-export vm=${vmname}_${ano} filename="$p_montagem/$vmname/${vmname}_${dhvm}.xva" > temp_${vmname}.txt 2>&1
if [ $? -eq 0 ]
then
        echo "  [Ok] Exportacao finalizada" >> $dir
else
        echo "  [Erro!] Aconteceu algo de errado!" >> $dir
        echo "  [Erro!] Excluindo Template e Snapshots. Verifique o log em $dir" >> $dir
        echo "  Causa:" >> $dir
        cat temp_${vmname}.txt >> $dir
        xe vm-uninstall uuid=$cvvm force=true >> /dev/null
        xe vm-uninstall uuid=$idvm force=true >> /dev/null
exit 1
fi




data=`date +%c`
echo >> $dir
echo " 5- Deletando Snapshot ${data}" >> $dir
xe vm-uninstall uuid=$idvm force=true > temp_${vmname}.txt 2>&1
if [ $? -eq 0 ]
then
        echo "  [Ok] Exclusao realizada com sucesso" >> $dir
else
        echo "  [Erro!] Aconteceu algo de errado! Verifique em $dir" >> $dir
        echo "  Causa:" >> $dir
        cat temp_${vmname}.txt >> $dir
exit 1
fi




data=`date +%c`
echo >> $dir
echo " 6- Deletando VM e VDI ${data}" >> $dir
xe vm-uninstall uuid=$cvvm force=true > temp_${vmname}.txt 2>&1
if [ $? -eq 0 ]
then
        echo "  [Ok] Exclusao realizada com sucesso" >> $dir
        echo "  [Ok] Processo de Backup e Exportacao Concluido com Exito" >> $dir
else
        echo "  [Erro!] Aconteceu algo de errado! Verifique em $dir" >>$dir
        echo "  Causa:" >> $dir
        cat temp_${vmname}.txt >> $dir
exit 1
fi



data=`date +%c`
echo >> $dir
echo " Excluindo backups com mais de 3 DIAS em ${data}" >> $dir
find $p_montagem/$vmname/* -mtime +3 -exec rm {} \;
if [ $? -eq 0 ];
then
        echo "  [Ok] Arquivos excluidos." >> $dir
        echo "  [Ok] Backup Concluido em ${data}." >> $dir
        echo " *******************************************************************************" >> $dir
else
        echo "  [Erro!] Nao foi possivel fazer a exclusao dos backups antigos, verifique no log " >> $dir
        echo " ===============================================================================" >> $dir
exit 1
fi
