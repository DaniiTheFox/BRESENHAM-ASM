// ===============================
// = SIMPLE DRAWING TEST PROGRAM  =
// ===============================
MOV ESI,32      // SETUP SCREEN WIDTH
MOV EDI,32      // SETUP SCREEN HEIGHT
MOV EBP,65536   // SETUP SCREEN MEMORY START
JMP START       // JUMP TO START ROUTINE
// =============================
// = COLOR PALETTE FOR THE GAME =
// =============================
RED:
	DB 255,0,0
ORANGE:
	DB 255,155,0
YELLOW:
	DB 255,255,0
GREEN:
	DB 0,255,0
LBLUE:
	DB 0,155,255
BLUE:
	DB 0,0,255
PURPLE:
	DB 155,0,255
PINK:
	DB 255,0,255

// =============================
// = INITIALIZE PROGRAM SCREEN =
// =============================
INIT:
    MOV [65536+1048572],ESI
    MOV [65536+1048572+1],EDI
    MOV [65536+1048574],1
    MOV [65536+1048569],1
    MOV EAX,65536
    RET
	
// =================================
// = THIS IS THE PUT PIXEL ROUTINE =
// =================================
PUT_PIXEL:  // R0 AND R1 ARE X, Y ARGS
    // ===========
    PUSH R2     // FIRST STEP IS TO CALCULATE PIXEL POSITION
    PUSH R3     // HERE WE PUSH 3 VALUES TO STACK
    PUSH R7     // 
    MOV R2,R1   // MOVE THE VALUE OF Y TO R2
    MUL R2,ESI  // MULTIPLY Y TIMES SCREEN WIDTH
    ADD R2,R0   // ADD THE X COORDINATE TO THE RESULT (Y*SCRWIDTH+X)
    MUL R2,3    // MULTIPLY TIMES 3 AS THE SCREEN REQUIRES
    MOV R3,EAX  // MOVE THE VALUE OF EAX (SCREEN START) TO R3
    ADD R3,R2   // ADD THE SCREEN START AND THE CALCULATED POS
    // ===========
    MOV R7, [R8]       // RED VALUE
    MOV [R3], R7       // WRITE RED VALUE
    MOV R7, [R8+1]     // GREEN VALUE
    MOV [R3+1], R7     // WRITE GREEN VALUE
    MOV R7, [R8+2]     // BLUE
    MOV [R3+2], R7     // WRITE BLUE VALUE
    // =================
    POP R7          // WE POP THE STACK AS WE WONT BE USING IT ANYMORE
    POP R3          // TO DELETE THE VALUES WE PUSHED
    POP R2          // AT THE BEGINNING
    RET             // AND RETURN TO THE MAIN FUNC

// ===================================
// = BRESENHAM LINE DRAWING ALGORITHM =
// ===================================
DRAW_LINE: // R10=X1, R11=Y1, R12=X2, R13=Y2, R8=COLOR
	PUSH R14
	PUSH R15
	PUSH R16
	PUSH R17
	
	// [0] - DX
	// [1] - DY
	// [2] - INCYR
	// [3] - INCYI
	// [4] - INCXR
	// [5] - INCXI
	// [6] - TEMP (K)
	// [7] - AVR (2*DY)
	// [8] - AV (AVR-DX)
	// [9] - AVI (AV-DX)
	// [10] - CURRENT X
	// [11] - CURRENT Y
	// [12] - X2 (TARGET)
	// [13] - Y2 (TARGET)
	
	// SAVE TARGET ENDPOINTS
	MOV [12], R12     // SAVE X2
	MOV [13], R13     // SAVE Y2
	
	// CALCULATE DX = X2 - X1
	MOV R14, R10      // GET X1
	MOV R16, R12      // GET X2
	SUB R16, R14      // SUBTRACT X2 - X1
	MOV [0], R16      // STORE IN MEM 0 (DX)

	// CALCULATE DY = Y2 - Y1
	MOV R15, R11      // GET Y1
	MOV R17, R13      // GET Y2
	SUB R17, R15      // SUBTRACT Y2 - Y1
	MOV [1], R17      // STORE IN MEM 1 (DY)

	// HANDLE DY SIGN FOR INCYI
	CMP [1], 0	       // COMPARE DY TO 0
	JGE SETY	       // IF GREATER OR EQUAL
	JL  LWRY	       // ELSE IF LOWER

	SETY:
		MOV [3], 1         // SET INCYI TO 1
		JMP YOPND          // SKIP ELSE SCENARIO
	LWRY:
		MOV R14, [1]       // ELSE SCENARIO
		MUL R14, -1	       // INVERT SIGN
		MOV [1], R14       // STORE POSITIVE DY
		MOV [3], -1	       // SET INCYI -1	
	YOPND:

	// HANDLE DX SIGN FOR INCXI
	CMP [0], 0	       // COMPARE DX TO 0
	JGE SETX	       // IF GREATER OR EQUAL
	JL  LWRX	       // ELSE IF LOWER

	SETX:
		MOV [5], 1         // SET INCXI TO 1
		JMP XOPND          // SKIP ELSE SCENARIO
	LWRX:
		MOV R14, [0]       // ELSE SCENARIO
		MUL R14, -1	       // INVERT SIGN
		MOV [0], R14       // STORE POSITIVE DX
		MOV [5], -1	       // SET INCXI -1	
	XOPND:
	
	// DETERMINE WHETHER DX OR DY IS LARGER
	CMP [0], [1]	   // COMPARE DX TO DY
	JGE MODY		   // IF DX >= DY
	JL  MODX		   // ELSE IF DX < DY

	MODY:  // DX >= DY
		MOV [2], 0	       // INCYR = 0
		MOV [4], [5]       // INCXR = INCXI
		JMP MODND	       // END IF

	MODX:  // DX < DY
		MOV [4], 0	       // INCXR = 0
		MOV [2], [3]       // INCYR = INCYI
		MOV R14, [0]       // K = DX
		MOV R15, [1]       // 
		MOV [6], R14       // STORE K
		MOV [0], R15       // DX = DY
		MOV [1], R14       // DY = K
	MODND:
	
	// SET INITIAL X AND Y
	MOV [10], R10      // CURRENT X = X1
	MOV [11], R11      // CURRENT Y = Y1

	// CALCULATE BRESENHAM PARAMETERS
	MOV R14, [1]       // LOAD DY
	MUL R14, 2         // AVR = 2 * DY
	MOV [7], R14       // STORE AVR

	MOV R14, [7]       // AVR
	MOV R15, [0]       // DX
	SUB R14, R15       // AV = AVR - DX
	MOV [8], R14       // STORE AV

	MOV R14, [8]       // AV
	MOV R15, [0]       // DX
	SUB R14, R15       // AVI = AV - DX
	MOV [9], R14       // STORE AVI

	LINE_LOOP:             // START DO WHILE
		// DRAW CURRENT PIXEL
		MOV R0, [10]	   // MOVE X TO PARAMETER
		MOV R1, [11]	   // MOVE Y TO PARAMETER
		CALL PUT_PIXEL	   // PUT A PIXEL IN POSITION
	
		// CHECK IF WE REACHED THE END (X != X2 OR Y != Y2)
		MOV R14, [10]
		MOV R15, [12]      // LOAD SAVED X2
		CMP R14, R15
		JNE CONTINUE_LINE
		MOV R14, [11]
		MOV R15, [13]      // LOAD SAVED Y2
		CMP R14, R15
		JE  LINE_DONE      // IF BOTH EQUAL, EXIT
	
		CONTINUE_LINE:
			CMP [8], 0		   // COMPARE AV TO 0
			JGE INCI		   // IF AV >= 0, USE I INCREMENT
			JL	INCR		   // IF AV < 0, USE R INCREMENT

			INCI:  // AV >= 0 CASE
				MOV R14, [10]      // LOAD X
				MOV R15, [5]       // LOAD INCXI
				ADD R14, R15       // ADD X AND INCXI
				MOV [10], R14      // STORE X NEW VAL

				MOV R14, [11]      // LOAD Y
				MOV R15, [3]       // LOAD INCYI
				ADD R14, R15       // ADD Y AND INCYI
				MOV [11], R14      // STORE Y NEW VAL
	
				MOV R14, [8]       // LOAD AV
				MOV R15, [9]       // LOAD AVI
				ADD R14, R15       // ADD AV AND AVI
				MOV [8], R14       // SAVE AV NEW VAL
				JMP ENDINC

			INCR:  // AV < 0 CASE
				MOV R14, [10]      // LOAD X
				MOV R15, [4]       // LOAD INCXR
				ADD R14, R15       // ADD X AND INCXR
				MOV [10], R14      // STORE X NEW VAL
	
				MOV R14, [11]      // LOAD Y
				MOV R15, [2]       // LOAD INCYR
				ADD R14, R15       // ADD Y AND INCYR
				MOV [11], R14      // STORE Y NEW VAL
	
				MOV R14, [8]       // LOAD AV
				MOV R15, [7]       // LOAD AVR
				ADD R14, R15       // ADD AV AND AVR
				MOV [8], R14       // SAVE AV NEW VAL
	
		ENDINC:
		JMP LINE_LOOP

	LINE_DONE:
	POP R17
	POP R16
	POP R15
	POP R14
	RET

SCREEN_FUNC:
	// TEST DRAW_LINE WITH DIAGONAL
	MOV R10, 5       // X1
	MOV R11, 5       // Y1
	MOV R12, 20      // X2
	MOV R13, 20      // Y2
	MOV R8, YELLOW   // COLOR
	CALL DRAW_LINE
	
	// TEST HORIZONTAL LINE
	MOV R10, 5       // X1
	MOV R11, 10      // Y1
	MOV R12, 25      // X2
	MOV R13, 10      // Y2
	MOV R8, GREEN    // COLOR
	CALL DRAW_LINE
	
	// TEST VERTICAL LINE
	MOV R10, 15      // X1
	MOV R11, 5       // Y1
	MOV R12, 15      // X2
	MOV R13, 25      // Y2
	MOV R8, BLUE     // COLOR
	CALL DRAW_LINE
RET

INPUT_FUNC:
	// =====================
	// = FETCH KEYBD INPUT =
	// =====================
	MOV R6, PORT1
	MOV [500], R6  // FETCH ASCII VALUE FROM IOBus
	// ==========================================
	CMP [500], 119 // IF KEY == w
	JE CASE_W
	CMP [500], 97  // IF KEY == a
	JE CASE_A
	CMP [500], 115 // IF KEY == s
	JE CASE_S
	CMP [500], 100 // IF KEY == d
	JE CASE_D
	CMP [500], 0   // NO KEY PRESSED (DEFAULT)
	JE CASE_N
	// =======================================
	// =      SWITCH CASES IN THE CODE      =
	// =======================================
	JMP K_FINISH
	CASE_W:
		// W WAS PRESSED IN KEYBOARD
		MOV R0, 0
		MOV R1, 0
		MOV R8, GREEN
		CALL PUT_PIXEL
	JMP K_FINISH
	CASE_A:
		// A WAS PRESSED IN KEYBOARD
		MOV R0, 0
		MOV R1, 0
		MOV R8, YELLOW
		CALL PUT_PIXEL
	JMP K_FINISH
	CASE_S:
		// S WAS PRESSED IN KEYBOARD
		MOV R0, 0
		MOV R1, 0
		MOV R8, BLUE
		CALL PUT_PIXEL
	JMP K_FINISH
	CASE_D:
		// D WAS PRESSED IN KEYBOARD
		MOV R0, 0
		MOV R1, 0
		MOV R8, PURPLE
		CALL PUT_PIXEL
	JMP K_FINISH
	CASE_N: // NULL DATA
		// EMPTY CASE
	JMP K_FINISH
	// ==========================================
	K_FINISH:
		MOV [500], 0
RET

// =======================
START:              // PROGRAM STARTS HERE THIS IS THE MAIN ROUTINE
    CALL INIT       // INITIALIZE SCREEN
	
	BON_MAIN_LOOP:
		CALL SCREEN_FUNC
		CALL INPUT_FUNC
	JMP BON_MAIN_LOOP
INT 1               // SYSTEM INTERRUPTION FOR END PROGRAM
