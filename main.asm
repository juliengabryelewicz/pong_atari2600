
	processor 6502
	include "vcs.h"
	org $F000
	
;=================
; Constantes
;=================

BackgroundColor = $48
BallHeight = $02
BallStartX = $7A
BallStartY = $5E
BallVolleyIncrement = $02
BallVelocityMaxY = $04
BallVelocityMinY = $FC
EndWaitTime = $50
GeneralColor = $0E
MinPaddleY = $0E
MaxPaddleY = $AA
PaddleHeight = $10
Player1Goal = $33
Player0Goal = $C2
ScoreVictory = $0A
StartingWaitTime = $FF

;==================
; Variables
;==================

	seg.u Variables
	ORG  $80
	
Player0Y = $80
Player1Y = $81
Player0Score = $82
Player1Score = $83
Player0Sprite = $84
Player1Sprite = $85
BallY = $86
BallEnabled = $87
BallVelocityY = $88
BallVelocityX = $89
BallPositionX = $8A
Player0Delta = $8B
Player1Delta = $8C
VolleyCount = $8D
Player0ScoreMemLoc = $8E
Player1ScoreMemLoc = $8F
AITick = $90
VictoryTime = $91
WaitTime = $92
NewBallVelocityX = $93

PlayerWhoScored = #03
ToCap = #03
CapRetVal = #04

;==================
; Code
;==================

	seg Code
	ORG  $f000
	

;==================
; Initialisation
;==================	
Start:
	SEI
	CLD
        LDX #$ff 
        TXS 
        LDA #0
        LDX #$ff
        	
ClearZeroPage:
	STA $0,X
	DEX
        BNE ClearZeroPage
        
InitializeValues:
	LDA #BackgroundColor
	STA COLUBK
	LDA #GeneralColor
	STA COLUPF
	STA COLUP0
	STA COLUP1
Positioning:
	STA WSYNC
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP 
	NOP
	STA RESP0
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP 
	STA RESP1
	LDA #%01110000
	STA HMP1
	STA WSYNC
	STA HMOVE
	LDA #%00010000
	STA HMP1
	STA WSYNC
	STA HMOVE
	STA HMCLR
	LDA #96
	STA Player0Y
	STA Player1Y
	STA BallY
	JSR ResetBall
	LDA #0
	STA BallVelocityX
	STA BallVelocityY
	LDA #StartingWaitTime
	STA WaitTime
	STA WSYNC
	STA WSYNC
	
;==================
; Boucle principale
;==================

Main:
        JSR VerticalSync
        JSR CheckJoystick
        JSR CheckCollision
        JSR CheckScore
        JSR CheckAI
        JSR VerticalBlank
        JSR Drawing
        JSR OverScan
        JMP Main
        
;==================
; Vertical Sync
;==================   
     
VerticalSync:
	LDA #2
	STA VSYNC
	STA WSYNC
	STA WSYNC
	STA WSYNC
	LDA #43
	STA TIM64T
	LDA #0
	STA VSYNC
        
;==================
; Joystick
;==================   
        
CheckJoystick:
	LDA #0
	STA Player0Delta
	STA Player1Delta
	LDA VictoryTime
	BNE NoInput
Player0Up:
	LDA %00010000
	BIT SWCHA
	BNE Player0Down
	INC Player0Y
	INC Player0Y
	LDA #1
	STA Player0Delta
Player0Down:
	LDA %00100000
	BIT SWCHA
	BNE NoInput
	DEC Player0Y
	DEC Player0Y
	LDA #-1
	STA Player0Delta
NoInput:
	RTS
	
;==================
; Check Collision
;================== 

CheckCollision:
Player0Playfield:
	LDA #%10000000
	BIT CXP0FB
	BEQ Player1Playfield
	PHA
	LDA Player0Y
	PHA
	JSR CanPaddleToMinMax
	PLA
	PLA
	STA Player0Y
Player1Playfield:
	LDA #%10000000
	BIT CXP1FB
	BEQ PlayerBallCheck
	PHA
	LDA Player1Y
	PHA
	JSR CanPaddleToMinMax
	PLA
	PLA
	STA Player1Y
PlayerBallCheck:
	LDA WaitTime
	BEQ SkipWaitCheck
	DEC WaitTime
	LDA WaitTime
	CMP #EndWaitTime
	BNE SkipBallPhysics
	JMP ClearWait
SkipBallPhysics:
	JMP EndCollision
ClearWait:
	LDA #0
	STA WaitTime
	JSR ResetBall
SkipWaitCheck:
	LDA Player0Delta
	PHA
	LDA #%01000000
	BIT CXP0FB
	BNE PlayerBallConfirmed
	PLA
	LDA Player1Delta
	PHA
	LDA #%01000000
	BIT CXP1FB
	BNE PlayerBallConfirmed
	PLA
	JMP BallPlayfield
PlayerBallConfirmed:
	INC VolleyCount
	LDA VolleyCount
BallVelocityChange:
	LDA BallVelocityX
	CLC
	EOR #$FF
	ADC #1
	STA BallVelocityX
	PLA
	CLC
	ADC BallVelocityY
	CMP #BallVelocityMaxY
	BEQ CapBallToUpper
	CMP #BallVelocityMinY
	BEQ CapBallToLower
	CMP #0
	JMP BallZeroYCheck
CapBallToUpper:
	LDA #BallVelocityMaxY-1
	STA BallVelocityY
	JMP Ricochet
CapBallToLower:
	LDA #BallVelocityMinY+1
	STA BallVelocityY
	JMP Ricochet
BallZeroYCheck:
	BNE Ricochet
	LDA #1
	JMP Ricochet
Ricochet:
	STA BallVelocityY
BallPlayfield:
	LDA #%10000000
	BIT CXBLPF
	BEQ EndCollision
TestBallPlayer0:
	LDA BallPositionX
	CMP #Player0Goal
	BCC TestBallPlayer1
	LDA #1
	PHA
	JSR OnScore
	PLA
	JMP EndCollision
TestBallPlayer1:
	CMP #Player1Goal
	BCS BallRicochet
	LDA #0
	PHA
	JSR OnScore
	PLA
	JMP EndCollision
BallRicochet:
	LDA BallVelocityY
	CLC
	EOR #$FF
	ADC #1
	STA BallVelocityY
EndCollision:
	STA CXCLR
	LDA BallY
	CLC
	ADC BallVelocityY
	STA BallY
	LDA BallVelocityX
	STA HMBL
	STA WSYNC
	STA HMOVE
	CMP #$80
	ROR
	CMP #$80
	ROR
	CMP #$80
	ROR
	CMP #$80
	ROR
	ADC BallPositionX
	STA BallPositionX
	LDA #$00
	STA COLUBK
	LDA %00000001
	STA CTRLPF
	LDX #0
	LDA Player0Score
	ASL
	ASL
	ASL
	STA Player0ScoreMemLoc
	LDA Player1Score
	ASL
	ASL
	ASL
	STA Player1ScoreMemLoc
	LDA BallY
	RTS
	
;==================
; Check Score
;==================
        
CheckScore:
	LDA VictoryTime
	BNE StillWinning
	LDA Player0Score
	CMP #ScoreVictory
	BEQ Player0Won
	LDA Player1Score
	CMP #ScoreVictory
	BEQ Player1Won
	JMP CheckAI
Player0Won:
	INC Player0Score
	LDA #255
	STA VictoryTime
	JMP StillWinning
Player1Won:
	INC Player1Score
	LDA #255
	STA VictoryTime
	JMP StillWinning
StillWinning:
	JSR OnWin
	LDA VictoryTime
	BNE CheckScoreEnd
	LDA #0
	JMP Start
CheckScoreEnd:
	RTS	
	
;================
; AI
;================	
CheckAI:
	LDA AITick
	CMP #2
	BEQ AIStart
	JMP AIEnd
AIStart:
	LDA #0
	STA AITick
	LDA Player1Y
	CMP BallY
	BEQ AIEnd
	BCS AIDown
	INC Player1Y
	INC Player1Y
	JMP AIEnd
AIDown:
	DEC Player1Y
	DEC Player1Y
AIEnd:
	INC AITick
	RTS

;================
; Vertical Blank
;================
VerticalBlank:
	LDA INTIM
	BNE VerticalBlank
	STA WSYNC
	STA VBLANK
	LDY #8
	RTS
	
;================
; Drawing
;================
Drawing:
ScoreDrawLine:
	STA WSYNC
	STA GRP0
	STA GRP1
	STA ENABL
	STA PF0
	STA PF1
	STA PF2
	STA WSYNC
	LDA %00000010
	STA CTRLPF
	LDX #8
ScoreLoop:
	STA WSYNC
	LDA Player0ScoreMemLoc
	TAY
	LDA Numbers,Y
	STA PF1
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	LDA Player1ScoreMemLoc
	TAY
	LDA Numbers,Y
	STA PF1
	INC Player0ScoreMemLoc
	INC Player1ScoreMemLoc
	DEX
	BEQ EndScore
	JMP ScoreLoop
EndScore:
	LDA #0
	STA WSYNC
	STA PF1
	STA PF0
	STA PF2
	STA WSYNC
	STA VBLANK
	LDA %00000001
	STA CTRLPF
	LDY #192
ScanLoop:
	STA WSYNC
ProcessingLine:
	TYA
	SEC
	SBC Player0Y
	BMI DisablePlayer0
	CMP #PaddleHeight
	BCS DisablePlayer0
	LDA %00011000
	STA Player0Sprite
	JMP Player1Check
DisablePlayer0:
	LDA %00000000
	STA Player0Sprite
Player1Check:
	TYA
	SEC
	SBC Player1Y
	BMI DisablePlayer1
	CMP #PaddleHeight
	BCS DisablePlayer1
	LDA %00011000
	STA Player1Sprite
	JMP BallCheck
DisablePlayer1:
	LDA %00000000
	STA Player1Sprite
BallCheck:
	LDA VictoryTime
	BNE DisableBall
	TYA
	SEC
	SBC BallY
	BMI DisableBall
	CMP #BallHeight
	BCS DisableBall
	LDA %00000010
	STA BallEnabled
	JMP DrawLine
DisableBall:
	LDA %00000000
	STA BallEnabled
DrawLine:
	DEY
	STA WSYNC
	LDA Playfield0,Y
	STA PF0
	LDA Playfield1,Y
	STA PF1
	STA PF2
	LDA Player0Sprite
	STA GRP0
	LDA BallEnabled
	STA ENABL
	LDA Player1Sprite
	STA GRP1
	DEY
	CPY #0
	BNE ScanLoop
	LDY #29
	RTS
        
;==================
; OverScan
;==================

OverScan:
        STA WSYNC
        LDA #2
        STA VBLANK
        LDA #32
        STA TIM64T
OverScanWait:
        STA WSYNC
        LDA INTIM
        BNE OverScanWait
        RTS
        
;=================
; Subroutines
;=================
	
CanPaddleToMinMax:
	TSX
	LDA #96
	CMP ToCap,X
	BCS CanPaddleMin
	JMP CanPaddleMax
CanPaddleMin:
	LDA #MinPaddleY
	CMP ToCap,X
	BCC CanPaddleReturn
	STA ToCap,X
	JMP CanPaddleReturn
CanPaddleMax:
	LDA #MaxPaddleY
	CMP ToCap,X
	BCS CanPaddleReturn
	STA ToCap,X
CanPaddleReturn:
	LDA ToCap,X
	STA CapRetVal,X
	RTS
OnScore:
	TSX
	LDA PlayerWhoScored,X
	CMP #0
	BEQ Player0AddScore
	INC Player1Score
	JMP PostScored
Player0AddScore:
	INC Player0Score
PostScored:
	JSR ResetBall
	LDA #0
	STA BallVelocityX
	STA BallVelocityY
	TSX
	LDA PlayerWhoScored,X
	ASL
	ASL
	ASL
	ASL
	STA BallVelocityX
	STA NewBallVelocityX
	LDA #StartingWaitTime
	STA WaitTime
	LDA #0
	STA BallVelocityX
	STA BallVelocityY
	RTS
ResetBall:
	LDA Player0Score
	STA WSYNC
	NOP 
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP 
	NOP
	STA Player0Score
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	BIT Player0Score
	STA RESBL
	LDA #BallStartX
	STA BallPositionX
	LDA #BallStartY
	STA BallY
	LDA Player0Score
	CLC
	ADC Player1Score
	TAY
	LDA VelocityTable,Y
	STA BallVelocityY
	LDA NewBallVelocityX
	BNE SkipResetXVel
	LDA #%00010000
SkipResetXVel:
	STA BallVelocityX
	LDA #0
	STA VolleyCount
	RTS
OnWin:
	LDA #%00001000
	DEC VictoryTime
	BNE OnWinEnd
	LDA #0
	RTS
OnWinEnd:
	RTS
	
;=================
; Graphismes
;=================


Playfield0:
	.byte %11110000
	.byte %11110000
	.byte %11110000
	.byte %11110000
	.byte %11110000
	.byte %11110000
	.byte %11110000
	.byte %11110000
	.byte %11110000
	.byte %11110000
	.byte %11110000
	.byte %11110000
	.byte %11110000
	.byte %11110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %00110000
	.byte %11110000
	.byte %11110000
	.byte %11110000
	.byte %11110000
	.byte %11110000
	.byte %11110000
	.byte %11110000
	.byte %11110000
	.byte %11110000
	.byte %11110000
Playfield1:
	.byte %11111111
	.byte %11111111
	.byte %11111111
	.byte %11111111
	.byte %11111111
	.byte %11111111
	.byte %11111111
	.byte %11111111
	.byte %11111111
	.byte %11111111
	.byte %11111111
	.byte %11111111
	.byte %11111111
	.byte %11111111
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %11111111
	.byte %11111111
	.byte %11111111
	.byte %11111111
	.byte %11111111
	.byte %11111111
	.byte %11111111
	.byte %11111111
	.byte %11111111
	.byte %11111111
Numbers:
Zero:
	.byte %00000111
	.byte %00000101
	.byte %00000101
	.byte %00000101
	.byte %00000101
	.byte %00000101
	.byte %00000101
	.byte %00000111
One:
	.byte %00000010
	.byte %00000010
	.byte %00000010
	.byte %00000010
	.byte %00000010
	.byte %00000010
	.byte %00000010
	.byte %00000010
Two:
	.byte %00000111
	.byte %00000001
	.byte %00000001
	.byte %00000111
	.byte %00000100
	.byte %00000100
	.byte %00000100
	.byte %00000111
Three:
	.byte %00000111
	.byte %00000001
	.byte %00000001
	.byte %00000111
	.byte %00000001
	.byte %00000001
	.byte %00000001
	.byte %00000111
Four:
	.byte %00000101
	.byte %00000101
	.byte %00000101
	.byte %00000111
	.byte %00000001
	.byte %00000001
	.byte %00000001
	.byte %00000001
Five:
	.byte %00000111
	.byte %00000100
	.byte %00000100
	.byte %00000111
	.byte %00000001
	.byte %00000001
	.byte %00000001
	.byte %00000111
Six:
	.byte %00000100
	.byte %00000100
	.byte %00000100
	.byte %00000100
	.byte %00000111
	.byte %00000101
	.byte %00000101
	.byte %00000111
Seven:
	.byte %00000111
	.byte %00000001
	.byte %00000001
	.byte %00000001
	.byte %00000001
	.byte %00000001
	.byte %00000001
	.byte %00000001
Eight:
	.byte %00000111
	.byte %00000101
	.byte %00000101
	.byte %00000111
	.byte %00000101
	.byte %00000101
	.byte %00000101
	.byte %00000111
Nine:
	.byte %00000111
	.byte %00000101
	.byte %00000101
	.byte %00000111
	.byte %00000001
	.byte %00000001
	.byte %00000001
	.byte %00000001
	
Ten:
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	
Win:
	.byte %00000101
	.byte %00000101
	.byte %00000101
	.byte %00000101
	.byte %00000010
	.byte %00000010
	.byte %00000010
	.byte %00000010
VelocityTable:
	.byte %11111111
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %11111111
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %11111111
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %11111111
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %11111111

;=================
; End
;=================
	org $FFFC
	.word Start
	.word Start
