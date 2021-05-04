# Script de Backup de VM a quente no XenServer---PT-BR #

### Esse Script tem como objetivo fazer o Backup das Maquinas Virtuais existentes no Hypervisor atraves de um Script feito em Bash.
### No inicio do corpo do Script, o usuario deverá definir o nome da VM a ser feito o Backup e o UUID do Local Storage.

#   IMPORTANTE ###
### As maquinas serão exportadas para um ponto de montagem de uma pasta na rede. Então é preciso configurar dentro do /etc/fstab ou de outra forma que preferir, a montagem da pasta # em que serão enviadas após a conclusão dos procedimentos. Caso queira criar o arquivo .XVA e coloca-lo em um HD ou coisa do tipo, voce pode passar o comando de montagem no inicio do Script e alterar a variavel p_montagem= indicando assim a pasta montada.

### Apos preencher os campos vmname= e storagebkp= (que não são passados por parametro, mas sim incluido dentro do Script), o Script irá prosseguir com os seguintes passos na seguinte ordem:
###  Criação de pasta no ponto de montagem
###  Criação de Snapshot
### Conversão do Snapshot em Template (Caso não consiga, apagará o Snapshot recem criado)
###  Conversão do Template em VM (Caso não consiga, apagará o Snapshot recem criado)
###  Exportando VM para SR na data atual (Caso nao consiga, apagara o Snapshot e o Template recem criado)
###  Apaga o Snapshot 
###  Apaga a VM e VDI
###  Exclusão de Backups com mais de 3 DIAS

# IMPORTANTE ###
# O vmname precisa receber o nome EXATAMENTE como está no XenCenter ou identificado dentro do XenServer. Se isso não for respeitado, o Script nao funcionará
###

### O Script irá criar um arquivo temporario para que ele possa armazenar a saida dos comandos e redirecionar isso para o STDOUT, já que ele precisará usar um hash que é gerado por alguns comandos. Esses arquivos temporarios podem ser deletados antes e depois de concluido todo procedimento.
### As saidas são redirecionadas para um arquivo de log que está dentro da variavel dir. Voce pode alterar o caminho para onde for de sua preferencia.
### A variavel DIR irá armazenar o caminho para o qual os logs serão direcionados. Voce pode usar o que se encontra no Script, mas certifique-se de criar o diretorio.

# Por fim, antes de colocar o Script em execução em suas VMs de produção, crie uma VM e teste para verificar se o funcionamento é o adequado para voce.
