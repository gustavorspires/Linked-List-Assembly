	.data
strFstInput:.asciz "Insira a primeira operação: \n"
strInput: 	.asciz "Insira a próxima operação: \n"
strOutMul: 	.asciz "O produto de "
strOutSum: 	.asciz "A soma de "
strOutDiv: 	.asciz "A Divisão entre "
strOutSub: 	.asciz "A subtração entre "
strAnd:			.asciz " e "
strEquals:	.asciz " é igual a: "
	.text
# ====== DEFINIÇOES DO PROGRAMA =======
	.align 2
	.globl main
	
# ============== MACROS =============
	.macro empilhar (%reg)
		addi sp, sp, -4
		sw %reg, (sp)
	.end_macro
	
	.macro desempilhar (%reg)
		lw %reg, (sp)
		addi sp, sp, 4
	.end_macro
	
	.macro criar_slot (%output, %dado, %endereço)
		empilhar %dado
		empilhar %endereço
		empilhar a2
		empilhar a3
		add a2, zero, %dado
		add a3, zero, %endereço
		jal list_make_slot
		add %output, zero, t0
		desempilhar a3
		desempilhar a2
		desempilhar %endereço
		desempilhar %dado
	.end_macro

	.macro remover_slot (%output_dado, %output_endereço, %endereço)
		empilhar %endereço
		empilhar a2
		add a2, zero, %endereço
		jal list_remove_slot
		add %output_dado, zero, t1
		add %output_endereço, zero, t0
		desempilhar a2
		desempilhar %endereço
	.end_macro
	
	.macro criar_lista (%output)
		jal list_new
		add %output, zero, t0
	.end_macro

	.macro apagar_lista (%lista)
		empilhar a2
		add a2, zero, %lista
		jal list_delete
		add %lista, zero, a2
		desempilhar a2
	.end_macro
	
	.macro inserir_lista (%novo_valor, %lista)
		empilhar %novo_valor
		empilhar %lista
		empilhar a2
		empilhar a3
		add a2, zero, %novo_valor
		add a3, zero, %lista
		jal list_insert
		desempilhar a3
		desempilhar a2
		desempilhar %lista
		desempilhar %novo_valor
	.end_macro

	.macro remover_lista (%output_dado, %lista)
		empilhar %lista
		empilhar a2
		add a2, zero, %lista
		jal list_remove
		add %output_dado, zero, t1
		desempilhar a2
		desempilhar %lista
	.end_macro

# ============= MAIN ===============
main:	
	criar_lista
	add t1, zero, a0
	lb t0, (t1)
	li a7, 1
	add a0, zero, t0
	ecall
	addi t1, t1, 1
	lb t0, (t1)
	add a0, zero, t0
	ecall
	li a7, 10
	ecall
	

# ========= OPERAÇÕES =========

trata_op:
	add t0, zero, zero 				# Reinicia o valor de t0
	li t0, '+' 						# Carrega o caractere '+' em t0
	beq t0, a2, adiciona 			# Se t0 == a2 -> função adiciona
	
	add t0, zero, zero				# Reinicia o valor de t0
	li t0, '-'						# Carrega o caractere '-' em t0
	beq t0, a2, subtrai				# Se t0 == a2 -> função subtrai

	add t0, zero, zero				# Reinicia o valor de t0
	li t0, '*'						# Carrega o caractere '*' em t0
	beq t0, a2, multiplica			# Se t0 == a2 -> função multiplica

	add t0, zero, zero				# Reinicia o valor de t0
	li t0, '/'						# Carrega o caractere '/' em t0
	beq t0, a2, divide				# Se t0 == a2 -> função divide

adiciona:
	empilhar ra # Guarda o endereço de retorno da pilha
	add s0, a0, a1 					# Cálculo principal - s0 = a0 + a1
	desempilhar ra # Restaura o endereço de retorno da pilha
	ret
subtrai:
	empilhar ra # Guarda o endereço de retorno da pilha
	sub s0, a0, a1 					# Cálculo principal
	desempilhar ra # Restaura o endereço de retorno da pilha
	ret
multiplica:
	empilhar ra # Guarda o endereço de retorno da pilha
	mul s0, a0, a1 					# Cálculo principal
	desempilhar ra # Restaura o endereço de retorno da pilha
	ret
divide:
	empilhar ra # Guarda o endereço de retorno da pilha
	div s0, a0, a1 					# Cálculo principal
	desempilhar ra # Restaura o endereço de retorno da pilha
	ret

undo:
	empilhar ra					# Guarda o endereço de retorno na pilha
	
	# Remove o último resultado da lista
	remover_lista s0, s1		# Remove o último resultado e o armazena em s0

	li a7, 4					# Carrega o serviço de printar string
	la a0, strUndo				# Carrega o endereço da mensagem de undo
	ecall						# Chama o serviço para imprimir a mensagem

	li a7, 1					# Carrega o serviço de printar inteiro
	add a0, zero, s0			# Carrega o resultado em a0
	ecall						# Chama o serviço para imprimir o resultado

	li a7, 11					# Carrega o serviço de printar caractere
	li a0, '\n'					# Carrega o caractere de nova linha
	ecall						# Chama o serviço para imprimir a nova linha
	
	desempilhar ra				# Restaura o endereço de retorno da pilha
	j loop_principal			# Volta ao loop principal

finalizar:

apagar_lista s1
	li a7, 10 						# Carrega o serviço de finalização de programa
	ecall							# Chamada do sistema (encerra o programa)
	
# ========= FUNÇOES DA LISTA ==========
# Funções para implementação e manejo da lista.
# *Nota: Para garantir que nenhuma função se perca, por padrão toda a função empilha seu endereço na stack
# e suas macros empilham tanto os valores dos registradores usados para passar argumentos quanto os
# registradores dos provisórios usados para passar inputs para as funções, de modo que se a main utiliza
# algum desses registradores, o usuário não precisa se preocupar em guardá-lo. As exceções à regra são casos
# em que o output é o registrador do input modificado, como o caso de apagar a lista. 
# *ATENÇÃO: Registradores temporários t0, t1, ... são modificados e não são empilhados entre chamadas de função!
# Sumário:
# -Internas:
# 	- Criar Slot: Cria um bloco (slot) da lista, passa um valor [NUM] e o endereço do bloco anterior
#                 [END] e retorna o valor do bloco alocado num registrador de output. Esta função é
#                 automaticamente manejada pelas funções externas, portanto não é necessário que o usuário
#                 se preocupe com os dados alocados.
#	- Remover Slot: Apaga um bloco (slot) da lista dado o endereço dele, zerando seus valores e retornando o
#                   dado do bloco removido e o endereço do bloco anterior. Esta função é automaticamente 
#                   manejada pelas funções externas, portanto, a limpeza de memória e recuperação dos dados
#                   não devem ser preocupações do usuário.
# -Externas:
# 	- Criar Lista: Armazena em um espaço de memória o endereço do bloco que está na ponta da lista.
#                  Quando a lista é criada, ela é vazia, ou seja, remover não farão nada até que o 
#                  usuário use a função de inserir para adicionar elementos a ela. 
#                  *É necessário que o usuário forneça um registrador que possa ter seu conteúdo sobrescrito, 
#                  para armazenar o endereço de memória onde a estrutura da lista está guardada.
# 	- Apagar Lista: Apaga todos os elementos de uma lista dada. Diferente da função Remover Lista, esta funcão
#                   não só apaga os blocos da lista, mas quando chega ao estado de lista vazia, apaga a própria
#                   estrutura da lista, removendo até a própria referencia do endereço da lista
# 	- Inserir Lista:
# 	- Remover Lista:
# ----- FUNCAO CRIAR SLOT -----
# Aloca um pedaço de memoria com 8 bytes, os primeiros 4 bytes servem para armazenar o dado
# (número armazenado) [NUM] e os últimos 4 bytes servem para armazenar o endereço da unidade anterior
# da lista (endereço do bloco anterior alocado) [END]. Se não houver bloco anterior, o padrão é
# armazenar -1 no local do endereço [END].
# -----------------------------
# Macro: criar_slot output, dado, endereço
# -----------------------------
# a0 - mutável de chamadas               ->   Auxiliar
# a7 - reservado para instruções         ->   Auxiliar
# a2 - dado                              ->   Input
# a3 - endereço anterior                 ->   Input
# t0 - endereço do novo bloco (alocado)  ->   Output / Auxiliar
# -----------------------------
list_make_slot:
	empilhar ra     # guarda o endereço da função na stack (ra)
	li a0, 8       # carrega 8 (bytes) no a0
	li a7, 9              # carrega instruçao 9 (alocar memória: bytes em a0 -> endereço alocado em a0) em a7
	ecall         # executa a chamada (aloca 8 bytes de memória)
	add t0, zero, a0          # passa o endereço alocado que está em a0 para t0
	sw a2, (t0)           # guarda nos primeiros 4 bytes de t0 [NUM] o valor de a2 (dado) 
	addi t0, t0, 4     # move o endereço em t0 4 bytes para acessar os 4 últimos bytes reservados [END]
	sw a3, (t0)            # guarda nos ultimos 4 bytes de t0 [END] o endereço em a3 (endereço anterior)
	addi t0, t0, -4    # move o endereço em t0 4 bytes para trás para retornar ao endereço original
	desempilhar ra         # retorna da stack o endereço da função (ra)
	ret # retorna função

# ----- FUNCAO REMOVER SLOT -----
# Libera espaços de memória de um slot colocando seus conteúdos para 0 e soltando a referencia de endereço do
# atual, passando o valor do bloco anterior para que a correção de [CAUDA] seja feita na estrutura da lista.
# Se o bloco removido tiver marcador [END] = -2, apaga o conteúdo de [NUM] e coloca [END] = -1.
# -------------------------------
# Macro: remover_slot output_dado, output_endereço, endereço_slot 
# -------------------------------
# a2 - endereço do slot                 -> Input / Auxiliar
# t0 - endereço do anterior             -> Output / Auxiliar
# t1 - dado do atual                    -> Output / Auxiliar
# t2 - marcador de endereço (t1 / t2)   -> Auxiliar
# -------------------------------
list_remove_slot:
	empilhar ra  # guarda o endereço da função na stack (ra)
	lw t1, (a2)        # recupera o dado de [NUM] do bloco removido
	sw zero, (a2)  # zera valor armazenado nos primeiros 4 bytes de a2 ([NUM])
	addi a2, a2, 4      # incrementa a2 para acessar os 4 últimos bytes de a2 ([END])
	lw t0, (a2)     # recupera o endereço do anterior ([END])
	li t2, -2          # carrega -2 em t2 (marcador não vazio)
	beq t0, t2, remove    # se o endereço recuperado for -2, segue para seção que colocar [END] = -1
	sw zero, (a2)       # zera o valor armazenado nos 4 últimos bytes de a2 ([END])
	fim_remove:
	addi a2, a2, -4   # decrementa a2 em 4 bytes para retornar ao endereço original
	desempilhar ra     # retorna da stack o endereço da função (ra)
	ret

remove:
	li t2, -1  # carrega -1 em t2 (marcador vazio)
	sw t2, (a2)    # coloca -1 em a2 ([END])
	j fim_remove   # pula para fim_remove
	
	
# ----- FUNCAO CRIAR LISTA -----
# Aloca um pedaço de memória com 4 bytes, que servem para armazenar o endereço de memória do último bloco
# da lista [CAUDA]. Depois disso chama a função "criar_slot" para criar um slot vazio com [NUM] = 0 e 
# [END] = -1, que será o primeiro e único bloco da lista enquanto ela não for aumentada.
# ------------------------------
# Macro: criar_lista output
# ------------------------------
# a0 - mutável de chamadas               -> Auxiliar
# a7 - reservado para instruções         -> Auxiliar
# t0 - endereço da nova lista (alocado)  -> Output
# t1 - marcador de endereço (-1)         -> Auxiliar
# t2 - endereço do novo slot (alocado)   -> Auxiliar
# ------------------------------
list_new:
	empilhar ra   # guarda endereço da funçao na stack (ra)
	li a0, 4           # carrega 4 (bytes) em a0
	li a7, 9      # carrega instruçao 9 (alocar memória: bytes em a0 -> endereço alocado em a0) em a7
	ecall              # executa a chamada (aloca 4 bytes de memória)
	add t0, zero, a0     # passa o endereço alocado que está em a0 para t0
	li t1, -1      # carrega -1 em t1 (marcador vazio)
	empilhar t0       # guarda t0 na pilha para não perde-lo ao chamar próxima função
	criar_slot t2, zero, t1   # chama funçao para criar um slot zerado, com [NUM] = 0 (zero) e
	 #                          [END] = -1 (marcador vazio), que retorna o endereço do slot em t2
	desempilhar t0    # volta o valor na pilha para o registrador t0
	sw t2, (t0)            # guarda no endereço da nova lista [CAUDA] o endereço do novo slot
	desempilhar ra    # retorna da stack o endereço da função (ra)
	ret # retorna função


# ----- FUNCAO APAGAR LISTA -----
# Chama função para remover slots até que a remoção retorne -1 (marcador vazio). Quando retornar marcador vazio
# Coloca [END] do último bloco para 0 e coloca [CAUDA] para 0.
# -------------------------------
# Macro: apagar_lista lista
# -------------------------------
# a2 - endereço da lista           -> Input / Output
# t0 - endereço de cauda           -> Auxiliar
# t1 - marcador de endereço (-1 / -2)   -> Auxiliar
# t2 - valor do dado removido      -> Auxiliar
# t3 - valor do endereço removido  -> Auxiliar
# -------------------------------
list_delete:
	empilhar ra
loop_delete:
	remover_slot t2, t3, t0     # executa função "remover slot" para o slot de [CAUDA]
	#                             e retorna o dado removido em t2 e o endereço anterior em t3
	li t1, -2     # reinicia o marcador para -2
	beq t3, t1, delete_list      # se o endereço de [END] for igual a -2 (marcador nao vazio), pula para seção
	#                              que deleta estrutura da lista
	li t1, -1    # reinicia o marcador para -1
	beq t3, t1, delete_list      # se o endereço de [END] for igual a -1 (marcador nao vazio), pula para seção
	#                              que deleta estrutura da lista
	sw t3, (a2)       # guarda o endereço do anterior em [CAUDA]
	j loop_delete         # retorna para o começo do loop
	fim_delete_list:
	desempilhar ra     #retorna da stack o endereço da função (ra)
	ret # retorna função

delete_list:
	sw zero, (a2)    # coloca 0 no lugar de [CAUDA]
	li a2, 0      # coloca 0 no lugar do endereço da lista (a2)
	j fim_delete_list  # pula para fim_delete_list
	
# ----- FUNCAO INSERIR LISTA -----
# Aloca um novo slot com a funçao "criar_slot", colocando o dado inserido em [NUM], o endereço de [CAUDA]
# em [END] e atualizando [CAUDA] para o endereço do novo slot criado. Se o slot de [CAUDA] for vazio
# [END = -1], insere dado no próprio bloco.
# --------------------------------
# Macro: inserir_lista novo_dado, lista
# --------------------------------
# a2 - novo dado                        -> Input         
# a3 - endereço da lista                -> Input
# t0 - endereço em [CAUDA]              -> Auxiliar
# t1 - endereço do novo slot (alocado)  -> Auxiliar
# t2 - marcador de endereço (-1 / -2)   -> Auxiliar
# t3 - valor de [END]                   -> Auxiliar
# --------------------------------
list_insert:
	empilhar ra     # guarda endereço da funçao na stack (ra)
	lw t0, (a3)                # carrega em t0 o endereço guardado em [CAUDA]
	addi t0, t0, 4       # incrementa t0 em 4 bytes para acessar [END] da [CAUDA]
	lw t3, (t0)                # carrega [END] em t3
	addi t0, t0, -4      # decrementa t0 em 4 bytes para voltar ao endereço original
	li t2, -1         # carrega -1 em t2 (marcador vazio)
	beq t3, t2, insert    # se for o primeiro bloco ([END] = -1), pula para parte que insere dado
	#                       diretamente em [NUM] do primeiro bloco
	criar_slot t1, a2, t0    # cria um novo slot com [NUM] = a2 (dado), [END] = t0 ([CAUDA]) e guarda
    #                          o endereço do novo slot em t1
	sw t1, (a3)     # atualiza [CAUDA] com o endereço do novo slot
	fim_insert:
	desempilhar ra     # retorna da stack o endereço da função (ra)
	ret # retorna função

insert:
	sw a2, (t0)    # carrega o a2 (dado) nos 4 primeiros bytes do slot [NUM]
	addi t0, t0, 4        # incrementa t0 em 4 bytes para acessar os 4 útlimos bytes [END]
	li t2, -2      # carrega -2 em t2 (marcador não vazio)
	sw t2 (t0)           # carrega o t2 (marcador não vazio) nos 4 últimos bytes do slot [END]
	addi t0, t0, -4   # decrementa t0 em 4 bytes para voltar ao endereço original
	j fim_insert     # pula para fim_insert

# ----- FUNCAO REMOVER LISTA -----
# Remove um bloco da lista e retorna o dado removido e o endereço do bloco de slot anterior.
# --------------------------------
# Macro: remover_lista output_dado, lista
# --------------------------------
# a2 - endereço da lista                   -> Input
# t0 - endereço de [CAUDA]                 -> Auxiliar
# t1 - dado recuperado                     -> Output
# t2 - endereço do anterior (nova [CAUDA]) -> Auxiliar
# t3 - marcador de não vazio (-1 / -2)              -> Auxiliar
# --------------------------------
list_remove:
	empilhar ra     # guarda o endereço da função na stack (ra)
	lw t0, (a2)           # guarda em t0 [CAUDA]
	remover_slot t1, t2, t0     # executa a função "remover slot" para o slot de [CAUDA] (t0), retornando
	#                             o dado recuperado em t1 e o endereço do anterior em t2
	li t3, -2          # carrega -2 em t3 (marcador nao vazio)
	beq t2, t3, fim_list_remove  # se o valor do endereço anterior for -2, não atualiza [CAUDA] e pula para o fim
	li t3, -1            # carrega -1 em t3 (marcador vazio)
	beq t2, t3, fim_list_remove # se o valor do endereço anterior for -1, nao atualiza [CAUDA] e pula para o fim
	sw t2, (a2)        # atualiza [CAUDA] colocando o endereço do anterior recuperado (t2)
	fim_list_remove:
	desempilhar ra  # retorna da stack o endereço da função (ra)
	ret # retorna função
	
# ========= FUNÇOES DE IO ==========
#
#

 #FUNÇÃO READ FIRST INPUT -----------
 #Lê o primeiro e segundo, armazenando em a1 e a2 e a operação em a0
lerPrimeiroInput:
	li a7, 4						# Carrega o serviço de printar string
	la a0, strFstInput  # Carrega a string como argumento
	ecall								# Chama o serviço

	li a7, 5						# Carrega o serviço de ler inteiro
	ecall								# Chama o Serviço
	add t0, zero, a0		# Armazena em t0 o resultado da primeira leitura

	li a7, 12						# Carrega o serviço de ler string
	ecall								# Chama o Serviço
	add t1, zero, a0		# Armazena em t1 o resultado da leitura da operação

	li a7, 5						# Carrega o serviço de ler inteiro
	ecall								# Chama o Serviço
	add t2, zero, a0		# Armazena em t2 o resultado da segunda leitura

	add  a0, zero, t1		# Armazena em a0 a opração
	add  a1, zero, t0		# Armazena em a1 o primeiro valor
	add  a2, zero, t2		# Armazena em a2 o segundo valor	

#FUNÇÃO DE READ INPUT --------------
# Lê o próximo comando, se for uma operação aritimética, também lê o próximo número
# Se for uma operação aritimética, retorna em a0 a operação e em a1 o próximo operador
lerInput:
	li a7, 4						# Carrega o serviço de printar string
	la a0, strInput  		# Carrega a string como argumento
	ecall								# Chama o serviço

	jal leOperacao			# Função para ler operação
	
	li t0, 177					# Armazena 'u' em t0 para comparar
	li t1, 102					# Armazena 'f' em t0 para comparar
	beq t0, a0, naoEhAritimetica
	beq t1, a0, naoEhAritimetica # Se o char lido for u ou f, retorna sem ler o próximo número

	add t0, zero, a0		# Armazena em t0 a operação 

	li a7, 5						# Carrega o serviço de ler inteiro
	ecall								# Chama o Serviço
	add t1, zero, a0		# Armazena em t1 o valor da operação

	add a0, zero, t0		# Armazena em a0 a operação
	add a1, zero, t1		# Armazena em a1 o valor da operação
	jalr zero, 0(ra)		#	retorna

leOperacao:
	li a7, 12						# Carrega o serviço de ler string
	ecall								# Chama o Serviço
	add t1, zero, a0		# Armazena em t1 o resultado da leitura da operação

	li t0, 32						# Compara o valor 32(caractere ' ') para comparar
	beq a0, t0, leOperacao # Se ler espaço, lê novamnete

	jalr
naoEhAritimetica:
	jalr zero, 0(ra)
	
#FUNÇÃO OUTPUT ---------------------
# Recebe em a0 a operação e em a1 e a2 o primeiro e segundo valor e em a3 o resultado
printaResultado:
	li a7, 4						# Carrega o serviço de printar string
	
	li t0, 42 					# Carrega o Char '+' em t0 para comparacao
	beq t0, a0, soma    # Se for soma, vai para rotina
	
	li t0, 43 					# Carrega o Char '*' em t0 para comparacao
	beq t0, a0, mult    # Se for multiplicacao, vai para rotina
	
	li t0, 47 					# Carrega o Char '/' em t0 para comparacao
	beq t0, a0, soma    # Se for divisão, vai para rotina

	la a0, strOutSub		# Se não for nenhum dos anteriores, é uma subtração
	ecall
	li a7, 1						# Carrega Serviço de printa inteiro
	add a0, zero, a1		# 

	la a0, strEquals		# Carrega a string " e "
	ecall

soma:
	la a0, strOutSum
	ecall


