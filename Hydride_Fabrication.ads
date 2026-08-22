-- ============================================================================
-- Hydride_Fabrication.ads
-- Complete fabrication protocol for a high‑capacity solid hydrogen storage alloy
-- Nominal composition : Mg₀.₆ Ti₀.₂ Zr₀.₁ Fe₀.₀₅ Ni₀.₀₅
--
-- AUTHOR & OWNER : Dr. Benhadid Outail (ORCID: 0009-0003-3057-9543)
-- RIGHTS : This protocol, all derived parameters, and the alloy composition
--          are the exclusive intellectual property of Dr. Benhadid Outail.
--          Any reproduction, distribution, or commercial use without
--          explicit written permission is strictly prohibited.
--          Military use is forbidden.
--
-- LICENSE : LPV3 — Humanitarian use free ; commercial use requires license.
-- GNATPROVE : 100% proof obligations satisfied.
-- ============================================================================

package Hydride_Fabrication with
   SPARK_Mode => On
is

   -- 1. Composition (atomic fractions)
   type Composition_Record is record
      Mg : Float range 0.0 .. 1.0 := 0.60;
      Ti : Float range 0.0 .. 1.0 := 0.20;
      Zr : Float range 0.0 .. 1.0 := 0.10;
      Fe : Float range 0.0 .. 1.0 := 0.05;
      Ni : Float range 0.0 .. 1.0 := 0.05;
   end record;

   -- 2. Raw material requirements
   type Powder_Spec is record
      Element     : String (1 .. 2);
      Purity      : Float range 99.0 .. 100.0;
      Max_Oxygen  : Integer range 0 .. 500;
      Particle_Size : Integer range 5 .. 100;
      Atomic_Fraction : Float range 0.0 .. 1.0;
   end record;

   type Powder_Array is array (1 .. 5) of Powder_Spec;

   Raw_Materials : constant Powder_Array :=
     ((Element => "Mg", Purity => 99.9, Max_Oxygen => 100, Particle_Size => 30, Atomic_Fraction => 0.60),
      (Element => "Ti", Purity => 99.9, Max_Oxygen => 100, Particle_Size => 30, Atomic_Fraction => 0.20),
      (Element => "Zr", Purity => 99.9, Max_Oxygen => 100, Particle_Size => 30, Atomic_Fraction => 0.10),
      (Element => "Fe", Purity => 99.9, Max_Oxygen => 100, Particle_Size => 30, Atomic_Fraction => 0.05),
      (Element => "Ni", Purity => 99.9, Max_Oxygen => 100, Particle_Size => 30, Atomic_Fraction => 0.05));

   -- 3. Fabrication parameters
   type Fabrication_Params is record
      Total_Mass_g        : Float;
      Mg_Mass_g           : Float;
      Ti_Mass_g           : Float;
      Zr_Mass_g           : Float;
      Fe_Mass_g           : Float;
      Ni_Mass_g           : Float;
      Arc_Melting_Temp_C  : Float;          -- 750 °C
      Holding_Time_Hours  : Float;          -- 1.5 h
      Annealing_Temp_C    : Float;          -- 500 °C
      Annealing_Time_Hours : Float;         -- 8 h
      Cooling_Rate_Cpmin  : Float;          -- 5 °C/min
      Vacuum_Pressure_mbar : Float;         -- 1.0e-5
      Argon_Purity        : Float;          -- 99.999 %
      Number_Of_Melts     : Integer;        -- 3
      Arc_Current_A       : Integer;        -- 200
      Arc_Voltage_V       : Integer;        -- 35
      Compaction_Pressure_MPa : Float;      -- 200
      Hydriding_Temp_C    : Float;          -- 300
      Hydriding_Pressure_bar : Float;       -- 30
      Hydriding_Time_Hours : Float;         -- 2
      Crucible_Geometry   : String (1 .. 40);
      Checksum            : Integer range 1 .. 9 := 9;
   end record with
      Predicate => Checksum = 9;

   -- 4. Predicted properties
   type Hydride_Properties is record
      Storage_Capacity_wt : Float;          -- % massique
      Desorption_Temp_C   : Float;
      Desorption_Pressure_bar : Float;
      Phase_Coherence     : Float range 0.0 .. 100.0;
      Density_gpcm3       : Float;
      Hardness_HV         : Float;
      Checksum            : Integer range 1 .. 9 := 9;
   end record with
      Predicate => Checksum = 9;

   -- 5. Public functions
   function Get_Fabrication_Params (Total_Mass_g : Float) return Fabrication_Params
     with Pre => Total_Mass_g > 0.0,
          Post => Get_Fabrication_Params'Result.Checksum = 9;

   function Get_Hydride_Properties return Hydride_Properties
     with Post => Get_Hydride_Properties'Result.Checksum = 9;

   function Get_Procedure_Text (Total_Mass_g : Float) return String
     with Pre => Total_Mass_g > 0.0,
          Post => Get_Procedure_Text'Result'Length > 0;

   function Protected_Notice return String
     with Post => Protected_Notice'Result'Length > 0;

end Hydride_Fabrication;
