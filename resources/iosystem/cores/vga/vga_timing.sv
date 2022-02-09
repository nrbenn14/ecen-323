/*********************************************************************************
*
*********************************************************************************/

module vga_timing (clk, rst, HS, VS, pixel_x, pixel_y, last_column, last_row, blank);

    input logic clk;
    input logic rst;
    output logic HS;
    output logic VS;
    output logic [9:0] pixel_x;
    output logic [9:0] pixel_y;
    output logic last_column;
    output logic last_row;
    output logic blank;

    localparam X_MAX = 799;
    localparam Y_MAX = 520;
    localparam LAST_COLUMN_NUM = 639;
    localparam LAST_ROW_NUM = 479;
    localparam HS_LOW_COL_MIN = 656;
    localparam HS_LOW_COL_MAX = 751;
    localparam VS_LOW_COL_MIN = 490;
    localparam VS_LOW_COL_MAX = 491;
    localparam BLANK_FIRST_COL = 640;
    localparam BLANK_FIRST_ROW = 480;

    logic [9:0] x_reg, x_next, y_reg, y_next;
    logic pixel_en = 0;

    always_ff@(posedge clk)
        if (rst) begin
            pixel_en <= 0;
            x_reg <= 0;
            y_reg <= 0;
        end
        else begin
            pixel_en <= ~pixel_en;
            if (pixel_en) begin
                x_reg <= x_next;
                y_reg <= y_next;                
            end
        end

    assign x_next = (x_reg == X_MAX) ? 0 : x_reg + 1;
    assign y_next = (x_reg == X_MAX && y_reg == Y_MAX) ? 0 :
                    (x_reg == X_MAX) ? y_reg + 1 :
                    y_reg;

    assign pixel_x = x_reg;
    assign pixel_y = y_reg;
    assign last_column = (x_reg == LAST_COLUMN_NUM);
    assign last_row = (y_reg == LAST_ROW_NUM);
    assign HS = ~(x_reg >= HS_LOW_COL_MIN && x_reg <= HS_LOW_COL_MAX );
    assign VS = ~(y_reg >= VS_LOW_COL_MIN && y_reg <= VS_LOW_COL_MAX );
    assign blank = (x_reg >= BLANK_FIRST_COL && y_reg >= BLANK_FIRST_ROW );

endmodule

