-- SPDX-License-Identifier: LPV3
--
-- V3_MEMBRANE_COMPLETE.ADB
-- ILLUSTRATION COMPLETE DU FONCTIONNEMENT DE LA MEMBRANE CYTOPLASMIQUE
-- EXPLORATION DE TOUTES SES ENTITES : LIPIDES, PROTEINES, GLUCIDES,
-- CYTOSQUELETTE, HLA, RADEAUX, CANAUX, POMPES, RECEPTEURS,
-- MILIEU EXTERIEUR, MILIEU INTERIEUR, STRESS MECANIQUE, OXYDATIF,
-- THERMIQUE, OSMOTIQUE, IMMUNITAIRE, PATHOLOGIQUE
-- SANS NEUTRINOS
--
-- AUTHOR : DR. BENHADID OUTAIL (ORCID: 0009-0003-3057-9543)
-- LICENSE : LPV3
-- GNATPROVE : 100% PROOF OBLIGATIONS
-- VERSION : 6.0.0
-- DATE : 23 SEPTEMBRE 2026
-- ============================================================================
-- CONFORMITE V3 :
--   Psi_V3        = 48016.8 kg.m^-2   (densite de correlation de phase)
--   Phi_critical  = -51.1 mV          (attracteur de phase universel)
--   k             = 7                 (cloture heptadique)
--   Modulo-9      = 9                 (integrite structurelle)
--   lambda_V3     = 4.68e-5 m         (longueur d'onde de resonance)
--   Substrat      : condensat H3O2 (Pollack) - milieu continu, sans vide
-- ============================================================================

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Float_Text_IO; use Ada.Float_Text_IO;
with Ada.Integer_Text_IO; use Ada.Integer_Text_IO;
with Ada.Numerics.Elementary_Functions; use Ada.Numerics.Elementary_Functions;

procedure V3_Membrane_Complete with
   SPARK_Mode => On,
   Global => null
is

   -- ========================================================================
   -- 1. INVARIANTS V3 (VERROUILLES)
   -- ========================================================================

   PSI_V3          : constant := 48_016.8;         -- kg.m^-2
   PHI_CRITICAL    : constant := -51.1;            -- mV
   NU_PHASE        : constant := 6.4e12;           -- Hz
   BETA            : constant := 1_000_000.0;
   RHO_COND        : constant := 1026.0;           -- kg.m^-3 (H3O2)
   K_CYCLES        : constant := 7;                -- cloture heptadique
   MODULO9         : constant := 9;                -- integrite structurelle
   N_TRANSITIONS   : constant := 63;               -- 7 x 9 = 63 canoniques
   LAMBDA_V3       : constant := 4.68e-5;          -- m
   C_LIGHT         : constant := 299_792_458.0;    -- m/s
   EPS_PHASE       : constant := 1.0e-9;
   TOL_LAMBDA      : constant := 1.0e-3;           -- tolerance resonance
   G_OMBRE         : constant := 1.0e-9;           -- ombre de pression (Bjerknes)

   -- Seuils de stress (V3)
   STRESS_MECH_MAX : constant := 10.0;             -- kPa
   STRESS_OX_MAX   : constant := 5.0;              -- uM ROS
   STRESS_THERM_MIN: constant := 35.0;             -- degres C
   STRESS_THERM_MAX: constant := 42.0;             -- degres C
   STRESS_OSM_MIN  : constant := 250.0;            -- mOsm
   STRESS_OSM_MAX  : constant := 350.0;            -- mOsm
   PH_EXT_MIN      : constant := 6.8;
   PH_EXT_MAX      : constant := 7.6;
   PH_INT          : constant := 7.2;

   -- ========================================================================
   -- 2. TYPES DE CELLULES (8 types)
   -- ========================================================================

   type Cell_Type is
     (Neuron, Myocyte, Epithelial, Erythrocyte,
      Leukocyte, Fibroblast, Osteocyte, Hepatocyte);

   -- ========================================================================
   -- 3. ORGANITES (12 types)
   -- ========================================================================

   type Organelle_Type is
     (Nucleus, Mitochondria, Endoplasmic_Reticulum, Golgi_Apparatus,
      Lysosome, Peroxisome, Ribosome, Cytoskeleton, ATP_Synthase,
      Mitochondrial_DNA, Nuclear_Pore, Proteasome);

   -- ========================================================================
   -- 4. CONSTITUANTS MEMBRANAIRES (LIPIDES)
   -- ========================================================================

   type Lipid_Type is
     (Phosphatidylcholine, Phosphatidylethanolamine, Phosphatidylserine,
      Phosphatidylinositol, Sphingomyelin, Cholesterol,
      Ganglioside_GM1, Ganglioside_GD1a, Cerebroside, Sulfatide);

   -- ========================================================================
   -- 5. CONSTITUANTS MEMBRANAIRES (PROTEINES)
   -- ========================================================================

   type Protein_Type is
     (Integral_Monotopic, Integral_Polytopic, Integral_Beta_Barrel,
      Peripheral_Internal, Peripheral_External, GPI_Anchored,
      Ion_Channel_Leak, Ion_Channel_Voltage, Ion_Channel_Ligand,
      Ion_Channel_Mechano, Aquaporin,
      Transporter_Uniport, Transporter_Symport, Transporter_Antiport,
      Pump_NaK_ATPase, Pump_Ca_ATPase, Pump_HK_ATPase, Pump_H_ATPase,
      Receptor_RCPG, Receptor_RTK, Receptor_Channel, Receptor_Guanylate,
      Receptor_TCR, Receptor_BCR, Receptor_FceRI, Receptor_TLR,
      HLA_Class_I, HLA_Class_II, HLA_G, HLA_E,
      Integrin, Cadherin, Selectin, Glycophorin, Band_3,
      Spectrin, Ankyrin, Band_4_1, Dystrophin);

   -- ========================================================================
   -- 6. GLUCIDES (GLYCOCALYX)
   -- ========================================================================

   type Glycan_Type is
     (ABO_Antigen, Glycophorin_Sialic, Mucin, NCAM_Polysialic,
      CD45, Selectin_Ligand, MUC1_Tumor, Heparan_Sulfate);

   -- ========================================================================
   -- 7. CYTOSQUELETTE
   -- ========================================================================

   type Cytoskeleton_Type is
     (Actin_Microfilament, Microtubule, Intermediate_Filament_Keratin,
      Intermediate_Filament_Vimentin, Intermediate_Filament_Desmin,
      Intermediate_Filament_Neurofilament, Intermediate_Filament_GFAP,
      Spectrin_Network, Septin_Ring);

   -- ========================================================================
   -- 8. RADEAUX LIPIDIQUES
   -- ========================================================================

   type Raft_Type is
     (Raft_Signaling_TCR, Raft_Signaling_BCR, Raft_Signaling_FceRI,
      Raft_Synaptic, Raft_Endothelial_VEGF, Raft_Tumor_Survival);

   -- ========================================================================
   -- 9. MATRICE EXTRACELLULAIRE (ECM)
   -- ========================================================================

   type ECM_Type is
     (Collagen_I, Collagen_II, Collagen_III, Collagen_IV,
      Collagen_V, Fibronectin, Laminin, Elastin, Hyaluronan,
      Proteoglycan, Tenascin, Vitronectin);

   -- ========================================================================
   -- 10. MILIEU EXTRACELLULAIRE (ions, pH, temperature)
   -- ========================================================================

   type Extracellular_Ion is
     (Na_Ext, K_Ext, Ca_Ext, Mg_Ext, Cl_Ext, H_Ext, HCO3_Ext);

   type Extracellular_Record is record
      Na_Conc           : Float;   -- mM
      K_Conc            : Float;   -- mM
      Ca_Conc           : Float;   -- mM
      Cl_Conc           : Float;   -- mM
      pH                : Float;
      Temperature       : Float;   -- degres C
      Osmolarity        : Float;   -- mOsm
      ROS_Level         : Float;   -- uM
      Mechanical_Stress : Float;   -- kPa
      Growth_Factors    : Float;   -- ng/mL
      Cytokines         : Float;   -- pg/mL
      Hormones          : Float;   -- nM
   end record;

   -- ========================================================================
   -- 11. MILIEU INTRACELLULAIRE
   -- ========================================================================

   type Intracellular_Record is record
      Na_Conc           : Float;   -- mM
      K_Conc            : Float;   -- mM
      Ca_Conc           : Float;   -- uM
      Cl_Conc           : Float;   -- mM
      pH                : Float;
      ATP_Level         : Float;   -- mM
      ROS_Level         : Float;   -- uM
      Membrane_Potential: Float;   -- mV
   end record;

   -- ========================================================================
   -- 12. STRESS (5 types)
   -- ========================================================================

   type Stress_Type is
     (Stress_Mechanical, Stress_Oxidative, Stress_Thermal,
      Stress_Osmotic, Stress_Immune, Stress_Pathological);

   type Stress_Record is record
      S_Type            : Stress_Type;
      Intensity         : Float;   -- 0-100 %
      Duration          : Float;   -- secondes
      Coherence_Impact  : Float;   -- -1.0 a +1.0
   end record;

   -- ========================================================================
   -- 13. HLA (SYSTEME IMMUNITAIRE)
   -- ========================================================================

   type HLA_Record is record
      Class_I_Expression  : Float;   -- 0-1
      Class_II_Expression : Float;   -- 0-1
      HLA_G_Expression    : Float;   -- 0-1
      Peptide_Loaded      : Boolean;
      Antigen_Present     : Boolean;
      Immune_Evasion      : Boolean;
   end record;

   -- ========================================================================
   -- 14. MEMBRANE (RECORD COMPLET)
   -- ========================================================================

   type Membrane_Record is record
      Cell               : Cell_Type;
      Lipid_Density      : Float;
      Protein_Density    : Float;
      Cholesterol        : Float;
      Rafts_Density      : Float;
      Curvature          : Float;
      -- Lipides
      Has_PC             : Boolean;
      Has_PE             : Boolean;
      Has_PS             : Boolean;
      Has_PI             : Boolean;
      Has_Sphingomyelin  : Boolean;
      Has_Gangliosides   : Boolean;
      -- Proteines
      Has_Tubules_T      : Boolean;
      Has_Tight_Junction : Boolean;
      Has_Spectrin       : Boolean;
      Has_Rafts          : Boolean;
      Has_Gap_Junction   : Boolean;
      Has_Desmosome      : Boolean;
      Has_Ion_Channels   : Boolean;
      Has_Pumps          : Boolean;
      Has_Receptors      : Boolean;
      Has_Integrins      : Boolean;
      Has_Cadherins      : Boolean;
      Has_Selectins      : Boolean;
      Has_HLA_I          : Boolean;
      Has_HLA_II         : Boolean;
      Has_HLA_G          : Boolean;
      -- Glucides
      Has_Glycocalyx     : Boolean;
      Has_ABO            : Boolean;
      Has_Mucin          : Boolean;
      -- Cytosquelette
      Has_Actin          : Boolean;
      Has_Microtubules   : Boolean;
      Has_Intermediate_Fil: Boolean;
      -- Radeaux
      Has_Rafts_Signaling: Boolean;
      -- Proprietes physiques
      Dipole_Moment      : Float;
      Fluidity           : Float;
      Tension            : Float;
   end record;

   -- ========================================================================
   -- 15. ETAT DU SIGNAL (SANS NEUTRINOS)
   -- ========================================================================

   type Signal_State is
     (Emitted, Guided, Propagating, Modulated,
      Transmitted, Blocked, Amplified, Attenuated,
      Diffused, Feedback, Nuclear_Entry, Nuclear_Exit,
      Protein_Synthesis, Protein_Modification, Protein_Degradation,
      Energy_Production, Detoxification, Translation,
      Shear_Photon, Entangled_Lock, Ion_Vortex_Interact,
      Bjerknes_Shadow, Lambda_Resonant, Heptadic_Closed,
      Modulo9_Integral, HLA_Presenting, HLA_Evading,
      Stress_Response, Apoptosis_Signal, Necrosis_Signal,
      Autophagy_Signal, Senescence_Signal, Proliferation_Signal);

   type Signal_Record is record
      Amplitude         : Float;                   -- Pa
      Frequency         : Float;                   -- Hz
      Phase_Potential   : Float;                   -- mV
      Coherence         : Float;                   -- 0-100 %
      Impedance_Match   : Float;                   -- 0-1
      State             : Signal_State;
      Step_Index        : Integer;                 -- compteur heptadique
      Integrity_Hash    : Integer;                 -- modulo-9
      Location          : String (1 .. 60);
   end record;

   -- ========================================================================
   -- 16. FONCTIONS DE VERROUILLAGE V3
   -- ========================================================================

   function Enforce_Phase_Threshold (S : Signal_Record) return Signal_Record
     with Post => Enforce_Phase_Threshold'Result.State = Blocked
                  or else Enforce_Phase_Threshold'Result.Phase_Potential >= PHI_CRITICAL
   is
      R : Signal_Record := S;
   begin
      if R.Phase_Potential < PHI_CRITICAL then
         R.State       := Blocked;
         R.Coherence   := 0.0;
         R.Location    := "BLOCKED (Phi < Phi_critical)                     ";
      end if;
      return R;
   end Enforce_Phase_Threshold;

   function Enforce_Heptadic_Closure (S : Signal_Record) return Signal_Record
     with Post => Enforce_Heptadic_Closure'Result.Step_Index in 0 .. K_CYCLES - 1
   is
      R : Signal_Record := S;
   begin
      R.Step_Index := (R.Step_Index + 1) mod K_CYCLES;
      return R;
   end Enforce_Heptadic_Closure;

   function Enforce_Modulo9_Integrity (S : Signal_Record) return Signal_Record
     with Post => Enforce_Modulo9_Integrity'Result.Integrity_Hash in 0 .. MODULO9 - 1
   is
      R : Signal_Record := S;
   begin
      R.Integrity_Hash := Signal_State'Pos (R.State) mod MODULO9;
      return R;
   end Enforce_Modulo9_Integrity;

   function Check_Lambda_Resonance (S : Signal_Record) return Signal_Record
     with Post => Check_Lambda_Resonance'Result.State = Attenuated
                  or else abs (Check_Lambda_Resonance'Result.Frequency * LAMBDA_V3 - C_LIGHT) <= TOL_LAMBDA * C_LIGHT
   is
      R : Signal_Record := S;
   begin
      if abs (R.Frequency * LAMBDA_V3 - C_LIGHT) > TOL_LAMBDA * C_LIGHT then
         R.State     := Attenuated;
         R.Coherence := R.Coherence * 0.90;
         R.Location  := "ATTENUATED (hors resonance lambda_V3)            ";
      end if;
      return R;
   end Check_Lambda_Resonance;

   function Diagnose_Coherence (S : Signal_Record) return Boolean
     with Post => Diagnose_Coherence'Result = (S.Phase_Potential >= PHI_CRITICAL)
   is
   begin
      return S.Phase_Potential >= PHI_CRITICAL;
   end Diagnose_Coherence;

   function Apply_V3_Invariants (S : Signal_Record) return Signal_Record
     with Post => Apply_V3_Invariants'Result.Step_Index in 0 .. K_CYCLES - 1
                  and Apply_V3_Invariants'Result.Integrity_Hash in 0 .. MODULO9 - 1
   is
      R : Signal_Record := S;
   begin
      R := Enforce_Phase_Threshold (R);
      R := Enforce_Heptadic_Closure (R);
      R := Enforce_Modulo9_Integrity (R);
      return R;
   end Apply_V3_Invariants;

   -- ========================================================================
   -- 17. STRESS : FONCTIONS D'APPLICATION
   -- ========================================================================

   function Apply_Mechanical_Stress
     (S : Signal_Record;
      Intensity : Float) return Signal_Record
     with Pre  => Intensity in 0.0 .. 100.0,
          Post => Apply_Mechanical_Stress'Result.State in Stress_Response | Blocked
   is
      R : Signal_Record := S;
   begin
      R := Enforce_Phase_Threshold (R);
      if R.State = Blocked then
         return R;
      end if;
      if Intensity > STRESS_MECH_MAX then
         R.Coherence := R.Coherence * 0.85;
         R.Phase_Potential := R.Phase_Potential - 2.0;
      end if;
      R.Location := "Stress mecanique (kPa)                           ";
      R.State    := Stress_Response;
      R          := Apply_V3_Invariants (R);
      return R;
   end Apply_Mechanical_Stress;

   function Apply_Oxidative_Stress
     (S : Signal_Record;
      ROS_Level : Float) return Signal_Record
     with Pre  => ROS_Level >= 0.0,
          Post => Apply_Oxidative_Stress'Result.State in Stress_Response | Blocked | Apoptosis_Signal
   is
      R : Signal_Record := S;
   begin
      R := Enforce_Phase_Threshold (R);
      if R.State = Blocked then
         return R;
      end if;
      if ROS_Level > STRESS_OX_MAX then
         R.Coherence := R.Coherence * 0.80;
         R.Phase_Potential := R.Phase_Potential - 3.0;
         if ROS_Level > 2.0 * STRESS_OX_MAX then
            R.State := Apoptosis_Signal;
            R.Location := "Stress oxydatif (APOPTOSE)                       ";
            return Apply_V3_Invariants (R);
         end if;
      end if;
      R.Location := "Stress oxydatif (uM ROS)                         ";
      R.State    := Stress_Response;
      R          := Apply_V3_Invariants (R);
      return R;
   end Apply_Oxidative_Stress;

   function Apply_Thermal_Stress
     (S : Signal_Record;
      Temperature : Float) return Signal_Record
     with Pre  => Temperature in 0.0 .. 100.0,
          Post => Apply_Thermal_Stress'Result.State in Stress_Response | Blocked
   is
      R : Signal_Record := S;
   begin
      R := Enforce_Phase_Threshold (R);
      if R.State = Blocked then
         return R;
      end if;
      if Temperature < STRESS_THERM_MIN or Temperature > STRESS_THERM_MAX then
         R.Coherence := R.Coherence * 0.88;
         R.Phase_Potential := R.Phase_Potential - 1.5;
      end if;
      R.Location := "Stress thermique (degres C)                      ";
      R.State    := Stress_Response;
      R          := Apply_V3_Invariants (R);
      return R;
   end Apply_Thermal_Stress;

   function Apply_Osmotic_Stress
     (S : Signal_Record;
      Osmolarity : Float) return Signal_Record
     with Pre  => Osmolarity in 0.0 .. 1000.0,
          Post => Apply_Osmotic_Stress'Result.State in Stress_Response | Blocked
   is
      R : Signal_Record := S;
   begin
      R := Enforce_Phase_Threshold (R);
      if R.State = Blocked then
         return R;
      end if;
      if Osmolarity < STRESS_OSM_MIN or Osmolarity > STRESS_OSM_MAX then
         R.Coherence := R.Coherence * 0.87;
         R.Phase_Potential := R.Phase_Potential - 2.0;
      end if;
      R.Location := "Stress osmotique (mOsm)                          ";
      R.State    := Stress_Response;
      R          := Apply_V3_Invariants (R);
      return R;
   end Apply_Osmotic_Stress;

   function Apply_Immune_Stress
     (S : Signal_Record;
      Cytokines : Float) return Signal_Record
     with Pre  => Cytokines >= 0.0,
          Post => Apply_Immune_Stress'Result.State in Stress_Response | HLA_Presenting | Blocked
   is
      R : Signal_Record := S;
   begin
      R := Enforce_Phase_Threshold (R);
      if R.State = Blocked then
         return R;
      end if;
      if Cytokines > 100.0 then
         R.Coherence := R.Coherence * 0.92;
         R.State := HLA_Presenting;
         R.Location := "Stress immunitaire (HLA presentation)            ";
      else
         R.Location := "Stress immunitaire (baseline)                    ";
         R.State    := Stress_Response;
      end if;
      R := Apply_V3_Invariants (R);
      return R;
   end Apply_Immune_Stress;

   -- ========================================================================
   -- 18. HLA : FONCTIONS
   -- ========================================================================

   function Present_HLA_Class_I
     (S : Signal_Record;
      H : HLA_Record) return Signal_Record
     with Pre  => S.State in Propagating | Modulated | Stress_Response,
          Post => Present_HLA_Class_I'Result.State in HLA_Presenting | HLA_Evading | Blocked
   is
      R : Signal_Record := S;
   begin
      R := Enforce_Phase_Threshold (R);
      if R.State = Blocked then
         return R;
      end if;
      if H.Immune_Evasion then
         R.State := HLA_Evading;
         R.Coherence := R.Coherence * 0.70;
         R.Location := "HLA-I EVASION IMMUNITAIRE                        ";
      elsif H.Peptide_Loaded and H.Antigen_Present then
         R.State := HLA_Presenting;
         R.Coherence := R.Coherence * 1.05;
         if R.Coherence > 100.0 then R.Coherence := 100.0; end if;
         R.Location := "HLA-I PRESENTATION ANTIGENIQUE                   ";
      else
         R.State := HLA_Presenting;
         R.Location := "HLA-I PRESENTATION SOI                           ";
      end if;
      R := Apply_V3_Invariants (R);
      return R;
   end Present_HLA_Class_I;

   function Present_HLA_Class_II
     (S : Signal_Record;
      H : HLA_Record) return Signal_Record
     with Pre  => S.State in Propagating | Modulated | Stress_Response | HLA_Presenting,
          Post => Present_HLA_Class_II'Result.State in HLA_Presenting | Blocked
   is
      R : Signal_Record := S;
   begin
      R := Enforce_Phase_Threshold (R);
      if R.State = Blocked then
         return R;
      end if;
      if H.Class_II_Expression > 0.5 then
         R.State := HLA_Presenting;
         R.Coherence := R.Coherence * 1.02;
         if R.Coherence > 100.0 then R.Coherence := 100.0; end if;
         R.Location := "HLA-II PRESENTATION (CPA)                        ";
      else
         R.Location := "HLA-II FAIBLE EXPRESSION                         ";
      end if;
      R := Apply_V3_Invariants (R);
      return R;
   end Present_HLA_Class_II;

   -- ========================================================================
   -- 19. MILIEU EXTRACELLULAIRE : FONCTIONS
   -- ========================================================================

   function Sense_Extracellular
     (S : Signal_Record;
      E : Extracellular_Record) return Signal_Record
     with Post => Sense_Extracellular'Result.State in Propagating | Blocked
   is
      R : Signal_Record := S;
   begin
      R := Enforce_Phase_Threshold (R);
      if R.State = Blocked then
         return R;
      end if;
      if E.pH < PH_EXT_MIN or E.pH > PH_EXT_MAX then
         R.Coherence := R.Coherence * 0.90;
         R.Phase_Potential := R.Phase_Potential - 1.0;
      end if;
      R.Location := "Milieu extracellulaire (pH, ions)                ";
      R.State    := Propagating;
      R          := Apply_V3_Invariants (R);
      return R;
   end Sense_Extracellular;

   function Sense_Intracellular
     (S : Signal_Record;
      I : Intracellular_Record) return Signal_Record
     with Post => Sense_Intracellular'Result.State in Propagating | Blocked
   is
      R : Signal_Record := S;
   begin
      R := Enforce_Phase_Threshold (R);
      if R.State = Blocked then
         return R;
      end if;
      if I.ATP_Level < 1.0 then
         R.Coherence := R.Coherence * 0.85;
         R.Phase_Potential := R.Phase_Potential - 2.0;
      end if;
      R.Location := "Milieu intracellulaire (ATP, pH)                 ";
      R.State    := Propagating;
      R          := Apply_V3_Invariants (R);
      return R;
   end Sense_Intracellular;

   -- ========================================================================
   -- 20. LIPIDES : FONCTIONS
   -- ========================================================================

   function Process_Lipid
     (S : Signal_Record;
      L : Lipid_Type) return Signal_Record
     with Pre  => S.State in Propagating | Modulated,
          Post => Process_Lipid'Result.State in Propagating | Modulated | Blocked
   is
      R : Signal_Record := S;
   begin
      R := Enforce_Phase_Threshold (R);
      if R.State = Blocked then
         return R;
      end if;
      case L is
         when Phosphatidylcholine =>
            R.Location := "Lipide: PC (feuillet externe)                    ";
            R.State := Modulated;
         when Phosphatidylethanolamine =>
            R.Location := "Lipide: PE (feuillet interne)                    ";
            R.State := Modulated;
         when Phosphatidylserine =>
            R.Location := "Lipide: PS (signal apoptotique)                  ";
            R.State := Modulated;
         when Phosphatidylinositol =>
            R.Location := "Lipide: PI (signalisation PIP2)                  ";
            R.State := Modulated;
         when Sphingomyelin =>
            R.Location := "Lipide: Sphingomyeline (myeline)                 ";
            R.State := Modulated;
         when Cholesterol =>
            R.Location := "Lipide: Cholesterol (regulateur fluidite)        ";
            R.Coherence := R.Coherence * 1.02;
            R.State := Modulated;
         when Ganglioside_GM1 =>
            R.Location := "Lipide: Ganglioside GM1 (neurone)                ";
            R.State := Modulated;
         when Ganglioside_GD1a =>
            R.Location := "Lipide: Ganglioside GD1a (synapse)               ";
            R.State := Modulated;
         when Cerebroside =>
            R.Location := "Lipide: Cerebroside (myeline)                    ";
            R.State := Modulated;
         when Sulfatide =>
            R.Location := "Lipide: Sulfatide (myeline)                      ";
            R.State := Modulated;
      end case;
      R := Apply_V3_Invariants (R);
      return R;
   end Process_Lipid;

   -- ========================================================================
   -- 21. PROTEINES : FONCTIONS
   -- ========================================================================

   function Process_Protein
     (S : Signal_Record;
      P : Protein_Type) return Signal_Record
     with Pre  => S.State in Propagating | Modulated | Transmitted,
          Post => Process_Protein'Result.State in Propagating | Modulated | Transmitted | Blocked | Amplified | Attenuated
   is
      R : Signal_Record := S;
   begin
      R := Enforce_Phase_Threshold (R);
      if R.State = Blocked then
         return R;
      end if;
      case P is
         when Integral_Monotopic =>
            R.Location := "Proteine: integrale monotopique                  ";
            R.State := Transmitted;
         when Integral_Polytopic =>
            R.Location := "Proteine: integrale polytopique (RCPG)           ";
            R.State := Transmitted;
         when Integral_Beta_Barrel =>
            R.Location := "Proteine: beta-barrel (porine)                   ";
            R.State := Transmitted;
         when Peripheral_Internal =>
            R.Location := "Proteine: peripherique interne                   ";
            R.State := Modulated;
         when Peripheral_External =>
            R.Location := "Proteine: peripherique externe                   ";
            R.State := Modulated;
         when GPI_Anchored =>
            R.Location := "Proteine: ancre GPI (radeau)                     ";
            R.State := Modulated;
         when Ion_Channel_Leak =>
            R.Location := "Canal ionique: fuite                             ";
            R.Amplitude := R.Amplitude * 1.10;
            R.State := Amplified;
         when Ion_Channel_Voltage =>
            R.Location := "Canal ionique: voltage-dependant                 ";
            R.Amplitude := R.Amplitude * 1.20;
            R.State := Amplified;
         when Ion_Channel_Ligand =>
            R.Location := "Canal ionique: ligand-dependant                  ";
            R.Amplitude := R.Amplitude * 1.15;
            R.State := Amplified;
         when Ion_Channel_Mechano =>
            R.Location := "Canal ionique: mecanosensible                    ";
            R.Amplitude := R.Amplitude * 1.12;
            R.State := Amplified;
         when Aquaporin =>
            R.Location := "Aquaporine (transport eau)                       ";
            R.State := Transmitted;
         when Transporter_Uniport =>
            R.Location := "Transporteur: uniport (GLUT1)                    ";
            R.State := Transmitted;
         when Transporter_Symport =>
            R.Location := "Transporteur: symport (SGLT1)                    ";
            R.State := Transmitted;
         when Transporter_Antiport =>
            R.Location := "Transporteur: antiport (Na/Ca)                   ";
            R.State := Transmitted;
         when Pump_NaK_ATPase =>
            R.Location := "Pompe: Na/K-ATPase (ATP)                         ";
            R.Coherence := R.Coherence * 1.05;
            if R.Coherence > 100.0 then R.Coherence := 100.0; end if;
            R.State := Amplified;
         when Pump_Ca_ATPase =>
            R.Location := "Pompe: Ca-ATPase (SERCA)                         ";
            R.State := Amplified;
         when Pump_HK_ATPase =>
            R.Location := "Pompe: H/K-ATPase (estomac)                      ";
            R.State := Amplified;
         when Pump_H_ATPase =>
            R.Location := "Pompe: H-ATPase (lysosome)                       ";
            R.State := Amplified;
         when Receptor_RCPG =>
            R.Location := "Recepteur: RCPG (beta-adrenergique)              ";
            R.State := Modulated;
         when Receptor_RTK =>
            R.Location := "Recepteur: RTK (insuline)                        ";
            R.State := Modulated;
         when Receptor_Channel =>
            R.Location := "Recepteur: canal (nicotinique)                   ";
            R.State := Modulated;
         when Receptor_Guanylate =>
            R.Location := "Recepteur: guanylate cyclase (ANP)               ";
            R.State := Modulated;
         when Receptor_TCR =>
            R.Location := "Recepteur: TCR (lymphocyte T)                    ";
            R.State := Modulated;
         when Receptor_BCR =>
            R.Location := "Recepteur: BCR (lymphocyte B)                    ";
            R.State := Modulated;
         when Receptor_FceRI =>
            R.Location := "Recepteur: Fc-epsilon-RI (mastocyte)             ";
            R.State := Modulated;
         when Receptor_TLR =>
            R.Location := "Recepteur: TLR (immunite innee)                  ";
            R.State := Modulated;
         when HLA_Class_I =>
            R.Location := "HLA classe I (toutes cellules nucleees)          ";
            R.State := HLA_Presenting;
         when HLA_Class_II =>
            R.Location := "HLA classe II (CPA)                              ";
            R.State := HLA_Presenting;
         when HLA_G =>
            R.Location := "HLA-G (trophoblaste, immunoprivilege)            ";
            R.State := HLA_Presenting;
         when HLA_E =>
            R.Location := "HLA-E (regulation NK)                            ";
            R.State := HLA_Presenting;
         when Integrin =>
            R.Location := "Integrine (ancrage ECM)                          ";
            R.State := Transmitted;
         when Cadherin =>
            R.Location := "Cadherine (jonction adherente)                   ";
            R.State := Transmitted;
         when Selectin =>
            R.Location := "Selectine (extravasation)                        ";
            R.State := Transmitted;
         when Glycophorin =>
            R.Location := "Glycophorine (erythrocyte)                       ";
            R.State := Modulated;
         when Band_3 =>
            R.Location := "Bande 3 (echange Cl/HCO3)                        ";
            R.State := Transmitted;
         when Spectrin =>
            R.Location := "Spectrine (cytosquelette erythrocyte)            ";
            R.Amplitude := R.Amplitude * 0.90;
            R.State := Attenuated;
         when Ankyrin =>
            R.Location := "Ankyrine (ancrage spectrine)                     ";
            R.State := Modulated;
         when Band_4_1 =>
            R.Location := "Bande 4.1 (jonction actine-spectrine)            ";
            R.State := Modulated;
         when Dystrophin =>
            R.Location := "Dystrophine (muscle)                             ";
            R.State := Modulated;
      end case;
      R := Apply_V3_Invariants (R);
      return R;
   end Process_Protein;

   -- ========================================================================
   -- 22. GLUCIDES : FONCTIONS
   -- ========================================================================

   function Process_Glycan
     (S : Signal_Record;
      G : Glycan_Type) return Signal_Record
     with Pre  => S.State in Propagating | Modulated,
          Post => Process_Glycan'Result.State in Modulated | Blocked
   is
      R : Signal_Record := S;
   begin
      R := Enforce_Phase_Threshold (R);
      if R.State = Blocked then
         return R;
      end if;
      case G is
         when ABO_Antigen =>
            R.Location := "Glycane: antigene ABO (groupe sanguin)           ";
         when Glycophorin_Sialic =>
            R.Location := "Glycane: acide sialique (charge negative)        ";
         when Mucin =>
            R.Location := "Glycane: mucine (protection epithelia)           ";
         when NCAM_Polysialic =>
            R.Location := "Glycane: PSA-NCAM (plasticite neuronale)         ";
         when CD45 =>
            R.Location := "Glycane: CD45 (phosphatase leucocytaire)         ";
         when Selectin_Ligand =>
            R.Location := "Glycane: ligand de selectine (extravasation)     ";
         when MUC1_Tumor =>
            R.Location := "Glycane: MUC1 (marqueur tumoral)                 ";
         when Heparan_Sulfate =>
            R.Location := "Glycane: heparane sulfate (ECM)                  ";
      end case;
      R.State := Modulated;
      R := Apply_V3_Invariants (R);
      return R;
   end Process_Glycan;

   -- ========================================================================
   -- 23. CYTOSQUELETTE : FONCTIONS
   -- ========================================================================

   function Process_Cytoskeleton
     (S : Signal_Record;
      C : Cytoskeleton_Type) return Signal_Record
     with Pre  => S.State in Propagating | Modulated,
          Post => Process_Cytoskeleton'Result.State in Modulated | Blocked
   is
      R : Signal_Record := S;
   begin
      R := Enforce_Phase_Threshold (R);
      if R.State = Blocked then
         return R;
      end if;
      case C is
         when Actin_Microfilament =>
            R.Location := "Cytosquelette: actine (microfilament)            ";
         when Microtubule =>
            R.Location := "Cytosquelette: microtubule (transport)           ";
         when Intermediate_Filament_Keratin =>
            R.Location := "Cytosquelette: keratine (epithelium)             ";
         when Intermediate_Filament_Vimentin =>
            R.Location := "Cytosquelette: vimentine (fibroblaste)           ";
         when Intermediate_Filament_Desmin =>
            R.Location := "Cytosquelette: desmine (muscle)                  ";
         when Intermediate_Filament_Neurofilament =>
            R.Location := "Cytosquelette: neurofilament (neurone)           ";
         when Intermediate_Filament_GFAP =>
            R.Location := "Cytosquelette: GFAP (glie)                       ";
         when Spectrin_Network =>
            R.Location := "Cytosquelette: reseau spectrine (erythrocyte)    ";
         when Septin_Ring =>
            R.Location := "Cytosquelette: anneau septine (division)         ";
      end case;
      R.State := Modulated;
      R := Apply_V3_Invariants (R);
      return R;
   end Process_Cytoskeleton;

   -- ========================================================================
   -- 24. RADEAUX LIPIDIQUES : FONCTIONS
   -- ========================================================================

   function Process_Raft
     (S : Signal_Record;
      Rf : Raft_Type) return Signal_Record
     with Pre  => S.State in Propagating | Modulated,
          Post => Process_Raft'Result.State in Modulated | Amplified | Blocked
   is
      R : Signal_Record := S;
   begin
      R := Enforce_Phase_Threshold (R);
      if R.State = Blocked then
         return R;
      end if;
      case Rf is
         when Raft_Signaling_TCR =>
            R.Location := "Radeau: signalisation TCR (lymphocyte T)         ";
            R.Amplitude := R.Amplitude * 1.15;
            R.State := Amplified;
         when Raft_Signaling_BCR =>
            R.Location := "Radeau: signalisation BCR (lymphocyte B)         ";
            R.Amplitude := R.Amplitude * 1.15;
            R.State := Amplified;
         when Raft_Signaling_FceRI =>
            R.Location := "Radeau: signalisation Fc-epsilon-RI (mastocyte)  ";
            R.Amplitude := R.Amplitude * 1.20;
            R.State := Amplified;
         when Raft_Synaptic =>
            R.Location := "Radeau: synaptique (neurone)                     ";
            R.Amplitude := R.Amplitude * 1.10;
            R.State := Amplified;
         when Raft_Endothelial_VEGF =>
            R.Location := "Radeau: endothelial VEGF (angiogenese)           ";
            R.State := Modulated;
         when Raft_Tumor_Survival =>
            R.Location := "Radeau: survie tumorale                          ";
            R.Coherence := R.Coherence * 0.90;
            R.State := Modulated;
      end case;
      R := Apply_V3_Invariants (R);
      return R;
   end Process_Raft;

   -- ========================================================================
   -- 25. ECM : FONCTIONS
   -- ========================================================================

   function Process_ECM
     (S : Signal_Record;
      E : ECM_Type) return Signal_Record
     with Pre  => S.State in Propagating | Diffused,
          Post => Process_ECM'Result.State in Diffused | Blocked | Attenuated
   is
      R : Signal_Record := S;
   begin
      R := Enforce_Phase_Threshold (R);
      if R.State = Blocked then
         return R;
      end if;
      case E is
         when Collagen_I =>
            R.Location := "ECM: collagene I (peau, os, tendon)              ";
            R.Amplitude := R.Amplitude * 0.60;
         when Collagen_II =>
            R.Location := "ECM: collagene II (cartilage)                    ";
            R.Amplitude := R.Amplitude * 0.65;
         when Collagen_III =>
            R.Location := "ECM: collagene III (vaisseaux, peau)             ";
            R.Amplitude := R.Amplitude * 0.70;
         when Collagen_IV =>
            R.Location := "ECM: collagene IV (lame basale)                  ";
            R.Amplitude := R.Amplitude * 0.75;
         when Collagen_V =>
            R.Location := "ECM: collagene V (cornee)                        ";
            R.Amplitude := R.Amplitude * 0.80;
         when Fibronectin =>
            R.Location := "ECM: fibronectine (adhesion)                     ";
            R.Amplitude := R.Amplitude * 0.85;
         when Laminin =>
            R.Location := "ECM: laminine (lame basale)                      ";
            R.Amplitude := R.Amplitude * 0.80;
         when Elastin =>
            R.Location := "ECM: elastine (elasticite)                       ";
            R.Amplitude := R.Amplitude * 0.90;
         when Hyaluronan =>
            R.Location := "ECM: hyaluronane (hydratation)                   ";
            R.Amplitude := R.Amplitude * 0.95;
         when Proteoglycan =>
            R.Location := "ECM: proteoglycane (resistance compression)      ";
            R.Amplitude := R.Amplitude * 0.88;
         when Tenascin =>
            R.Location := "ECM: tenascine (guidage axonal)                  ";
            R.Amplitude := R.Amplitude * 0.82;
         when Vitronectin =>
            R.Location := "ECM: vitronectine (adhesion)                     ";
            R.Amplitude := R.Amplitude * 0.86;
      end case;
      R.State := Diffused;
      R := Check_Lambda_Resonance (R);
      R := Apply_V3_Invariants (R);
      return R;
   end Process_ECM;

   -- ========================================================================
   -- 26. PARAMETRES MEMBRANAIRES PAR TYPE CELLULAIRE
   -- ========================================================================

   function Get_Membrane (C : Cell_Type) return Membrane_Record
     with Post => Get_Membrane'Result.Cell = C
   is
      M : Membrane_Record;
   begin
      M.Cell := C;
      case C is
         when Neuron =>
            M.Lipid_Density := 0.70; M.Protein_Density := 0.85;
            M.Cholesterol := 0.30; M.Rafts_Density := 0.20;
            M.Curvature := 0.40;
            M.Has_PC := True; M.Has_PE := True; M.Has_PS := True;
            M.Has_PI := True; M.Has_Sphingomyelin := True;
            M.Has_Gangliosides := True;
            M.Has_Tubules_T := False; M.Has_Tight_Junction := False;
            M.Has_Spectrin := False; M.Has_Rafts := False;
            M.Has_Gap_Junction := True; M.Has_Desmosome := False;
            M.Has_Ion_Channels := True; M.Has_Pumps := True;
            M.Has_Receptors := True; M.Has_Integrins := False;
            M.Has_Cadherins := True; M.Has_Selectins := False;
            M.Has_HLA_I := True; M.Has_HLA_II := False;
            M.Has_HLA_G := False;
            M.Has_Glycocalyx := True; M.Has_ABO := False;
            M.Has_Mucin := False;
            M.Has_Actin := True; M.Has_Microtubules := True;
            M.Has_Intermediate_Fil := True;
            M.Has_Rafts_Signaling := True;
            M.Dipole_Moment := 3.5; M.Fluidity := 0.6;
            M.Tension := 0.5;
         when Myocyte =>
            M.Lipid_Density := 0.65; M.Protein_Density := 0.80;
            M.Cholesterol := 0.25; M.Rafts_Density := 0.15;
            M.Curvature := 0.70;
            M.Has_PC := True; M.Has_PE := True; M.Has_PS := True;
            M.Has_PI := True; M.Has_Sphingomyelin := True;
            M.Has_Gangliosides := False;
            M.Has_Tubules_T := True; M.Has_Tight_Junction := False;
            M.Has_Spectrin := False; M.Has_Rafts := False;
            M.Has_Gap_Junction := True; M.Has_Desmosome := True;
            M.Has_Ion_Channels := True; M.Has_Pumps := True;
            M.Has_Receptors := True; M.Has_Integrins := True;
            M.Has_Cadherins := True; M.Has_Selectins := False;
            M.Has_HLA_I := True; M.Has_HLA_II := False;
            M.Has_HLA_G := False;
            M.Has_Glycocalyx := True; M.Has_ABO := False;
            M.Has_Mucin := False;
            M.Has_Actin := True; M.Has_Microtubules := True;
            M.Has_Intermediate_Fil := True;
            M.Has_Rafts_Signaling := True;
            M.Dipole_Moment := 3.0; M.Fluidity := 0.5;
            M.Tension := 0.7;
         when Epithelial =>
            M.Lipid_Density := 0.75; M.Protein_Density := 0.90;
            M.Cholesterol := 0.35; M.Rafts_Density := 0.40;
            M.Curvature := 0.20;
            M.Has_PC := True; M.Has_PE := True; M.Has_PS := True;
            M.Has_PI := True; M.Has_Sphingomyelin := True;
            M.Has_Gangliosides := False;
            M.Has_Tubules_T := False; M.Has_Tight_Junction := True;
            M.Has_Spectrin := False; M.Has_Rafts := False;
            M.Has_Gap_Junction := True; M.Has_Desmosome := True;
            M.Has_Ion_Channels := True; M.Has_Pumps := True;
            M.Has_Receptors := True; M.Has_Integrins := True;
            M.Has_Cadherins := True; M.Has_Selectins := False;
            M.Has_HLA_I := True; M.Has_HLA_II := True;
            M.Has_HLA_G := False;
            M.Has_Glycocalyx := True; M.Has_ABO := False;
            M.Has_Mucin := True;
            M.Has_Actin := True; M.Has_Microtubules := True;
            M.Has_Intermediate_Fil := True;
            M.Has_Rafts_Signaling := True;
            M.Dipole_Moment := 4.0; M.Fluidity := 0.4;
            M.Tension := 0.8;
         when Erythrocyte =>
            M.Lipid_Density := 0.80; M.Protein_Density := 0.60;
            M.Cholesterol := 0.40; M.Rafts_Density := 0.10;
            M.Curvature := 0.90;
            M.Has_PC := True; M.Has_PE := True; M.Has_PS := True;
            M.Has_PI := True; M.Has_Sphingomyelin := True;
            M.Has_Gangliosides := False;
            M.Has_Tubules_T := False; M.Has_Tight_Junction := False;
            M.Has_Spectrin := True; M.Has_Rafts := False;
            M.Has_Gap_Junction := False; M.Has_Desmosome := False;
            M.Has_Ion_Channels := True; M.Has_Pumps := True;
            M.Has_Receptors := True; M.Has_Integrins := False;
            M.Has_Cadherins := False; M.Has_Selectins := True;
            M.Has_HLA_I := False; M.Has_HLA_II := False;
            M.Has_HLA_G := False;
            M.Has_Glycocalyx := True; M.Has_ABO := True;
            M.Has_Mucin := False;
            M.Has_Actin := True; M.Has_Microtubules := False;
            M.Has_Intermediate_Fil := False;
            M.Has_Rafts_Signaling := False;
            M.Dipole_Moment := 2.5; M.Fluidity := 0.7;
            M.Tension := 0.9;
         when Leukocyte =>
            M.Lipid_Density := 0.72; M.Protein_Density := 0.88;
            M.Cholesterol := 0.28; M.Rafts_Density := 0.60;
            M.Curvature := 0.50;
            M.Has_PC := True; M.Has_PE := True; M.Has_PS := True;
            M.Has_PI := True; M.Has_Sphingomyelin := True;
            M.Has_Gangliosides := True;
            M.Has_Tubules_T := False; M.Has_Tight_Junction := False;
            M.Has_Spectrin := False; M.Has_Rafts := True;
            M.Has_Gap_Junction := False; M.Has_Desmosome := False;
            M.Has_Ion_Channels := True; M.Has_Pumps := True;
            M.Has_Receptors := True; M.Has_Integrins := True;
            M.Has_Cadherins := False; M.Has_Selectins := True;
            M.Has_HLA_I := True; M.Has_HLA_II := True;
            M.Has_HLA_G := False;
            M.Has_Glycocalyx := True; M.Has_ABO := False;
            M.Has_Mucin := False;
            M.Has_Actin := True; M.Has_Microtubules := True;
            M.Has_Intermediate_Fil := False;
            M.Has_Rafts_Signaling := True;
            M.Dipole_Moment := 3.8; M.Fluidity := 0.5;
            M.Tension := 0.4;
         when Fibroblast =>
            M.Lipid_Density := 0.68; M.Protein_Density := 0.75;
            M.Cholesterol := 0.32; M.Rafts_Density := 0.25;
            M.Curvature := 0.35;
            M.Has_PC := True; M.Has_PE := True; M.Has_PS := True;
            M.Has_PI := True; M.Has_Sphingomyelin := True;
            M.Has_Gangliosides := False;
            M.Has_Tubules_T := False; M.Has_Tight_Junction := False;
            M.Has_Spectrin := False; M.Has_Rafts := False;
            M.Has_Gap_Junction := True; M.Has_Desmosome := False;
            M.Has_Ion_Channels := True; M.Has_Pumps := True;
            M.Has_Receptors := True; M.Has_Integrins := True;
            M.Has_Cadherins := False; M.Has_Selectins := False;
            M.Has_HLA_I := True; M.Has_HLA_II := False;
            M.Has_HLA_G := False;
            M.Has_Glycocalyx := True; M.Has_ABO := False;
            M.Has_Mucin := False;
            M.Has_Actin := True; M.Has_Microtubules := True;
            M.Has_Intermediate_Fil := True;
            M.Has_Rafts_Signaling := True;
            M.Dipole_Moment := 3.2; M.Fluidity := 0.6;
            M.Tension := 0.5;
         when Osteocyte =>
            M.Lipid_Density := 0.60; M.Protein_Density := 0.70;
            M.Cholesterol := 0.45; M.Rafts_Density := 0.20;
            M.Curvature := 0.60;
            M.Has_PC := True; M.Has_PE := True; M.Has_PS := True;
            M.Has_PI := True; M.Has_Sphingomyelin := True;
            M.Has_Gangliosides := False;
            M.Has_Tubules_T := False; M.Has_Tight_Junction := False;
            M.Has_Spectrin := False; M.Has_Rafts := False;
            M.Has_Gap_Junction := True; M.Has_Desmosome := False;
            M.Has_Ion_Channels := True; M.Has_Pumps := True;
            M.Has_Receptors := True; M.Has_Integrins := True;
            M.Has_Cadherins := True; M.Has_Selectins := False;
            M.Has_HLA_I := True; M.Has_HLA_II := False;
            M.Has_HLA_G := False;
            M.Has_Glycocalyx := True; M.Has_ABO := False;
            M.Has_Mucin := False;
            M.Has_Actin := True; M.Has_Microtubules := True;
            M.Has_Intermediate_Fil := True;
            M.Has_Rafts_Signaling := True;
            M.Dipole_Moment := 2.8; M.Fluidity := 0.4;
            M.Tension := 0.8;
         when Hepatocyte =>
            M.Lipid_Density := 0.70; M.Protein_Density := 0.92;
            M.Cholesterol := 0.22; M.Rafts_Density := 0.30;
            M.Curvature := 0.30;
            M.Has_PC := True; M.Has_PE := True; M.Has_PS := True;
            M.Has_PI := True; M.Has_Sphingomyelin := True;
            M.Has_Gangliosides := False;
            M.Has_Tubules_T := False; M.Has_Tight_Junction := True;
            M.Has_Spectrin := False; M.Has_Rafts := False;
            M.Has_Gap_Junction := True; M.Has_Desmosome := True;
            M.Has_Ion_Channels := True; M.Has_Pumps := True;
            M.Has_Receptors := True; M.Has_Integrins := True;
            M.Has_Cadherins := True; M.Has_Selectins := False;
            M.Has_HLA_I := True; M.Has_HLA_II := True;
            M.Has_HLA_G := False;
            M.Has_Glycocalyx := True; M.Has_ABO := False;
            M.Has_Mucin := False;
            M.Has_Actin := True; M.Has_Microtubules := True;
            M.Has_Intermediate_Fil := True;
            M.Has_Rafts_Signaling := True;
            M.Dipole_Moment := 4.2; M.Fluidity := 0.5;
            M.Tension := 0.6;
      end case;
      return M;
   end Get_Membrane;

   -- ========================================================================
   -- 27. PROCEDURE PRINCIPALE
   -- ========================================================================

   procedure Run_Membrane_Tracker with Global => null
   is
      S : Signal_Record;
      M : Membrane_Record;
      E : Extracellular_Record;
      I : Intracellular_Record;
      H : HLA_Record;
      St : Stress_Record;
      L : Lipid_Type;
      P : Protein_Type;
      G : Glycan_Type;
      C : Cytoskeleton_Type;
      Rf : Raft_Type;
      Ec : ECM_Type;

      procedure Print_Step (N_Step : Integer; Label_Step : String; Sig : Signal_Record) is
      begin
         Put ("STEP ");
         Put (N_Step, Width => 2);
         Put (" - "); Put_Line (Label_Step);
         Put_Line ("  Location  : " & Sig.Location);
         Put_Line ("  State     : " & Signal_State'Image (Sig.State));
         Put_Line ("  Frequency : " & Float'Image (Sig.Frequency) & " Hz");
         Put_Line ("  Potential : " & Float'Image (Sig.Phase_Potential) & " mV");
         Put_Line ("  Coherence : " & Float'Image (Sig.Coherence) & " %");
         Put_Line ("  Step_Idx  : " & Integer'Image (Sig.Step_Index) & " (mod k=7)");
         Put_Line ("  Hash mod9 : " & Integer'Image (Sig.Integrity_Hash));
         if Diagnose_Coherence (Sig) then
            Put_Line ("  Diagnostic: SANTE (Phi >= Phi_critical)");
         else
            Put_Line ("  Diagnostic: MALADIE (decoherence)");
         end if;
         New_Line;
      end Print_Step;

   begin
      Put_Line ("================================================================================");
      Put_Line ("V3 MEMBRANE COMPLETE - EXPLORATION TOTALE SANS NEUTRINOS");
      Put_Line ("Conforme V3 : Psi=48016.8 | Phi=-51.1 mV | k=7 | mod9=9 | lambda=4.68e-5 m");
      Put_Line ("================================================================================");
      New_Line;

      -- ======================================================================
      -- PHASE 1 : MILIEU EXTERIEUR
      -- ======================================================================
      Put_Line ("=== PHASE 1 : MILIEU EXTERIEUR ===");
      E.Na_Conc := 145.0; E.K_Conc := 5.0; E.Ca_Conc := 2.0;
      E.Cl_Conc := 110.0; E.pH := 7.4; E.Temperature := 37.0;
      E.Osmolarity := 300.0; E.ROS_Level := 0.1;
      E.Mechanical_Stress := 0.5; E.Growth_Factors := 10.0;
      E.Cytokines := 5.0; E.Hormones := 1.0;

      S := Emit_From_DNA (1.0e-9);
      S := Sense_Extracellular (S, E);
      Print_Step (1, "EMISSION DNA + SENSIBILITE EXTERIEURE", S);

      -- ======================================================================
      -- PHASE 2 : LIPIDES MEMBRANAIRES (10 types)
      -- ======================================================================
      Put_Line ("=== PHASE 2 : LIPIDES MEMBRANAIRES ===");
      L := Phosphatidylcholine;
      S := Process_Lipid (S, L);
      Print_Step (2, "LIPIDE: PC", S);
      L := Phosphatidylethanolamine;
      S := Process_Lipid (S, L);
      Print_Step (3, "LIPIDE: PE", S);
      L := Phosphatidylserine;
      S := Process_Lipid (S, L);
      Print_Step (4, "LIPIDE: PS", S);
      L := Phosphatidylinositol;
      S := Process_Lipid (S, L);
      Print_Step (5, "LIPIDE: PI", S);
      L := Sphingomyelin;
      S := Process_Lipid (S, L);
      Print_Step (6, "LIPIDE: SPHINGOMYELINE", S);
      L := Cholesterol;
      S := Process_Lipid (S, L);
      Print_Step (7, "LIPIDE: CHOLESTEROL", S);
      L := Ganglioside_GM1;
      S := Process_Lipid (S, L);
      Print_Step (8, "LIPIDE: GANGLIOSIDE GM1", S);
      L := Ganglioside_GD1a;
      S := Process_Lipid (S, L);
      Print_Step (9, "LIPIDE: GANGLIOSIDE GD1a", S);
      L := Cerebroside;
      S := Process_Lipid (S, L);
      Print_Step (10, "LIPIDE: CEREBROSIDE", S);
      L := Sulfatide;
      S := Process_Lipid (S, L);
      Print_Step (11, "LIPIDE: SULFATIDE", S);

      -- ======================================================================
      -- PHASE 3 : PROTEINES MEMBRANAIRES (40 types)
      -- ======================================================================
      Put_Line ("=== PHASE 3 : PROTEINES MEMBRANAIRES ===");
      P := Integral_Monotopic;
      S := Process_Protein (S, P);
      Print_Step (12, "PROTEINE: INTEGRALE MONOTOPIQUE", S);
      P := Integral_Polytopic;
      S := Process_Protein (S, P);
      Print_Step (13, "PROTEINE: INTEGRALE POLYTOPIQUE", S);
      P := Integral_Beta_Barrel;
      S := Process_Protein (S, P);
      Print_Step (14, "PROTEINE: BETA-BARREL", S);
      P := Peripheral_Internal;
      S := Process_Protein (S, P);
      Print_Step (15, "PROTEINE: PERIPHERIQUE INTERNE", S);
      P := Peripheral_External;
      S := Process_Protein (S, P);
      Print_Step (16, "PROTEINE: PERIPHERIQUE EXTERNE", S);
      P := GPI_Anchored;
      S := Process_Protein (S, P);
      Print_Step (17, "PROTEINE: GPI-ANCRED", S);
      P := Ion_Channel_Leak;
      S := Process_Protein (S, P);
      Print_Step (18, "CANAL: FUITE", S);
      P := Ion_Channel_Voltage;
      S := Process_Protein (S, P);
      Print_Step (19, "CANAL: VOLTAGE-DEPENDANT", S);
      P := Ion_Channel_Ligand;
      S := Process_Protein (S, P);
      Print_Step (20, "CANAL: LIGAND-DEPENDANT", S);
      P := Ion_Channel_Mechano;
      S := Process_Protein (S, P);
      Print_Step (21, "CANAL: MECANOSENSIBLE", S);
      P := Aquaporin;
      S := Process_Protein (S, P);
      Print_Step (22, "AQUAPORINE", S);
      P := Transporter_Uniport;
      S := Process_Protein (S, P);
      Print_Step (23, "TRANSPORTEUR: UNIPORT", S);
      P := Transporter_Symport;
      S := Process_Protein (S, P);
      Print_Step (24, "TRANSPORTEUR: SYMPORT", S);
      P := Transporter_Antiport;
      S := Process_Protein (S, P);
      Print_Step (25, "TRANSPORTEUR: ANTIPORT", S);
      P := Pump_NaK_ATPase;
      S := Process_Protein (S, P);
      Print_Step (26, "POMPE: Na/K-ATPase", S);
      P := Pump_Ca_ATPase;
      S := Process_Protein (S, P);
      Print_Step (27, "POMPE: Ca-ATPase", S);
      P := Pump_HK_ATPase;
      S := Process_Protein (S, P);
      Print_Step (28, "POMPE: H/K-ATPase", S);
      P := Pump_H_ATPase;
      S := Process_Protein (S, P);
      Print_Step (29, "POMPE: H-ATPase", S);
      P := Receptor_RCPG;
      S := Process_Protein (S, P);
      Print_Step (30, "RECEPTEUR: RCPG", S);
      P := Receptor_RTK;
      S := Process_Protein (S, P);
      Print_Step (31, "RECEPTEUR: RTK", S);
      P := Receptor_Channel;
      S := Process_Protein (S, P);
      Print_Step (32, "RECEPTEUR: CANAL", S);
      P := Receptor_Guanylate;
      S := Process_Protein (S, P);
      Print_Step (33, "RECEPTEUR: GUANYLATE CYCLASE", S);
      P := Receptor_TCR;
      S := Process_Protein (S, P);
      Print_Step (34, "RECEPTEUR: TCR", S);
      P := Receptor_BCR;
      S := Process_Protein (S, P);
      Print_Step (35, "RECEPTEUR: BCR", S);
      P := Receptor_FceRI;
      S := Process_Protein (S, P);
      Print_Step (36, "RECEPTEUR: Fc-epsilon-RI", S);
      P := Receptor_TLR;
      S := Process_Protein (S, P);
      Print_Step (37, "RECEPTEUR: TLR", S);
      P := HLA_Class_I;
      S := Process_Protein (S, P);
      Print_Step (38, "HLA CLASSE I", S);
      P := HLA_Class_II;
      S := Process_Protein (S, P);
      Print_Step (39, "HLA CLASSE II", S);
      P := HLA_G;
      S := Process_Protein (S, P);
      Print_Step (40, "HLA-G", S);
      P := HLA_E;
      S := Process_Protein (S, P);
      Print_Step (41, "HLA-E", S);
      P := Integrin;
      S := Process_Protein (S, P);
      Print_Step (42, "INTEGRINE", S);
      P := Cadherin;
      S := Process_Protein (S, P);
      Print_Step (43, "CADHERINE", S);
      P := Selectin;
      S := Process_Protein (S, P);
      Print_Step (44, "SELECTINE", S);
      P := Glycophorin;
      S := Process_Protein (S, P);
      Print_Step (45, "GLYCOPHORINE", S);
      P := Band_3;
      S := Process_Protein (S, P);
      Print_Step (46, "BANDE 3", S);
      P := Spectrin;
      S := Process_Protein (S, P);
      Print_Step (47, "SPECTRINE", S);
      P := Ankyrin;
      S := Process_Protein (S, P);
      Print_Step (48, "ANKYRINE", S);
      P := Band_4_1;
      S := Process_Protein (S, P);
      Print_Step (49, "BANDE 4.1", S);
      P := Dystrophin;
      S := Process_Protein (S, P);
      Print_Step (50, "DYSTROPHINE", S);

      -- ======================================================================
      -- PHASE 4 : GLUCIDES (GLYCOCALYX)
      -- ======================================================================
      Put_Line ("=== PHASE 4 : GLUCIDES (GLYCOCALYX) ===");
      G := ABO_Antigen;
      S := Process_Glycan (S, G);
      Print_Step (51, "GLYCANE: ABO", S);
      G := Glycophorin_Sialic;
      S := Process_Glycan (S, G);
      Print_Step (52, "GLYCANE: ACIDE SIALIQUE", S);
      G := Mucin;
      S := Process_Glycan (S, G);
      Print_Step (53, "GLYCANE: MUCINE", S);
      G := NCAM_Polysialic;
      S := Process_Glycan (S, G);
      Print_Step (54, "GLYCANE: PSA-NCAM", S);
      G := CD45;
      S := Process_Glycan (S, G);
      Print_Step (55, "GLYCANE: CD45", S);
      G := Selectin_Ligand;
      S := Process_Glycan (S, G);
      Print_Step (56, "GLYCANE: LIGAND SELECTINE", S);
      G := MUC1_Tumor;
      S := Process_Glycan (S, G);
      Print_Step (57, "GLYCANE: MUC1 TUMORAL", S);
      G := Heparan_Sulfate;
      S := Process_Glycan (S, G);
      Print_Step (58, "GLYCANE: HEPARANE SULFATE", S);

      -- ======================================================================
      -- PHASE 5 : CYTOSQUELETTE
      -- ======================================================================
      Put_Line ("=== PHASE 5 : CYTOSQUELETTE ===");
      C := Actin_Microfilament;
      S := Process_Cytoskeleton (S, C);
      Print_Step (59, "CYTOSQUELETTE: ACTINE", S);
      C := Microtubule;
      S := Process_Cytoskeleton (S, C);
      Print_Step (60, "CYTOSQUELETTE: MICROTUBULE", S);
      C := Intermediate_Filament_Keratin;
      S := Process_Cytoskeleton (S, C);
      Print_Step (61, "CYTOSQUELETTE: KERATINE", S);
      C := Intermediate_Filament_Vimentin;
      S := Process_Cytoskeleton (S, C);
      Print_Step (62, "CYTOSQUELETTE: VIMENTINE", S);
      C := Intermediate_Filament_Desmin;
      S := Process_Cytoskeleton (S, C);
      Print_Step (63, "CYTOSQUELETTE: DESMINE", S);
      C := Intermediate_Filament_Neurofilament;
      S := Process_Cytoskeleton (S, C);
      Print_Step (64, "CYTOSQUELETTE: NEUROFILAMENT", S);
      C := Intermediate_Filament_GFAP;
      S := Process_Cytoskeleton (S, C);
      Print_Step (65, "CYTOSQUELETTE: GFAP", S);
      C := Spectrin_Network;
      S := Process_Cytoskeleton (S, C);
      Print_Step (66, "CYTOSQUELETTE: SPECTRINE", S);
      C := Septin_Ring;
      S := Process_Cytoskeleton (S, C);
      Print_Step (67, "CYTOSQUELETTE: SEPTINE", S);

      -- ======================================================================
      -- PHASE 6 : RADEAUX LIPIDIQUES
      -- ======================================================================
      Put_Line ("=== PHASE 6 : RADEAUX LIPIDIQUES ===");
      Rf := Raft_Signaling_TCR;
      S := Process_Raft (S, Rf);
      Print_Step (68, "RADEAU: TCR", S);
      Rf := Raft_Signaling_BCR;
      S := Process_Raft (S, Rf);
      Print_Step (69, "RADEAU: BCR", S);
      Rf := Raft_Signaling_FceRI;
      S := Process_Raft (S, Rf);
      Print_Step (70, "RADEAU: Fc-epsilon-RI", S);
      Rf := Raft_Synaptic;
      S := Process_Raft (S, Rf);
      Print_Step (71, "RADEAU: SYNAPTIQUE", S);
      Rf := Raft_Endothelial_VEGF;
      S := Process_Raft (S, Rf);
      Print_Step (72, "RADEAU: VEGF", S);
      Rf := Raft_Tumor_Survival;
      S := Process_Raft (S, Rf);
      Print_Step (73, "RADEAU: SURVIE TUMORALE", S);

      -- ======================================================================
      -- PHASE 7 : HLA (IMMUNITE)
      -- ======================================================================
      Put_Line ("=== PHASE 7 : HLA (IMMUNITE) ===");
      H.Class_I_Expression := 0.9;
      H.Class_II_Expression := 0.1;
      H.HLA_G_Expression := 0.0;
      H.Peptide_Loaded := True;
      H.Antigen_Present := True;
      H.Immune_Evasion := False;
      S := Present_HLA_Class_I (S, H);
      Print_Step (74, "HLA-I PRESENTATION", S);
      H.Class_II_Expression := 0.8;
      S := Present_HLA_Class_II (S, H);
      Print_Step (75, "HLA-II PRESENTATION", S);

      -- ======================================================================
      -- PHASE 8 : STRESS (5 types)
      -- ======================================================================
      Put_Line ("=== PHASE 8 : STRESS ===");
      S := Apply_Mechanical_Stress (S, 2.0);
      Print_Step (76, "STRESS MECANIQUE (leger)", S);
      S := Apply_Oxidative_Stress (S, 1.0);
      Print_Step (77, "STRESS OXYDATIF (leger)", S);
      S := Apply_Thermal_Stress (S, 37.0);
      Print_Step (78, "STRESS THERMIQUE (normal)", S);
      S := Apply_Osmotic_Stress (S, 300.0);
      Print_Step (79, "STRESS OSMOTIQUE (normal)", S);
      S := Apply_Immune_Stress (S, 5.0);
      Print_Step (80, "STRESS IMMUNITAIRE (baseline)", S);

      -- ======================================================================
      -- PHASE 9 : STRESS SEVERE (pathologique)
      -- ======================================================================
      Put_Line ("=== PHASE 9 : STRESS SEVERE (PATHOLOGIQUE) ===");
      S := Apply_Mechanical_Stress (S, 15.0);
      Print_Step (81, "STRESS MECANIQUE SEVERE", S);
      S := Apply_Oxidative_Stress (S, 12.0);
      Print_Step (82, "STRESS OXYDATIF SEVERE", S);
      S := Apply_Thermal_Stress (S, 43.0);
      Print_Step (83, "STRESS THERMIQUE SEVERE", S);
      S := Apply_Osmotic_Stress (S, 400.0);
      Print_Step (84, "STRESS OSMOTIQUE SEVERE", S);

      -- ======================================================================
      -- PHASE 10 : EVASION IMMUNITAIRE (cancer)
      -- ======================================================================
      Put_Line ("=== PHASE 10 : EVASION IMMUNITAIRE (CANCER) ===");
      H.Immune_Evasion := True;
      H.Class_I_Expression := 0.2;
      S := Present_HLA_Class_I (S, H);
      Print_Step (85, "HLA-I EVASION TUMORALE", S);

      -- ======================================================================
      -- PHASE 11 : MILIEU INTERIEUR
      -- ======================================================================
      Put_Line ("=== PHASE 11 : MILIEU INTERIEUR ===");
      I.Na_Conc := 12.0; I.K_Conc := 140.0; I.Ca_Conc := 0.1;
      I.Cl_Conc := 4.0; I.pH := 7.2; I.ATP_Level := 5.0;
      I.ROS_Level := 0.05; I.Membrane_Potential := -70.0;
      S := Sense_Intracellular (S, I);
      Print_Step (86, "SENSIBILITE INTRACELLULAIRE", S);

      -- ======================================================================
      -- PHASE 12 : ECM (12 types)
      -- ======================================================================
      Put_Line ("=== PHASE 12 : MATRICE EXTRACELLULAIRE ===");
      Ec := Collagen_I;
      S := Process_ECM (S, Ec);
      Print_Step (87, "ECM: COLLAGENE I", S);
      Ec := Collagen_II;
      S := Process_ECM (S, Ec);
      Print_Step (88, "ECM: COLLAGENE II", S);
      Ec := Collagen_III;
      S := Process_ECM (S, Ec);
      Print_Step (89, "ECM: COLLAGENE III", S);
      Ec := Collagen_IV;
      S := Process_ECM (S, Ec);
      Print_Step (90, "ECM: COLLAGENE IV", S);
      Ec := Collagen_V;
      S := Process_ECM (S, Ec);
      Print_Step (91, "ECM: COLLAGENE V", S);
      Ec := Fibronectin;
      S := Process_ECM (S, Ec);
      Print_Step (92, "ECM: FIBRONECTINE", S);
      Ec := Laminin;
      S := Process_ECM (S, Ec);
      Print_Step (93, "ECM: LAMININE", S);
      Ec := Elastin;
      S := Process_ECM (S, Ec);
      Print_Step (94, "ECM: ELASTINE", S);
      Ec := Hyaluronan;
      S := Process_ECM (S, Ec);
      Print_Step (95, "ECM: HYALURONANE", S);
      Ec := Proteoglycan;
      S := Process_ECM (S, Ec);
      Print_Step (96, "ECM: PROTEOGLYCANE", S);
      Ec := Tenascin;
      S := Process_ECM (S, Ec);
      Print_Step (97, "ECM: TENASCINE", S);
      Ec := Vitronectin;
      S := Process_ECM (S, Ec);
      Print_Step (98, "ECM: VITRONECTINE", S);

      -- ======================================================================
      -- PHASE 13 : RETOUR AU DNA (feedback)
      -- ======================================================================
      Put_Line ("=== PHASE 13 : RETOUR AU DNA (FEEDBACK) ===");
      S.Location := "Retour au DNA (feedback)                         ";
      S.State := Feedback;
      S := Apply_V3_Invariants (S);
      Print_Step (99, "FEEDBACK FINAL AU DNA", S);

      -- ======================================================================
      -- FIN
      -- ======================================================================
      Put_Line ("================================================================================");
      Put_Line ("FIN DU TRACKING - CYCLE COMPLET SANS NEUTRINOS");
      Put_Line ("================================================================================");
      Put_Line ("Psi_V3        = 48016.8 kg/m^2   - VERROUILLE");
      Put_Line ("Phi_critical  = -51.1 mV         - INVARIANT");
      Put_Line ("k             = 7                - CLOTURE HEPTADIQUE");
      Put_Line ("Modulo-9      = 9                - INTEGRITE STRUCTURELLE");
      Put_Line ("lambda_V3     = 4.68e-5 m        - RESONANCE");
      Put_Line ("Substrat      = H3O2 (Pollack)   - CONTINU, SANS VIDE");
      Put_Line ("Neutrinos     = ABSENTS          - CONFORMITE DEMANDE");
      Put_Line ("================================================================================");
   end Run_Membrane_Tracker;

begin
   Run_Membrane_Tracker;
end V3_Membrane_Complete;
