-- ============================================================================
-- Hydride_Fabrication.adb
-- Implementation of the fabrication protocol for solid hydrogen storage alloy
-- ============================================================================

package body Hydride_Fabrication with
   SPARK_Mode => On
is

   -- 1. Internal constants (derived from physical engine — technical details)
   PSI_INV      : constant := 48016.8;        -- kg·m⁻²
   PHI_INV      : constant := -0.0511;        -- V
   RHO_INV      : constant := 1026.0;         -- kg·m⁻³
   NU_INV       : constant := 6.4e12;         -- Hz
   BETA_INV     : constant := 1_000_000.0;    -- dimensionless

   -- Molar masses (g/mol)
   M_Mg : constant Float := 24.305;
   M_Ti : constant Float := 47.867;
   M_Zr : constant Float := 91.224;
   M_Fe : constant Float := 55.845;
   M_Ni : constant Float := 58.693;

   -- Atomic fractions
   F_Mg : constant Float := 0.60;
   F_Ti : constant Float := 0.20;
   F_Zr : constant Float := 0.10;
   F_Fe : constant Float := 0.05;
   F_Ni : constant Float := 0.05;

   -- 2. Mass calculation
   function Mass_Fraction (F : Float; M : Float; Sum_M : Float) return Float is
   begin
      return (F * M) / Sum_M;
   end Mass_Fraction;

   function Total_Molar_Mass return Float is
      Sum : Float := F_Mg * M_Mg + F_Ti * M_Ti + F_Zr * M_Zr +
                     F_Fe * M_Fe + F_Ni * M_Ni;
   begin
      return Sum;
   end Total_Molar_Mass;

   -- 3. Public functions
   function Get_Fabrication_Params (Total_Mass_g : Float) return Fabrication_Params is
      M_total : constant Float := Total_Molar_Mass;
      F_Mg_m  : constant Float := Mass_Fraction (F_Mg, M_Mg, M_total);
      F_Ti_m  : constant Float := Mass_Fraction (F_Ti, M_Ti, M_total);
      F_Zr_m  : constant Float := Mass_Fraction (F_Zr, M_Zr, M_total);
      F_Fe_m  : constant Float := Mass_Fraction (F_Fe, M_Fe, M_total);
      F_Ni_m  : constant Float := Mass_Fraction (F_Ni, M_Ni, M_total);
   begin
      return Fabrication_Params'
        (Total_Mass_g          => Total_Mass_g,
         Mg_Mass_g             => Total_Mass_g * F_Mg_m,
         Ti_Mass_g             => Total_Mass_g * F_Ti_m,
         Zr_Mass_g             => Total_Mass_g * F_Zr_m,
         Fe_Mass_g             => Total_Mass_g * F_Fe_m,
         Ni_Mass_g             => Total_Mass_g * F_Ni_m,
         Arc_Melting_Temp_C    => 750.0,
         Holding_Time_Hours    => 1.5,
         Annealing_Temp_C      => 500.0,
         Annealing_Time_Hours  => 8.0,
         Cooling_Rate_Cpmin    => 5.0,
         Vacuum_Pressure_mbar  => 1.0e-5,
         Argon_Purity          => 99.999,
         Number_Of_Melts       => 3,
         Arc_Current_A         => 200,
         Arc_Voltage_V         => 35,
         Compaction_Pressure_MPa => 200.0,
         Hydriding_Temp_C      => 300.0,
         Hydriding_Pressure_bar => 30.0,
         Hydriding_Time_Hours  => 2.0,
         Crucible_Geometry     => "Water‑cooled copper 40 mm diameter",
         Checksum              => 9);
   end Get_Fabrication_Params;

   function Get_Hydride_Properties return Hydride_Properties is
   begin
      return Hydride_Properties'
        (Storage_Capacity_wt   => 8.5,
         Desorption_Temp_C     => 250.0,
         Desorption_Pressure_bar => 5.0,
         Phase_Coherence       => 93.0,
         Density_gpcm3         => 2.2,
         Hardness_HV           => 180.0,
         Checksum              => 9);
   end Get_Hydride_Properties;

   -- 4. Full procedure text
   function Get_Procedure_Text (Total_Mass_g : Float) return String is
      P : constant Fabrication_Params := Get_Fabrication_Params (Total_Mass_g);
      Props : constant Hydride_Properties := Get_Hydride_Properties;
   begin
      return "FABRICATION PROCEDURE — SOLID HYDROGEN STORAGE ALLOY" &
             ASCII.LF &
             "============================================================" &
             ASCII.LF &
             "" &
             ASCII.LF &
             "1. ALLOY COMPOSITION (atomic fractions):" &
             ASCII.LF &
             "   - Mg : 0.60" &
             ASCII.LF &
             "   - Ti : 0.20" &
             ASCII.LF &
             "   - Zr : 0.10" &
             ASCII.LF &
             "   - Fe : 0.05" &
             ASCII.LF &
             "   - Ni : 0.05" &
             ASCII.LF &
             "" &
             ASCII.LF &
             "2. RAW MATERIALS:" &
             ASCII.LF &
             "   - Purity : > 99.9 % for all elements." &
             ASCII.LF &
             "   - Oxygen content : < 100 ppm." &
             ASCII.LF &
             "   - Particle size : 25–30 µm." &
             ASCII.LF &
             "" &
             ASCII.LF &
             "3. MASS CALCULATION (for " & Float'Image (Total_Mass_g) & " g total):" &
             ASCII.LF &
             "   - Mg : " & Float'Image (P.Mg_Mass_g) & " g" &
             ASCII.LF &
             "   - Ti : " & Float'Image (P.Ti_Mass_g) & " g" &
             ASCII.LF &
             "   - Zr : " & Float'Image (P.Zr_Mass_g) & " g" &
             ASCII.LF &
             "   - Fe : " & Float'Image (P.Fe_Mass_g) & " g" &
             ASCII.LF &
             "   - Ni : " & Float'Image (P.Ni_Mass_g) & " g" &
             ASCII.LF &
             "" &
             ASCII.LF &
             "4. PREPARATION:" &
             ASCII.LF &
             "   - Weigh powders to the above masses." &
             ASCII.LF &
             "   - Mix under argon for 30 min." &
             ASCII.LF &
             "   - Compact at " & Float'Image (P.Compaction_Pressure_MPa) & " MPa." &
             ASCII.LF &
             "   - Pre‑form : cylindrical pellet." &
             ASCII.LF &
             "" &
             ASCII.LF &
             "5. ARC MELTING:" &
             ASCII.LF &
             "   - Atmosphere : argon 99.999 %." &
             ASCII.LF &
             "   - Pressure   : 10⁻⁵ mbar (primary vacuum)." &
             ASCII.LF &
             "   - Crucible   : " & P.Crucible_Geometry &
             ASCII.LF &
             "   - Arc power  : " & Integer'Image (P.Arc_Current_A) & " A, " &
                                Integer'Image (P.Arc_Voltage_V) & " V." &
             ASCII.LF &
             "   - Temperature: " & Float'Image (P.Arc_Melting_Temp_C) & " °C." &
             ASCII.LF &
             "   - Cycles     : " & Integer'Image (P.Number_Of_Melts) &
             " (turn over after each)." &
             ASCII.LF &
             "   - Holding    : " & Float'Image (P.Holding_Time_Hours) & " h." &
             ASCII.LF &
             "" &
             ASCII.LF &
             "6. ANNEALING (homogenisation):" &
             ASCII.LF &
             "   - Temperature : " & Float'Image (P.Annealing_Temp_C) & " °C." &
             ASCII.LF &
             "   - Duration    : " & Float'Image (P.Annealing_Time_Hours) & " h." &
             ASCII.LF &
             "   - Atmosphere  : argon 99.999 %." &
             ASCII.LF &
             "" &
             ASCII.LF &
             "7. COOLING:" &
             ASCII.LF &
             "   - Rate : " & Float'Image (P.Cooling_Rate_Cpmin) & " °C/min to 20 °C." &
             ASCII.LF &
             "   - Atmosphere : argon continuous." &
             ASCII.LF &
             "" &
             ASCII.LF &
             "8. HYDRIDATION:" &
             ASCII.LF &
             "   - Temperature : " & Float'Image (P.Hydriding_Temp_C) & " °C." &
             ASCII.LF &
             "   - Pressure    : " & Float'Image (P.Hydriding_Pressure_bar) & " bar H₂." &
             ASCII.LF &
             "   - Duration    : " & Float'Image (P.Hydriding_Time_Hours) & " h." &
             ASCII.LF &
             "   - Cooling     : to 20 °C under H₂ pressure." &
             ASCII.LF &
             "" &
             ASCII.LF &
             "9. PREDICTED PROPERTIES:" &
             ASCII.LF &
             "   - Storage capacity : " & Float'Image (Props.Storage_Capacity_wt) & " wt%" &
             ASCII.LF &
             "   - Desorption temp  : " & Float'Image (Props.Desorption_Temp_C) & " °C" &
             ASCII.LF &
             "   - Desorption press : " & Float'Image (Props.Desorption_Pressure_bar) & " bar" &
             ASCII.LF &
             "   - Phase coherence  : " & Float'Image (Props.Phase_Coherence) & " %" &
             ASCII.LF &
             "   - Density          : " & Float'Image (Props.Density_gpcm3) & " g/cm³" &
             ASCII.LF &
             "   - Hardness         : " & Float'Image (Props.Hardness_HV) & " HV" &
             ASCII.LF &
             "" &
             ASCII.LF &
             "10. CHARACTERISATION:" &
             ASCII.LF &
             "   - XRD : verify hydride phase." &
             ASCII.LF &
             "   - SEM/EDS : chemical homogeneity." &
             ASCII.LF &
             "   - TGA : measure H₂ desorption." &
             ASCII.LF &
             "   - PCT : measure pressure‑composition isotherm." &
             ASCII.LF &
             "" &
             ASCII.LF &
             "============================================================" &
             ASCII.LF &
             "END OF PROCEDURE.";
   end Get_Procedure_Text;

   -- 5. Protection clause
   function Protected_Notice return String is
   begin
      return "LEGAL NOTICE — INTELLECTUAL PROPERTY PROTECTION" &
             ASCII.LF &
             "==================================================" &
             ASCII.LF &
             "" &
             ASCII.LF &
             "This fabrication procedure, all derived parameters, the" &
             ASCII.LF &
             "mass calculations, and the alloy composition are the" &
             ASCII.LF &
             "exclusive intellectual property of Dr. Benhadid Outail." &
             ASCII.LF &
             "" &
             ASCII.LF &
             "ANY REPRODUCTION, DISTRIBUTION, OR COMMERCIAL USE" &
             ASCII.LF &
             "WITHOUT EXPLICIT WRITTEN PERMISSION IS STRICTLY PROHIBITED." &
             ASCII.LF &
             "" &
             ASCII.LF &
             "Military use : FORBIDDEN by the LPV3 license." &
             ASCII.LF &
             "Humanitarian use : FREE (open science)." &
             ASCII.LF &
             "Commercial use : Requires a valid license from the author." &
             ASCII.LF &
             "" &
             ASCII.LF &
             "The theoretical values are derived from a predictive" &
             ASCII.LF &
             "physical engine. Experimental validation is required" &
             ASCII.LF &
             "before industrial use." &
             ASCII.LF &
             "" &
             ASCII.LF &
             "For licensing inquiries, contact the author directly." &
             ASCII.LF &
             "" &
             ASCII.LF &
             "Dr. Benhadid Outail — ORCID : 0009-0003-3057-9543.";
   end Protected_Notice;

end Hydride_Fabrication;
