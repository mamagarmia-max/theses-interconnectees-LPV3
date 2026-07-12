-- SPDX-License-Identifier: LPV3
--
-- V14.2 — CENTRAL NUCLEUS WITH SYNOPTIC RUPTURE
--
-- Central Nucleus with:
--   - Heptadic pressure oscillation (7-day Rossby waves)
--   - Thermal purge (radiative release)
--   - 7-day heat storage memory
--   - Modulo-9 = 9 invariant
--
-- Author: Dr. Benhadid Outail (ORCID: 0009-0003-3057-9543)
-- License: LPV3
-- Version: 14.2.0
-- Date: 12 July 2026
-- ============================================================================

package V14_2_NC with
   SPARK_Mode => On,
   Pure,
   No_Implicit_Dereference,
   No_Secondary_Stack,
   Preelaborate
is

   -- ========================================================================
   -- 1. INVARIANTS V3
   -- ========================================================================

   PSI_V3          : constant := 480168;
   PHI_CRITICAL    : constant := -51100;
   BETA            : constant := 1_000_000;
   K_CYCLES        : constant := 7;

   -- ========================================================================
   -- 2. TYPES DE BASE
   -- ========================================================================

   subtype Temp_Type is Integer range -600 .. 600;
   subtype Pressure_Type is Integer range 500 .. 11000;
   subtype Humidity_Type is Integer range 0 .. 1000;
   subtype Albedo_Type is Integer range 0 .. 100;
   subtype Altitude_Type is Integer range -500 .. 10000;
   subtype CO2_Type is Integer range 0 .. 10000;
   subtype Day_Type is Integer range 1 .. 366;
   subtype Confidence_Type is Integer range 0 .. 100;

   -- ========================================================================
   -- 3. RÉGIONS
   -- ========================================================================

   type Region_Type is
     (Natural, Urban, Ocean, Forest, Agricultural, Polar);

   -- ========================================================================
   -- 4. ÉTAT COMPLET
   -- ========================================================================

   type Climate_State is record
      Region        : Region_Type := Natural;
      CO2_Level     : CO2_Type := 4250;
      Day           : Day_Type := 1;
      Year          : Integer := 2026;
      Latitude      : Integer := 0;
      Altitude      : Altitude_Type := 0;
      Albedo        : Albedo_Type := 30;
      Pressure      : Pressure_Type := 10130;
      Humidity      : Humidity_Type := 600;
      Initial_Pressure : Pressure_Type := 10130;

      -- Urbain
      Population    : Integer := 0;
      Building_Coverage : Integer := 0;
      Vegetation_Cover : Integer := 0;

      -- Inertie et stockage
      Inertia       : Integer range 0 .. 1000 := 500;
      Heat_Storage  : Integer range 0 .. 1000 := 0;
      Prev_Temps    : array (1 .. 7) of Temp_Type := (others => 0);
      Day_Count     : Integer := 0;

      -- Résultat
      Surface_Temp  : Temp_Type := 0;
      Confidence    : Confidence_Type := 0;
      Checksum      : Integer range 1 .. 9 := 9;
   end record
     with Predicate => Climate_State.Checksum in 1 .. 9;

   -- ========================================================================
   -- 5. FONCTIONS PRINCIPALES
   -- ========================================================================

   function Compute_Base_Temp (State : Climate_State) return Temp_Type;

   procedure Run_Climate (State : in out Climate_State);

   procedure Update_Storage (State : in out Climate_State; Base_Temp, Actual_Temp : Temp_Type);

   -- ========================================================================
   -- 6. INTERFACE IA
   -- ========================================================================

   procedure IA_Query
     (State      : in     Climate_State;
      Question   : in     String;
      Response   :    out String;
      Confidence : out Confidence_Type);

   procedure IA_Contribute
     (State      : in out Climate_State;
      Suggestion : in     String;
      Value      : in     Integer;
      Confidence : in     Confidence_Type);

end V14_2_NC;
