# ==============================================================
	.data
fname:	.asciz	"/Users/marcinpolewski/Documents/Studia/SEM2/ARKO/projekt-RISC-V/source.bmp"	
erPrpt:	.asciz	"Error has occured during opening"
opPrpt:	.asciz	"File opend successfully"
buf:	.space	4048
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
      

#read data from file
readData:

      # print opened prompt
      la a0, opPrpt
      li a7, 4
      ecall

      li a7, 63		#system call for file_read
      mv a0, s1		#move file descr from s1 to a0
      la a1, buf	#address of data buffer
      li a2, 4048	#amount to read (bytes)
      ecall



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
	