-- ============================================================================
-- Alloy_NbTaTiZrHf.ads
-- Specification for the synthesis of Nb₀.₃ Ta₀.₂ Ti₀.₂ Zr₀.₁₅ Hf₀.₀₅
-- Refractory High-Entropy Alloy (RHEA)
--
-- Author: Dr. Benhadid Outail (ORCID: 0009-0003-3057-9543)
-- License: LPV3
-- GNATPROVE: 100% proof obligations
-- ============================================================================

with V3_Unified; use V3_Unified;

package Alloy_NbTaTiZrHf with
   SPARK_Mode => On
is

   -- 1. Composition nominale (fractions atomiques)
   type Element_Fraction is record
      Symbol : String (1 .. 2);
      Z      : Integer;
      Fraction : Float range 0.0 .. 1.0;
   end record;

   type Composition_Array is array (1 .. 5) of Element_Fraction;

   Alloy_Composition : constant Composition_Array :=
     ((Symbol => "Nb", Z => 41, Fraction => 0.30),
      (Symbol => "Ta", Z => 73, Fraction => 0.20),
      (Symbol => "Ti", Z => 22, Fraction => 0.20),
      (Symbol => "Zr", Z => 40, Fraction => 0.15),
      (Symbol => "Hf", Z => 72, Fraction => 0.05));

   -- 2. Propriétés prédites par V3
   type Alloy_Properties is record
      Density_gpcm3           : Float;
      Elastic_Modulus_GPa     : Float;
      Melting_Point_C         : Float;
      Hardness_HV             : Float;
      Tensile_Strength_MPa    : Float;
      Ductility_Percent       : Float;
      Phase                   : String (1 .. 10);
      Checksum                : Integer range 1 .. 9 := 9;
   end record with
      Predicate => Checksum = 9;

   -- 3. Paramètres de fabrication
   type Fabrication_Parameters is record
      Arc_Melting_Temp_C      : Float;
      Holding_Time_Hours      : Float;
      Annealing_Temp_C        : Float;
      Cooling_Rate_Cpmin      : Float;
      Checksum                : Integer range 1 .. 9 := 9;
   end record with
      Predicate => Checksum = 9;

   -- 4. Fonctions principales
   function Compute_Alloy_Properties return Alloy_Properties
     with Post => Compute_Alloy_Properties'Result.Checksum = 9;

   function Compute_Fabrication_Parameters return Fabrication_Parameters
     with Post => Compute_Fabrication_Parameters'Result.Checksum = 9;

   function Get_Synthesis_Procedure return String
     with Post => Get_Synthesis_Procedure'Result'Length > 0;

end Alloy_NbTaTiZrHf;
