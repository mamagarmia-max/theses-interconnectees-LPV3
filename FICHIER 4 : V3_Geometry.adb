-- ============================================================================
-- V3_Geometry.adb — Implementation V3_Geometry
-- Version 11.0.0
-- ============================================================================

package body V3_Geometry with
   SPARK_Mode => On
is

   function Get_Compact_Packing (N : Integer) return Compact_Packing_Type is
   begin
      case N is
         when 1      => return Single;
         when 2      => return Pair;
         when 6      => return Octahedron;
         when 8      => return Cube;
         when 10     => return Bipyramid;
         when 12     => return Icosahedron;
         when 14     => return None;      -- Non compact mais stable (Si)
         when 16     => return None;      -- Non compact mais stable (S)
         when 18     => return None;      -- Non compact mais stable (Ar)
         when 20     => return None;
         when 24     => return None;
         when 28     => return None;
         when 32     => return None;
         when 36     => return None;
         when 50     => return None;
         when 54     => return None;
         when 82     => return None;
         when 86     => return None;
         when others => return None;
      end case;
   end Get_Compact_Packing;

   function Is_Stable_Vortex_Count (N : Integer) return Boolean is
   begin
      for I in Stable_Numbers'Range loop
         if Stable_Numbers (I) = N then
            return True;
         end if;
      end loop;
      return False;
   end Is_Stable_Vortex_Count;

   function Compute_Valence_Sites (N : Integer; Packing : Compact_Packing_Type)
                                   return Valence_Site_Array is
      Sites : Valence_Site_Array;
      Max_Sites : Integer := 0;
   begin
      -- Initialisation
      for I in 1 .. 20 loop
         Sites (I) := (Site_Index => I,
                       Position_X => 0.0,
                       Position_Y => 0.0,
                       Position_Z => 0.0,
                       Is_Occupied => False,
                       Site_Type => S,
                       Phase_Availability => 0.0);
      end loop;

      -- Nombre de sites selon la géométrie
      case Packing is
         when Single =>
            Max_Sites := 1;
            Sites (1) := (1, 0.0, 0.0, 0.0, False, S, 1.0);
         when Pair =>
            Max_Sites := 2;
            Sites (1) := (1, -1.0, 0.0, 0.0, False, S, 1.0);
            Sites (2) := (2, 1.0, 0.0, 0.0, False, S, 1.0);
         when Octahedron =>
            Max_Sites := 4;
            Sites (1) := (1, 1.0, 0.0, 0.0, False, P, 1.0);
            Sites (2) := (2, -1.0, 0.0, 0.0, False, P, 1.0);
            Sites (3) := (3, 0.0, 1.0, 0.0, False, P, 1.0);
            Sites (4) := (4, 0.0, -1.0, 0.0, False, P, 1.0);
         when Cube =>
            Max_Sites := 2;
            Sites (1) := (1, 0.0, 0.0, 0.0, False, S, 1.0);
            Sites (2) := (2, 0.0, 0.0, 0.0, False, S, 1.0);
         when Bipyramid =>
            Max_Sites := 3;
            Sites (1) := (1, 1.0, 0.0, 0.0, False, P, 1.0);
            Sites (2) := (2, -1.0, 0.0, 0.0, False, P, 1.0);
            Sites (3) := (3, 0.0, 1.0, 0.0, False, P, 1.0);
         when Icosahedron =>
            Max_Sites := 2;
            Sites (1) := (1, 0.0, 0.0, 0.0, False, S, 1.0);
            Sites (2) := (2, 0.0, 0.0, 0.0, False, S, 1.0);
         when None =>
            Max_Sites := 0;
      end case;

      for I in Max_Sites + 1 .. 20 loop
         Sites (I).Is_Occupied := True;  -- Marquer comme occupé (non disponible)
      end loop;

      return Sites;
   end Compute_Valence_Sites;

   function Phase_Demand_Of_Cluster (N : Integer) return Float is
      Base_Demand : constant Float := 0.01;  -- V par vortex
   begin
      return Base_Demand * Float (N);
   end Phase_Demand_Of_Cluster;

   function Check_Phase_Stability_Geometric (N : Integer; Phi_local : Float) return Boolean is
      Demand : Float := Phase_Demand_Of_Cluster (N);
   begin
      return (Phi_local - Demand) >= PHI_CRITICAL;
   end Check_Phase_Stability_Geometric;

   function Geometric_Valence (Z : Integer) return Integer is
   begin
      if Z in 1 .. 118 then
         return Valence_Table (Z);
      else
         return 0;
      end if;
   end Geometric_Valence;

   function Geometric_Period (N : Integer) return Integer is
   begin
      if N <= 2 then return 1;
      elsif N <= 10 then return 2;
      elsif N <= 18 then return 3;
      elsif N <= 36 then return 4;
      elsif N <= 54 then return 5;
      elsif N <= 86 then return 6;
      elsif N <= 118 then return 7;
      else return 0;
      end if;
   end Geometric_Period;

   function Geometric_Group (N : Integer) return Integer is
   begin
      case N is
         when 1 | 3 | 11 | 19 | 37 | 55 | 87 => return 1;
         when 4 | 12 | 20 | 38 | 56 | 88 => return 2;
         when 5 | 13 | 31 | 49 | 81 | 113 => return 13;
         when 6 | 14 | 32 | 50 | 82 | 114 => return 14;
         when 7 | 15 | 33 | 51 | 83 | 115 => return 15;
         when 8 | 16 | 34 | 52 | 84 | 116 => return 16;
         when 9 | 17 | 35 | 53 | 85 | 117 => return 17;
         when 2 | 10 | 18 | 36 | 54 | 86 | 118 => return 18;
         when 57 .. 71 | 89 .. 103 => return 3;  -- Lanthanides/Actinides
         when others => return 3;
      end case;
   end Geometric_Group;

end V3_Geometry;
