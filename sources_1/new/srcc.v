`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 23.04.2023 16:41:41
// Design Name: 
// Module Name: srcc
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module ClockDivider300hz(input CLK_IN,output reg CLK_OUT);   
    reg[17:0] counter=18'b0;
    parameter DIVISOR = 18'b111111110011111111;
    //for nearly 300hz frequency
    always @(posedge CLK_IN)
    begin
        counter <= counter + 18'b1;  
        if(counter >= ( DIVISOR-1 ) )
            counter <= 18'b0;        

        CLK_OUT <= ( counter < DIVISOR >> 1 )? 1'b1 : 1'b0;  
    end
endmodule


module ClockDivider1by3sec(input CLK_IN,output reg CLK_OUT);   
    reg[24:0] counter=25'b00000000000000000000000;
    parameter DIVISOR = 25'b11111111111111111110110;
    
    always @(posedge CLK_IN)
    begin
        counter <= counter + 25'b1;  
        if(counter > ( DIVISOR-1 ) )     //codn check may be 8 row not visible
            counter <= 25'b0;        

        CLK_OUT <= ( counter < DIVISOR >> 1 )? 1'b1 : 1'b0;  
    end
endmodule

module ClockDivider_slow(input CLK_IN,output reg CLK_OUT);   
    reg[25:0] counter=26'b00000000000000000000000;
    parameter DIVISOR = 26'b111111111110111111110110;
    
    always @(posedge CLK_IN)
    begin
        counter <= counter + 26'b1;  
        if(counter > ( DIVISOR-1 ) )     //codn check may be 8 row not visible
            counter <= 26'b0;        

        CLK_OUT <= ( counter < DIVISOR >> 1 )? 1'b1 : 1'b0;  
    end
endmodule


module srcc( clk,reset,level,user1_up,user1_down,user2_up,user2_down ,col,row 
        ,centre_r,centre_c,movement
         );
    input clk,user1_up,user1_down,user2_up,user2_down;
    input reset,level;
    output reg [7:0] col, row;
    
    reg [7:0] mat_col [0:7];
    
    output reg [2:0] centre_r,centre_c;
    output reg [2:0] movement;       // 0 left  1 up -left 3 up- right 4 right 5 down - right 7 down - left
    reg temp;
    
    wire clk_300hz;
    
    ClockDivider300hz c00hz(clk,clk_300hz );

    reg clk_milisec;
    wire [2:0] divisorr;
    wire clk_fast,clk_slow;
    ClockDivider1by3sec c26(clk,clk_fast);
    ClockDivider_slow c526(clk,clk_slow);
    always @(posedge clk_300hz)
    begin
        if(level==1) 
        begin    clk_milisec = clk_fast;   end
        else
        begin    clk_milisec = clk_slow;   end
    
    end
       
  
    reg [2:0]counter = 3'd0;
    always @(posedge clk_300hz)
    begin
        case(counter)
            3'd0: begin   row <= 8'b11111110;  col <= mat_col[0]; end
            3'd1: begin   row <= 8'b11111101;  col <= mat_col[1]; end
            3'd2: begin   row <= 8'b11111011;  col <= mat_col[2]; end
            3'd3: begin   row <= 8'b11110111;  col <= mat_col[3]; end
            3'd4: begin   row <= 8'b11101111;  col <= mat_col[4]; end
            3'd5: begin   row <= 8'b11011111;  col <= mat_col[5]; end
            3'd6: begin   row <= 8'b10111111;  col <= mat_col[6]; end
            3'd7: begin   row <= 8'b01111111;  col <= mat_col[7]; end
        endcase
        if (counter == 3'd7)
            begin
                counter <= 3'd0;
            end
        else
            begin
                counter <= counter + 3'd1;
            end
    end
    
     
    reg counter2 = 1'd0;
    always @(posedge clk_milisec)   //later use clockdivider only
    begin
     if( reset == 1'b1)
            begin 
                centre_r =3'b0100  ;
                centre_c =3'b0100  ;
                mat_col[0] = 8'b00000000 ;
                mat_col[1] = 8'b00000000 ;
                mat_col[2] = 8'b00000000 ;
                mat_col[3] = 8'b10000001 ;
                mat_col[4] = 8'b10001001 ;
                mat_col[5] = 8'b10000001 ;
                mat_col[6] = 8'b00000000 ;
                mat_col[7] = 8'b00000000 ;
                movement = 3'b000;
            end
     else
      begin
        if (counter2 == 1'd1)
            begin
                counter2 <= 1'd0;
            end
        else
            begin
                counter2 <= counter2 + 1'd1;
            end
        
        case(counter2)
        1'd0:
        begin 
            //0 left 
            if ( movement == 3'b000) 
            begin
                  //if at column=1
                  if(centre_c == 3'b001) //do game over or reflect if ball at col==1
                     begin
                       if(mat_col[centre_r][centre_c - 1] == 1'b1) 
                           //what if  centre_r =0 or 7,ignoring corner valur here
                           begin  //move up,doen or right depends 3 codn
                                 if      (mat_col[centre_r - 1][centre_c-1] == 1'b1 && mat_col[centre_r + 1][centre_c-1] == 1'b1)   begin movement = 3'b100; end
                                 else if (mat_col[centre_r - 1][centre_c-1] == 1'b1 && mat_col[centre_r + 1][centre_c-1] == 1'b0)   begin movement = 3'b101; end
                                 else if (mat_col[centre_r - 1][centre_c-1] == 1'b0 && mat_col[centre_r + 1][centre_c-1] == 1'b1)   begin movement = 3'b011; end
                           end
                        else //game over 
                          begin    movement = 3'b010; 
//                                                       mat_col[0][7] <= 1;mat_col[1][7] <= 1;mat_col[2][7] <= 1;mat_col[3][7] <= 1;
//                                                       mat_col[4][7] <= 1;mat_col[5][7] <= 1;mat_col[6][7] <= 1;mat_col[7][7] <= 1;
                          end 
                     end    
                  else //decrese led on left
                      begin
                         mat_col[centre_r][centre_c] <= 1'b0;
                         mat_col[centre_r][centre_c - 1'b1] <= 1'b1;
                         centre_c = centre_c - 1;
                      end
            end  // movement == 3'b000
            
            // 1 up -left  
            else if ( movement == 3'b001) 
            begin
                  if(centre_r == 3'b000) //do game over or reflect if ball at col==1
                     begin
                       movement <= 3'b111;
                     end
                  //if at column=1
                  else if(centre_c == 3'b001) //do game over or reflect if ball at col==1
                     begin
                       if(mat_col[centre_r][centre_c - 1] == 1)  
                           //what if  centre_r =0 or 7,ignoring corner valur here
                           begin  //move up,doen or right depends 3 codn
                                 if      (mat_col[centre_r - 1][centre_c-1] == 1 && mat_col[centre_r + 1][centre_c-1] == 1)   begin movement <= 3'b100; end
                                 else if (mat_col[centre_r - 1][centre_c-1] == 1 && mat_col[centre_r + 1][centre_c-1] == 0)   begin movement <= 3'b101; end
                                 else if (mat_col[centre_r - 1][centre_c-1] == 0 && mat_col[centre_r + 1][centre_c-1] == 1)   begin movement <= 3'b011; end
                           end
                        else //game over 
                          begin    movement <= 3'b010; 
//                                                       mat_col[0][7] <= 1'b1;mat_col[1][7] <= 1'b1;mat_col[2][7] <= 1'b1;mat_col[3][7] <= 1'b1;
//                                                       mat_col[4][7] <= 1'b1;mat_col[5][7] <= 1'b1;mat_col[6][7] <= 1'b1;mat_col[7][7] <= 1'b1;
                          end 
                     end    
                  else //decrese led on left
                      begin
                         mat_col[centre_r][centre_c] = 0;
                         mat_col[centre_r-1][centre_c-1] = 1;
                         centre_c <= centre_c - 1;
                         centre_r <= centre_r - 1;
                      end
            end
        
            // if left side win
            else if ( movement == 3'b010) 
            begin
                mat_col[0] = 8'b10000001 ;
                mat_col[1] = 8'b11000011 ;
                mat_col[2] = 8'b10100101 ;
                mat_col[3] = 8'b10011001 ;
                mat_col[4] = 8'b10000001 ;
                mat_col[5] = 8'b10000001 ;
                mat_col[6] = 8'b10000001 ;
                mat_col[7] = 8'b00000000 ;
            end


            // 3 up- right 
            else if ( movement == 3'b011) 
            begin
                if(centre_r == 3'b000) //do game over or reflect if ball at col==1
                     begin
                       movement <= 3'b101;
                     end
                //if at column=7
                  else if(centre_c == 3'b110) //do game over or reflect if ball at col==1
                     begin
                       if(mat_col[centre_r][centre_c+1] == 1)  
                           begin  //move up,doen or right depends 3 codn
                                 if      (mat_col[centre_r - 1][centre_c+1] == 1 && mat_col[centre_r + 1][centre_c+1] == 1)   begin movement <= 3'b000; end         
                                 else if (mat_col[centre_r - 1][centre_c+1] == 1 && mat_col[centre_r + 1][centre_c+1] == 0)   begin movement <= 3'b111; end          
                                 else if (mat_col[centre_r - 1][centre_c+1] == 0 && mat_col[centre_r + 1][centre_c+1] == 1)   begin movement <= 3'b001; end          
                           end
                        else //game over 
                          begin    movement <= 3'b110; 
//                                                       mat_col[0][0] = 1;mat_col[1][0] = 1;mat_col[2][0] = 1;mat_col[3][0] = 1;
//                                                       mat_col[4][0] = 1;mat_col[5][0] = 1;mat_col[6][0] = 1;mat_col[7][0] = 1;
                          end 
                     end    
                  else //decrese led on left
                      begin
                         mat_col[centre_r][centre_c] = 0;
                         mat_col[centre_r-1][centre_c+1] = 1;
                         centre_c <= centre_c + 1;
                         centre_r <= centre_r - 1;
                      end
                 
            end
            
            // 4 right 
            else if ( movement == 3'b100) 
            begin
                //if at column=7
                  if(centre_c == 3'b110) //do game over or reflect if ball at col==1
                     begin
                       if(mat_col[centre_r][centre_c+1] == 1)  
                           begin  //move up,doen or right depends 3 codn
                                 if      (mat_col[centre_r - 1][centre_c+1] == 1 && mat_col[centre_r + 1][centre_c+1] == 1)   begin movement <= 3'b000; end         
                                 else if (mat_col[centre_r - 1][centre_c+1] == 1 && mat_col[centre_r + 1][centre_c+1] == 0)   begin movement <= 3'b111; end          
                                 else if (mat_col[centre_r - 1][centre_c+1] == 0 && mat_col[centre_r + 1][centre_c+1] == 1)   begin movement <= 3'b001; end          
                           end
                        else //game over 
                          begin    movement <= 3'b110; 
//                                                       mat_col[0][0] = 1;mat_col[1][0] = 1;mat_col[2][0] = 1;mat_col[3][0] = 1;
//                                                       mat_col[4][0] = 1;mat_col[5][0] = 1;mat_col[6][0] = 1;mat_col[7][0] = 1;
                          end 
                     end    
                  else //decrese led on left
                      begin
                         mat_col[centre_r][centre_c] = 0;
                         mat_col[centre_r][centre_c+1] = 1;
                         centre_c <= centre_c + 1;
                      end
            end
            
            // 5 down - right  
            else if ( movement == 3'b101) 
            begin
                if(centre_r == 3'b111) //do game over or reflect if ball at col==1
                     begin
                       movement <= 3'b011;
                     end
                //if at column=7
                 else if(centre_c == 3'b110) //do game over or reflect if ball at col==1
                     begin
                       if(mat_col[centre_r][centre_c+1] == 1'b1)  
                           begin  //move up,doen or right depends 3 codn
                                 if      (mat_col[centre_r - 1][centre_c+1] == 1'b1 && mat_col[centre_r + 1][centre_c+1] == 1'b1)   begin movement <= 3'b000; end         
                                 else if (mat_col[centre_r - 1][centre_c+1] == 1'b1 && mat_col[centre_r + 1][centre_c+1] == 1'b0)   begin movement <= 3'b111; end          
                                 else if (mat_col[centre_r - 1][centre_c+1] == 1'b0 && mat_col[centre_r + 1][centre_c+1] == 1'b1)   begin movement <= 3'b001; end          
                           end
                        else //game over 
                          begin    movement <= 3'b110; 
//                                                       mat_col[0][0] = 1'b1;mat_col[1][0] = 1'b1;mat_col[2][0] = 1'b1;mat_col[3][0] = 1'b1;
//                                                       mat_col[4][0] = 1'b1;mat_col[5][0] = 1'b1;mat_col[6][0] = 1'b1;mat_col[7][0] = 1'b1;
                          end 
                     end    
                  else //decrese led on left
                      begin
                         mat_col[centre_r][centre_c] = 0;
                         mat_col[centre_r+1][centre_c+1] = 1;
                         centre_c <= centre_c + 1;
                         centre_r <= centre_r + 1;
                      end
            end
            
            // if right side win
            else if ( movement == 3'b110) 
            begin
//                mat_col[0][7] <= 1'b1;mat_col[1][7] <= 1'b1;mat_col[2][7] <= 1'b1;mat_col[3][7] <= 1'b1;
//                mat_col[4][7] <= 1'b1;mat_col[5][7] <= 1'b1;mat_col[6][7] <= 1'b1;mat_col[7][7] <= 1'b1;
                mat_col[0] = 8'b10000001 ;
                mat_col[1] = 8'b10000011 ;
                mat_col[2] = 8'b10000101 ;
                mat_col[3] = 8'b10001001 ;
                mat_col[4] = 8'b10010001 ;
                mat_col[5] = 8'b10100001 ;
                mat_col[6] = 8'b11000001 ;
                mat_col[7] = 8'b10000001 ;
            end
            // 7 down - left       
            else if ( movement == 3'b111) begin
                if(centre_r == 3'b111) //do game over or reflect if ball at col==1
                     begin
                       movement <= 3'b001;
                     end
                  //if at column=1
                  else if(centre_c == 3'b001) //do game over or reflect if ball at col==1
                     begin
                       if(mat_col[centre_r][centre_c - 1] == 1'b1)  
                           //what if  centre_r =0 or 7,ignoring corner valur here
                           begin  //move up,doen or right depends 3 codn
                                 if      (mat_col[centre_r - 1][centre_c-1] == 1'b1 && mat_col[centre_r + 1][centre_c-1] == 1'b1)   begin movement <= 3'b100; end
                                 else if (mat_col[centre_r - 1][centre_c-1] == 1'b1 && mat_col[centre_r + 1][centre_c-1] == 1'b0)   begin movement <= 3'b101; end
                                 else if (mat_col[centre_r - 1][centre_c-1] == 1'b0 && mat_col[centre_r + 1][centre_c-1] == 1'b1)   begin movement <= 3'b011; end
                           end
                        else //game over 
                          begin    movement <= 3'b010; 
//                                                       mat_col[0][7] = 1'b1;mat_col[1][7] = 1'b1;mat_col[2][7] = 1'b1;mat_col[3][7] = 1'b1;
//                                                       mat_col[4][7] = 1'b1;mat_col[5][7] = 1'b1;mat_col[6][7] = 1'b1;mat_col[7][7] = 1'b1;
                          end 
                     end    
                  else //decrese led on left
                      begin
                         mat_col[centre_r][centre_c] = 1'b0;
                         mat_col[centre_r+1][centre_c-1] = 1'b1;
                         centre_c <= centre_c - 1;
                         centre_r <= centre_r + 1;
                      end
            end   // movement == 3'b111   
             
        
            else begin  
                    movement <= 3'b010; 
                end // movement == null matched 
             
       end //divisorr == 3'b001 and case 1,d0
       
        1'd1: 
        begin
        //for user slide up down
        if( user1_up == 1'b1)   begin      
            if(mat_col[0][0] == 1'b0) begin
                if     ( mat_col[1][0] == 1'b1) begin  mat_col[0][0] <= 1'b1;   mat_col[3][0] <= 1'b0;  end
                else if( mat_col[2][0] == 1'b1) begin  mat_col[1][0] <= 1'b1;   mat_col[4][0] <= 1'b0;  end
                else if( mat_col[3][0] == 1'b1) begin  mat_col[2][0] <= 1'b1;   mat_col[5][0] <= 1'b0;  end
                else if( mat_col[4][0] == 1'b1) begin  mat_col[3][0] <= 1'b1;   mat_col[6][0] <= 1'b0;  end
                else if( mat_col[5][0] == 1'b1) begin  mat_col[4][0] <= 1'b1;   mat_col[7][0] <= 1'b0;  end
            end     
        
        end
        
        else if( user1_down == 1'b1) begin    
            if(mat_col[7][0] == 1'b0) begin
                if     ( mat_col[6][0] == 1'b1) begin  mat_col[7][0] <= 1'b1;   mat_col[4][0] <= 1'b0;  end
                else if( mat_col[5][0] == 1'b1) begin  mat_col[6][0] <= 1'b1;   mat_col[3][0] <= 1'b0;  end
                else if( mat_col[4][0] == 1'b1) begin  mat_col[5][0] <= 1'b1;   mat_col[2][0] <= 1'b0;  end
                else if( mat_col[3][0] == 1'b1) begin  mat_col[4][0] <= 1'b1;   mat_col[1][0] <= 1'b0;  end
                else if( mat_col[2][0] == 1'b1) begin  mat_col[3][0] <= 1'b1;   mat_col[0][0] <= 1'b0;  end
            end  
        end
        
    
//        end //divisorr == 3'b011
        
//        else if( divisorr == 3'b110) 
//        begin        
        if( user2_up == 1'b1)   
        begin 
            if(mat_col[0][7] == 1'b0) begin
                if     ( mat_col[1][7] == 1'b1) begin  mat_col[0][7] <= 1'b1;   mat_col[3][7] <= 1'b0;  end
                else if( mat_col[2][7] == 1'b1) begin  mat_col[1][7] <= 1'b1;   mat_col[4][7] <= 1'b0;  end
                else if( mat_col[3][7] == 1'b1) begin  mat_col[2][7] <= 1'b1;   mat_col[5][7] <= 1'b0;  end
                else if( mat_col[4][7] == 1'b1) begin  mat_col[3][7] <= 1'b1;   mat_col[6][7] <= 1'b0;  end
                else if( mat_col[5][7] == 1'b1) begin  mat_col[4][7] <= 1'b1;   mat_col[7][7] <= 1'b0;  end
            end  
        end
        
        else if( user2_down == 1'b1) 
        begin             
            if(mat_col[7][7] == 1'b0) begin
                if     ( mat_col[6][7] == 1'b1) begin  mat_col[7][7] <= 1'b1;   mat_col[4][7] <= 1'b0;  end
                else if( mat_col[5][7] == 1'b1) begin  mat_col[6][7] <= 1'b1;   mat_col[3][7] <= 1'b0;  end
                else if( mat_col[4][7] == 1'b1) begin  mat_col[5][7] <= 1'b1;   mat_col[2][7] <= 1'b0;  end
                else if( mat_col[3][7] == 1'b1) begin  mat_col[4][7] <= 1'b1;   mat_col[1][7] <= 1'b0;  end
                else if( mat_col[2][7] == 1'b1) begin  mat_col[3][7] <= 1'b1;   mat_col[0][7] <= 1'b0;  end
            end 
        end
 
        end  // divisorr == 3'b110
        
        endcase
    
      end  //end of 'else' inside 'always'
    end  //end of  always
     
           
endmodule


