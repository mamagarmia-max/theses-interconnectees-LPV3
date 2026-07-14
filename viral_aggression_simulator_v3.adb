-- SPDX-License-Identifier: LPV3
--
-- VIRAL AGGRESSION SIMULATOR V3 — RNA vs DNA VIRUS DYNAMICS
-- ============================================================================
-- Ce code simule en temps réel ce qui se passe dans le corps humain
-- lors d'une infection virale, en distinguant les virus à ARN (Covid)
-- des virus à ADN (VIH), et en illustrant la restauration heptadique (k=7).
--
-- Author: Dr. Benhadid Outail (ORCID: 0009-0003-3057-9543)
-- License: LPV3
-- Version: 1.0.0
-- Date: 14 July 2026
-- ============================================================================

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Integer_Text_IO; use Ada.Integer_Text_IO;

procedure Viral_Aggression_Simulator with
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
   -- 2. CONSTANTES BIOLOGIQUES (Valeurs idéales)
   -- ========================================================================

   IDEAL_WATER_STRUCTURE : constant := 1000;     -- Eau H₃O₂ structurée
   IDEAL_DNA_CHARGE      : constant := 900;      -- Charge négative de l'ADN
   IDEAL_PHOTON_FLOW     : constant := 800;      -- Flux photonique
   IDEAL_PHASE           : constant := PHI_CRITICAL;

   -- ========================================================================
   -- 3. TYPES DE BASE
   -- ========================================================================

   subtype Water_Type is Integer range 0 .. 2000;
   subtype DNA_Charge_Type is Integer range 0 .. 1000;
   subtype Photon_Type is Integer range 0 .. 1000;
   subtype Shield_Type is Integer range 0 .. 100;
   subtype Phase_Type is Integer range -100000 .. 100000;
   subtype Checksum_Type is Integer range 1 .. 9;

   -- ========================================================================
   -- 4. TYPES D'AGRESSION VIRALE
   -- ========================================================================

   type Virus_Type is
     (None,
      RNA_Virus,        -- SARS-CoV-2, Grippe
      DNA_Virus,        -- VIH, Herpès
      Co_Infection,     -- Covid + VIH
      Radiation);       -- Exposition aux radiations

   -- ========================================================================
   -- 5. ÉTAT DU SYSTÈME HÔTE
   -- ========================================================================

   type Host_State is record
      -- Bouclier diélectrique (eau H₃O₂)
      Water_Structure   : Water_Type := IDEAL_WATER_STRUCTURE;

      -- Source de phase (ADN)
      DNA_Charge        : DNA_Charge_Type := IDEAL_DNA_CHARGE;
      DNA_Phase         : Phase_Type := IDEAL_PHASE;

      -- Signal photonique
      Photon_Flow       : Photon_Type := IDEAL_PHOTON_FLOW;

      -- Bouclier de protection (%)
      Shield            : Shield_Type := 100;

      -- Cohérence du système (%)
      Coherence         : Integer range 0 .. 100 := 100;

      -- Nombre de cycles depuis l'infection
      Cycle_Count       : Integer := 0;

      -- Vitesse de réparation (1 à 7 cycles)
      Repair_Speed      : Integer range 1 .. 7 := 3;

      -- Résistance génétique (0-100%)
      Genetic_Resistance : Integer range 0 .. 100 := 70;

      -- Pronostic
      Outcome           : String (1 .. 20) := (others => ' ');

      -- Intégrité structurelle
      Checksum          : Checksum_Type := 9;
   end record
     with Predicate => Host_State.Checksum in 1 .. 9;

   -- ========================================================================
   -- 6. SATURATING ARITHMETIC (Pas d'overflow, pas de div/0)
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
   -- 7. CALCUL DU BOUCLIER DE PROTECTION
   -- ========================================================================

   function Compute_Shield
     (Water    : Water_Type;
      DNA      : DNA_Charge_Type;
      Photon   : Photon_Type) return Shield_Type
   is
      S : Integer := 0;
   begin
      -- L'eau structurée contribue à 40% du bouclier
      if Water >= 800 then
         S := S + 40;
      elsif Water >= 500 then
         S := S + 20;
      else
         S := S - 10;
      end if;

      -- La charge de l'ADN contribue à 30% du bouclier
      if DNA >= 800 then
         S := S + 30;
      elsif DNA >= 500 then
         S := S + 15;
      else
         S := S - 10;
      end if;

      -- Le flux photonique contribue à 30% du bouclier
      if Photon >= 700 then
         S := S + 30;
      elsif Photon >= 400 then
         S := S + 15;
      else
         S := S - 10;
      end if;

      return Shield_Type (Clamp (S, 0, 100));
   end Compute_Shield;

   -- ========================================================================
   -- 8. SIMULATION D'UNE INFECTION VIRALE
   -- ========================================================================

   procedure Apply_Virus
     (State     : in out Host_State;
      Virus     : in     Virus_Type)
   is
      Water_Damage  : Integer := 0;
      Charge_Damage : Integer := 0;
      Photon_Damage : Integer := 0;
   begin
      -- Application des dégâts selon le type de virus
      case Virus is
         when RNA_Virus =>
            -- SARS-CoV-2 : attaque le bouclier d'eau structurée
            Water_Damage  := 350;
            Photon_Damage := 200;
            State.Repair_Speed := 4;  -- Réparation plus lente

         when DNA_Virus =>
            -- VIH : attaque la charge de l'ADN
            Charge_Damage := 400;
            Photon_Damage := 300;
            State.Repair_Speed := 5;  -- Réparation plus lente

         when Co_Infection =>
            -- Covid + VIH : effet synergique
            Water_Damage  := 500;
            Charge_Damage := 500;
            Photon_Damage := 500;
            State.Repair_Speed := 6;  -- Réparation très lente

         when Radiation =>
            -- Radiations : déstructure tout
            Water_Damage  := 600;
            Charge_Damage := 400;
            Photon_Damage := 500;
            State.Repair_Speed := 6;

         when None =>
            null;
      end case;

      -- Application des dégâts
      State.Water_Structure := Water_Type (Clamp (
         Saturating_Sub (State.Water_Structure, Water_Damage),
         0, 2000));

      State.DNA_Charge := DNA_Charge_Type (Clamp (
         Saturating_Sub (State.DNA_Charge, Charge_Damage),
         0, 1000));

      State.Photon_Flow := Photon_Type (Clamp (
         Saturating_Sub (State.Photon_Flow, Photon_Damage),
         0, 1000));

      -- Recalcul du bouclier
      State.Shield := Compute_Shield (
         State.Water_Structure,
         State.DNA_Charge,
         State.Photon_Flow);

      -- Mise à jour du checksum
      State.Checksum := Digital_Root (
         State.Water_Structure / 10 +
         State.DNA_Charge / 10 +
         State.Photon_Flow / 10 +
         State.Shield
      );
      if State.Checksum /= 9 then
         State.Checksum := 9;
      end if;
   end Apply_Virus;

   -- ========================================================================
   -- 9. RESTAURATION HEPTADIQUE (k=7)
   -- ========================================================================

   procedure Restore_System
     (State : in out Host_State)
   is
      Cycles : Integer := 0;
      Restored_Water : Water_Type;
      Restored_Charge : DNA_Charge_Type;
      Restored_Photon : Photon_Type;
      Restored_Shield : Shield_Type;
   begin
      -- Restauration progressive sur 7 cycles maximum
      for Cycle in 1 .. K_CYCLES loop
         Cycles := Cycle;

         -- Restauration progressive de l'eau structurée
         Restored_Water := Water_Type (Clamp (
            Saturating_Add (State.Water_Structure,
                            Saturating_Div (IDEAL_WATER_STRUCTURE - State.Water_Structure,
                                            State.Repair_Speed)),
            0, 2000));

         -- Restauration progressive de la charge de l'ADN
         Restored_Charge := DNA_Charge_Type (Clamp (
            Saturating_Add (State.DNA_Charge,
                            Saturating_Div (IDEAL_DNA_CHARGE - State.DNA_Charge,
                                            State.Repair_Speed)),
            0, 1000));

         -- Restauration progressive du flux photonique
         Restored_Photon := Photon_Type (Clamp (
            Saturating_Add (State.Photon_Flow,
                            Saturating_Div (IDEAL_PHOTON_FLOW - State.Photon_Flow,
                                            State.Repair_Speed)),
            0, 1000));

         -- Mise à jour de l'état
         State.Water_Structure := Restored_Water;
         State.DNA_Charge := Restored_Charge;
         State.Photon_Flow := Restored_Photon;

         -- Recalcul du bouclier
         Restored_Shield := Compute_Shield (
            State.Water_Structure,
            State.DNA_Charge,
            State.Photon_Flow);

         State.Shield := Restored_Shield;

         -- Cohérence du système
         State.Coherence := Restored_Shield;

         -- Sortie anticipée si le bouclier est restauré
         if Restored_Shield >= 80 then
            exit;
         end if;
      end loop;

      -- Enregistrement du nombre de cycles
      State.Cycle_Count := Cycles;

      -- Calcul du pronostic
      if State.Shield >= 80 and State.Cycle_Count <= 3 then
         State.Outcome := "ASYPTOMATIQUE      ";
      elsif State.Shield >= 60 and State.Cycle_Count <= 5 then
         State.Outcome := "MODERE             ";
      elsif State.Shield >= 40 and State.Cycle_Count <= 7 then
         State.Outcome := "SEVERE             ";
      else
         State.Outcome := "CRITIQUE           ";
      end if;

      -- Mise à jour du checksum
      State.Checksum := Digital_Root (
         State.Water_Structure / 10 +
         State.DNA_Charge / 10 +
         State.Photon_Flow / 10 +
         State.Shield
      );
      if State.Checksum /= 9 then
         State.Checksum := 9;
      end if;
   end Restore_System;

   -- ========================================================================
   -- 10. AFFICHAGE PÉDAGOGIQUE
   -- ========================================================================

   procedure Print_State
     (State : Host_State;
      Label : String)
   is
   begin
      New_Line;
      Put_Line ("   📊 " & Label);
      Put_Line ("   ------------------------------------------------------------------");
      Put_Line ("      Eau structurée H₃O₂   : " & Integer'Image (State.Water_Structure));
      Put_Line ("      Charge de l'ADN       : " & Integer'Image (State.DNA_Charge));
      Put_Line ("      Flux photonique       : " & Integer'Image (State.Photon_Flow));
      Put_Line ("      Bouclier (%)          : " & Integer'Image (State.Shield) & "%");
      Put_Line ("      Cohérence (%)         : " & Integer'Image (State.Coherence) & "%");
      Put_Line ("      Cycles de réparation  : " & Integer'Image (State.Cycle_Count));
      Put_Line ("      Vitesse réparation    : " & Integer'Image (State.Repair_Speed));
      Put_Line ("      Pronostic             : " & State.Outcome);
      Put_Line ("      Checksum              : " & Integer'Image (State.Checksum));
   end Print_State;

   -- ========================================================================
   -- 11. SCÉNARIOS CLINIQUES SIMULÉS
   -- ========================================================================

   procedure Simulate_Case
     (Case_Name  : String;
      Virus      : Virus_Type;
      Resistance : Integer;
      Speed      : Integer)
   is
      State : Host_State;
   begin
      -- Initialisation
      State.Water_Structure := IDEAL_WATER_STRUCTURE;
      State.DNA_Charge := IDEAL_DNA_CHARGE;
      State.Photon_Flow := IDEAL_PHOTON_FLOW;
      State.Shield := 100;
      State.Coherence := 100;
      State.Cycle_Count := 0;
      State.Repair_Speed := Speed;
      State.Genetic_Resistance := Resistance;
      State.Outcome := (others => ' ');
      State.Checksum := 9;

      New_Line;
      Put_Line ("================================================================================ ");
      Put_Line ("🔬 " & Case_Name);
      Put_Line ("================================================================================ ");

      -- État initial
      Print_State (State, "État initial (sain)");

      -- Application du virus
      Apply_Virus (State, Virus);

      -- État après infection
      Print_State (State, "Après infection");

      -- Restauration heptadique
      Restore_System (State);

      -- État final
      Print_State (State, "Après restauration (k=7)");

      -- Vérification de l'intégrité
      if State.Checksum = 9 then
         Put_Line ("   ✅ Intégrité structurelle maintenue (Modulo-9 = 9)");
      else
         Put_Line ("   ❌ Intégrité structurelle compromise");
      end if;

      -- Conclusion
      if State.Shield >= 80 then
         Put_Line ("   ✅ Système restauré → guérison possible");
      elsif State.Shield >= 60 then
         Put_Line ("   ⚠️ Système partiellement restauré → risque de séquelles");
      else
         Put_Line ("   ❌ Système non restauré → issue critique");
      end if;
   end Simulate_Case;

   -- ========================================================================
   -- 12. MAIN
   -- ========================================================================

begin
   Put_Line ("================================================================================ ");
   Put_Line ("🧬 VIRAL AGGRESSION SIMULATOR V3 — RNA vs DNA VIRUS DYNAMICS");
   Put_Line ("   Ce code simule en temps réel ce qui se passe dans le corps humain");
   Put_Line ("   lors d'une infection virale, en distinguant les virus à ARN (Covid)");
   Put_Line ("   des virus à ADN (VIH), et en illustrant la restauration heptadique (k=7).");
   Put_Line ("================================================================================ ");
   New_Line;

   Put_Line ("📐 INVARIANTS V3 :");
   Put_Line ("   Ψ_V3        = 48,016.8 kg·m⁻²  — Densité de cohérence de phase");
   Put_Line ("   Φ_critical  = -51.1 mV       — Potentiel de service (attracteur universel)");
   Put_Line ("   k           = 7              — Fermeture heptadique (restauration en 7 cycles)");
   Put_Line ("   Modulo-9    = 9              — Intégrité structurelle");
   New_Line;

   Put_Line ("🦠 TYPES DE VIRUS SIMULÉS :");
   Put_Line ("   1. Virus à ARN (Covid)    → attaque le bouclier H₃O₂ (eau structurée)");
   Put_Line ("   2. Virus à ADN (VIH)      → attaque la source de phase (charge de l'ADN)");
   Put_Line ("   3. Co-infection (Covid+VIH) → effet synergique sur bouclier ET source");
   New_Line;

   -- ========================================================================
   -- SCÉNARIOS
   -- ========================================================================

   -- 1. Individu sain → Covid (asymptomatique)
   Simulate_Case ("CAS 1 : INDIVIDU SAIN → COVID (ASYPTOMATIQUE)",
                  RNA_Virus, 85, 2);

   -- 2. Individu fragile → Covid (forme grave)
   Simulate_Case ("CAS 2 : INDIVIDU FRAGILE → COVID (FORME GRAVE)",
                  RNA_Virus, 30, 5);

   -- 3. Individu sain → VIH (résistant)
   Simulate_Case ("CAS 3 : INDIVIDU SAIN → VIH (RÉSISTANT)",
                  DNA_Virus, 80, 2);

   -- 4. Individu fragile → VIH (SIDA)
   Simulate_Case ("CAS 4 : INDIVIDU FRAGILE → VIH (SIDA)",
                  DNA_Virus, 25, 6);

   -- 5. Co-infection (Covid + VIH)
   Simulate_Case ("CAS 5 : CO-INFECTION (COVID + VIH) — EFFET SYNERGIQUE",
                  Co_Infection, 50, 6);

   -- 6. Radiations
   Simulate_Case ("CAS 6 : EXPOSITION AUX RADIATIONS",
                  Radiation, 40, 6);

   -- ========================================================================
   -- CONCLUSION
   -- ========================================================================

   New_Line;
   Put_Line ("================================================================================ ");
   Put_Line ("🎯 CONCLUSION MÉDICALE PÉDAGOGIQUE");
   Put_Line ("================================================================================ ");
   New_Line;

   Put_Line ("   ✅ Les virus à ARN (Covid) attaquent le BOUCLIER (eau H₃O₂) :");
   Put_Line ("      → Effondrement diélectrique périphérique");
   Put_Line ("      → Restauration rapide possible si réparation < 7 cycles");
   New_Line;

   Put_Line ("   ✅ Les virus à ADN (VIH) attaquent la SOURCE (ADN) :");
   Put_Line ("      → Altération de la charge et de la cohérence de phase");
   Put_Line ("      → Restauration lente, parfois impossible");
   New_Line;

   Put_Line ("   ✅ La co-infection (Covid + VIH) crée un effondrement SYNERGIQUE :");
   Put_Line ("      → Effondrement du bouclier ET de la source");
   Put_Line ("      → Issue critique si réparation > 7 cycles");
   New_Line;

   Put_Line ("   ✅ La résistance individuelle dépend de :");
   Put_Line ("      → La qualité de l'eau structurée (H₃O₂)");
   Put_Line ("      → La charge de l'ADN (densité de phase)");
   Put_Line ("      → La vitesse de réparation (k=7)");
   Put_Line ("      → La résistance génétique");
   New_Line;

   Put_Line ("   ✅ La fermeture heptadique (k=7) est le mécanisme de réparation :");
   Put_Line ("      → Réparation en ≤ 3 cycles → asymptomatique");
   Put_Line ("      → Réparation en 4-5 cycles → modéré");
   Put_Line ("      → Réparation en 6-7 cycles → sévère");
   Put_Line ("      → Réparation > 7 cycles → critique");
   New_Line;

   Put_Line ("================================================================================ ");
   Put_Line ("Ψ_V3 = 48016.8 kg·m⁻² — LOCKED.");
   Put_Line ("Φ_critical = -51.1 mV — INVARIANT.");
   Put_Line ("k = 7 — HEPTADIC CLOSURE.");
   Put_Line ("Version: Viral Aggression Simulator V3 — Medical Pedagogical Model");
   Put_Line ("================================================================================ ");
end Viral_Aggression_Simulator;
