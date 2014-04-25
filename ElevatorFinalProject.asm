;Final Project
;ElevatorFinalProject.asm
;Austin Shahan, Melody Engel

Assume cs:code, ds:data, ss:stack

data segment
; All variables defined within the data segment
ElevatorCalls db	0FFH		;A byte storing whether the direction has been called from a floor
								;Was chosen to store this way so that each bit corresponds directly to an LED
						
CurrentFloor db		11111110B	;The first five bits hold the current floor of the elevator
								;Was chosen to store this way so that each bit corresponds directly to an LED
								;And can be rotated to change the current floor

ElevatorMotion db	10111111B 	;The eighth bit contains whether the elevator is currently stopped
MovingUp db			10111111B	;The seventh bit says if the elevator is going up
MovingDown db		11011111B	;The sixth bit says if the elevator is going down
						
UserDestinations db	0FFH		;A byte that stores whether somebody on the elevator wishes to go to that given
								;Floor. Bytes 0 through 4 correspond to floors 1 through 5 respectively
							
CurrentFloorStatement db "Current Floor:$"							
FloorPrompt db "Enter Floor (1-5) (Enter to quit):$"
InvalidSelection db "Invalid.$"
BeginningGoodbye db "You have arrived at floor $"
EndingGoodbye db ". Have a nice day!$"
ProgramGoodbye db "Goodbye.$"
				
data ends

stack segment
dw 100 dup(?)
stacktop:
stack ends

code segment
begin:
MOV AX, data
MOV DS, AX
MOV AX, stack
MOV SS, AX
MOV SP, offset stacktop

;THIS IS WHERE CODE BEGINS
CALL SETUP

waitForInput:			;Wait for the initial call
CALL PUSHBUTTONS
CALL UPDATE_LEDS
CMP ElevatorCalls, 0FFH
JE waitForInput			;There are no calls for the elevator to process
JNE determineMovement	;The elevator should process calls

determineMovement:
MOV DL, ElevatorMotion
OR DL, 10011111B		;Only worry about the elevator direction
CMP DL, MovingUp		;Is the UP direction bit set?
JE SearchCallsUp
CMP DL, MovingDown		;Is the DOWN direction bit set?
JE SearchCallsDown
JNE exit

SearchCallsUp:
CALL PUSHBUTTONS
CALL UPDATE_LEDS
MOV AL, UserDestinations
MOV DL, ElevatorCalls
MOV DH, CurrentFloor
CMP DH, 11111110B		;Are we on floor 1?
JE UpOnOne
CMP DH, 11111101B		;Are we on floor 2?
JE UpOnTwo
CMP DH, 11111011B		;Are we on floor 3?
JE UpOnThree
CMP DH, 11110111B		;Are we on floor 4?
JE UpOnFour
CMP DH, 11101111B		;Are we on floor 5?
JE UpOnFive

UpOnOne:					;Going Up On 1
OR DL, 10101010B			;Only worry about the up calls
OR AL, 11100001B			;Only worry about the destinations above this floor
JMP ProcessUpCalls
UpOnTwo:					;Going Up On 2
OR DL, 10101011B			;Only worry about the up calls
OR AL, 11100011B			;Only worry about the destinations above this floor
JMP ProcessUpCalls
UpOnThree:					;Going Up On 3
OR DL, 10101111B			;Only worry about the up calls
OR AL, 11100111B			;Only worry about the destinations above this floor
JMP ProcessUpCalls
UpOnFour:					;Going Up On 4
OR DL, 10111111B			;Only worry about the up calls
OR AL, 11101111B			;Only worry about the destinations above this floor
JMP ProcessUpCalls
UpOnFive:					;Since the elevator can't go up from 5
CALL SET_MOVING_DOWN		;Set the elevator to go up
JMP SearchCallsDown			;And search up

ProcessUpCalls:
CALL PUSHBUTTONS
CALL UPDATE_LEDS
CMP DL, 0FFH						;Are there calls?
JNE MoveUpDirection
CMP AL, 0FFH						;Are there user destinations?
JNE MoveUpDirection					;If there are no calls of any kind in the up direction,
CALL SET_MOVING_DOWN				;Search the down direction
JMP SearchCallsDown

MoveUpDirection:			;Move Up and Check Whether a user wants on or off
CALL MOVE_UP				
CALL CHECK_USER_WANTS_OFF
CALL CHECK_USER_WANTS_ON
JMP DetermineMovement

SearchCallsDown:
CALL PUSHBUTTONS
CALL UPDATE_LEDS
MOV AL, UserDestinations
MOV DL, ElevatorCalls
MOV DH, CurrentFloor
CMP DH, 11111110B					;Are we on floor 1?
JE DownOnOne
CMP DH, 11111101B					;Are we on floor 2?
JE DownOnTwo
CMP DH, 11111011B					;Are we on floor 3?
JE DownOnThree
CMP DH, 11110111B					;Are we on floor 4?
JE DownOnFour
CMP DH, 11101111B					;Are we on floor 5?
JE DownOnFive

DownOnOne:							;Since we can't go down from 1
CALL SET_MOVING_UP					;Set the elevator to go up
JMP SearchCallsUp					;And Search up
DownOnTwo:					;Going down on 2
OR DL, 11111101B			;Only worry about the down calls
OR AL, 11111110B			;Only worry about the destinations below this floor
JMP ProcessDownCalls
DownOnThree:				;Going down on 3
OR DL, 11110101B			;Only worry about the down calls
OR AL, 11111100B			;Only worry about the destinations below this floor
JMP ProcessDownCalls
DownOnFour:					;Going down on 4
OR DL, 11010101B			;Only worry about the down calls
OR AL, 11111000B			;Only worry about the destinations below this floor
JMP ProcessDownCalls
DownOnFive:					;Going down on 5
OR DL, 01010101B			;Only worry about the down calls
OR AL, 11110000B			;Only worry about the destinations below this floor
JMP ProcessDownCalls

ProcessDownCalls:
CALL PUSHBUTTONS
CALL UPDATE_LEDS
CMP DL, 0FFH						;Are there calls?
JNE MoveDownDirection
CMP AL, 0FFH						;Are there user destinations?
JNE MoveDownDirection				;If there are no calls in the down direction,
CALL SET_MOVING_UP					;Search up
JMP SearchCallsUp

MoveDownDirection:			;Move down and check whether the user wants on or off
CALL MOVE_DOWN
CALL CHECK_USER_WANTS_OFF
CALL CHECK_USER_WANTS_ON
JMP DetermineMovement

exit:
LEA SI, ProgramGoodbye
CALL PRINT
MOV AH, 4CH
INT 21H

;----------Subroutines----------
;----SETUP----
;Setup the inital states of the I/O Ports
SETUP:
MOV DX, 143H
MOV AL, 02H
OUT DX, AL

setup_OutputA:	;Setup the output on Port A
MOV DX, 140H
MOV AL, 0FFH
OUT DX, AL

setup_OutputB:	;Setup the output on Port B
MOV DX, 141H
MOV AL, 0FFH
OUT DX, AL

setup_InputC:	;Setup the input on Port C
MOV DX, 142H
MOV AL, 00H
OUT DX, AL

MOV DX, 143H
MOV AL, 03H
OUT DX, AL

MOV DX, 140H
MOV AL, 0FFH	;Reset Port A
OUT DX, AL

MOV DX, 141H	;Reset Port B
MOV AL, 0FFH
OUT DX, AL
RET

;----PRINT----
PRINT:
PUSH AX
PUSH DX

MOV AH, 2
pLoop:
MOV DL, [SI]
CMP DL, "$"
JE endPrint
INT 21H
INC SI
JMP pLoop

endPrint:
MOV AH, 2
MOV DL, 0DH
INT 21H
MOV DL, 0AH
INT 21H

POP DX
POP AX
RET

;----DELAY----
DELAY:
PUSH BX
PUSH CX

MOV BX, 0FFFFH	 		;Set BX and CX to values
MOV CX, 24
outL:
CALL PUSHBUTTONS		;Check the pushbutton's state while in the delay
CALL UPDATE_LEDS
DEC BX	 				;Decrement BX
CMP BX, 0H	 			;If BX is 0, then MOVe to the inner loop
JNE outL
MOV BX, 0FFFFH	 		;Reset BX
DEC CX	 				;Decrement CX in the inner loop
CMP CX, 0H	 			;If CX is 0, then end the delay loop
JNE outL

POP CX
POP BX
RET

;----CHECK PUSHBUTTONS----
PUSHBUTTONS:	 		;A Loop to sense the input from the buttons in Port C
PUSH DX
PUSH AX
PUSH BX
MOV BL, ElevatorCalls	;Current Elevator Calls State
MOV DX, 142H
IN AL, DX				;NEW Elevator Calls State
AND AL, BL	 			;Only worry about the bits that haven't already been pressed
MOV ElevatorCalls, AL

POP BX
POP AX
POP DX
RET

;----MOVE UP----
MOVE_UP:
PUSH DX
PUSH AX
CALL DELAY				;Call DELAY to simulate the elevator taking time to move floors
MOV AL, CurrentFloor	;Grab the current floor
ROL AL, 1				;Shift the current floor to the left, moving the bit to the next one
MOV CurrentFloor, AL	;Store the current floor bits back into the CurrentFloor
CALL UPDATE_LEDS
POP AX
POP DX
RET

;----SET MOVING DOWN----
SET_MOVING_DOWN:		;Set the elevator to move down
PUSH SI
PUSH AX
MOV AH, MovingDown
MOV ElevatorMotion, AH
POP AX
POP SI
RET

;----MOVE DOWN----
MOVE_DOWN:
PUSH DX
PUSH AX
CALL DELAY				;Call DELAY to simulate the elevator taking time to move floors
MOV AL, CurrentFloor	;Grab the current floor
ROR AL, 1				;Shift the current floor to the right, moving the bit to the previous one
MOV CurrentFloor, AL	;Store the current floor bits back into the CurrentFloor
CALL UPDATE_LEDS
POP AX
POP DX
RET

;----SET MOVING UP----
SET_MOVING_UP:		;Set the elevator to move up
PUSH SI
PUSH AX
MOV AH, MovingUp
MOV ElevatorMotion, AH
POP AX
POP SI
RET

;----CHECK USER WANTS ON----
CHECK_USER_WANTS_ON:
PUSH DX
PUSH CX
PUSH AX
PUSH SI
PUSH BX
MOV CX, 3
MOV BX, 1
CALL RESET_ELEVATOR_CALLS	;Reset the current elevator calls for this floor, because the people requesting the elevator got on
CMP BX, 0					;BX is set to 0 by RESET_ELEVATOR_CALLS in order to determine whether people want on
JNE EndGetDestinations		;Nobody Wants On
LEA SI, CurrentFloorStatement	;Print the current floor statement, along with the current floor number
CALL PRINT
CALL PRINT_CURRENT_FLOOR
MOV DL, 0DH
INT 21H
MOV DL, 0AH
INT 21H
PromptDestination:
CALL GREET_USER				;Ask the user what floor they'd like
MOV AH, 1
INT 21H
PUSH AX
PUSH DX
MOV AH, 2
MOV DL, 0DH
INT 21H
MOV DL, 0AH
INT 21H
POP DX
POP AX
CMP AL, 0DH		;User Entered an Enter
JE EndGetDestinations
CMP AL, 31H		;User Entered a 1
JE Floor1Destination
CMP AL, 32H		;User Entered a 2
JE Floor2Destination
CMP AL, 33H		;User Entered a 3
JE Floor3Destination
CMP AL, 34H		;User Entered a 4
JE Floor4Destination
CMP AL, 35H		;User Entered a 5
JE Floor5Destination
JNE InvalidDestination

;Depending on the floor input, mark that floor in UserDestinations
Floor1Destination:
AND UserDestinations, 11111110B
JMP PromptNextDestination

Floor2Destination:
AND UserDestinations, 11111101B
JMP PromptNextDestination

Floor3Destination:
AND UserDestinations, 11111011B
JMP PromptNextDestination

Floor4Destination:
AND UserDestinations, 11110111B
JMP PromptNextDestination

Floor5Destination:
AND UserDestinations, 11101111B
JMP PromptNextDestination

InvalidDestination:
LEA SI, InvalidSelection
CALL PRINT
JMP PromptDestination
PromptNextDestination:
LOOP PromptDestination

EndGetDestinations:
POP BX
POP SI
POP AX
POP CX
POP DX
RET

;----RESET ELEVATOR CALLS----
RESET_ELEVATOR_CALLS:
PUSH DX
PUSH AX
;If there are no elevator calls, exit
CMP ElevatorCalls, 0FFH
JE EndResetCalls

MOV DL, ElevatorCalls
MOV AL, ElevatorMotion
;Reset different bits depending on the current floor
CMP CurrentFloor, 11111110B
JE ResetOnOne
CMP CurrentFloor, 11111101B
JE ResetOnTwo
CMP CurrentFloor, 11111011B
JE ResetOnThree
CMP CurrentFloor, 11110111B
JE ResetOnFour
CMP CurrentFloor, 11101111B
JE ResetOnFive

;For each floor, reset different bits depending on the current direction
;the elevator is headed
ResetOnOne:
CMP AL, MovingUp
JE ResetUpOneCall
ResetOnTwo:
CMP AL, MovingUp
JE ResetUpTwoCall
JMP ResetDownTwoCall
ResetOnThree:
CMP AL, MovingUp
JE ResetUpThreeCall
JMP ResetDownThreeCall
ResetOnFour:
CMP AL, MovingUp
JE ResetUpFourCall
JMP ResetDownFourCall
ResetOnFive:
CMP AL, MovingDown
JE ResetDownFiveCall
JMP EndResetCalls

ResetUpOneCall:
OR DL, 11111110B				;Only worry about the first floor up call
CMP DL, 11111110B
JNE EndResetCalls
OR ElevatorCalls, 00000001B
MOV BX, 0
JMP EndResetCalls
ResetDownTwoCall:
OR DL, 11111101B				;Only worry about the second floor down call
CMP DL, 11111101B
JNE EndResetCalls
OR ElevatorCalls, 00000010B
MOV BX, 0
JMP EndResetCalls
ResetUpTwoCall:
OR DL, 11111011B				;Only worry about the second floor up call
CMP DL, 11111011B
JNE EndResetCalls
OR ElevatorCalls, 00000100B
MOV BX, 0
JMP EndResetCalls
ResetDownThreeCall:
OR DL, 11110111B				;Only worry about the third floor down call
CMP DL, 11110111B
JNE EndResetCalls
OR ElevatorCalls, 00001000B
MOV BX, 0
JMP EndResetCalls
ResetUpThreeCall:				;Only worry about the third floor up call
OR DL, 11101111B
CMP DL, 11101111B
JNE EndResetCalls
OR ElevatorCalls, 00010000B
MOV BX, 0
JMP EndResetCalls
ResetDownFourCall:
OR DL, 11011111B				;Only worry about the fourth floor down call
CMP DL, 11011111B
JNE EndResetCalls
OR ElevatorCalls, 00100000B
MOV BX, 0
JMP EndResetCalls
ResetUpFourCall:				;Only worry about the fourth floor up call
OR DL, 10111111B
CMP DL, 10111111B
JNE EndResetCalls
OR ElevatorCalls, 01000000B
MOV BX, 0
JMP EndResetCalls
ResetDownFiveCall:				;Only worry about the fifth floor down call
OR DL, 01111111B
CMP DL, 01111111B
JNE EndResetCalls
OR ElevatorCalls, 10000000B
MOV BX, 0

EndResetCalls:
CALL UPDATE_LEDS
POP AX
POP DX
RET

;----RESET USER DESTINATIONS----
RESET_USER_DESTINATIONS:
PUSH DX
;If there are no user destinations, exit
CMP UserDestinations, 0FFH
JE EndResetUserDestinations
;Reset different bits based on the current floor
MOV DL, UserDestinations
CMP CurrentFloor, 11111110B
JE ResetOnOneB
CMP CurrentFloor, 11111101B
JE ResetOnTwoB
CMP CurrentFloor, 11111011B
JE ResetOnThreeB
CMP CurrentFloor, 11110111B
JE ResetOnFourB
CMP CurrentFloor, 11101111B
JE ResetOnFiveB

ResetOnOneB:
OR DL, 11111110B
CMP DL, 11111110B
JNE EndResetUserDestinations
OR UserDestinations, 00000001B
MOV BX, 0
JMP EndResetUserDestinations
ResetOnTwoB:
OR DL, 11111101B
CMP DL, 11111101B
JNE EndResetUserDestinations
OR UserDestinations, 00000010B
MOV BX, 0
JMP EndResetUserDestinations
ResetOnThreeB:
OR DL, 11111011B
CMP DL, 11111011B
JNE EndResetUserDestinations
OR UserDestinations, 00000100B
MOV BX, 0
JMP EndResetUserDestinations
ResetOnFourB:
OR DL, 11110111B
CMP DL, 11110111B
JNE EndResetUserDestinations
OR UserDestinations, 00001000B
MOV BX, 0
JMP EndResetUserDestinations
ResetOnFiveB:
OR DL, 11101111B
CMP DL, 11101111B
JNE EndResetUserDestinations
OR UserDestinations, 00010000B
MOV BX, 0
JMP EndResetUserDestinations

EndResetUserDestinations:
CALL UPDATE_LEDS
POP DX
RET

;----GREET USER----
;Prompt the user to enter a floor
GREET_USER:
PUSH SI
PUSH DX
PUSH AX
MOV AH, 2
MOV DL, 0DH
INT 21H
MOV DL, 0AH
INT 21H
LEA SI, FloorPrompt
CALL PRINT
POP AX
POP DX
POP SI
RET

;----CHECK USER WANTS OFF----
CHECK_USER_WANTS_OFF:
PUSH DX
PUSH SI
POP SI
MOV BX, 1
CALL RESET_USER_DESTINATIONS	;Check if somebody wants off and the UserDestination bit needs reset
CMP BX, 0
JNE NobodyWantsOff
;If somebody wants off, say goodbye
CALL SAY_BYE
;Reset the bit of UserDestinations corresponding to the current floor
MOV DH, CurrentFloor
NOT DH
OR UserDestinations, DH
NobodyWantsOff:
POP DX
RET

;----SAY BYE----
;Say goodbye to the user for the current floor
SAY_BYE:
PUSH SI
PUSH AX
PUSH DX

LEA SI, BeginningGoodbye
CALL PRINT

CALL PRINT_CURRENT_FLOOR

LEA SI, EndingGoodbye
CALL PRINT

POP DX
POP AX
POP SI
RET

;----PRINT CURRENT FLOOR----
;Print the current floor number
PRINT_CURRENT_FLOOR:
MOV AH, 2
;Print a different statment based on the current floor
MOV AL, CurrentFloor
OR AL, 11100000B		;Worry only about the 5 bits that actually correspond to floor values
CMP AL, 11111110B
JE PrintFloor1
CMP AL, 11111101B
JE PrintFloor2
CMP AL, 11111011B
JE PrintFloor3
CMP AL, 11110111B
JE PrintFloor4
CMP AL, 11101111B
JE PrintFloor5

;Print floor numbers respectively
PrintFloor1:
MOV DL, "1"
INT 21H
JMP PrintEnd
PrintFloor2:
MOV DL, "2"
INT 21H
JMP PrintEnd
PrintFloor3:
MOV DL, "3"
INT 21H
JMP PrintEnd
PrintFloor4:
MOV DL, "4"
INT 21H
JMP PrintEnd
PrintFloor5:
MOV DL, "5"
INT 21H
JMP PrintEnd

PrintEnd:
RET

;----UPDATE LEDS----
;Update the LEDS by sending their states to the ports
UPDATE_LEDS:
CALL ELEVATOR_DIRECTIONS_LEDS
CALL ELEVATOR_STATUS_LEDS
RET

;----ELEVATOR DIRECTIONS----
ELEVATOR_DIRECTIONS_LEDS:
PUSH DX
PUSH AX

MOV DX, 140H
MOV AL, ElevatorCalls
OUT DX, AL

POP AX
POP DX
RET

;----ELEVATOR STATUS----
ELEVATOR_STATUS_LEDS:
PUSH DX
PUSH AX

MOV DX, 141H
MOV AL, CurrentFloor	;AND CurrentFloor and ElevatorMotion to get a byte value
AND AL, ElevatorMotion	;for both pieces of data that can be sent to the port at once
OUT DX, AL

POP AX
POP DX
RET

;This is where code ends
code ends
end begin