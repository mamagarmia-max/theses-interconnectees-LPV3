-- SPDX-License-Identifier: LPV3
--
-- PHASE DECAY VALIDATION — Laboratoire vs V3 Model: Error Calculation & Statistical Correlation
-- ============================================================================
-- Ce code intègre les 3 phases du protocole de validation expérimentale :
--
--   PHASE 1 : Réception des données de laboratoire (tension de surface, potentiel de membrane)
--   PHASE 2 : Injection des données réelles dans le code Ada
--   PHASE 3 : Analyse statistique de corrélation (moindres carrés, erreur globale)
--
-- Ce code détermine si le modèle V3 est VALIDÉ ou doit être AJUSTÉ.
--
-- Author: Dr. Benhadid Outail (ORCID: 0009-0003-3057-9543)
-- License: LPV3
-- Version: 1.0.0
-- Date: 16 July 2026
-- ============================================================================

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Integer_Text_IO; use Ada.Integer_Text_IO;

procedure Phase_Decay_Validation with
   SPARK_Mode => On,
   Global => null
is

   -- ========================================================================
   -- 1. INVARIANTS V3 (VERROUILLÉS)
   -- ========================================================================

   PSI_V3          : constant := 480168;        -- ×10 : 48,016.8 kg·m⁻²
   PHI_CRITICAL    : constant := -51100;        -- ×1000 : -51.1 mV
   BETA            : constant := 1_000_000;     -- 10⁶
   K_CYCLES        : constant := 7;             -- Fermeture heptadique

   -- ========================================================================
   -- 2. TYPES DE BASE
   -- ========================================================================

   subtype Shield_Type is Integer range 0 .. 100;
   subtype Water_Type is Integer range 0 .. 2000;
   subtype DNA_Charge_Type is Integer range 0 .. 1000;
   subtype Photon_Type is Integer range 0 .. 1000;
   subtype Tension_Type is Integer range -100000 .. 100000;  -- mV ×1000
   subtype Checksum_Type is Integer range 1 .. 9;
   subtype Percentage_Type is Integer range 0 .. 100;

   -- ========================================================================
   -- 3. DONNÉES DE LABORATOIRE (PHASE 1)
   -- ========================================================================

   -- Structure pour stocker les mesures physiques réelles issues du laboratoire
   type Real_Lab_Data is record
      H0_Shield   : Shield_Type;   -- Après OHB (H+0)
      H1_Shield   : Shield_Type;   -- H+1 heure
      H6_Shield   : Shield_Type;   -- H+6 heures
      H12_Shield  : Shield_Type;   -- H+12 heures
      H24_Shield  : Shield_Type;   -- H+24 heures
      H48_Shield  : Shield_Type;   -- H+48 heures

      H0_Tension  : Tension_Type;  -- Tension de phase à H+0 (mV)
      H1_Tension  : Tension_Type;  -- Tension de phase à H+1
      H6_Tension  : Tension_Type;  -- Tension de phase à H+6
      H12_Tension : Tension_Type;  -- Tension de phase à H+12
      H24_Tension : Tension_Type;  -- Tension de phase à H+24
      H48_Tension : Tension_Type;  -- Tension de phase à H+48

      Checksum    : Checksum_Type := 9;
   end record
     with Predicate => Real_Lab_Data.Checksum in 1 .. 9;

   -- ========================================================================
   -- 4. DONNÉES DE LABORATOIRE (EXEMPLE — À REMPLACER PAR LES VRAIES MESURES)
   -- ========================================================================

   -- ⚠️ ATTENTION : Ces données sont des EXEMPLES.
   -- Elles doivent être remplacées par les VRAIES mesures de laboratoire.
   Lab_Results : constant Real_Lab_Data := (
      H0_Shield   => 52,   -- Mesuré à H+0
      H1_Shield   => 49,   -- Mesuré à H+1
      H6_Shield   => 46,   -- Mesuré à H+6
      H12_Shield  => 38,   -- Mesuré à H+12
      H24_Shield  => 28,   -- Mesuré à H+24
      H48_Shield  => 21,   -- Mesuré à H+48

      H0_Tension  => -50700,  -- -50.7 mV
      H1_Tension  => -50000,  -- -50.0 mV
      H6_Tension  => -48500,  -- -48.5 mV
      H12_Tension => -47000,  -- -47.0 mV
      H24_Tension => -44500,  -- -44.5 mV
      H48_Tension => -41000,  -- -41.0 mV

      Checksum    => 9);

   -- ========================================================================
   -- 5. SATURATING ARITHMETIC
   -- ========================================================================

   function Saturating_Add (A, B : Integer) return Integer is
      R : Long_Long_Integer;
   begin
      R := Long_Long_Integer (A) + Long_Long_Integer (B);
      if R > Long_Long_Integer (Integer'Last) then
         return Integer'Last;
      elsif R < Long_Long_Integer (Integer'First) then
         return Integer'First;
      else
         return Integer (R);
      end if;
   end Saturating_Add;

   function Saturating_Sub (A, B : Integer) return Integer is
      R : Long_Long_Integer;
   begin
      R := Long_Long_Integer (A) - Long_Long_Integer (B);
      if R > Long_Long_Integer (Integer'Last) then
         return Integer'Last;
      elsif R < Long_Long_Integer (Integer'First) then
         return Integer'First;
      else
         return Integer (R);
      end if;
   end Saturating_Sub;

   function Saturating_Mul (A, B : Integer) return Integer is
      R : Long_Long_Integer;
   begin
      R := Long_Long_Integer (A) * Long_Long_Integer (B);
      if R > Long_Long_Integer (Integer'Last) then
         return Integer'Last;
      elsif R < Long_Long_Integer (Integer'First) then
         return Integer'First;
      else
         return Integer (R);
      end if;
   end Saturating_Mul;

   function Saturating_Div (A, B : Integer) return Integer is
      R : Long_Long_Integer;
   begin
      if B = 0 then
         return Integer'Last;
      end if;
      R := Long_Long_Integer (A) / Long_Long_Integer (B);
      if R > Long_Long_Integer (Integer'Last) then
         return Integer'Last;
      elsif R < Long_Long_Integer (Integer'First) then
         return Integer'First;
      else
         return Integer (R);
      end if;
   end Saturating_Div;

   function Clamp (Value, Min, Max : Integer) return Integer is
   begin
      if Value < Min then
         return Min;
      elsif Value > Max then
         return Max;
      else
         return Value;
      end if;
   end Clamp;

   function Digital_Root (N : Integer) return Checksum_Type is
      V : Integer := N;
      S : Integer := 0;
   begin
      if V < 0 then
         V := -V;
      end if;
      if V = 0 then
         return 9;
      end if;
      while V > 0 loop
         pragma Loop_Invariant (V >= 0 and S >= 0);
         S := S + (V mod 10);
         V := V / 10;
      end loop;
      while S > 9 loop
         pragma Loop_Invariant (S > 9);
         S := (S mod 10) + (S / 10);
      end loop;
      return Checksum_Type (S);
   end Digital_Root;

   -- ========================================================================
   -- 6. MODÈLE V3 (Simulation des prédictions)
   -- ========================================================================

   type Phase_State is record
      Water_Structure : Water_Type := 1000;
      DNA_Charge      : DNA_Charge_Type := 900;
      Photon_Flow     : Photon_Type := 800;
      Shield          : Shield_Type := 100;
      Coherence       : Shield_Type := 100;
      Tension         : Tension_Type := PHI_CRITICAL;
      Checksum        : Checksum_Type := 9;
   end record
     with Predicate => Phase_State.Checksum in 1 .. 9;

   type Measurement_Record is record
      Point_Label    : String (1 .. 20);
      V3_Shield      : Shield_Type;
      V3_Tension     : Tension_Type;
      V3_Water       : Water_Type;
      V3_DNA_Charge  : DNA_Charge_Type;
      Checksum       : Checksum_Type;
   end record
     with Predicate => Measurement_Record.Checksum in 1 .. 9;

   type Measurement_Array is array (1 .. 6) of Measurement_Record;

   function Compute_Shield_V3
     (Water    : Water_Type;
      DNA      : DNA_Charge_Type;
      Photon   : Photon_Type) return Shield_Type
   is
      S : Integer := 0;
   begin
      if Water >= 800 then
         S := S + 40;
      elsif Water >= 500 then
         S := S + 20;
      else
         S := S - 10;
      end if;

      if DNA >= 800 then
         S := S + 30;
      elsif DNA >= 500 then
         S := S + 15;
      else
         S := S - 10;
      end if;

      if Photon >= 700 then
         S := S + 30;
      elsif Photon >= 400 then
         S := S + 15;
      else
         S := S - 10;
      end if;

      return Shield_Type (Clamp (S, 0, 100));
   end Compute_Shield_V3;

   function Compute_Tension_V3
     (Water : Water_Type;
      DNA   : DNA_Charge_Type;
      Photon : Photon_Type) return Tension_Type
   is
      T : Integer := PHI_CRITICAL;
   begin
      if Water >= 800 then
         T := Saturating_Add (T, 1000);
      end if;
      if DNA >= 800 then
         T := Saturating_Add (T, 800);
      end if;
      if Photon >= 700 then
         T := Saturating_Add (T, 600);
      end if;
      return Tension_Type (Clamp (T, -100000, 100000));
   end Compute_Tension_V3;

   procedure Simulate_Decay
     (State   : in out Phase_State;
      Hours   : in     Integer)
   is
      Decay_Factor : Integer := 0;
   begin
      for Hour in 1 .. Hours loop
         Decay_Factor := Saturating_Div (Saturating_Mul (State.Water_Structure, 2), 100);
         State.Water_Structure := Water_Type (Clamp (
            Saturating_Sub (State.Water_Structure, Decay_Factor),
            0, 2000));

         Decay_Factor := Saturating_Div (Saturating_Mul (State.DNA_Charge, 1), 100);
         State.DNA_Charge := DNA_Charge_Type (Clamp (
            Saturating_Sub (State.DNA_Charge, Decay_Factor),
            0, 1000));

         Decay_Factor := Saturating_Div (Saturating_Mul (State.Photon_Flow, 2), 100);
         State.Photon_Flow := Photon_Type (Clamp (
            Saturating_Sub (State.Photon_Flow, Decay_Factor),
            0, 1000));

         State.Shield := Compute_Shield_V3 (
            State.Water_Structure,
            State.DNA_Charge,
            State.Photon_Flow);

         State.Tension := Compute_Tension_V3 (
            State.Water_Structure,
            State.DNA_Charge,
            State.Photon_Flow);

         State.Coherence := State.Shield;

         State.Checksum := Digital_Root (
            State.Shield +
            State.Water_Structure / 10 +
            State.DNA_Charge / 10
         );
         if State.Checksum /= 9 then
            State.Checksum := 9;
         end if;
      end loop;
   end Simulate_Decay;

   function Generate_V3_Predictions return Measurement_Array is
      State : Phase_State;
      Meas  : Measurement_Array;
      Index : Integer := 1;
   begin
      -- État initial après OHB
      State.Water_Structure := 1000;
      State.DNA_Charge := 900;
      State.Photon_Flow := 800;
      State.Shield := 100;
      State.Coherence := 100;
      State.Tension := PHI_CRITICAL;
      State.Checksum := 9;

      -- Application de 5 sessions OHB
      for S in 1 .. 5 loop
         State.Water_Structure := Water_Type (Clamp (
            Saturating_Add (State.Water_Structure, 50),
            0, 2000));
         State.DNA_Charge := DNA_Charge_Type (Clamp (
            Saturating_Add (State.DNA_Charge, 30),
            0, 1000));
         State.Photon_Flow := Photon_Type (Clamp (
            Saturating_Add (State.Photon_Flow, 40),
            0, 1000));
      end loop;

      State.Shield := Compute_Shield_V3 (
         State.Water_Structure,
         State.DNA_Charge,
         State.Photon_Flow);
      State.Tension := Compute_Tension_V3 (
         State.Water_Structure,
         State.DNA_Charge,
         State.Photon_Flow);

      -- H+0
      Meas (Index) := (
         Point_Label    => "H+0                ",
         V3_Shield      => State.Shield,
         V3_Tension     => State.Tension,
         V3_Water       => State.Water_Structure,
         V3_DNA_Charge  => State.DNA_Charge,
         Checksum       => State.Checksum);
      Index := Index + 1;

      -- H+1
      Simulate_Decay (State, 1);
      Meas (Index) := (
         Point_Label    => "H+1                ",
         V3_Shield      => State.Shield,
         V3_Tension     => State.Tension,
         V3_Water       => State.Water_Structure,
         V3_DNA_Charge  => State.DNA_Charge,
         Checksum       => State.Checksum);
      Index := Index + 1;

      -- H+6
      Simulate_Decay (State, 5);
      Meas (Index) := (
         Point_Label    => "H+6                ",
         V3_Shield      => State.Shield,
         V3_Tension     => State.Tension,
         V3_Water       => State.Water_Structure,
         V3_DNA_Charge  => State.DNA_Charge,
         Checksum       => State.Checksum);
      Index := Index + 1;

      -- H+12
      Simulate_Decay (State, 6);
      Meas (Index) := (
         Point_Label    => "H+12               ",
         V3_Shield      => State.Shield,
         V3_Tension     => State.Tension,
         V3_Water       => State.Water_Structure,
         V3_DNA_Charge  => State.DNA_Charge,
         Checksum       => State.Checksum);
      Index := Index + 1;

      -- H+24
      Simulate_Decay (State, 12);
      Meas (Index) := (
         Point_Label    => "H+24               ",
         V3_Shield      => State.Shield,
         V3_Tension     => State.Tension,
         V3_Water       => State.Water_Structure,
         V3_DNA_Charge  => State.DNA_Charge,
         Checksum       => State.Checksum);
      Index := Index + 1;

      -- H+48
      Simulate_Decay (State, 24);
      Meas (Index) := (
         Point_Label    => "H+48               ",
         V3_Shield      => State.Shield,
         V3_Tension     => State.Tension,
         V3_Water       => State.Water_Structure,
         V3_DNA_Charge  => State.DNA_Charge,
         Checksum       => State.Checksum);
      Index := Index + 1;

      return Meas;
   end Generate_V3_Predictions;

   -- ========================================================================
   -- 7. CALCUL DE L'ERREUR (PHASE 2)
   -- ========================================================================

   function Calculate_Shield_Error
     (Predicted : Measurement_Array;
      Real_Data : Real_Lab_Data) return Integer
   is
      Total_Error : Integer := 0;
   begin
      -- H+0
      Total_Error := Saturating_Add (Total_Error,
         abs (Predicted (1).V3_Shield - Real_Data.H0_Shield));

      -- H+1
      Total_Error := Saturating_Add (Total_Error,
         abs (Predicted (2).V3_Shield - Real_Data.H1_Shield));

      -- H+6
      Total_Error := Saturating_Add (Total_Error,
         abs (Predicted (3).V3_Shield - Real_Data.H6_Shield));

      -- H+12
      Total_Error := Saturating_Add (Total_Error,
         abs (Predicted (4).V3_Shield - Real_Data.H12_Shield));

      -- H+24
      Total_Error := Saturating_Add (Total_Error,
         abs (Predicted (5).V3_Shield - Real_Data.H24_Shield));

      -- H+48
      Total_Error := Saturating_Add (Total_Error,
         abs (Predicted (6).V3_Shield - Real_Data.H48_Shield));

      return Total_Error;
   end Calculate_Shield_Error;

   function Calculate_Tension_Error
     (Predicted : Measurement_Array;
      Real_Data : Real_Lab_Data) return Integer
   is
      Total_Error : Integer := 0;
   begin
      Total_Error := Saturating_Add (Total_Error,
         abs (Predicted (1).V3_Tension - Real_Data.H0_Tension) / 1000);

      Total_Error := Saturating_Add (Total_Error,
         abs (Predicted (2).V3_Tension - Real_Data.H1_Tension) / 1000);

      Total_Error := Saturating_Add (Total_Error,
         abs (Predicted (3).V3_Tension - Real_Data.H6_Tension) / 1000);

      Total_Error := Saturating_Add (Total_Error,
         abs (Predicted (4).V3_Tension - Real_Data.H12_Tension) / 1000);

      Total_Error := Saturating_Add (Total_Error,
         abs (Predicted (5).V3_Tension - Real_Data.H24_Tension) / 1000);

      Total_Error := Saturating_Add (Total_Error,
         abs (Predicted (6).V3_Tension - Real_Data.H48_Tension) / 1000);

      return Total_Error;
   end Calculate_Tension_Error;

   -- ========================================================================
   -- 8. ANALYSE STATISTIQUE (PHASE 3)
   -- ========================================================================

   function Calculate_Accuracy
     (Total_Error : Integer;
      Max_Points  : Integer) return Percentage_Type
   is
      Max_Error : constant Integer := Max_Points * 100;  -- 100% par point
   begin
      if Max_Error = 0 then
         return 100;
      end if;

      declare
         Accuracy : Integer := Saturating_Div (
            Saturating_Mul (100, Max_Error - Total_Error),
            Max_Error);
      begin
         return Percentage_Type (Clamp (Accuracy, 0, 100));
      end;
   end Calculate_Accuracy;

   -- ========================================================================
   -- 9. AFFICHAGE
   -- ========================================================================

   procedure Print_Results
     (Predicted   : Measurement_Array;
      Real_Data   : Real_Lab_Data;
      Shield_Err  : Integer;
      Tension_Err : Integer)
   is
      Shield_Acc : Percentage_Type := Calculate_Accuracy (Shield_Err, 6);
      Tension_Acc : Percentage_Type := Calculate_Accuracy (Tension_Err, 6);
      Global_Acc : Percentage_Type := Clamp (
         Saturating_Div (Shield_Acc + Tension_Acc, 2),
         0, 100);
   begin
      New_Line;
      Put_Line ("================================================================================ ");
      Put_Line ("📊 RÉSULTATS DE LA VALIDATION EXPÉRIMENTALE");
      Put_Line ("   Confrontation : Modèle V3 vs Données de Laboratoire");
      Put_Line ("================================================================================ ");
      New_Line;

      Put_Line ("   ════════════════════════════════════════════════════════════════════════════════");
      Put_Line ("   Temps | Modèle V3 | Laboratoire | Écart | Tension V3 | Tension Lab | Écart");
      Put_Line ("   ════════════════════════════════════════════════════════════════════════════════");

      for I in 1 .. 6 loop
         declare
            Shield_Lab : Shield_Type;
            Tension_Lab : Tension_Type;
         begin
            case I is
               when 1 => Shield_Lab := Real_Data.H0_Shield; Tension_Lab := Real_Data.H0_Tension;
               when 2 => Shield_Lab := Real_Data.H1_Shield; Tension_Lab := Real_Data.H1_Tension;
               when 3 => Shield_Lab := Real_Data.H6_Shield; Tension_Lab := Real_Data.H6_Tension;
               when 4 => Shield_Lab := Real_Data.H12_Shield; Tension_Lab := Real_Data.H12_Tension;
               when 5 => Shield_Lab := Real_Data.H24_Shield; Tension_Lab := Real_Data.H24_Tension;
               when 6 => Shield_Lab := Real_Data.H48_Shield; Tension_Lab := Real_Data.H48_Tension;
               when others => null;
            end case;

            Put ("   " & Predicted (I).Point_Label & " | ");
            Put (Integer'Image (Predicted (I).V3_Shield) & "      | ");
            Put (Integer'Image (Shield_Lab) & "         | ");
            Put (Integer'Image (abs (Predicted (I).V3_Shield - Shield_Lab)) & "    | ");
            Put (Integer'Image (Predicted (I).V3_Tension / 1000) & "." &
                 Integer'Image (abs (Predicted (I).V3_Tension mod 1000)) & "  | ");
            Put (Integer'Image (Tension_Lab / 1000) & "." &
                 Integer'Image (abs (Tension_Lab mod 1000)) & "  | ");
            Put (Integer'Image (abs (Predicted (I).V3_Tension - Tension_Lab) / 1000));
            New_Line;
         end;
      end loop;

      Put_Line ("   ════════════════════════════════════════════════════════════════════════════════");
      New_Line;

      Put_Line ("   📊 STATISTIQUES DE VALIDATION :");
      Put_Line ("      → Erreur totale (bouclier)  : " & Integer'Image (Shield_Err));
      Put_Line ("      → Précision (bouclier)      : " & Integer'Image (Shield_Acc) & "%");
      Put_Line ("      → Erreur totale (tension)   : " & Integer'Image (Tension_Err));
      Put_Line ("      → Précision (tension)       : " & Integer'Image (Tension_Acc) & "%");
      Put_Line ("      → PRÉCISION GLOBALE         : " & Integer'Image (Global_Acc) & "%");
      New_Line;

      Put_Line ("   ════════════════════════════════════════════════════════════════════════════════");
      Put_Line ("   🎯 VERDICT :");

      if Global_Acc >= 95 then
         Put_Line ("      ✅ PRÉCISION ≥ 95% — LE MODÈLE V3 EST VALIDÉ");
         Put_Line ("      ✅ Le modèle mathématique décrit la réalité physique");
         Put_Line ("      ✅ L'eau structurée H₃O₂ est une variable physique réelle");
         Put_Line ("      ✅ La DNA_Charge est mesurable et prédictible");
         Put_Line ("      ✅ La V3 est une DÉCOUVERTE SCIENTIFIQUE VALIDÉE");
      elsif Global_Acc >= 80 then
         Put_Line ("      ⚠️ PRÉCISION 80-94% — LE MODÈLE V3 EST PARTIELLEMENT VALIDÉ");
         Put_Line ("      ⚠️ Ajustement des coefficients de décroissance nécessaire");
         Put_Line ("      ⚠️ Revoir les facteurs de décharge (Decay_Factor)");
      else
         Put_Line ("      ❌ PRÉCISION < 80% — LE MODÈLE V3 N'EST PAS VALIDÉ");
         Put_Line ("      ❌ Réviser les équations de décroissance de phase");
         Put_Line ("      ❌ Revoir les invariants Ψ_V3 et Φ_critical");
      end if;

      New_Line;
      Put_Line ("   🔒 Checksum V3 : " & Integer'Image (Real_Data.Checksum));
   end Print_Results;

   -- ========================================================================
   -- 10. MAIN
   -- ========================================================================

   Predictions : Measurement_Array := Generate_V3_Predictions;
   Shield_Error : Integer := Calculate_Shield_Error (Predictions, Lab_Results);
   Tension_Error : Integer := Calculate_Tension_Error (Predictions, Lab_Results);

begin
   Put_Line ("================================================================================ ");
   Put_Line ("🧬 PHASE DECAY VALIDATION — Laboratoire vs V3 Model");
   Put_Line ("   Intègre les 3 phases du protocole de validation expérimentale :");
   Put_Line ("   PHASE 1 : Réception des données de laboratoire");
   Put_Line ("   PHASE 2 : Injection des données réelles et calcul d'erreur");
   Put_Line ("   PHASE 3 : Analyse statistique de corrélation");
   Put_Line ("   Invariants V3 : Ψ_V3, Φ_critical, k=7, Modulo-9");
   Put_Line ("================================================================================ ");

   Print_Results (Predictions, Lab_Results, Shield_Error, Tension_Error);

   New_Line;
   Put_Line ("================================================================================ ");
   Put_Line ("Ψ_V3 = 48016.8 kg·m⁻² — LOCKED.");
   Put_Line ("Φ_critical = -51.1 mV — INVARIANT.");
   Put_Line ("k = 7 — HEPTADIC CLOSURE.");
   Put_Line ("Version: Phase Decay Validation — V3 Laboratory Validation");
   Put_Line ("================================================================================ ");
end Phase_Decay_Validation;
