	.eqv HEADER_SIZE 	54	# in bytes
	.eqv WIDTH		240	# in pixels(each pixels is 3 bytes)
	.eqv HEIGHT		320
	.eqv PIXEL_B_COUNT 	230400	# = 240*320*3 <- number of pixels reawd

# ==============================================================

	.data

nic:	.space 	2		#only purpose of this is to fix alignment issues while reading first pixel offest	
hdr:	.space	HEADER_SIZE	# stores header information
buf:	.space	4048

#fname:	.asciz	"/Users/marcinpolewski/Documents/Studia/SEM2/ARKO/projekt-RISC-V/source.bmp"	
fname:	.asciz	"/Users/marcinpolewski/Documents/Studia/SEM2/ARKO/projekt-RISC-V/line.bmp"	
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
      ebreak
      ecall
      # returns selected position in a0
      
      # check if seek was successful
      li t1, -1
      beq a0, t1, exitWithError		# exit if error has occured
      
      # write pixels to buffor
      li a7, 63			#system call for file_read
      mv a0, s1			#move file descr from s1 to a0
      la a1, buf		#address of data buffer
      li a2, PIXEL_B_COUNT	#amount to read (bytes)
      
      #check how much data was actually read
      beq zero,a0, fclose
      
processData:
      # used registered till this point: s1
      li t0, HEIGHT		# t0 <- pointer over row(starting from height-1, because .bmp-s are flipped vertically ; i
      addi t0, t0, -1
      
      li t1, 0		# t1 <- pointer over column ; j
      
      li t2, WIDTH
      li t3, HEIGHT
 
rowLoop:			# iterates over rows
columnLoop:			# iterates over columns
      mul t4, t2,t0		# idx = i*width
      add t4,t4, t1		# idx += j
      
      li t5, 3
      mul t4,t4,t5		# idx *= 3
      
      la t5, buf
      add t4, t4, t5		# now t4 is pointing to pixel in row and column set in t0 and t1
      
      
      mv t5,t4			# temporary pointer, for checking next pixels
      ebreak
checkIfBlack:			# checks if curren pixel is black, if not, take the next one
      lbu a7, (t5)		# load first colour of the pixel lbu ???????????????
      bnez a7, endOfChecking	
      addi t5,t5,1
      
      lbu a7, (t5)
      bnez a7, endOfChecking
      addi t5,t5,1
      
      lbu a7, (t5)
      bnez a7, endOfChecking
calcLengtht:			# calculate length of horizontal line starting at this pixel
      # calculate how many iterations left in this row(stored in t6)
      sub t6, t2, t1		# t6 = width - currentColumn -1 ; 
      addi t6, t6, -1		# t6 = t6 -1, because we know that first pixel is surely black
      
      addi t5,t5, 1		# now t5 points to the right of idx
      
      # a0 stores length of vertical line
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
      # currently used registers: s1-fileDescriptor, a0-length of vertical line, t0-t4 <- used for iteration
       
      
      # used regisers at this point: s1-descriptor, t0-t4 <- iteration purposes
      
      
endOfChecking:


#close the file
fclose:
      li a7, 57
      mv a0, s1
      ecall
#branch if no data is read
#system call for file_close
#move file descr from s1 to a0

terminateProgram: 
	