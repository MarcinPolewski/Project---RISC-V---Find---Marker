	.eqv HEADER_SIZE 	54	# in bytes
	.eqv WIDTH		240	# in pixels(each pixels is 3 bytes)
	.eqv HEIGHT		320
	.eqv PIXEL_B_COUNT 	230400	# = 240*320*3 <- number of pixels reawd

# ==============================================================

	.data

nic:	.space 	2		#only purpose of this is to fix alignment issues while reading first pixel offest	
hdr:	.space	HEADER_SIZE	# stores header information
buf:	.space	4048

fname:	.asciz	"/Users/marcinpolewski/Documents/Studia/SEM2/ARKO/projekt-RISC-V/source.bmp"	
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
      
      # korzystać s LSeek sys call zeby ustaic wskaznik w pliku
      
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
      mv a0, s1		# loading file descriptor
      mv a1, t0		# load offset from the base
      li a2, 0		# set the base to the beggining of the file
      ecall
      
      # check if seek was successful
      li t1, -1
      beq a0, t1, exitWithError		# exit if error has occured
      
      # write pixels to buffor
      li a7, 63			#system call for file_read
      mv a0, s1			#move file descr from s1 to a0
      la a1, buf		#address of data buffer
      li a2, PIXEL_B_COUNT	#amount to read (bytes)

      # read data from file
      #li a7, 63			#system call for file_read
      #mv a0, s1			#move file descr from s1 to a0
      #la a1, buf		#address of data buffer
      #li a2, 4048		#amount to read (bytes)
      #ecall



#check how much data was actually read
      beq zero,a0, fclose
...
#close the file
fclose:
      li a7, 57
      mv a0, s1
      ecall
#branch if no data is read
#system call for file_close
#move file descr from s1 to a0

terminateProgram: 
	