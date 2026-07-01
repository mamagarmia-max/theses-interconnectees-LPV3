// ============================================================================
// V14.0 — ASIC Testbench
// ============================================================================
// Tests the ASIC implementation of V14.0
// ============================================================================

`timescale 1ns / 1ps

module v14_climate_model_asic_tb;

    reg         clk, reset, start;
    wire        done;
    reg  signed [31:0] latitude, altitude, pressure, humidity, co2, day, albedo, urban_heat, solar_flux;
    wire signed [31:0] surface_temp, layer1_temp, layer2_temp, layer3_temp, layer4_temp, layer5_temp;
    wire [7:0] stability;
    wire [3:0] checksum;
    
    // Instantiate DUT
    v14_climate_model_asic dut (
        .clk(clk),
        .reset(reset),
        .start(start),
        .done(done),
        .latitude(latitude),
        .altitude(altitude),
        .pressure(pressure),
        .humidity(humidity),
        .co2(co2),
        .day(day),
        .albedo(albedo),
        .urban_heat(urban_heat),
        .solar_flux(solar_flux),
        .surface_temp(surface_temp),
        .layer1_temp(layer1_temp),
        .layer2_temp(layer2_temp),
        .layer3_temp(layer3_temp),
        .layer4_temp(layer4_temp),
        .layer5_temp(layer5_temp),
        .stability(stability),
        .checksum(checksum)
    );
    
    // Clock generation: 500 MHz
    always #1 clk = ~clk;
    
    // Test sequence
    initial begin
        // Initialize
        clk = 0;
        reset = 1;
        start = 0;
        latitude = 489;
        altitude = 35;
        pressure = 10130;
        humidity = 200;
        co2 = 4350;
        day = 180;
        albedo = 20;
        urban_heat = 15;
        solar_flux = 13600;
        
        // Reset
        #10 reset = 0;
        #10 start = 1;
        #10 start = 0;
        
        // Wait for completion
        wait(done == 1);
        
        // Display results
        #10 $display("========================================");
        $display("V14.0 — ASIC Simulation Results");
        $display("========================================");
        $display("Surface Temp : %d.%d°C", surface_temp/10, surface_temp%10);
        $display("Layer 1 (1km): %d.%d°C", layer1_temp/10, layer1_temp%10);
        $display("Layer 2 (5km): %d.%d°C", layer2_temp/10, layer2_temp%10);
        $display("Layer 3 (10km): %d.%d°C", layer3_temp/10, layer3_temp%10);
        $display("Layer 4 (15km): %d.%d°C", layer4_temp/10, layer4_temp%10);
        $display("Layer 5 (40km): %d.%d°C", layer5_temp/10, layer5_temp%10);
        $display("Stability : %d%%", stability);
        $display("Checksum : %d", checksum);
        $display("========================================");
        
        #50 $finish;
    end

endmodule
