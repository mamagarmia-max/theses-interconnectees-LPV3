-- SPDX-License-Identifier: LPV3
--
-- V14_CRASH_TEST_SUITE — Suite de validation déterministe du modèle V14.0
-- ============================================================================
-- Version 1.0 : Regroupe les 9 crash-tests physiques extrêmes
--   - Test 1 : Fairbanks, Alaska (Inversion thermique)
--   - Test 2 : Koweït Airport (Pic de chaleur désertique)
--   - Test 3 : La Paz, Bolivie (Haute altitude)
--   - Test 4 : Sedom, Mer Morte (Sous le niveau de la mer)
--   - Test 5 : Lhasa, Tibet (Reconstitution barométrique)
--   - Test 6 : Salar d'Uyuni (Albédo extrême)
--   - Test 7 : Tozeur, Tunisie (Effet d'oasis)
--   - Test 8 : Stornoway, Écosse (Dépression explosive)
--   - Test 9 : Mong Kok, Hong Kong (Canyon urbain)
--
-- Auteur : Dr. Benhadid Outail (ORCID: 0009-0003-3057-9543)
-- Licence : LPV3
-- Version : 1.0.0
-- Date : 10 Juillet 2026
-- ============================================================================

package V14_Crash_Test_Suite with
   SPARK_Mode => On,
   Pure,
   No_Implicit_Dereference,
   No_Secondary_Stack,
   Preelaborate
is

   -- ========================================================================
   -- 1. INVARIANTS V14 (VERROUILLÉS)
   -- ========================================================================

   PSI_V14          : constant := 480168;        -- ×10 : 48,016.8 kg·m⁻²
   PHI_CRITICAL     : constant := -51100;        -- ×1000 : -51.1 mV
   BETA             : constant := 1_000_000;     -- 10⁶
   K_CYCLES         : constant := 7;             -- Heptadic closure
   ALPHA_INV        : constant := 13703599913;   -- 1/α × 10⁵

   -- ========================================================================
   -- 2. TYPES DE BASE
   -- ========================================================================

   subtype Temp_Type is Integer range -600 .. 600;        -- ×10°C
   subtype Pressure_Type is Integer range 500 .. 11000;   -- hPa ×10
   subtype Humidity_Type is Integer range 0 .. 1000;      -- %
   subtype Albedo_Type is Integer range 0 .. 100;         -- %
   subtype Altitude_Type is Integer range -500 .. 10000;  -- mètres
   subtype CO2_Type is Integer range 0 .. 10000;          -- ppm ×10
   subtype Solar_Flux_Type is Integer range 0 .. 2000;    -- W·m⁻²

   -- ========================================================================
   -- 3. STRUCTURE D'UN CAS DE TEST
   -- ========================================================================

   type Test_ID is
     (Fairbanks, Kuwait, LaPaz, Sedom, Lhasa,
      Uyuni, Tozeur, Stornoway, MongKok);

   type Test_Case is record
      ID           : Test_ID;
      Name         : String (1 .. 30) := (others => ' ');
      Latitude     : Integer := 0;         -- ×100 °N (négatif pour Sud)
      Altitude     : Altitude_Type := 0;
      Pressure     : Pressure_Type := 0;   -- QFE ×10 hPa
      Humidity     : Humidity_Type := 0;   -- %
      Albedo       : Albedo_Type := 0;     -- %
      CO2          : CO2_Type := 4140;     -- ppm ×10
      Solar_Flux   : Solar_Flux_Type := 0; -- W·m⁻²
      Day          : Integer range 1 .. 366 := 1;
      Year         : Integer range 1900 .. 2030 := 2020;
      Hour         : Integer range 0 .. 23 := 12;
      Predicted_Temp : Temp_Type := 0;     -- ×10°C
      Reference_Temp : Temp_Type := 0;     -- ×10°C (à remplir après validation)
      Checksum     : Integer range 1 .. 9 := 9;
   end record
     with Predicate => Test_Case.Checksum in 1 .. 9;

   type Test_Array is array (Test_ID) of Test_Case;

   -- ========================================================================
   -- 4. SATURATING ARITHMETIC
   -- ========================================================================

   function Saturating_Add (A, B : Integer) return Integer
     with Pre => (A in Integer'First .. Integer'Last and
                  B in Integer'First .. Integer'Last),
          Post => Saturating_Add'Result in Integer'First .. Integer'Last;

   function Saturating_Sub (A, B : Integer) return Integer
     with Pre => (A in Integer'First .. Integer'Last and
                  B in Integer'First .. Integer'Last),
          Post => Saturating_Sub'Result in Integer'First .. Integer'Last;

   function Saturating_Mul (A, B : Integer) return Integer
     with Pre => (A in Integer'First .. Integer'Last and
                  B in Integer'First .. Integer'Last),
          Post => Saturating_Mul'Result in Integer'First .. Integer'Last;

   function Saturating_Div (A, B : Integer) return Integer
     with Pre => B /= 0,
          Post => Saturating_Div'Result in Integer'First .. Integer'Last;

   function Clamp (Value, Min, Max : Integer) return Integer
     with Pre => Min <= Max,
          Post => Clamp'Result in Min .. Max;

   -- ========================================================================
   -- 5. DIGITAL ROOT (MODULO-9)
   -- ========================================================================

   function Digital_Root (N : Integer) return Integer
     with Pre => N >= 0,
          Post => Digital_Root'Result in 1 .. 9;

   -- ========================================================================
   -- 6. FONCTION DE CALCUL V14.0
   -- ========================================================================

   function Compute_V14_Temperature
     (Latitude      : Integer;
      Altitude      : Altitude_Type;
      Pressure      : Pressure_Type;
      Humidity      : Humidity_Type;
      Albedo        : Albedo_Type;
      CO2           : CO2_Type;
      Solar_Flux    : Solar_Flux_Type;
      Day           : Integer;
      Year          : Integer;
      Hour          : Integer) return Temp_Type
     with Pre => Latitude in -9000 .. 9000 and
                 Altitude in -500 .. 10000 and
                 Pressure in 500 .. 11000 and
                 Humidity in 0 .. 1000 and
                 Albedo in 0 .. 100 and
                 CO2 in 0 .. 10000,
          Post => Compute_V14_Temperature'Result in -600 .. 600;
   -- T_surface = Ψ_V14 × (CO2 × P_surface) / (β × H × k)
   --            + Altitude_Adj + Latitude_Adj + Seasonal_Adj
   --            + Urban_Adj + Albedo_Adj

   -- ========================================================================
   -- 7. INITIALISATION DES CAS DE TEST
   -- ========================================================================

   procedure Initialize_Test_Cases
     (Tests : out Test_Array)
     with Post => (for all T in Test_ID => Tests (T).Checksum = 9);

   -- ========================================================================
   -- 8. EXÉCUTION DE LA SUITE DE TESTS
   -- ========================================================================

   procedure Run_Test_Suite
     (Tests  : in out Test_Array;
      Status :    out Boolean)
     with Pre => (for all T in Test_ID => Tests (T).Checksum = 9),
          Post => (if Status then
                     (for all T in Test_ID => Tests (T).Checksum = 9));

   -- ========================================================================
   -- 9. RAPPORT DE VALIDATION
   -- ========================================================================

   type Validation_Report is record
      Total_Tests      : Integer := 0;
      Passed_Tests     : Integer := 0;
      Failed_Tests     : Integer := 0;
      Mean_Error       : Integer := 0;     -- ×10°C
      Max_Error        : Integer := 0;     -- ×10°C
      Checksum         : Integer range 1 .. 9 := 9;
   end record
     with Predicate => Validation_Report.Checksum in 1 .. 9;

   procedure Generate_Report
     (Tests  : in Test_Array;
      Report : out Validation_Report)
     with Pre => (for all T in Test_ID => Tests (T).Checksum = 9),
          Post => Report.Checksum = 9;

   -- ========================================================================
   -- 10. INTERFACE IA – QUERY
   -- ========================================================================

   procedure IA_Query
     (Tests      : in     Test_Array;
      Question   : in     String;
      Response   :    out String;
      Confidence : out Integer)
     with Pre => (for all T in Test_ID => Tests (T).Checksum = 9) and
                 Question'Length > 0,
          Post => Confidence in 0 .. 100;

   -- ========================================================================
   -- 11. INTERFACE IA – CONTRIBUTE
   -- ========================================================================

   procedure IA_Contribute
     (Tests      : in out Test_Array;
      Suggestion : in     String;
      Value      : in     Integer;
      Confidence : in     Integer)
     with Pre => Confidence in 0 .. 100 and Suggestion'Length > 0,
          Post => (for all T in Test_ID => Tests (T).Checksum = 9);

end V14_Crash_Test_Suite;
