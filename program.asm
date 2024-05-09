	.eqv HEADER_SIZE 	54	# in bytes
	.eqv WIDTH		320	# in pixels(each pixels is 3 bytes)
	.eqv HEIGHT		240
	.eqv PIXEL_B_COUNT 	230400	# = 240*320*3 <- number of pixels reawd

# ==============================================================

	.data

nic:	.space 	2		#only purpose of this is to fix alignment issues while reading first pixel offest	
hdr:	.space	HEADER_SIZE	# stores header information
buf:	.space	PIXEL_B_COUNT

#fname:	.asciz	"/Users/marcinpolewski/Documents/Studia/SEM2/ARKO/projekt-RISC-V/source.bmp"	
#fname:	.asciz	"/Users/marcinpolewski/Documents/Studia/SEM2/ARKO/projekt-RISC-V/line.bmp"	
fname:	.asciz	"/Users/marcinpolewski/Documents/Studia/SEM2/ARKO/projekt-RISC-V/blackPage.bmp"	
erPrpt:	.asciz	"Error has occured during opening"
opPrpt:	.asciz	"File opend successfully"


# ==============================================================
	.text

#open the file
      li a7, 1024	# code for opening file
      la a0, fname	# name of file to open
      li a1, 0		# flag - read only
      ecall

      mv s1, a0		#save the file descriptor

      li t1, -1
      bne t1, s1, readData	# check if error has occured
      
exitWithError:
      # print error prompt
      la a0, erPrpt
      li a7, 4
      ecall
      
      # terminate program
      li a7,10
      ecall
      
readData:

      # print file opened prompt
      la a0, opPrpt
      li a7, 4
      ecall
      
      # read data header
      li a7, 63			#system call for file_read
      mv a0, s1			#move file descr from s1 to a0
      la a1, hdr		#address of data buffer
      li a2, HEADER_SIZE	#amount to read (bytes)
      ecall
      
      # read offset of the first pixel from header
      la t1, hdr
      addi t1,t1, 10
      lw t0, (t1)	# now t0 has wanted offset
      
      # Seek position in a file, so below we will read only pixels
      li a7, 62
      mv a0, s1		# loading file descriptor
      mv a1, t0		# load offset from the base
      li a2, 0		# set the base to the beggining of the file
      ecall
      # returns 54, that means success?
      
      # check if seek was successful
      li t1, -1
      beq a0, t1, exitWithError		# exit if error has occured
      
      # write pixels to buffor
      li a7, 63			#system call for file_read
      mv a0, s1			#move file descr from s1 to a0
      la a1, buf		#address of data buffer
      li a2, PIXEL_B_COUNT	#amount to read (bytes)
      ecall
      
      #check how much data was actually read
      beq zero,a0, fclose
      
processData:
      # used registered till this point: s1
      li t0, HEIGHT		# t0 <- pointer over row(starting from height-1, because .bmp-s are flipped vertically ; i
      addi t0, t0, -1

      li t2, WIDTH
      li t3, HEIGHT
ebreak
rowLoop:			# iterates over rows
      li t1, 0		# t1 <- pointer over column ; j
columnLoop:			# iterates over columns
      mul t4, t2,t0		# idx = i*width
      add t4,t4, t1		# idx += j
      
      li t5, 3
      mul t4,t4,t5		# idx *= 3
      
      
      la t5, buf
      add t4, t4, t5		# now t4 is pointing to pixel in row and column set in t0 and t1(basically idx)
      
      
      mv t5,t4			# temporary pointer, for checking next pixels
checkIfBlack:			# checks if curren pixel is black, if not, take the next one
      lbu a7, (t5)		# load first colour of the pixel lbu ???????????????
      bnez a7, continueLoops	
      addi t5,t5,1
      
      lbu a7, (t5)
      bnez a7, continueLoops
      addi t5,t5,1
      
      lbu a7, (t5)
      bnez a7, continueLoops
calcLengtht:			# calculate length of horizontal line starting at this pixel
      # calculate how many iterations left in this row(stored in t6)
      sub t6, t2, t1		# t6 = width - currentColumn -1 ; 
      addi t6, t6, -1		# t6 = t6 -1, because we know that first pixel is surely black
      
      addi t5,t5, 1		# now t5 points to the right of idx
      
      # a0 stores length of horizontal line
      li a0, 1			# a0 stores length of vertical line(starts with 1, because we know, that at least one element is black)
      
lengthLoop:			
      beqz t6, exitLengthLoop 	# exit loop if no more pixels are left in this row  
      
      lbu a7, (t5)		# exit the loop if pixel is not black
      bnez a7, exitLengthLoop	
      addi t5,t5,1
      lbu a7, (t5)
      bnez a7, exitLengthLoop
      addi t5,t5,1
      lbu a7, (t5)
      bnez a7, exitLengthLoop
      addi t5,t5,1
      
      addi a0,a0, 1		# increment counter
      addi t6, t6, -1		# decrement number of elements left in this row
      j lengthLoop
exitLengthLoop:
      # currently used registers: s1-fileDescriptor, a0-length of horizontal line, t0-t4 <- used for iteration, t6 - number of pixels left in the row
       
       # check if end of line has not been reached - if so continue with loops
       beqz t6, continueLoops
       
       # check parity of horizontal line
       li t5, 2
       remu t6, a0, t5
       bnez t6, continueLoops 	# continue checking if length of horizonal line is an odd number -  
       
       # storing in t5 and t6 lengths of first lines - horisontal and vertical respectively 
       mv t5, a0		# t5 stores length of currently checked horizontal line
       
       mv t6, a0		# t6 stores length of currently check vertical line
       srai t6,t6, 1 		# sra - division by 2 in  U2 code - ok ?????????? theoretically value must be positive - same as in NKB
       
       
       # currently used registers: s1-fileDescriptor, a0-length of horizontal line, t0-t3 <- used for iteration,t4-idx,t5-horizontalLineLength t6-verticalLineLength



checkWhiteL:			# loop responsible for checking L-shape above marker is white(must be of length >= t5+2    
      addi a1,t5,2		# a1 stores required length for horizontal line 
      li a2, -1			# a2 = -1
      add a2, a2, t2		# now a2 = -1 + width 
      
      li a3, 3
      mul a2,a2,a3		# now a2 = -3 + 3width
      
      add a2, a2, t4		# nod a2 = idx + 3(width-1) <- pointer over buffor, where 
      mv a3, a2			# storing this pointer for vertical iteration
      
      	# currently used registers: s1-fileDescriptor, a0-length of horizontal line, t0-t3 <- used for iteration,t4-idx,t5-horizontalLineLength t6-verticalLineLength
	# a3 - sotred pointer to, for next loop ; a2- currently used pointer, a1 - counter of required elngth

checkWhiteLHorizontal:		# iterates and checks horizontal line
      # co gdy na granicy jestesmy ????????
      # co gdy dlugosc lini to 1 ??? <- wtedy reszta z dzielenia przez 2 to jeden i petla bedzie kontynuwoac - nie dojedzie do tego momemntu 
      
      # check if this pixel is black 
      
      lbu a7, (a2)		# exit the loop if pixel is not black
      bnez a7, endOfChecking	
      addi a2,a2,1
      lbu a7, (a2)
      bnez a7, endOfChecking
      addi a2,a2,1
      lbu a7, (a2)
      bnez a7, endOfChecking
      addi a2,a2,1
      
      # pointer over buf is already incremented at this point
      addi a1,a1,-1			# decrementin counter of how many iteration left 
      bnez a1, checkWhiteLHorizontal	# continue iterating if current length

endOfHorizontalChecking: 
      addi a1,t6,2		# a1 stores required length for vertical line 

checkWhiteLVertical:		# checks if vertical horizontal line is white
      lbu a7, (a3)		# exit the loop if pixel is not black
      bnez a7, endOfChecking	
      addi a3,a3,1
      lbu a7, (a3)
      bnez a7, endOfChecking
      addi a3,a3,1
      lbu a7, (a3)
      bnez a7, endOfChecking
      
      addi a2, a2, -2 		# a2 = start_a2 - 3*width <- pixel below this pixel 
      
      li a6, 3 
      mul a6, a6, t2		# a6 = 3*width
      
      sub a3, a3, a6		# now a3 point to pixel below prevoius a3
      
      addi a1, a1,-1			# corecting amount of iteration left
      bnez a1, checkWhiteLVertical

endOfCheckingVerticalWhiteLine:	# successfully ended checking white L 
        # currently used registers: s1-fileDescriptor, a0-length of horizontal line, t0-t3 <- used for iteration,t4-idx,t5-horizontalLineLength t6-verticalLineLength
      
      # copy pointer - each iteration of checking will start from here 
      mv a2, t4 
      

checkBlackLsLoop:		# loop responsible for checking if next L-s are of right length (whilte av!=0 && checkBlackL())

checkBlackLLoop:

	# copy a2 pointer
      mv a3,a2
      
      # copy how many pixels to check
      mv a4, t5 
      
      # currently used registers: s1-fileDescriptor, a0-length of horizontal line, t0-t3 <- used for iteration,t4-idx,t5-horizontalLineLength t6-verticalLineLength
      # a0- how many pixels to check horizontally ; a1 - how many vertically; a2-copy of idx a3 - pointer over line(horizontal/vertical), a4 - copy of how many pixels to check
checkHorizontalLineBlack:	# checks if horizontal line is black 
	
      # check if  pixel is black
      lbu a7, (a3)		
      bnez a7, exitBlackLLoop 
      addi a3,a3,1
      lbu a7, (a3)
      bnez a7, exitBlackLLoop
      addi a3,a3,1
      lbu a7, (a3)
      bnez a7, exitBlackLLoop
      addi a3,a3,1
      
      # decrement amount of pixels to check
      addi a4,a4,-1
       
      # pointer over horizontal list is alread adjusted at this point
      bnez a4, checkHorizontalLineBlack # jump if there are pixels left to check

checkPixelAtTheEndHorizontal:	# sprawdzenie czy pixel dalej nie jest czarny
      # addi a3,a3, 3	# moving pointer to the right - potrzebne ????????????????
      
checkPx1:
      lbu a7, (a3)
      bnez   a7, checkVerticalLineBlack 		# jeśli dana składowa jest różna od 0, to znaczy że jest ok 
      addi a3,a3,1
checkPx2:
      lbu a7, (a3)
      bnez a7, checkVerticalLineBlack
      addi a3,a3,1
checkPx3:
      lbu a7, (a3)
      bnez a7, checkVerticalLineBlack

      j exitBlackLLoop	# pixel was black

      # end of checking horizontal black line in L
      
      # copy a2 pointer
      mv a3,a2
      
      # copy how many pixels to check
      mv a4, t6 
      
      # currently used registers: s1-fileDescriptor, a0-length of horizontal line, t0-t3 <- used for iteration,t4-idx,t5-horizontalLineLength t6-verticalLineLength
      # a0- how many pixels to check horizontally ; a1 - how many vertically; a2-copy of idx a3 - pointer over line(horizontal/vertical), a4 - copy of how many pixels to check

checkVerticalLineBlack:	# checks if vertical black line is good
      # check if  pixel is black
      lbu a7, (a3)		
      bnez a7, exitBlackLLoop 
      addi a3,a3,1
      lbu a7, (a3)
      bnez a7, exitBlackLLoop
      addi a3,a3,1
      lbu a7, (a3)
      bnez a7, exitBlackLLoop
      addi a3,a3,1
      
      # decrement amount of pixels to check
      addi a4,a4,-1
       
      # adjust the pointer
      li a6, 3
      sub a3, a3, li		# pointer -= 3
      
      mul a6, a6, t2			# a6 = 3*width
      sub a3,a3, a6			# pointer -= 3*width 
      
      # now pointer over vertical line is adjusted, point to pixel below previous iteration 
      bnez a4, checkHorizontalLineBlack # jump if there are pixels left to check
checkPixelAtTheEndVertical: # check if pixel at the end is white 

checkPxV1:
      lbu a7, (a3)
      bnez   a7, blackLIsCorrect 		# jeśli dana składowa jest różna od 0, to znaczy że jest ok 
      addi a3,a3,1
checkPxV2:
      lbu a7, (a3)
      bnez a7, blackLIsCorrect
      addi a3,a3,1
checkPxV3:
      lbu a7, (a3)
      bnez a7, blackLIsCorrect

      j exitBlackLLoop
 	
blackLIsCorrect:	# at this point horizontal and vertical black lines are of correct lengths
      # adjust idx for next iteration

      # decremnt amount of pixels to check - check if they are 0? t5 and t6
      addi t5,t5 -1
      addi t6,t6,-1
      
      
      beqz t5, endOfChecking	# that means that we have a rectangle -
      
      j checkBlackLLoop			# if everything is correct continue checking 
 	
exitBlackLLoop: 	# program will reach this point if current error was found in current black L
	# 1. check if at least one black L was found -  if a0= t6 that means no black line was found
	beq a0,t6, endOfChecking
	# 2. check white line
	
	# 3. if correct, print result	

	# dekrementacja dlugosci 
	
	# moodyfikacja pointera po liscie
 
 
endOfChecking:		# finished processing - increment pointers and jump to right labels
       addi t1,t1, -1
       add t1,t1,a0	# adding to column pointer length of horizontal black line - 1 ; +1 will be added  in next lines

continueLoops:
       addi t1,t1,1		# increment pointer over columns
       bltu t1, t2, columnLoop 	# jump if pointer over columns is smaller than width
	# j++ j-- j+=length co gdy length == 0 ? <- osobno obchodzimy ten przypadek; co gdy wgl pixel nie jest czarny
	
	addi t0,t0,-1		# decrement pointer over rows
	bgtz t0, rowLoop	# continue row loop if j >= 0

#close the file
fclose:
      li a7, 57
      mv a0, s1
      ecall
#branch if no data is read
#system call for file_close
#move file descr from s1 to a0

terminateProgram: 
	
