# Task
Find a bitmap a marker of given proportions using RISC-V assembly language. Print to console row and column of the point, where lines cross. Marker is an "L", rotatet by 90 degrees to the right.

### Bitmap parameters:
- height: 240px
- width: 320px
- file name: "source.bmp"
### Marker parameters: 
- When marker's height==x, then marker's width==2x
- Must have 

# General idea - how it works
Solution is written in "program.asm". For development RARS simulator was used. When program is started it open source.bmp file, looks for markers and prints their position(top left corner) to the console

# Implementation/algorith 
- iterate over image untill black pixel is found
- get length of horizontal, black line starting at found pixel
- check parity, if length is odd - continue with loop(increment pointer, by one pixel and start point 1)
- divide length by 2 and store - it is height of an L-shape that we are looking for
- check if L-shape above found black pixel is white(if not continue with loop)
- iteratate over black L-shapes(two lines, which are 1px wide and cross at one point),starting from found pixel and lengths. In every step:
    - check if horizontal line is black 
    - check if vertical line is black 
    - move pointer by one to the right and down.
    - decrement variables(in fact registers) responsible for storing wanted length and height for next black L
- check if L-shape below last black L-shape is  white, if it's not continue with the loop 
- print found result

# Encountered problems: 
- could not read offset of the first pixel from bmp. header, because address of 4-bit data must be dividable by 4 
    - solution: declare 2-bit structure, before header. Now offset of first pixel is stores dividiable by 4 (it's the address of header buffor + 10)
- looking up white L-s would not be successful 
    - solution: it's a must to increment pointer before performin any jumps 