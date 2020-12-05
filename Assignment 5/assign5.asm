        include(`macros.m4')

        // Defining strings
output:         .string "%d, %d\n"
output_float:   .string "%f, %f\n"
allstr:         .string "alloc %d, sp %d, fp %d\n"
test_out:       .string "frq: %f, occurence: %d, word %d\n"

str_table_head: .string "===== Table =====\n"
str_occ:        .string " %d "
str_linebr:     .string "\n"
str_test:       .string "table[%d][%d](%d): %d\n"
str_top_head:   .string "The top documents are: \n"
str_top_doc:    .string "Document %02d: Occurence of %d, Frequency of %.4f\n"
        
        // Equates for alloc & dealloc
        alloc =  -(16 + 96) & -16
        dealloc = -alloc

        // Define register aliases
        fp      .req    x29
        lr      .req    x30

        // Equates for constants
        max_row = 20
        max_col = 20
        min_row = 5
        min_col = 5

        // Equantes for data types
        int = 8

        // Equates for struct Table
        st = -alloc + 0
        st_row = 0
        st_col = 8
        st_arr = 16
        st_arr_base = st + st_arr
        st_arr_amount = max_row * max_col
        st_arr_size = st_arr_amount * int
        st_size = -(st_arr + st_arr_size + 16) & -16

        // Equates for struct Word Frequency
        wf_freqency = 0
        wf_word = 8
        wf_occurence = 16
        wf_document = 24
        wf_size = -(wf_document) & -16

        wf_arr = -alloc + 0
        wf_arr_size = -(max_row * -wf_size) & -16



        // Expose main function to OS and set balign
        .global main
        .balign 4

main:   // main()
        xfunc()

        // Initialize values
        mov     x19,    min_row                 // int row = 5;
        mov     x20,    min_col                 // int col = 5;

        cmp     x0,     3                       // if (argc >= 3)
        b.ge    command_param                   // {read argument from command line}
        b       command_param_end               // {do nothing}

        command_param:

                // Store arguments
                mov 	x21, x1
                ldr 	x0, 	[x21, 8]
                bl 	atoi
                mov	x19, 	x0

                ldr	x0, 	[x21, 16]
                bl 	atoi
                mov 	x20, 	x0

        command_param_end:



        // Rand seed
        xrandSeed()

        // Limit the range of row and col as input validation
        xmin(x19, x19, max_row)                 // row = min(row, max_row);
        xmax(x19, x19, min_row)                 // row = max(row, min_row);
        xmin(x20, x20, max_col)                 // col = min(col, max_col);
        xmax(x20, x20, min_col)                 // col = max(col, min_col);

        // Construct struct Table
        xalloc(st_size)                         // allocate for struct Table
        xstruct(st, st_row, st_col)             // init struct Table attributes with 0
        xwriteStruct(x19, st, st_row)           // write the reset row to struct
        xwriteStruct(x20, st, st_col)           // write the reset col to struct

        xreadStruct(x21, st, st_row)
        xreadStruct(x22, st, st_col)

        
        xprint(allstr, alloc, sp, fp)
        

        xarray(st_arr_base, st_arr_amount, int)
        xwriteArray(18, st_arr_base, int, 0)
        xwriteArray(19, st_arr_base, int, 1)
        

        // struct Table table;                  // x28
        mov     x28,    st                      // base
        add     x28,    x28,    fp              // offset = base + fp


        // Initialize table
        mov     x0,     x28
        bl      initialize                      // initialize(&table)

        // Display table
        mov     x0,     x28
        bl      display                         // display(&table)

        // Top Docs
        mov     x0,     x28
        mov     x1,     -2
        mov     x2,     2
        bl      topRelevantDocs


        // Deallocate memory
        xdealloc(st_size)                       // deallocate struct Table

        xprint(allstr, alloc, sp, fp)


        xret()







initialize:     // initialize(struct Table* table)
	xfunc()

        // Save pointer of table
        mov     x19,    x0                              // int pointer;
        
        // Read row and column from table struct
        xreadStruct(x20, x19, st_row, true)             // int row = table.row;
        xreadStruct(x21, x19, st_col, true)             // int column = table.column;

        // Save pointer of table.array
        add     x19,    x19,    st_arr                  // int array_base = *table.array; get array base offset

        // For loop
        mov     x23,    0                               // int t = 0; current index
        mul     x26,    x20,    x21                     // int size = row * column;

        initialize_array:

                cmp     x23,    x26                     // if (t >= size)
                b.ge    initialize_array_end            // {end}

                // Generate random number
                mov     x0,     0
                mov     x1,     9
                bl      randomNum                       // randomNum(0, 9)

                // Write random number to array
                mov     x25,    x0                      // int random = rand()
                xwriteArray(x25, x19, int, x23, true)   // table.array[t] = random

                // Increment and loop
                xaddAdd(x23)                            // t ++;
                b       initialize_array                // go back to loop top

        initialize_array_end:


        xret()



randomNum:      // randomNum(m, n)
	xfunc()

        mov     x19,    x0                      // int m;
        mov     x20,    x1                      // int n;

        cmp     x19,    x20                     // if (m == n)
        b.eq    randomNum_end                   // {skip everything to the end}, to return m itself

        // For protection, check again the lower and upper bound
        xmax(x27, x19, x20)                     // int upper = max(m, n)
        xmin(x28, x19, x20)                     // int lower = min(m, n)

        // Calculate range
        sub     x21,    x27,    x28             // int range = upper - lower
        xaddAdd(x21)                            // range += 1;

        // Generate random number
        bl      rand

        // Limit range
        udiv    x22,    x0,     x21             // int quotient = rand / range;
        mul     x23,    x22,    x21             // int product = quotient * range
        sub     x24,    x0,     x23             // int remainder = rand - product

        mov     x0,     x24                     // return the remainder as the generated random number
       
        randomNum_end:
        xret()




display:        // display(struct Table* table)
        xfunc()

        // Save pointer of table
        mov     x19,    x0                              // int pointer;
        
        // Read row and column from table struct
        xreadStruct(x20, x19, st_row, true)             // int row = table.row;
        xreadStruct(x21, x19, st_col, true)             // int column = table.column;

        // Save pointer of table.array
        add     x19,    x19,    st_arr                  // int array_base = *table.array; get array base offset

        // Counters
        mov     x23,    0                               // int t = 0; current row index
        mov     x24,    0                               // int r = 0; current col index

        // Print table head
        xprint(str_table_head)

        // For loop of row
        display_array_row:

                // Check for t - current index of row
                cmp     x23,    x20                     // if (t >= table.row)
                b.ge    display_array_row_end           // {end}


                mov     x24,    0                       // int r = 0; current col index

                // For loop of column
                display_array_col:

                        // Check for r - current index of column
                        cmp     x24,    x21             // if (r >= table.col)
                        b.ge    display_array_col_end   // {end}

                        // Calculate current index: (t * table.row) + r
                        xmul(x26, x23, x20)             // int index = t * table.row
                        xaddEqual(x26, x24)             // index += r

                        // Read from array
                        xreadArray(x25, x19, int, x26, true)
                        xprint(str_occ, x25)

                        // Increment and loop
                        xaddAdd(x24)                    // r ++;
                        b       display_array_col       // go back to loop top

                display_array_col_end:


                // Print line break
                xprint(str_linebr)

                // Increment and loop
                xaddAdd(x23)                            // t ++;
                b       display_array_row               // go back to loop top

        display_array_row_end:


        xret()




topRelevantDocs:        // topRelevantDocs(struct Table* table, int index, int top)
        xfunc()

        // Save pointer of table and other two integer parameters
        mov     x19,    x0                              // int pointer;
        mov     x20,    x1                              // int index;
        mov     x21,    x2                              // int top;

        // Read row and column from table struct
        xreadStruct(x22, x19, st_row, true)             // int row = table.row;
        xreadStruct(x23, x19, st_col, true)             // int column = table.column;
        
        // Preventing invalid user input. Index cannot be greater than the table size or smaller than 0.
        // If smaller than 0, set to 0. If greater than table size, set to table size.
        sub     x18,    x23,    1                       // table.column - 1
        xmin(x20, x20, x18)                             // index = min(index, table.column - 1)
        xmax(x20, x20, 0)                               // index = max(index, 0)
        xmin(x21, x21, x22)                             // top = min(top, table.row)
        xmax(x21, x21, 0)                               // top = max(top, 0)



        // Save pointer of table.array
        add     x19,    x19,    st_arr                  // int array_base = *table.array; get array base offset


        // Build WordFrequency array
        xalloc(wf_arr_size)
        mov     x25,    0                               // int t = 0;
        mov     x26,    0                               // int r = 0;
        
        topdoc_wq_struct_row:

                // Check for t - current index of row
                cmp     x25,    x22                     // if (t >= table.row)
                b.ge    topdoc_wq_struct_row_end        // {end}

                // Reset local variables
                mov     x26,    0                       // int r = 0;
                mov     x27,    0                       // int totalOccurence = 0;

                // Calculate array offset
                xmul(x28, x25, -wf_size)                // int offset = t * sizeof(struct WordFrequency)
                add     x28,    x28,    wf_arr          // offset += base
                xwriteStruct(x25, x28, wf_document)     // array[t].document = t;
                xwriteStruct(x20, x28, wf_word)         // array[t].word = index;

                topdoc_wq_struct_col:

                        // Check for r - current index of column
                        cmp     x26,    x23             // if (r >= table.col)
                        b.ge    topdoc_wq_struct_col_end// {end}
                        
                        // Calculate current index: (t * table.row) + r
                        xmul(x17, x25, x22)             // int index = t * table.row
                        xaddEqual(x17, x26)             // index += r

                        // Read from array
                        xreadArray(x24, x19, int, x17, true)

                        // Add to totalOccurence
                        xaddEqual(x27, x24)             // totalOccurence += occurence;
                        
                        // Store index's occurence
                        cmp     x26,    x20             // if (r == index)
                        b.eq    topdoc_write_occ        // {write}
                        b       topdoc_write_occ_end    // {do nothing}

                        topdoc_write_occ:
                                // array[t].occurence = occurence;
                                xwriteStruct(x24, x28, wf_occurence)
                        topdoc_write_occ_end:

                        // Increment and loop
                        xaddAdd(x26)                    // r ++;
                        b       topdoc_wq_struct_col    // go back to loop top

                topdoc_wq_struct_col_end:


                // Get occurence
                xreadStruct(x24, x28, wf_occurence)

                // Convert registers
                scvtf   d24,    x24
                scvtf   d27,    x27
    
                // Calculate frequency and write to struct
                fdiv    d24,    d24,    d27             // int frequency = occurence / totalOccurence;
                xwriteStruct(d24, x28, wf_freqency)


                // Increment and loop
                xaddAdd(x25)                            // t ++;
                b       topdoc_wq_struct_row            // go back to loop top

        
        topdoc_wq_struct_row_end:




        // Bubble sort
        mov     x25,    0                               // int t = 0;
        mov     x26,    0                               // int r = 0;
        mov     x27,    0                               // int base1 = 0;
        mov     x28,    0                               // int base2 = 0;
        fmov    d27,    xzr                             // double frequency1 = 0;
        fmov    d28,    xzr                             // double frequency2 = 0;

        topdoc_bubble_row:

                // Check for t - current index of row
                cmp     x25,    x22                     // if (t >= table.row)
                b.ge    topdoc_bubble_row_end           // {end}

                // Reset local variables
                mov     x26,    0                       // int r = 0;

                topdoc_bubble_row2:

                        // Check for r - current index of column
                        sub     x18,    x23,    1       // table.row - 1
                        cmp     x26,    x18             // if (r >= table.row - 1)
                        b.ge    topdoc_bubble_row2_end  // {end}

                        // Calculate array offset for rth struct WordFrequency
                        xmul(x27, x26, -wf_size)                // int offset = r * sizeof(struct WordFrequency)
                        add     x27,    x27,    wf_arr          // offset += base

                        // Calculate array offset for (r + 1)th struct WordFrequency
                        add     x18,    x26,    1
                        xmul(x28, x18, -wf_size)                // int offset = (r + 1) * sizeof(struct WordFrequency)
                        add     x28,    x28,    wf_arr          // offset += base
                        
                        xreadStruct(d27, x27, wf_freqency)      // frequency1 = array[r].frequency
                        xreadStruct(d28, x28, wf_freqency)      // frequency2 = array[r + 1].frequency

                        fcmp     d27,    d28                    // if (frequency1 < frequency2)
                        b.lt    topdoc_bubble_swap              // {swap two structs}
                        b       topdoc_bubble_swap_end          // {do nothing}

                        topdoc_bubble_swap:
                                
                                // Swap frequency
                                xwriteStruct(d28, x27, wf_freqency)
                                xwriteStruct(d27, x28, wf_freqency)

                                // Swap document
                                xreadStruct(x17, x27, wf_document)
                                xreadStruct(x18, x28, wf_document)
                                xwriteStruct(x17, x28, wf_document)
                                xwriteStruct(x18, x27, wf_document)
                                
                                // Swap occurence
                                xreadStruct(x17, x27, wf_occurence)
                                xreadStruct(x18, x28, wf_occurence)
                                xwriteStruct(x17, x28, wf_occurence)
                                xwriteStruct(x18, x27, wf_occurence)
                                
                                // Swap word
                                xreadStruct(x17, x27, wf_word)
                                xreadStruct(x18, x28, wf_word)
                                xwriteStruct(x17, x28, wf_word)
                                xwriteStruct(x18, x27, wf_word)

                        topdoc_bubble_swap_end:
                        
                        // Increment and loop
                        xaddAdd(x26)                    // r ++;
                        b       topdoc_bubble_row2      // go back to loop top


                topdoc_bubble_row2_end:

                // Increment and loop
                xaddAdd(x25)                            // t ++;
                b       topdoc_bubble_row               // go back to loop top

        topdoc_bubble_row_end:


        // Print result
        mov     x25,    0                               // int t = 0;
        mov     x24,    0                               // int offset = 0;
        xprint(str_top_head)                            // print header

        topdoc_print:

                // Check for t - current index of row
                cmp     x25,    x21                     // if (t >= top)
                b.ge    topdoc_print_end                // {end}

                
                xmul(x24, x25, -wf_size)                // int offset = r * sizeof(struct WordFrequency)
                add     x24,    x24,    wf_arr          // offset += base
                
                xreadStruct(x26, x24, wf_document)
                xreadStruct(x27, x24, wf_occurence)
                xreadStruct(d28, x24, wf_freqency)

                xprint(str_top_doc, x26, x27, d28)

                
                // Increment and loop
                xaddAdd(x25)                            // t ++;
                b       topdoc_print                    // go back to loop top


        topdoc_print_end:
        

        xprint(allstr, alloc, sp, fp)

        
        // Dealloc WordFrequency array
        xdealloc(wf_arr_size)

        xret()