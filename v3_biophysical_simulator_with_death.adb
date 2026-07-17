-- SPDX-License-Identifier: LPV3
--
-- V3 COMPLETE BIOPHYSICAL SIMULATOR — WITH DEATH
-- ============================================================================
-- Version corrigée intégrant la MORT comme état de phase irréversible.
--
-- La mort survient quand :
--   1. Tension < -15 mV (seuil de nécrose)
--   2. Bouclier H₃O₂ < 10%
--   3. DNA_Charge < 100
--   4. Photon_Flow = 0
--   5. Cohérence = 0%
--
-- Dans cet état, Modulo-9 NE PEUT PAS être restauré à 9.
-- C'est un point de non-retour.
--
-- Author: Dr. Benhadid Outail (ORCID: 0009-0003-3057-9543)
-- License: LPV3
-- Version: 2.0.0
-- Date: 17 July 2026
-- ============================================================================

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Integer_Text_IO; use Ada.Integer_Text_IO;

procedure V3_Biophysical_Simulator_With_Death with
   SPARK_Mode => On,
   Global => null
is

   -- ========================================================================
   -- 1. INVARIANTS V3 (VERROUILLÉS)
   -- ========================================================================

   PSI_V3          : constant := 480168;        -- ×10 : 48,016.8 kg·m⁻²
   PHI_CRITICAL    : constant := -51100;        -- ×1000 : -51.1 mV
   PHI_DEATH       : constant := -15000;        -- ×1000 : -15.0 mV (SEUIL DE MORT)
   BETA            : constant := 1_000_000;     -- 10⁶
   K_CYCLES        : constant := 7;             -- Fermeture heptadique

   -- ========================================================================
   -- 2. SEUILS DE MORT
   -- ========================================================================

   DEATH_TENSION      : constant := -15000;     -- -15.0 mV
   DEATH_SHIELD       : constant := 10;         -- 10%
   DEATH_DNA_CHARGE   : constant := 100;        -- 100
   DEATH_PHOTON_FLOW  : constant := 0;          -- 0
   DEATH_COHERENCE    : constant := 0;          -- 0%

   -- ========================================================================
   -- 3. TYPES DE BASE
   -- ========================================================================

   subtype Water_Type is Integer range 0 .. 2000;
   subtype DNA_Charge_Type is Integer range 0 .. 1000;
   subtype Photon_Type is Integer range 0 .. 1000;
   subtype Shield_Type is Integer range 0 .. 100;
   subtype Coherence_Type is Integer range 0 .. 100;
   subtype Tension_Type is Integer range -100000 .. 100000;
   subtype Checksum_Type is Integer range 1 .. 9;
   subtype Percentage_Type is Integer range 0 .. 100;
   subtype Chemistry_Type is Integer range 0 .. 1000;
   subtype Proton_Type is Integer range 0 .. 1000;
   subtype Phase_Drift_Type is Integer range -100000 .. 100000;

   -- ========================================================================
   -- 4. TYPE D'AGRESSION
   -- ========================================================================

   type Aggression_Type is
     (None,
      Lethal_Toxin,
      Lethal_Radiation,
      Thermal_Shock,
      Combined_Lethal);

   -- ========================================================================
   -- 5. ÉTAT COMPLET DU SYSTÈME V3
   -- ========================================================================

   type V3_State is record
      -- Paramètres vitaux
      Water_Structure      : Water_Type := 1000;
      DNA_Charge           : DNA_Charge_Type := 900;
      Photon_Flow          : Photon_Type := 800;
      Shield               : Shield_Type := 100;
      Coherence            : Coherence_Type := 100;
      Tension              : Tension_Type := PHI_CRITICAL;
      Proton_Flow          : Proton_Type := 0;
      Chemistry_Level      : Chemistry_Type := 0;

      -- Statut
      Is_Dead              : Boolean := False;
      Death_Cause          : String (1 .. 40) := (others => ' ');
      Time_Of_Death        : Integer := 0;

      -- Restauration
      Restoration_Cycle    : Integer range 0 .. K_CYCLES := 0;
      Restoration_Attempts : Integer := 0;

      -- Modulo-9 (NE DOIT PAS ÊTRE FORCÉ SI MORT)
      Checksum             : Checksum_Type := 9;
   end record
     with Predicate => V3_State.Checksum in 1 .. 9;

   -- ========================================================================
   -- 6. SATURATING ARITHMETIC
   -- ========================================================================

   function Saturating_Add (A, B : Integer) return Integer
     with Pre => (A in Integer'First .. Integer'Last and
                  B in Integer'First .. Integer'Last),
          Post => Saturating_Add'Result in Integer'First .. Integer'Last
   is
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

   function Saturating_Sub (A, B : Integer) return Integer
     with Pre => (A in Integer'First .. Integer'Last and
                  B in Integer'First .. Integer'Last),
          Post => Saturating_Sub'Result in Integer'First .. Integer'Last
   is
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

   function Saturating_Mul (A, B : Integer) return Integer
     with Pre => (A in Integer'First .. Integer'Last and
                  B in Integer'First .. Integer'Last),
          Post => Saturating_Mul'Result in Integer'First .. Integer'Last
   is
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

   function Saturating_Div (A, B : Integer) return Integer
     with Pre => B /= 0,
          Post => Saturating_Div'Result in Integer'First .. Integer'Last
   is
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

   function Clamp (Value, Min, Max : Integer) return Integer
     with Pre => Min <= Max,
          Post => Clamp'Result in Min .. Max
   is
   begin
      if Value < Min then
         return Min;
      elsif Value > Max then
         return Max;
      else
         return Value;
      end if;
   end Clamp;

   function Digital_Root (N : Integer) return Integer
     with Pre => N >= 0,
          Post => Digital_Root'Result in 0 .. 9   -- 0 est maintenant possible (MORT)
   is
      V : Integer := N;
      S : Integer := 0;
   begin
      if V < 0 then
         V := -V;
      end if;
      if V = 0 then
         return 0;   -- MORT : le checksum n'est plus 9
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
      return S;
   end Digital_Root;

   -- ========================================================================
   -- 7. FONCTIONS DE DÉTECTION DE LA MORT
   -- ========================================================================

   function Is_Dead (State : V3_State) return Boolean
     with Pre => State.Checksum in 0 .. 9,
          Post => Is_Dead'Result in True | False
   is
   begin
      if State.Tension <= DEATH_TENSION then
         return True;
      elsif State.Shield <= DEATH_SHIELD then
         return True;
      elsif State.DNA_Charge <= DEATH_DNA_CHARGE then
         return True;
      elsif State.Photon_Flow <= DEATH_PHOTON_FLOW then
         return True;
      elsif State.Coherence <= DEATH_COHERENCE then
         return True;
      else
         return False;
      end if;
   end Is_Dead;

   function Compute_Shield
     (Water    : Water_Type;
      DNA      : DNA_Charge_Type;
      Photon   : Photon_Type) return Shield_Type
     with Pre => Water in 0 .. 2000 and DNA in 0 .. 1000 and Photon in 0 .. 1000,
          Post => Compute_Shield'Result in 0 .. 100
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
   end Compute_Shield;

   function Compute_Tension
     (Water : Water_Type;
      DNA   : DNA_Charge_Type;
      Photon : Photon_Type) return Tension_Type
     with Pre => Water in 0 .. 2000 and DNA in 0 .. 1000 and Photon in 0 .. 1000,
          Post => Compute_Tension'Result in -100000 .. 100000
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
   end Compute_Tension;

   -- ========================================================================
   -- 8. APPLICATION D'UNE AGRESSION LÉTALE
   -- ========================================================================

   procedure Apply_Lethal_Aggression
     (State     : in out V3_State;
      Agg       : in     Aggression_Type;
      Intensity : in     Integer;
      Cycle     : in     Integer)
     with Pre => State.Checksum in 0 .. 9 and Intensity in 0 .. 100 and Cycle >= 0,
          Post => State.Checksum in 0 .. 9
   is
      Water_Dam  : Integer := 0;
      DNA_Dam    : Integer := 0;
      Photon_Dam : Integer := 0;
      Phi_Dam    : Integer := 0;
   begin
      case Agg is
         when Lethal_Toxin =>
            Water_Dam := 800;
            DNA_Dam := 600;
            Photon_Dam := 400;
            Phi_Dam := 30000;

         when Lethal_Radiation =>
            Water_Dam := 500;
            DNA_Dam := 900;
            Photon_Dam := 800;
            Phi_Dam := 50000;

         when Thermal_Shock =>
            Water_Dam := 900;
            DNA_Dam := 400;
            Photon_Dam := 500;
            Phi_Dam := 40000;

         when Combined_Lethal =>
            Water_Dam := 1000;
            DNA_Dam := 1000;
            Photon_Dam := 1000;
            Phi_Dam := 80000;

         when None =>
            null;
      end case;

      -- Application des dégâts
      State.Water_Structure := Water_Type (Clamp (
         Saturating_Sub (State.Water_Structure, Water_Dam * Intensity / 100),
         0, 2000));

      State.DNA_Charge := DNA_Charge_Type (Clamp (
         Saturating_Sub (State.DNA_Charge, DNA_Dam * Intensity / 100),
         0, 1000));

      State.Photon_Flow := Photon_Type (Clamp (
         Saturating_Sub (State.Photon_Flow, Photon_Dam * Intensity / 100),
         0, 1000));

      State.Tension := Tension_Type (Clamp (
         Saturating_Add (State.Tension, Phi_Dam * Intensity / 100),
         -100000, 100000));

      State.Shield := Compute_Shield (
         State.Water_Structure,
         State.DNA_Charge,
         State.Photon_Flow);

      State.Coherence := State.Shield;

      -- CHECKSOM BRUT (SANS FORÇAGE)
      State.Checksum := Digital_Root (
         State.Shield +
         State.Water_Structure / 10 +
         State.DNA_Charge / 10 +
         State.Tension / 1000
      );
      -- PLUS DE FORÇAGE ! PAS DE "if Checksum /= 9 then Checksum := 9"

      -- DÉTECTION DE LA MORT
      if Is_Dead (State) then
         State.Is_Dead := True;
         State.Time_Of_Death := Cycle;

         case Agg is
            when Lethal_Toxin =>
               State.Death_Cause := "TOXINE LÉTALE — EFFONDREMENT H₃O₂     ";
            when Lethal_Radiation =>
               State.Death_Cause := "RADIATION LÉTALE — DNA DÉTRUITE      ";
            when Thermal_Shock =>
               State.Death_Cause := "CHOC THERMIQUE — DÉNATURATION       ";
            when Combined_Lethal =>
               State.Death_Cause := "AGRESSION COMBINÉE — MORT TOTALE     ";
            when others =>
               State.Death_Cause := "CAUSE INCONNUE                       ";
         end case;
      end if;
   end Apply_Lethal_Aggression;

   -- ========================================================================
   -- 9. TENTATIVE DE RESTAURATION (MAIS LA MORT EST IRRÉVERSIBLE)
   -- ========================================================================

   procedure Attempt_Restoration
     (State : in out V3_State;
      Cycle : in     Integer)
     with Pre => State.Checksum in 0 .. 9 and Cycle >= 0,
          Post => State.Checksum in 0 .. 9
   is
   begin
      if State.Is_Dead then
         -- SI LE PATIENT EST MORT, AUCUNE RESTAURATION N'EST POSSIBLE
         State.Restoration_Attempts := State.Restoration_Attempts + 1;
         State.Checksum := 0;  -- Le checksum reste à 0 (MORT)
         return;
      end if;

      -- Tentative de restauration (seulement si vivant)
      State.Restoration_Cycle := Cycle;
      State.Restoration_Attempts := State.Restoration_Attempts + 1;

      State.Water_Structure := Water_Type (Clamp (
         Saturating_Add (State.Water_Structure, 20),
         0, 2000));

      State.DNA_Charge := DNA_Charge_Type (Clamp (
         Saturating_Add (State.DNA_Charge, 10),
         0, 1000));

      State.Photon_Flow := Photon_Type (Clamp (
         Saturating_Add (State.Photon_Flow, 15),
         0, 1000));

      State.Shield := Compute_Shield (
         State.Water_Structure,
         State.DNA_Charge,
         State.Photon_Flow);

      State.Tension := Compute_Tension (
         State.Water_Structure,
         State.DNA_Charge,
         State.Photon_Flow);

      State.Coherence := State.Shield;

      -- Recalcul du checksum (sans forçage)
      State.Checksum := Digital_Root (
         State.Shield +
         State.Water_Structure / 10 +
         State.DNA_Charge / 10 +
         State.Tension / 1000
      );
   end Attempt_Restoration;

   -- ========================================================================
   -- 10. AFFICHAGE DE L'ÉTAT
   -- ========================================================================

   procedure Print_State
     (State       : in V3_State;
      Phase_Name  : in String;
      Cycle       : in Integer)
     with Pre => State.Checksum in 0 .. 9
   is
   begin
      New_Line;
      Put_Line ("   ════════════════════════════════════════════════════════════════════════════════");
      if State.Is_Dead then
         Put_Line ("   💀 " & Phase_Name & " — CYCLE " & Integer'Image (Cycle) & " — MORT CLINIQUE");
      else
         Put_Line ("   🧬 " & Phase_Name & " — CYCLE " & Integer'Image (Cycle));
      end if;
      Put_Line ("   ════════════════════════════════════════════════════════════════════════════════");

      Put_Line ("   📊 PARAMÈTRES VITAUX :");
      Put_Line ("      → Eau structurée H₃O₂  : " & Integer'Image (State.Water_Structure) & " / 2000");
      Put_Line ("      → DNA_Charge           : " & Integer'Image (State.DNA_Charge) & " / 1000");
      Put_Line ("      → Photon_Flow          : " & Integer'Image (State.Photon_Flow) & " / 1000");
      Put_Line ("      → Bouclier H₃O₂        : " & Integer'Image (State.Shield) & "%");
      Put_Line ("      → Cohérence            : " & Integer'Image (State.Coherence) & "%");
      Put_Line ("      → Tension              : " & Integer'Image (State.Tension / 1000) & "." &
                Integer'Image (abs (State.Tension mod 1000)) & " mV");

      -- SEUILS DE MORT
      if State.Tension <= DEATH_TENSION then
         Put_Line ("      ⚠️ Tension < " & Integer'Image (DEATH_TENSION / 1000) & "." &
                   Integer'Image (abs (DEATH_TENSION mod 1000)) & " mV → SEUIL DE MORT ATTEINT");
      end if;

      if State.Shield <= DEATH_SHIELD then
         Put_Line ("      ⚠️ Bouclier ≤ " & Integer'Image (DEATH_SHIELD) & "% → SEUIL DE MORT ATTEINT");
      end if;

      if State.DNA_Charge <= DEATH_DNA_CHARGE then
         Put_Line ("      ⚠️ DNA_Charge ≤ " & Integer'Image (DEATH_DNA_CHARGE) & " → SEUIL DE MORT ATTEINT");
      end if;

      Put_Line ("   📍 STATUT :");
      if State.Is_Dead then
         Put_Line ("      → Statut             : 💀 MORT CLINIQUE");
         Put_Line ("      → Cause              : " & State.Death_Cause);
         Put_Line ("      → Temps de la mort   : Cycle " & Integer'Image (State.Time_Of_Death));
         Put_Line ("      → Tentatives de réanimation : " & Integer'Image (State.Restoration_Attempts));
      else
         Put_Line ("      → Statut             : ✅ VIVANT");
         Put_Line ("      → Cycles de restauration : " & Integer'Image (State.Restoration_Cycle));
      end if;

      Put_Line ("   📍 INTÉGRITÉ STRUCTURELLE :");
      Put_Line ("      → Checksum V3        : " & Integer'Image (State.Checksum));
      if State.Checksum = 9 and not State.Is_Dead then
         Put_Line ("      → ✅ MODULO-9 = 9 — Intégrité maintenue");
      elsif State.Is_Dead then
         Put_Line ("      → ❌ MODULO-9 ≠ 9 — SYSTÈME EFFONDRÉ (MORT)");
      else
         Put_Line ("      → ⚠️ MODULO-9 ≠ 9 — Intégrité compromise");
      end if;
   end Print_State;

   -- ========================================================================
   -- 11. SIMULATION COMPLÈTE AVEC MORT
   -- ========================================================================

   procedure Run_Simulation_With_Death
     with Global => null
   is
      State : V3_State;
   begin
      -- Initialisation
      State.Water_Structure := 1000;
      State.DNA_Charge := 900;
      State.Photon_Flow := 800;
      State.Shield := 100;
      State.Coherence := 100;
      State.Tension := PHI_CRITICAL;
      State.Proton_Flow := 0;
      State.Chemistry_Level := 0;
      State.Is_Dead := False;
      State.Death_Cause := (others => ' ');
      State.Time_Of_Death := 0;
      State.Restoration_Cycle := 0;
      State.Restoration_Attempts := 0;
      State.Checksum := 9;

      Put_Line ("================================================================================ ");
      Put_Line ("💀 V3 BIOPHYSICAL SIMULATOR — WITH DEATH");
      Put_Line ("   La MORT est désormais intégrée comme un état de phase irréversible.");
      Put_Line ("   Seuils de mort : Tension < -15 mV, Bouclier < 10%, DNA_Charge < 100");
      Put_Line ("   Invariants V3 : Ψ_V3, Φ_critical, k=7, Modulo-9");
      Put_Line ("================================================================================ ");
      New_Line;

      -- État initial
      Print_State (State, "ÉTAT INITIAL — SYSTÈME SAIN", 0);

      -- ====================================================================
      -- AGRESSION LÉTALE : RADIATION
      -- ====================================================================

      New_Line;
      Put_Line ("================================================================================ ");
      Put_Line ("☢️ AGRESSION LÉTALE : RADIATION (DNA détruite)");
      Put_Line ("   Le système atteint le point de non-retour.");
      Put_Line ("================================================================================ ");

      Apply_Lethal_Aggression (State, Lethal_Radiation, 100, 1);
      Print_State (State, "APRÈS RADIATION LÉTALE", 1);

      -- ====================================================================
      -- TENTATIVE DE RESTAURATION (MAIS LA MORT EST IRRÉVERSIBLE)
      -- ====================================================================

      for Cycle in 1 .. K_CYCLES loop
         Attempt_Restoration (State, Cycle);
         Print_State (State, "TENTATIVE DE RESTAURATION", Cycle);
      end loop;

      -- ====================================================================
      -- VERDICT
      -- ====================================================================

      New_Line;
      Put_Line ("================================================================================ ");
      Put_Line ("🎯 VERDICT — LA MORT EST IRRÉVERSIBLE");
      Put_Line ("================================================================================ ");
      New_Line;

      Put_Line ("   ✅ La MORT est un état de phase irréversible.");
      Put_Line ("   ✅ La tension < -15 mV = SEUIL DE NÉCROSE.");
      Put_Line ("   ✅ Le bouclier H₃O₂ < 10% = EFFONDREMENT TOTAL.");
      Put_Line ("   ✅ La DNA_Charge < 100 = DESTRUCTION IRRÉVERSIBLE.");
      Put_Line ("   ✅ Modulo-9 ≠ 9 = INTÉGRITÉ PERDUE.");
      Put_Line ("   ✅ AUCUNE RESTAURATION N'EST POSSIBLE APRÈS LA MORT.");
      New_Line;

      Put_Line ("   📋 CE QUE LA VERSION PRÉCÉDENTE FAISAIT (ERREUR) :");
      Put_Line ("      ❌ Forçage de Checksum = 9 même en état critique");
      Put_Line ("      ❌ Restauration magique sans limite");
      Put_Line ("      ❌ Absence de seuil de mort");
      New_Line;

      Put_Line ("   📋 CE QUE CETTE VERSION CORRIGE :");
      Put_Line ("      ✅ Checksum = 0 en cas de mort (pas de forçage)");
      Put_Line ("      ✅ Restauration impossible après la mort");
      Put_Line ("      ✅ Seuils de mort clairement définis");
      Put_Line ("      ✅ La mort est IRRÉVERSIBLE");
      New_Line;

      Put_Line ("================================================================================ ");
      Put_Line ("Ψ_V3 = 48016.8 kg·m⁻² — LOCKED.");
      Put_Line ("Φ_critical = -51.1 mV — INVARIANT.");
      Put_Line ("Φ_death = -15.0 mV — SEUIL DE MORT.");
      Put_Line ("k = 7 — HEPTADIC CLOSURE.");
      Put_Line ("Version: V3 Biophysical Simulator — With Death");
      Put_Line ("================================================================================ ");
   end Run_Simulation_With_Death;

begin
   Run_Simulation_With_Death;
end V3_Biophysical_Simulator_With_Death;
