;Written by Sanqui
INCLUDE "includes.asm"

SECTION "Music_Player", ROMX, BANK[MUSIC_PLAYER]

NUMSONGS EQU 167

placestring_: MACRO
    hlcoord \1, \2
    ld de, \3
    call PlaceString
    ENDM

jbutton: MACRO
	ld a, [hJoyPressed]
	and \1
	jp nz, \2 ; TODO jx
    ENDM

printbit: MACRO
    ld hl, \1
    bit \2, [hl]
    decoord \3, \4
    jr z, .notset\@
    ld a, \5
    ld [de], a
    jr .end\@
.notset\@
    ld a, \6
    ld [de], a
.end\@
    inc de
    ENDM

textbox: MACRO
    hlcoord \1, \2
    ld bc, ( (\4-\2) << 8) + (\3-\1)
    call TextBox
    ENDM

SECTION "bank79", ROMX, BANK[$79]

MusicPlayer:
	;ld de, 01
	;call PlayMusic
	;call WhiteBGMap
	;call ClearTileMap
	ld bc, MPTilemapEnd-MPTilemap
	ld hl, MPTilemap
	decoord 0, 0
	call CopyBytes
	ld a, [CurMusic]
	jr .redraw
.loop
    call DelayFrame
	call GetJoypad
	jbutton B_BUTTON, .exit
	jbutton D_LEFT, .left
	jbutton D_RIGHT, .right
	jbutton D_DOWN, .down
	jbutton D_UP, .up
	jbutton A_BUTTON, .a
	jbutton SELECT, .select
	call DrawChData
    jr .loop
.left
    ld a, [wSongSelection]
    dec a
    cp a, $0
    jr nz, .redraw
    ld a, NUMSONGS-1
    jr .redraw
.right
    ld a, [wSongSelection]
    inc a
    cp a, NUMSONGS
    jr nz, .redraw
    ld a, 1
    jr .redraw
.down
    ld a, [wSongSelection]
    sub a, 10
    cp a, NUMSONGS
    jr c, .redraw
    ld a, NUMSONGS-1
    jr .redraw
.up
    ld a, [wSongSelection]
    add a, 10
    cp a, NUMSONGS
    jr c, .redraw
    ld a, 1
    jr .redraw
.redraw
    ld [wSongSelection], a
	ld a, " "
	hlcoord 5, 2
	ld bc, 75
	call ByteFill
	hlcoord 0, 7
	ld bc, 40
	call ByteFill
	hlcoord 0, 10
	ld bc, 40
	call ByteFill
	hlcoord 5, 2
	ld de, wSongSelection
	ld bc, $0103
	call PrintNum
	call DrawSongName
	hlcoord 16, 1
	ld de, .daystring
	ld a, [GBPrinter]
	bit 2, a
	jr nz, .nitemusic
.drawtimestring
	call PlaceString
	jp .loop
.nitemusic
	ld de, .nitestring
	jr .drawtimestring
.nitestring
	db "Nite@"
.daystring
	db "    @"
.a
	ld a, [wSongSelection]
	ld e, a
	ld d, 0
	callba PlayMusic2
	jp .loop
.select
	ld a, [GBPrinter]
	xor 4
	ld [GBPrinter], a
	ld a, [wSongSelection]
	ld e, a
	ld d, 0
	callba PlayMusic2
	ld a, [wSongSelection]
	jp .redraw
.exit
    ret

DrawChData:
    printbit Channel1Flags,  0, 0, 13, "1", "-" ; enabled
    printbit Channel1Flags,  4, 1, 13, "N", "n" ; noise sampling
    printbit Channel1Flags2, 0, 2, 13, "V", "v" ; vibrato
    printbit Channel1Flags2, 2, 3, 13, "D", "d" ; dutycycle
    printbit Channel1Flags3, 0, 4, 13, "U", "D" ; vibrato up/down
    ld a, [Channel1Pitch]
    ld hl, NoteNames
    call GetNthString
    push hl
    pop de
    hlcoord 1, 15
    call PlaceString
    ld a, [Channel1Octave]
    add $f6
    hlcoord 3, 15
    ld [hli], a
    
    hlcoord 0, 14
	ld de, Channel1Tempo
	ld bc, $0103
	call PrintNum
    
    hlcoord 1, 16
	ld de, Channel1NoteDuration
	ld bc, $0103
	call PrintNum
	
	
; CHANNEL 2
    printbit Channel1Flags+$32,  0, 6+0, 13, "1", "-" ; enabled
    printbit Channel1Flags+$32,  4, 6+1, 13, "N", "n" ; noise sampling
    printbit Channel1Flags2+$32, 0, 6+2, 13, "V", "v" ; vibrato
    printbit Channel1Flags2+$32, 2, 6+3, 13, "D", "d" ; dutycycle
    printbit Channel1Flags3+$32, 0, 6+4, 13, "U", "D" ; vibrato up/down
    ld a, [$c145]
    ld hl, NoteNames
    call GetNthString
    push hl
    pop de
    hlcoord 6+1, 15
    call PlaceString
    ld a, [$c146]
    add $f6
    hlcoord 6+3, 15
    ld [hli], a
    
    hlcoord 6+1, 16
	ld de, $c148
	ld bc, $0103
	call PrintNum

; CHANNEL 3
    printbit Channel3+3,  0, 12+0, 13, "1", "-" ; enabled
    
    ld a, [$c177]
    ld hl, NoteNames
    call GetNthString
    push hl
    pop de
    hlcoord 12+1, 15
    call PlaceString
    ld a, [$c178]
    add $f6
    hlcoord 12+3, 15
    ld [hli], a
    
    hlcoord 12+1, 16
	ld de, $c17a
	ld bc, $0103
	call PrintNum
	
; CHANNEL 4
    printbit Channel4+3,  0, 18+0, 13, "1", "-" ; enabled
    ret

DrawSongName:
    ld a, [wSongSelection]
    ld b, a
    ld hl, SongNames
.loop
    ld a, [hli]
    cp -1
    jr z, .noname
    cp b
    jr z, .found
.wrongcomposer
    ld a, [hli]
    cp "@"
    jr nz, .wrongcomposer
.wrongname
    ld a, [hli]
    cp "@"
    jr nz, .wrongname
    jr .loop
.found
    push hl
    pop de
    hlcoord 0, 3
    call PlaceString
    inc de
    hlcoord 0, 4
    call PlaceString
    inc de
    hlcoord 0, 7
    call PlaceString
    inc de
    hlcoord 0, 10
    call PlaceString
    ret
.noname
    ret

MusicPlayerText:
    db "--- MUSIC PLAYER ---@"

ZeroText:
    db "000@"

NoteNames:
    db "- @C @C'@D @D'@E @F @F'@G @G'@A @A'@B @XX@"
; ┌─┐│└┘
MPTilemap:
db "──┘ MUSIC PLAYER └──"
db "                    "
db "Song:               "
db "                    "
db "                    "
db "                    "
db "Composer:           "
db "                    "
db "                    "
db "Arranger:           "
db "                    "
db "                    "
db "─Ch1───Ch2───Ch3─Ch4"
db "     │     │     │  "
db "     │     │     │  "
db "     │     │     │  "
db "     │     │     │  "
db "────────────────────"
MPTilemapEnd

SongNames:
    db 001, "Title Screen@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 002, "Route 1@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 003, "Route 3@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 004, "Route 11@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 005, "Magnet Train@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 006, "VS. Kanto Gym Leader@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 007, "VS. Kanto Trainer@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 008, "VS. Kanto Wild@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 009, "Pokémon Center@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 010, "Spotted! Hiker@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 011, "Spotted! Girl 1@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 012, "Spotted! Boy 1@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 013, "Heal Pokémon@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 014, "Lavender Town@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 015, "Viridian Forest@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 016, "Kanto Cave@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 017, "Follow Me!@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 018, "Game Corner@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 019, "Bicycle@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 020, "Hall of Fame@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 021, "Viridian City@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 022, "Celedon City@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 023, "Victory! Trainer@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 024, "Victory! Wild@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 025, "Victory! Champion@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 026, "Mt. Moon@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 027, "Gym@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 028, "Pallet Town@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 029, "Oak's Lab@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 030, "Professor Oak@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 031, "Rival Appears@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 032, "Rival Departure@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 033, "Surfing@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 034, "Evolution@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 035, "National Park@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 036, "Credits@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 037, "Azalea Town@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 038, "Cherrygrove City@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 039, "Spotted! Kimono Girl@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 040, "Union Cave@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 041, "VS. Johto Wild@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 042, "VS. Johto Trainer@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 043, "Route 30@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 044, "Ecruteak City@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 045, "Violet City@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 046, "VS. Johto Gym Leader@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 047, "VS. Champion@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 048, "VS. Rival@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 049, "VS. Rocket Grunt@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 050, "Elm's Lab@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 051, "Dark Cave@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 052, "Route 29@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 053, "Route 34@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 054, "S.S. Aqua@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 055, "Spotted! Boy 2@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 056, "Spotted! Girl 2@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 057, "Spotted! Team Rocket@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 058, "Spotted! Suspicious@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 059, "Spotted! Sage@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 060, "New Bark Town@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 061, "Goldenrod City@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 062, "Vermilion City@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 063, "Pokémon Channel@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 064, "PokéFlute@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 065, "Tin Tower@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 066, "Sprout Tower@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 067, "Burned Tower@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 068, "Olivine Lighthouse@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 069, "Route 42@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 070, "Indigo Plateau@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 071, "Route 38@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 072, "Rocket Hideout@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 073, "Dragon's Den@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 074, "VS. Johto Wild Night@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 075, "Unown Radio@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 076, "Captured Pokémon@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 077, "Route 26@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 078, "Mom@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 079, "Victory Road@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 080, "Pokémon Lullaby@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 081, "Pokémon March@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 082, "Opening 1@", "Pokémon Gold@", "Junichi Masuda@", "Junichi Masuda@"
    db 083, "Opening 2@", "Pokémon Gold@", "Junichi Masuda@", "Junichi Masuda@"
    db 084, "Load Game@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 085, "Ruins of Alph Inside@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 086, "Team Rocket@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 087, "Dancing Hall@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 088, "Bug Contest Ranking@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 089, "Bug Contest@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 090, "Rocket Radio@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 091, "GameBoy Printer@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 092, "Post Credits@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 093, "Clair@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 094, "Mobile Adapter Menu@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 095, "Mobile Adapter@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 096, "Buena's Password@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 097, "Eusine@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 098, "Opening@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 099, "Battle Tower@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 100, "VS. Suicune@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 101, "Battle Tower Lobby@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 102, "Mobile Center@", "Pokémon Crystal@", "Junichi Masuda@", "Junichi Masuda@"
    db 103, "Opening@", "Pokémon Red@", "Junichi Masuda@", "Junichi Masuda@"
    db 104, "Opening@", "Pokémon Yellow@", "Junichi Masuda@", "Junichi Masuda@"
    db 105, "Title Screen@", "Pokémon Red@", "Junichi Masuda@", "Junichi Masuda@"
    db 106, "Introduction@", "Pokémon Red@", "Junichi Masuda@", "Junichi Masuda@"
    db 107, "Pallet Town@", "Pokémon Red@", "Junichi Masuda@", "Junichi Masuda@"
    db 108, "Professor Oak@", "Pokémon Red@", "Junichi Masuda@", "Junichi Masuda@"
    db 109, "Oak's Lab@", "Pokémon Red@", "Junichi Masuda@", "Junichi Masuda@"
    db 110, "Rival Appears@", "Pokémon Red@", "Junichi Masuda@", "Junichi Masuda@"
    db 111, "Rival Departure@", "Pokémon Red@", "Junichi Masuda@", "Junichi Masuda@"
    db 112, "Route 1@", "Pokémon Red@", "Junichi Masuda@", "Junichi Masuda@"
    db 113, "Viridian City@", "Pokémon Red@", "Junichi Masuda@", "Junichi Masuda@"
    db 114, "Pokémon Center@", "Pokémon Red@", "Junichi Masuda@", "Junichi Masuda@"
    db 115, "Heal Pokémon@", "Pokémon Red@", "Junichi Masuda@", "Junichi Masuda@"
    db 116, "Viridian Forest@", "Pokémon Red@", "Junichi Masuda@", "Junichi Masuda@"
    db 117, "Follow Me!@", "Pokémon Red@", "Junichi Masuda@", "Junichi Masuda@"
    db 118, "Gym@", "Pokémon Red@", "Junichi Masuda@", "Junichi Masuda@"
    db 119, "Jigglypuff Sings@", "Pokémon Red@", "Junichi Masuda@", "Junichi Masuda@"
    db 120, "Route 3@", "Pokémon Red@", "Junichi Masuda@", "Junichi Masuda@"
    db 121, "Mt. Moon@", "Pokémon Red@", "Junichi Masuda@", "Junichi Masuda@"
    db 122, "Jessie and James@", "Pokémon Yellow@", "Junichi Masuda@", "Junichi Masuda@"
    db 123, "Cerulean City@", "Pokémon Red@", "Junichi Masuda@", "Junichi Masuda@"
    db 124, "Vermilion City@", "Pokémon Red@", "Junichi Masuda@", "Junichi Masuda@"
    db 125, "S.S. Anne@", "Pokémon Red@", "Junichi Masuda@", "Junichi Masuda@"
    db 126, "Route 11@", "Pokémon Red@", "Junichi Masuda@", "Junichi Masuda@"
    db 127, "Lavender Town@", "Pokémon Red@", "Junichi Masuda@", "Junichi Masuda@"
    db 128, "Pokémon Tower@", "Pokémon Red@", "Junichi Masuda@", "Junichi Masuda@"
    db 129, "Celedon City@", "Pokémon Red@", "Junichi Masuda@", "Junichi Masuda@"
    db 130, "Game Corner@", "Pokémon Red@", "Junichi Masuda@", "Junichi Masuda@"
    db 131, "Rocket Hideout@", "Pokémon Red@", "Junichi Masuda@", "Junichi Masuda@"
    db 132, "Bicycle@", "Pokémon Red@", "Junichi Masuda@", "Junichi Masuda@"
    db 133, "Evolution@", "Pokémon Red@", "Junichi Masuda@", "Junichi Masuda@"
    db 134, "Surfing Pikachu@", "Pokémon Yellow@", "Junichi Masuda@", "Junichi Masuda@"
    db 135, "Silph Co.@", "Pokémon Red@", "Junichi Masuda@", "Junichi Masuda@"
    db 136, "Surfing@", "Pokémon Red@", "Junichi Masuda@", "Junichi Masuda@"
    db 137, "Cinnabar Island@", "Pokémon Red@", "Junichi Masuda@", "Junichi Masuda@"
    db 138, "Cinnabar Mansion@", "Pokémon Red@", "Junichi Masuda@", "Junichi Masuda@"
    db 139, "Indigo Plateau@", "Pokémon Red@", "Junichi Masuda@", "Junichi Masuda@"
    db 140, "Hall of Fame@", "Pokémon Red@", "Junichi Masuda@", "Junichi Masuda@"
    db 141, "Credits@", "Pokémon Red@", "Junichi Masuda@", "Junichi Masuda@"
    db 142, "Spotted! Boy@", "Pokémon Red@", "Junichi Masuda@", "Junichi Masuda@"
    db 143, "Spotted! Girl@", "Pokémon Red@", "Junichi Masuda@", "Junichi Masuda@"
    db 144, "Spotted! Rocket@", "Pokémon Red@", "Junichi Masuda@", "Junichi Masuda@"
    db 145, "VS. Wild@", "Pokémon Red@", "Junichi Masuda@", "Junichi Masuda@"
    db 146, "VS. Trainer@", "Pokémon Red@", "Junichi Masuda@", "Junichi Masuda@"
    db 147, "VS. Gym Leader@", "Pokémon Red@", "Junichi Masuda@", "Junichi Masuda@"
    db 148, "VS. Champion@", "Pokémon Red@", "Junichi Masuda@", "Junichi Masuda@"
    db 149, "Victory! Wild@", "Pokémon Red@", "Junichi Masuda@", "Junichi Masuda@"
    db 150, "Victory! Trainer@", "Pokémon Red@", "Junichi Masuda@", "Junichi Masuda@"
    db 151, "Victory! Champion@", "Pokémon Red@", "Junichi Masuda@", "Junichi Masuda@"
    db 152, "Unused@", "Pokémon Red@", "Junichi Masuda@", "Junichi Masuda@"
    db 153, "Unused@", "Pokémon Yellow@", "Junichi Masuda@", "Junichi Masuda@"
    db 154, "VS. Wild@", "Pokémon Diamond@", "Junichi Masuda@", "FroggestSpirit@"
    db 155, "VS. Trainer@", "Pokémon Diamond@", "Junichi Masuda@", "FroggestSpirit@"
    db 156, "Route 206@", "Pokémon Diamond@", "Junichi Masuda@", "FroggestSpirit@"
    db 157, "PokéRadar@", "Pokémon Diamond@", "Junichi Diamond@", "FroggestSpirit@"
    db 158, "Cerulean City@", "Pokémon HeartGold@", "Junichi Masuda@", "FroggestSpirit@"
    db 159, "Cinnabar Island@", "Pokémon HeartGold@", "Junichi Masuda@", "FroggestSpirit@"
    db 160, "Route 24@", "Pokémon HeartGold@", "Junichi Masuda@", "FroggestSpirit@"
    db 161, "Shop@", "Pokémon HeartGold@", "Junichi Masuda@", "FroggestSpirit@"
    db 162, "Pokéathelon Finals@", "Pokémon HeartGold@", "Junichi Masuda@", "FroggestSpirit@"
    db 163, "VS. Johto Trainer 2@", "Pokémon Crystal@", "Junichi Masuda@", "FroggestSpirit@"
    db 164, "VS. Naljo Wild@", "Pokémon Prism@", "LevusBevus@", "FroggestSpirit@"
    db 165, "VS. Naljo Gym Leader@", "Pokémon Crystal@", "GRonnoc@", "FroggestSpirit@"
    db 166, "VS. Pallet Patrol@", "Pokémon Crystal@", "Cat333Pokémon@", "FroggestSpirit@"
    db -1
