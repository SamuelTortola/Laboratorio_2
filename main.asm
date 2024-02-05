;******************************************************************************
; Universidad Del Valle De Guatemala
; IE2023: Programación de Microcontroladores
; Autor: Samuel Tortola - 22094
; Proyecto: Laboratorio 2
; Hardware: Atmega238p
; Creado: 1/02/2024
; Última modificación: 5/02/2024 
;******************************************************************************



;******************************************************************************
;ENCABEZADO
;******************************************************************************
.include "M328PDEF.inc"
.CSEG
.ORG 0x0000 //Iniciar en la posición 0


;******************************************************************************
;STACK POINTER
;******************************************************************************
LDI R16, LOW(RAMEND)  
OUT SPL, R16
 LDI R17, HIGH(RAMEND)
OUT SPH, R17


;******************************************************************************
;CONFIGURACIÓN
;******************************************************************************

SETUP:
	LDI R16, 0b1000_0000
	LDI R16, (1 << CLKPCE) //Corrimiento a CLKPCE
	STS CLKPR, R16        // Habilitando el prescaler 

	LDI R16, 0b0000_0100
	STS CLKPR, R16   //Frecuencia del sistema de 1MHz

	LDI R16, 0b11111110
    OUT DDRD, R16   //Configurar pin PD1 a PD7 Como salida

	LDI R16, 0b00000000
	OUT DDRB, R16   //Configurar PB1 y PB2 como entrada
	LDI R16, 0b00000110
	OUT PORTB, R16    //Configurar PULLUP de pin PB1 y PB2

	LDI R16, 0b0011111
	OUT DDRC, R16   //Configurar pin PC0 a PC4 como salidas

	LDI R18, 0 //Contador de 100ms
	LDI R20, 0 //Suma para el contador de 4 bits
	LDI R19, 1 //suma de 1 para el contador de 4 bits
	LDI R23, 1  //Suma 1 para display 
	LDI R28, 0  //Suma 2 para display
	LDI R29, 1  //Suma 3 para display
	LDI R31, 0b11111100 //Cero para el display
	
	

;*******************************Inicia programa********************************

CALL timer1 //salta al contador de 4 bits con retraso de 100ms

LOOP:
	IN R22, PINB   //Obtener el estado del puerto B
	SBRS R22, PB2  //La instrucción salta si el bit PB1 está en 1
	CALL INCREMENTOH   //Antirrebote y función
	SBRS R22, PB1  //La instrucción salta si el bit PB2 está en 1
	CALL DECREMENTOH   //Antirrebote y función

	IN R24, TIFR0 //Registro donde están las banderas
	CPI R24, (1<<TOV0)  //Comparar que este encendida la bandera de overflow
	BRNE LOOP     //Si no esta encendida, regresa al LOOP

	LDI R24, 158
	OUT TCNT0, R24 //Cargar el valor inicial del contador

	SBI TIFR0, TOV0 //Apagar la bandera de overflow

	INC R18    //Incrementar registro 18
	CPI R18, 10  //Verificar cuantas veces se necesita correr el temporizador 
	BRNE LOOP   

	CLR R18 //Borrar el registro 18

	CALL contador //Llamar al contador de 4 bits

	RJMP LOOP  //Regresa al loop

	


timer1:
	LDI R16, 0
	OUT TCCR0A, R16 //trabajar de forma normal con el temporizador

	LDI R24, (1<<CS02)|(1<<CS00)
	OUT TCCR0B, R24  //Configurar el temporizador con prescaler de 1024

	LDI R24, 158
	OUT TCNT0, R24 //Iniciar timer en 158 para conteo

	RET

contador:

	OUT PORTC, R20  //Colocar el numero correspondiente
	
	ADD R20, R19  //Aumentar el registro 20 

	CPI R20, 16  //Si el contador se pasa de 15
	BREQ restriccion //Saltar a restriccion
	OUT PORTD, R31 //Coloca 0 en el display

	//RJMP LOOP  //Regresar al LOOP
	RET

	restriccion:
		CLR R20   //limpia registro 20
		RJMP LOOP //Regresa al LOOP

;conexiones de display a atmega: a=PD2, b=PD3, c=PD4, d=PD5, e=PD6, f= PD7, g=PD1
INCREMENTOH:
	LDI R16, 255   //Cargar con un valor a R16
	delay:
		DEC R16 //Decrementa R16
		BRNE delay   //Si R16 no es igual a 0, tira al delay
	LDI R16, 255   //Cargar con un valor a R16
	delay1:
		DEC R16 //Decrementa R16
		BRNE delay1   //Si R16 no es igual a 0, tira al delay
	LDI R16, 255   //Cargar con un valor a R16
	delay5:
		DEC R16 //Decrementa R16
		BRNE delay5   //Si R16 no es igual a 0, tira al delay

		//Se vuelve a leer
	SBIS PINB, PB2   //La instrucción salta si el bit PD2 está en 1
	RJMP INCREMENTOH  //Repetir verificación, hasta que sea estable el pulsador

	CPI R23, 5   //Compara cada valor para saltar a cada caso
	BRLO iinc
	CPI R23, 6
	BRSH iiinc

	iinc:
	    TABLA: .DB 0x00, 0x18, 0x6E, 0x3E, 0x9A, 0xB6   //muestra hasta 0x05
		LDI ZH, HIGH(TABLA <<1)  //da el byte mas significativo
		LDI ZL, LOW(TABLA <<1) //va la dirección de TABLA
		ADD ZL, R23
		LPM R25,Z
		OUT PORTD, R25
	    INC R23
		LDI R21, 1   //Coloca R29  a 1 para evitar presionar el pulsador 2 veces
		RJMP LOOP

	iiinc:
		CPI R23, 12
		BRSH iiiinc

		TABLA1: .DB 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xF6, 0x1C, 0xFE, 0x9E, 0xDE, 0xF2 //muestra hasta el 0x0B
		LDI ZH, HIGH(TABLA1 <<1)  //da el byte mas significativo
		LDI ZL, LOW(TABLA1 <<1) //va la dirección de TABLA
		ADD ZL, R23
		LPM R25,Z
		OUT PORTD, R25
	    INC R23
		RJMP LOOP

	iiiinc:
	    CPI R23, 14
		BRSH iiiiinc

		CPI R28, 2  //Verifica si R28 es 2
		BREQ r280  //Salta si es igual

		TABLA2: .DB  0xE4, 0x7A //Muestra hasta 0x0D
		LDI ZH, HIGH(TABLA2 <<1)  //da el byte mas significativo
		LDI ZL, LOW(TABLA2 <<1) //va la dirección de TABLA
		ADD ZL, R28
		LPM R25,Z
		OUT PORTD, R25
	    INC R23
		INC R28
		RJMP LOOP

		r280:  //Si R28 no es cero
			LDI R28,0 //coloca R28 a 0
			RJMP iiiinc //Salta de regreso
		
	iiiiinc:
		CPI R23, 15
		BRSH iiiiiinc
		CPI R26, 1  //Verifica si ya hubo E antes
		BREQ iiiiiinc

		LDI R28, 2
		TABLA3: .DB  0x00, 0x00,0x3E, 0x00  //Muestra hasta 0x0E
		LDI ZH, HIGH(TABLA3 <<1)  //da el byte mas significativo
		LDI ZL, LOW(TABLA3 <<1) //va la dirección de TABLA
		ADD ZL, R28
		LPM R25,Z
		OUT PORTD, R25
	    INC R23
		RJMP LOOP

	iiiiiinc:
		TABLA4: .DB  0x00, 0x46  //Muestra hasta 0x0F
		LDI ZH, HIGH(TABLA4 <<1)  //da el byte mas significativo
		LDI ZL, LOW(TABLA4 <<1) //va la dirección de TABLA
		ADD ZL, R29
		LPM R25,Z
		OUT PORTD, R25
		SBI PIND, PD7
		INC R23
		CPI R23, 15
		BRSH restr
		restr:
			LDI R23, 15
			LDI R28, 2
			CLR R26    //Vuelve R26 a 0
			LDI R21,0
		RJMP LOOP//Regresa al LOOP

	RJMP LOOP //Regresa al LOOP


DECREMENTOH:
		LDI R16, 255   //Cargar con un valor a R16
	delay6:
		DEC R16 //Decrementa R16
		BRNE delay6   //Si R16 no es igual a 0, tira al delay
	LDI R16, 255   //Cargar con un valor a R16
	delay7:
		DEC R16 //Decrementa R16
		BRNE delay7   //Si R16 no es igual a 0, tira al delay
	LDI R16, 255   //Cargar con un valor a R16
	delay8:
		DEC R16 //Decrementa R16
		BRNE delay8   //Si R16 no es igual a 0, tira al delay

		//Se vuelve a leer
	SBIS PINB, PB1   //La instrucción salta si el bit PD2 está en 1
	RJMP DECREMENTOH  //Repetir verificación, hasta que sea estable el pulsador

	CPI R23, 16
	BRLO decc

	decc:
		CPI R23, 15
		BRLO deccc

		TABLA41: .DB  0x00, 0x3E  //Muestra hasta 0x0E
		LDI ZH, HIGH(TABLA41 <<1)  //da el byte mas significativo
		LDI ZL, LOW(TABLA41 <<1) //va la dirección de TABLA
		ADD ZL, R29
		LPM R25,Z
		OUT PORTD, R25
		CBI PIND, PD7
		DEC R23
		DEC R28
		LDI R26,1
		RJMP LOOP //Regresa al LOOP

	deccc:
		CPI R23, 13
		BRLO decccc
		

		TABLA21: .DB  0xE4, 0x7A //Muestra hasta 0x0D
		LDI ZH, HIGH(TABLA21 <<1)  //da el byte mas significativo
		LDI ZL, LOW(TABLA21 <<1) //va la dirección de TABLA
		ADD ZL, R28
		LPM R25,Z
		OUT PORTD, R25
	    DEC R23
		DEC R28  
		CPI R28,0  //Compara R28
		BRLT qq  //Si es menor a 0, osea -1
		LDI R26,0   //Deja R26 en su estado inicial
		RJMP LOOP
		qq:
			CLR R28  //Limpia R28
			RJMP LOOP

	decccc:
		CPI R21,1
		BREQ de
		CPI R23, 6
		BRLO deccccc

	    DEC R23
		TABLA18: .DB 0x00, 0x00, 0x00, 0x00, 0x00, 0xB6, 0xF6, 0x1C, 0xFE, 0x9E, 0xDE, 0xF2 //muestra hasta el 0x06
		LDI ZH, HIGH(TABLA18 <<1)  //da el byte mas significativo
		LDI ZL, LOW(TABLA18 <<1) //va la dirección de TABLA
		ADD ZL, R23
		LPM R25,Z
		OUT PORTD, R25
		RJMP LOOP
		de:
			DEC R23
			LDI R21, 0
			RJMP deccccc
		

	deccccc:
		CPI R23, 1
		BREQ resto

		TABLA14: .DB 0x00, 0x00, 0x18, 0x6E, 0x3E, 0x9A    //muestra hasta 0x01
		LDI ZH, HIGH(TABLA14 <<1)  //da el byte mas significativo
		LDI ZL, LOW(TABLA14 <<1) //va la dirección de TABLA
		ADD ZL, R23
		LPM R25,Z
		OUT PORTD, R25
		DEC R23
		RJMP LOOP
		resto:
			LDI R31, 0b11111100 //Cero para el display
		    OUT PORTD, R31 //Coloca 0 en el display
			LDI R23, 1
			LDI R28, 0   //Deja a R28 en su estado inicial
			LDI R26,0   //Deja R26 en su estado inicial
			LDI R21, 0
			
			RJMP LOOP

	RJMP LOOP //Regresa al LOOP

	



	





