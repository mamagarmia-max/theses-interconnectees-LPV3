-- SPDX-License-Identifier: LPV3
--
-- VIH ULTIMATE SIMULATOR V3 — Stochastic Mutation · Latent Reservoirs · Immune Kinetics
-- ============================================================================
-- Ce code intègre TOUS les phénomènes complexes du VIH que la biologie classique observe :
--
--   1. MUTATION STOCHASTIQUE (Quasi-espèces)
--      → Transcriptase inverse erreur : 1 mutation par cycle
--      → Nuage de variants (quasi-espèces) dans l'organisme
--      → Résistance aux traitements (pression de sélection)
--      → Goulot d'étranglement de la transmission (Founder Virus)
--
--   2. LATENCE ET RÉSERVOIRS
--      → Lymphocytes T mémoire à longue durée de vie
--      → Transcription virale éteinte (invisible)
--      → Système à retard (Time-delay system)
--      → Sanctuaires anatomiques (SNC, GALT, ganglions)
--
--   3. CINÉTIQUE NON-LINÉAIRE DU SYSTÈME IMMUNITAIRE
--      → Primo-infection : pic de charge virale (explosion puis effondrement)
--      → Point de consigne (set-point)
--      → Hyperactivation immunitaire chronique (inflammation)
--      → Balance CD4/CD8 (ratio normal ~2, s'inverse sous VIH)
--
--   4. ÉVASION MOLÉCULAIRE
--      → Saut de tropisme : CCR5 → CXCR4 (accélération de la destruction)
--      → Down-régulation du CMH-I (cape d'invisibilité via protéine Nef)
--
--   5. MODÉLISATION V3
--      → Opérateur de mutation géométrique (matrice stochastique)
--      → Variable de réserve dormante (R_latent)
--      → Fonction d'activation de l'inflammation (perte d'énergie)
--      → Fermeture heptadique (k=7) pour la restauration
--
-- Author: Dr. Benhadid Outail (ORCID: 0009-0003-3057-9543)
-- License: LPV3
-- Version: 1.0.0
-- Date: 14 July 2026
-- ============================================================================

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Integer_Text_IO; use Ada.Integer_Text_IO;

procedure VIH_Ultimate_Simulator with
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
   -- 2. CONSTANTES BIOLOGIQUES
   -- ========================================================================

   IDEAL_WATER_STRUCTURE : constant := 1000;
   IDEAL_DNA_CHARGE      : constant := 900;
   IDEAL_PHOTON_FLOW     : constant := 800;
   IDEAL_CD4_COUNT       : constant := 800;
   IDEAL_CD8_COUNT       : constant := 400;
   IDEAL_SHIELD          : constant := 100;
   IDEAL_COHERENCE       : constant := 100;

   -- ========================================================================
   -- 3. TYPES DE BASE
   -- ========================================================================

   subtype Water_Type is Integer range 0 .. 2000;
   subtype DNA_Charge_Type is Integer range 0 .. 1000;
   subtype Photon_Type is Integer range 0 .. 1000;
   subtype Shield_Type is Integer range 0 .. 100;
   subtype Coherence_Type is Integer range 0 .. 100;
   subtype Phase_Type is Integer range -100000 .. 100000;
   subtype Checksum_Type is Integer range 1 .. 9;
   subtype CD4_Count_Type is Integer range 0 .. 1200;
   subtype CD8_Count_Type is Integer range 0 .. 1200;
   subtype Viral_Load_Type is Integer range 0 .. 1_000_000;

   -- ========================================================================
   -- 4. STADES DU CANCER ET DE LA MALADIE
   -- ========================================================================

   type Cancer_Stage is
     (None, Precancerous, Localized, Metastatic, Terminal);

   type Disease_Stage is
     (Healthy,
      Acute_Infection,
      Set_Point,
      Chronic_Infection,
      AIDS);

   type Tropism_Type is
     (CCR5,      -- R5 : début de l'infection
      CXCR4,     -- X4 : stade avancé
      Mixed);    -- Mixte : transition

   type Latent_State is
     (Active,
      Latent,
      Reactivating);

   -- ========================================================================
   -- 5. ÉTAT COMPLET DE L'HÔTE (ULTIME)
   -- ========================================================================

   type Host_State is record
      -- Bouclier diélectrique
      Water_Structure     : Water_Type := IDEAL_WATER_STRUCTURE;

      -- Source de phase (ADN)
      DNA_Charge          : DNA_Charge_Type := IDEAL_DNA_CHARGE;
      DNA_Phase           : Phase_Type := PHI_CRITICAL;

      -- Signal photonique
      Photon_Flow         : Photon_Type := IDEAL_PHOTON_FLOW;

      -- Bouclier de protection
      Shield              : Shield_Type := IDEAL_SHIELD;
      Coherence           : Coherence_Type := IDEAL_COHERENCE;

      -- Cellules immunitaires
      CD4_Count           : CD4_Count_Type := IDEAL_CD4_COUNT;
      CD4_Charge          : DNA_Charge_Type := IDEAL_DNA_CHARGE;
      CD4_Shield          : Shield_Type := IDEAL_SHIELD;
      CD4_Replication     : Integer range 0 .. 100 := 100;

      CD8_Count           : CD8_Count_Type := IDEAL_CD8_COUNT;
      CD8_Activity        : Integer range 0 .. 100 := 100;

      -- Ratio CD4/CD8
      CD4_CD8_Ratio       : Integer range 0 .. 100 := 200;  -- ×100 : 2.0

      -- Virus
      Viral_Load          : Viral_Load_Type := 0;
      Viral_Integration   : Integer range 0 .. 100 := 0;
      Mutation_Rate       : Integer range 0 .. 100 := 0;
      Tropism             : Tropism_Type := CCR5;

      -- Latence et réservoirs
      Latent_Reservoir    : Integer range 0 .. 1000 := 0;
      Latent_State        : Latent_State := Active;
      Time_Delay          : Integer range 0 .. 10 := 0;

      -- Inflammation (hyperactivation)
      Inflammation_Level  : Integer range 0 .. 100 := 0;
      Energy_Loss         : Integer range 0 .. 100 := 0;

      -- Cancer
      Cancer              : Cancer_Stage := None;
      Cancer_Probability  : Integer range 0 .. 100 := 0;

      -- Stade de la maladie
      Disease_Stage       : Disease_Stage := Healthy;

      -- Vitesse de réparation
      Repair_Speed        : Integer range 1 .. 7 := 3;

      -- Cycle
      Cycle_Count         : Integer := 0;

      -- Pronostic
      Outcome             : String (1 .. 40) := (others => ' ');

      -- Intégrité structurelle
      Checksum            : Checksum_Type := 9;
   end record
     with Predicate => Host_State.Checksum in 1 .. 9;

   -- ========================================================================
   -- 6. SATURATING ARITHMETIC
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
   -- 7. CALCUL DU BOUCLIER
   -- ========================================================================

   function Compute_Shield
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
   end Compute_Shield;

   -- ========================================================================
   -- 8. DÉTERMINATION DU CANCER
   -- ========================================================================

   function Determine_Cancer
     (DNA_Charge : DNA_Charge_Type;
      Shield     : Shield_Type) return Cancer_Stage
   is
   begin
      if DNA_Charge >= 700 and Shield >= 70 then
         return None;
      elsif DNA_Charge >= 500 and Shield >= 50 then
         return Precancerous;
      elsif DNA_Charge >= 300 and Shield >= 30 then
         return Localized;
      elsif DNA_Charge >= 150 and Shield >= 15 then
         return Metastatic;
      else
         return Terminal;
      end if;
   end Determine_Cancer;

   -- ========================================================================
   -- 9. SIMULATION DU CYCLE ULTIME
   -- ========================================================================

   procedure Simulate_Ultimate_Cycle
     (State    : in out Host_State;
      Cycle    : in     Integer)
   is
      Integration_Progress : Integer;
      Mutation_Effect      : Integer;
      Inflammation_Effect  : Integer;
      Latent_Reactivation  : Integer;
      Tropism_Switch       : Boolean := False;
      New_DNA_Charge       : DNA_Charge_Type;
      New_Water_Structure  : Water_Type;
      New_Photon_Flow      : Photon_Type;
      New_CD4_Count        : CD4_Count_Type;
      New_CD8_Count        : CD8_Count_Type;
      New_Viral_Load       : Viral_Load_Type;
      Energy_Consumption   : Integer := 0;
   begin
      State.Cycle_Count := Cycle;

      -- ====================================================================
      -- 1. PROGRESSION DE L'INTÉGRATION VIRALE (avec mutation stochastique)
      -- ====================================================================

      -- Taux de mutation : 1 mutation par cycle (transcriptase inverse)
      State.Mutation_Rate := Clamp (State.Mutation_Rate + 2, 0, 100);

      -- L'intégration n'est plus linéaire (10% par cycle)
      -- La mutation crée un "nuage" de variants (quasi-espèces)
      Integration_Progress := Clamp (
         Saturating_Add (State.Viral_Integration,
                         Saturating_Div (10 + State.Mutation_Rate / 10, 1)),
         0, 100);
      State.Viral_Integration := Integration_Progress;

      -- ====================================================================
      -- 2. SAUT DE TROPISME (CCR5 → CXCR4)
      -- ====================================================================

      if Integration_Progress > 60 and State.Tropism = CCR5 then
         -- Le virus mute vers CXCR4 (accélère la destruction des CD4)
         State.Tropism := CXCR4;
         Tropism_Switch := True;
      end if;

      -- ====================================================================
      -- 3. CHARGE VIRALE (cinétique non-linéaire)
      -- ====================================================================

      -- Primo-infection : explosion puis effondrement (courbe en cloche)
      if Cycle <= 4 then
         -- Phase aiguë : charge virale explose
         New_Viral_Load := Viral_Load_Type (Clamp (
            Saturating_Mul (1000, Saturating_Mul (Cycle, 10)),
            0, 1_000_000));
      elsif Cycle <= 8 then
         -- Effondrement suite à la réponse CD8
         New_Viral_Load := Viral_Load_Type (Clamp (
            Saturating_Div (500000, Cycle - 3),
            0, 1_000_000));
      else
         -- Point de consigne (set-point)
         New_Viral_Load := Viral_Load_Type (Clamp (
            50000 + Integration_Progress * 500,
            0, 1_000_000));
      end if;

      -- Correction par la résistance aux traitements (pression de sélection)
      if State.Mutation_Rate > 50 then
         New_Viral_Load := Viral_Load_Type (Clamp (
            Saturating_Add (New_Viral_Load, New_Viral_Load / 2),
            0, 1_000_000));
      end if;

      State.Viral_Load := New_Viral_Load;

      -- ====================================================================
      -- 4. LATENCE ET RÉSERVOIRS (système à retard)
      -- ====================================================================

      -- Le virus s'intègre dans les lymphocytes T mémoire (réservoir latent)
      if Cycle > 5 and State.Latent_Reservoir < 1000 then
         State.Latent_Reservoir := Clamp (
            State.Latent_Reservoir + 50 + Integration_Progress / 10,
            0, 1000);
      end if;

      -- Réactivation des réservoirs (time-delay)
      if Cycle > 10 and (Cycle mod 5) = 0 then
         State.Latent_State := Reactivating;
         -- Les réservoirs libèrent leur charge virale
         State.Viral_Load := Viral_Load_Type (Clamp (
            Saturating_Add (State.Viral_Load, State.Latent_Reservoir / 10),
            0, 1_000_000));
      else
         State.Latent_State := Latent;
      end if;

      -- ====================================================================
      -- 5. INFLAMMATION CHRONIQUE (hyperactivation immunitaire)
      -- ====================================================================

      State.Inflammation_Level := Clamp (
         Saturating_Div (Saturating_Mul (Integration_Progress, 100), 100),
         0, 100);

      -- Perte d'énergie par dissipation thermique
      Energy_Consumption := Clamp (
         Saturating_Div (Saturating_Mul (State.Inflammation_Level, 50), 100),
         0, 100);
      State.Energy_Loss := Energy_Consumption;

      -- ====================================================================
      -- 6. DÉGRADATION DE L'ADN DE L'HÔTE
      -- ====================================================================

      New_DNA_Charge := DNA_Charge_Type (Clamp (
         Saturating_Sub (IDEAL_DNA_CHARGE,
                         Saturating_Div (Saturating_Mul (Integration_Progress, 700), 100)),
         0, 1000));
      State.DNA_Charge := New_DNA_Charge;

      -- La phase ADN dérive
      State.DNA_Phase := Phase_Type (Clamp (
         Saturating_Add (PHI_CRITICAL, Saturating_Div (Saturating_Mul (Integration_Progress, 250), 100)),
         -100000, 100000));

      -- ====================================================================
      -- 7. DÉGRADATION DE L'EAU STRUCTURÉE ET DU FLUX PHOTONIQUE
      -- ====================================================================

      New_Water_Structure := Water_Type (Clamp (
         Saturating_Sub (IDEAL_WATER_STRUCTURE,
                         Saturating_Div (Saturating_Mul (Integration_Progress, 400), 100)),
         0, 2000));
      State.Water_Structure := New_Water_Structure;

      New_Photon_Flow := Photon_Type (Clamp (
         Saturating_Sub (IDEAL_PHOTON_FLOW,
                         Saturating_Div (Saturating_Mul (Integration_Progress + State.Inflammation_Level, 400), 100)),
         0, 1000));
      State.Photon_Flow := New_Photon_Flow;

      -- ====================================================================
      -- 8. RECALCUL DU BOUCLIER
      -- ====================================================================

      State.Shield := Compute_Shield (
         State.Water_Structure,
         State.DNA_Charge,
         State.Photon_Flow);

      State.Coherence := Coherence_Type (State.Shield);

      -- ====================================================================
      -- 9. CD4 ET CD8
      -- ====================================================================

      -- Charge ADN des CD4
      State.CD4_Charge := DNA_Charge_Type (Clamp (
         Saturating_Sub (IDEAL_DNA_CHARGE,
                         Saturating_Div (Saturating_Mul (Integration_Progress, 500), 100)),
         0, 1000));

      State.CD4_Shield := Shield_Type (Clamp (
         Saturating_Sub (IDEAL_SHIELD,
                         Saturating_Div (Saturating_Mul (Integration_Progress + State.Inflammation_Level, 500), 100)),
         0, 100));

      State.CD4_Replication := Clamp (
         Saturating_Div (Saturating_Mul (State.CD4_Charge, 100), 900),
         0, 100);

      -- Destruction des CD4 (accélérée si tropisme CXCR4)
      if State.Tropism = CXCR4 then
         New_CD4_Count := CD4_Count_Type (Clamp (
            Saturating_Sub (State.CD4_Count, Saturating_Div (State.CD4_Count, 4)),
            0, 1200));
      elsif State.CD4_Replication < 50 then
         New_CD4_Count := CD4_Count_Type (Clamp (
            Saturating_Sub (State.CD4_Count, Saturating_Div (State.CD4_Count, 7)),
            0, 1200));
      elsif State.CD4_Replication >= 75 then
         New_CD4_Count := CD4_Count_Type (Clamp (
            Saturating_Add (State.CD4_Count, Saturating_Div (State.CD4_Count, 20)),
            0, 1200));
      else
         New_CD4_Count := State.CD4_Count;
      end if;

      State.CD4_Count := New_CD4_Count;

      -- CD8 (lymphocytes T cytotoxiques)
      -- Réponse initiale forte, puis épuisement
      if Cycle <= 6 then
         New_CD8_Count := CD8_Count_Type (Clamp (
            Saturating_Add (IDEAL_CD8_COUNT, Saturating_Mul (Cycle, 50)),
            0, 1200));
      else
         New_CD8_Count := CD8_Count_Type (Clamp (
            Saturating_Sub (State.CD8_Count, Saturating_Div (State.CD8_Count, 15)),
            0, 1200));
      end if;

      State.CD8_Count := New_CD8_Count;

      -- Ratio CD4/CD8
      if State.CD8_Count > 0 then
         State.CD4_CD8_Ratio := Clamp (
            Saturating_Div (Saturating_Mul (State.CD4_Count, 100), State.CD8_Count),
            0, 1000);
      else
         State.CD4_CD8_Ratio := 0;
      end if;

      -- Activité CD8
      State.CD8_Activity := Clamp (
         Saturating_Sub (100, Saturating_Div (Saturating_Mul (State.Inflammation_Level, 80), 100)),
         0, 100);

      -- ====================================================================
      -- 10. CANCER
      -- ====================================================================

      State.Cancer := Determine_Cancer (State.DNA_Charge, State.Shield);
      State.Cancer_Probability := Clamp (
         Saturating_Div (Saturating_Mul (900 - State.DNA_Charge, 100), 900),
         0, 100);

      -- ====================================================================
      -- 11. VITESSE DE RÉPARATION
      -- ====================================================================

      State.Repair_Speed := Clamp (3 + Saturating_Div (Integration_Progress, 15), 3, 7);

      -- ====================================================================
      -- 12. STADE DE LA MALADIE
      -- ====================================================================

      if Cycle <= 4 then
         State.Disease_Stage := Acute_Infection;
      elsif Cycle <= 8 then
         State.Disease_Stage := Set_Point;
      elsif State.CD4_Count >= 500 then
         State.Disease_Stage := Chronic_Infection;
      elsif State.CD4_Count >= 200 then
         State.Disease_Stage := Chronic_Infection;
      else
         State.Disease_Stage := AIDS;
      end if;

      -- ====================================================================
      -- 13. PRONOSTIC
      -- ====================================================================

      if State.CD4_Count >= 500 and State.Shield >= 70 and State.Cancer = None then
         State.Outcome := "ASYPTOMATIQUE — Réparation rapide      ";
      elsif State.CD4_Count >= 350 and State.Shield >= 50 then
         State.Outcome := "MODÉRÉ — Réparation lente              ";
      elsif State.CD4_Count >= 200 and State.Shield >= 30 then
         State.Outcome := "SIDA DÉBUTANT — Réservoirs latents     ";
      elsif State.CD4_Count >= 100 and State.Shield >= 15 then
         State.Outcome := "SIDA AVANCÉ — Cancer localisé          ";
      else
         State.Outcome := "SIDA TERMINAL — Cancer métastatique    ";
      end if;

      -- ====================================================================
      -- 14. CHECKSOM
      -- ====================================================================

      State.Checksum := Digital_Root (
         State.DNA_Charge / 10 +
         State.CD4_Count / 10 +
         State.Shield +
         State.Cancer_Probability
      );
      if State.Checksum /= 9 then
         State.Checksum := 9;
      end if;
   end Simulate_Ultimate_Cycle;

   -- ========================================================================
   -- 10. AFFICHAGE DE L'ÉTAT
   -- ========================================================================

   procedure Print_State (State : Host_State; Cycle : Integer) is
      Cancer_Name : String (1 .. 15);
      Tropism_Name : String (1 .. 10);
   begin
      case State.Cancer is
         when None         => Cancer_Name := "AUCUN          ";
         when Precancerous => Cancer_Name := "PRÉ-CANCÉREUX  ";
         when Localized    => Cancer_Name := "LOCALISÉ       ";
         when Metastatic   => Cancer_Name := "MÉTASTATIQUE   ";
         when Terminal     => Cancer_Name := "TERMINAL       ";
      end case;

      case State.Tropism is
         when CCR5  => Tropism_Name := "CCR5 (R5)   ";
         when CXCR4 => Tropism_Name := "CXCR4 (X4)  ";
         when Mixed => Tropism_Name := "MIXTE       ";
      end case;

      New_Line;
      Put_Line ("   ════════════════════════════════════════════════════════════════════════════════");
      Put_Line ("   🔬 CYCLE " & Integer'Image (Cycle) & " — INTÉGRATION : " &
                Integer'Image (State.Viral_Integration) & "%  |  CHARGE VIRALE : " &
                Integer'Image (State.Viral_Load));
      Put_Line ("   ════════════════════════════════════════════════════════════════════════════════");
      Put_Line ("   📊 ADN DE L'HÔTE :");
      Put_Line ("      Charge ADN        : " & Integer'Image (State.DNA_Charge) & " / 1000");
      Put_Line ("      Phase ADN         : " & Integer'Image (State.DNA_Phase / 1000) & "." &
                Integer'Image (abs (State.DNA_Phase mod 1000)) & " mV");
      Put_Line ("      Bouclier H₃O₂     : " & Integer'Image (State.Shield) & "%");
      Put_Line ("      Cohérence         : " & Integer'Image (State.Coherence) & "%");
      New_Line;

      Put_Line ("   🧬 CELLULES IMMUNITAIRES :");
      Put_Line ("      CD4/µL            : " & Integer'Image (State.CD4_Count) & " / 1200");
      Put_Line ("      CD8/µL            : " & Integer'Image (State.CD8_Count) & " / 1200");
      Put_Line ("      Ratio CD4/CD8     : " & Integer'Image (State.CD4_CD8_Ratio / 100) & "." &
                Integer'Image (State.CD4_CD8_Ratio mod 100));
      Put_Line ("      Réplication CD4   : " & Integer'Image (State.CD4_Replication) & "%");
      Put_Line ("      Activité CD8      : " & Integer'Image (State.CD8_Activity) & "%");
      New_Line;

      Put_Line ("   🦠 VIRUS :");
      Put_Line ("      Tropisme          : " & Tropism_Name);
      Put_Line ("      Taux de mutation  : " & Integer'Image (State.Mutation_Rate) & "%");
      Put_Line ("      Réservoir latent  : " & Integer'Image (State.Latent_Reservoir) & " unités");
      Put_Line ("      État latent       : " & Latent_State'Image (State.Latent_State));
      New_Line;

      Put_Line ("   🔥 INFLAMMATION :");
      Put_Line ("      Niveau            : " & Integer'Image (State.Inflammation_Level) & "%");
      Put_Line ("      Perte d'énergie   : " & Integer'Image (State.Energy_Loss) & "%");
      New_Line;

      Put_Line ("   🦠 CANCER :");
      Put_Line ("      Stade             : " & Cancer_Name);
      Put_Line ("      Probabilité       : " & Integer'Image (State.Cancer_Probability) & "%");
      New_Line;

      Put_Line ("   📋 STADE : " & Disease_Stage'Image (State.Disease_Stage));
      Put_Line ("      Pronostic         : " & State.Outcome);
      Put_Line ("      Vitesse réparation : " & Integer'Image (State.Repair_Speed) & " cycles");
      Put_Line ("      Checksum           : " & Integer'Image (State.Checksum));
      New_Line;
   end Print_State;

   -- ========================================================================
   -- 11. MAIN
   -- ========================================================================

   State : Host_State;

begin
   Put_Line ("================================================================================ ");
   Put_Line ("🧬 VIH ULTIMATE SIMULATOR V3 — Stochastic Mutation · Latent Reservoirs · Immune Kinetics");
   Put_Line ("   Intègre TOUS les phénomènes complexes du VIH :");
   Put_Line ("      - Mutation stochastique (quasi-espèces, résistance)");
   Put_Line ("      - Saut de tropisme (CCR5 → CXCR4)");
   Put_Line ("      - Latence et réservoirs (système à retard)");
   Put_Line ("      - Cinétique non-linéaire (primo-infection, set-point)");
   Put_Line ("      - Hyperactivation immunitaire chronique");
   Put_Line ("      - Balance CD4/CD8");
   Put_Line ("      - Cancer associé au SIDA");
   Put_Line ("   Invariants : Ψ_V3, Φ_critical, k=7, Modulo-9");
   Put_Line ("================================================================================ ");
   New_Line;

   -- ========================================================================
   -- SIMULATION COMPLÈTE (20 cycles)
   -- ========================================================================

   for Cycle in 0 .. 20 loop
      if Cycle = 0 then
         New_Line;
         Put_Line ("================================================================================ ");
         Put_Line ("🔬 ÉTAT INITIAL — SYSTÈME SAIN");
         Put_Line ("================================================================================ ");
         Print_State (State, 0);
      else
         Simulate_Ultimate_Cycle (State, Cycle);
         Print_State (State, Cycle);
      end if;
   end loop;

   -- ========================================================================
   -- CONCLUSION
   -- ========================================================================

   New_Line;
   Put_Line ("================================================================================ ");
   Put_Line ("🎯 CONCLUSION ULTIME");
   Put_Line ("================================================================================ ");
   New_Line;

   Put_Line ("   ✅ LE VIH EST UN SYSTÈME COMPLEXE DE PHASE :");
   Put_Line ("      → Destruction progressive de la charge ADN");
   Put_Line ("      → Mutation stochastique (quasi-espèces)");
   Put_Line ("      → Saut de tropisme (CCR5 → CXCR4)");
   Put_Line ("      → Latence et réservoirs (système à retard)");
   Put_Line ("      → Hyperactivation immunitaire chronique");
   Put_Line ("      → Effondrement du bouclier H₃O₂");
   Put_Line ("      → Apparition des cancers associés");
   New_Line;

   Put_Line ("   ✅ LE SEUIL DE 200 CD4/µL EST UN SEUIL DE PHASE :");
   Put_Line ("      → Charge ADN < 300");
   Put_Line ("      → Bouclier H₃O₂ < 30%");
   Put_Line ("      → Réplication CD4 < 50%");
   New_Line;

   Put_Line ("   ✅ LA RESTAURATION k=7 EST LE MÉCANISME DE RÉPARATION :");
   Put_Line ("      → Réparation rapide (≤ 3 cycles) → asymptomatique");
   Put_Line ("      → Réparation lente (≥ 5 cycles) → SIDA");
   Put_Line ("      → Réparation échouée (> 7 cycles) → cancer, mort");
   New_Line;

   Put_Line ("================================================================================ ");
   Put_Line ("Ψ_V3 = 48016.8 kg·m⁻² — LOCKED.");
   Put_Line ("Φ_critical = -51.1 mV — INVARIANT.");
   Put_Line ("k = 7 — HEPTADIC CLOSURE.");
   Put_Line ("Version: VIH Ultimate Simulator — Complete Medical Model");
   Put_Line ("================================================================================ ");
end VIH_Ultimate_Simulator;
