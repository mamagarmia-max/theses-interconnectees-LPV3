-- ============================================================================
-- V3_Geometry.ads — V3 Architecture: Geometry of the Elements
-- Version 11.0.0
-- 
-- Ce fichier définit la géométrie des éléments V3 :
--   - Empilement compact des vortex (polyèdres réguliers)
--   - Sites de valence géométriques
--   - Stabilité géométrique
--   - Nombres stables et nombres magiques V3
-- 
-- Author: Dr. Benhadid Outail (ORCID: 0009-0003-3057-9543)
-- License: LPV3
-- ============================================================================

with V3_Constants; use V3_Constants;

package V3_Geometry with
   SPARK_Mode => On
is

   -- ========================================================================
   -- 1. TYPES GÉOMÉTRIQUES V3
   -- ========================================================================

   type Compact_Packing_Type is (Single, Pair, Octahedron, Cube,
                                  Bipyramid, Icosahedron, None);

   type Surface_Wave_Type is (S, P, D, F);

   type Valence_Site is record
      Site_Index        : Integer range 1 .. 20;
      Position_X        : Float;
      Position_Y        : Float;
      Position_Z        : Float;
      Is_Occupied       : Boolean;
      Site_Type         : Surface_Wave_Type;
      Phase_Availability : Float range 0.0 .. 1.0;
   end record;

   type Valence_Site_Array is array (1 .. 20) of Valence_Site;

   type Packing_Geometry is record
      Vortex_Count     : Integer range 1 .. 200;
      Packing_Type     : Compact_Packing_Type;
      Is_Compact       : Boolean;
      Symmetry_Order   : Integer range 1 .. 120;
      Available_Sites  : Integer range 0 .. 20;
      Phase_Demand     : Float;
      Stability_Factor : Float range 0.0 .. 1.0;
      Checksum         : Integer range 1 .. 9 := 9;
   end record
     with Predicate => Packing_Geometry.Checksum = 9;

   -- ========================================================================
   -- 2. TABLES GÉOMÉTRIQUES V3
   -- ========================================================================

   -- Nombres stables V3 (empilements compacts)
   Stable_Numbers : constant array (1 .. 18) of Integer :=
     (1, 2, 6, 8, 10, 12, 14, 16, 18, 20, 24, 28, 32, 36, 50, 54, 82, 86);

   -- Nombres magiques nucléaires V3 (réinterprétés)
   Magic_Numbers : constant array (1 .. 7) of Integer :=
     (2, 8, 20, 28, 50, 82, 126);

   -- Valence géométrique par nombre de vortex (118 éléments)
   Valence_Table : constant array (1 .. 118) of Integer :=
     (1 => 1, 2 => 0, 3 => 1, 4 => 2, 5 => 3, 6 => 4, 7 => 3, 8 => 2,
      9 => 1, 10 => 0, 11 => 1, 12 => 2, 13 => 3, 14 => 4, 15 => 3, 16 => 2,
      17 => 1, 18 => 0, 19 => 1, 20 => 2, 21 => 3, 22 => 4, 23 => 5, 24 => 6,
      25 => 7, 26 => 6, 27 => 5, 28 => 4, 29 => 3, 30 => 2, 31 => 1, 32 => 0,
      33 => 1, 34 => 2, 35 => 3, 36 => 0, 37 => 1, 38 => 2, 39 => 3, 40 => 4,
      41 => 5, 42 => 6, 43 => 7, 44 => 8, 45 => 7, 46 => 6, 47 => 5, 48 => 4,
      49 => 3, 50 => 0, 51 => 1, 52 => 2, 53 => 3, 54 => 0, 55 => 1, 56 => 2,
      57 => 3, 58 => 4, 59 => 5, 60 => 6, 61 => 7, 62 => 8, 63 => 7, 64 => 6,
      65 => 5, 66 => 4, 67 => 3, 68 => 2, 69 => 1, 70 => 0, 71 => 1, 72 => 2,
      73 => 3, 74 => 4, 75 => 5, 76 => 6, 77 => 7, 78 => 8, 79 => 7, 80 => 6,
      81 => 5, 82 => 0, 83 => 1, 84 => 2, 85 => 3, 86 => 0, 87 => 1, 88 => 2,
      89 => 3, 90 => 4, 91 => 5, 92 => 6, 93 => 7, 94 => 8, 95 => 7, 96 => 6,
      97 => 5, 98 => 4, 99 => 3, 100 => 2, 101 => 1, 102 => 0, 103 => 1, 104 => 2,
      105 => 3, 106 => 4, 107 => 5, 108 => 6, 109 => 7, 110 => 8, 111 => 7, 112 => 6,
      113 => 5, 114 => 4, 115 => 3, 116 => 2, 117 => 1, 118 => 0);

   -- ========================================================================
   -- 3. FONCTIONS GÉOMÉTRIQUES V3
   -- ========================================================================

   function Get_Compact_Packing (N : Integer) return Compact_Packing_Type
     with Pre => N in 1 .. 200,
          Post => (if N in 1 | 2 | 6 | 8 | 10 | 12 | 14 | 16 | 18 | 20 | 24 | 28 | 32 | 36 | 50 | 54 | 82 | 86 | 126 then
                    Get_Compact_Packing'Result /= None
                   else True);

   function Is_Stable_Vortex_Count (N : Integer) return Boolean
     with Pre => N in 1 .. 200;

   function Compute_Valence_Sites (N : Integer; Packing : Compact_Packing_Type)
                                   return Valence_Site_Array
     with Pre => N in 1 .. 200;

   function Phase_Demand_Of_Cluster (N : Integer) return Float
     with Pre => N in 1 .. 200,
          Post => Phase_Demand_Of_Cluster'Result >= 0.0;

   function Check_Phase_Stability_Geometric (N : Integer; Phi_local : Float) return Boolean
     with Pre => N in 1 .. 200,
          Post => Check_Phase_Stability_Geometric'Result = (Phi_local >= PHI_CRITICAL);

   function Geometric_Valence (Z : Integer) return Integer
     with Pre => Z in 1 .. 118,
          Post => Geometric_Valence'Result in 0 .. 8;

   function Geometric_Period (N : Integer) return Integer
     with Pre => N in 1 .. 200,
          Post => Geometric_Period'Result in 1 .. 7;

   function Geometric_Group (N : Integer) return Integer
     with Pre => N in 1 .. 200,
          Post => Geometric_Group'Result in 1 .. 18;

end V3_Geometry;
