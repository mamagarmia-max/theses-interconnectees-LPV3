-- ============================================================================
-- Alloy_NbTaTiZrHf.adb
-- Implementation of the alloy synthesis simulation
-- ============================================================================

package body Alloy_NbTaTiZrHf with
   SPARK_Mode => On
is

   -- ------------------------------------------------------------------------
   -- Compute_Alloy_Properties
   -- Prédit les propriétés de l'alliage via V3
   -- ------------------------------------------------------------------------
   function Compute_Alloy_Properties return Alloy_Properties is
      Z_eff     : constant Float := 41.0*0.30 + 73.0*0.20 + 22.0*0.20 + 40.0*0.15 + 72.0*0.05;
      A_eff     : constant Float := (41.0*0.30 + 73.0*0.20 + 22.0*0.20 + 40.0*0.15 + 72.0*0.05) +
                                     (51.0*0.30 + 108.0*0.20 + 48.0*0.20 + 50.0*0.15 + 106.0*0.05);
      R_m       : constant Float := Vortex_Radius (Integer (A_eff));
      P_int     : constant Float := Vortex_Pressure (Integer (Z_eff), Integer (A_eff - Z_eff), R_m);
      P_crit    : constant Float := Critical_Pressure (R_m);
      Phi       : constant Float := Phase_Potential (R_m, 1.0e-10);
      Coh       : constant Float := Compute_Coherence (Phi);
      Density   : constant Float := (41.0*0.30 + 73.0*0.20 + 22.0*0.20 + 40.0*0.15 + 72.0*0.05) /
                                     (6.022e23 * 1.6605e-27) * 1e-3;
      E_mod     : constant Float := (P_int - P_crit) * 1e-9;
      T_melt    : constant Float := Friction_Gradient_Melting (Integer (Z_eff));
      Hardness  : constant Float := 0.1 * Coh * (P_int / P_crit);
      Tensile   : constant Float := P_int * 1e-6;
      Ductility : constant Float := Coh / (1.0 + P_int / P_crit);
   begin
      return Alloy_Properties'
        (Density_gpcm3        => Density,
         Elastic_Modulus_GPa  => E_mod,
         Melting_Point_C      => T_melt,
         Hardness_HV          => Hardness,
         Tensile_Strength_MPa => Tensile,
         Ductility_Percent    => Ductility,
         Phase                => "BCC       ",
         Checksum             => 9);
   end Compute_Alloy_Properties;

   -- ------------------------------------------------------------------------
   -- Compute_Fabrication_Parameters
   -- Calcule les paramètres de fabrication à partir des propriétés V3
   -- ------------------------------------------------------------------------
   function Compute_Fabrication_Parameters return Fabrication_Parameters is
      Props : constant Alloy_Properties := Compute_Alloy_Properties;
   begin
      return Fabrication_Parameters'
        (Arc_Melting_Temp_C   => Props.Melting_Point_C + 100.0,
         Holding_Time_Hours   => 2.0,
         Annealing_Temp_C     => 0.8 * Props.Melting_Point_C,
         Cooling_Rate_Cpmin   => 10.0,
         Checksum             => 9);
   end Compute_Fabrication_Parameters;

   -- ------------------------------------------------------------------------
   -- Get_Synthesis_Procedure
   -- Retourne la méthode de fabrication en clair
   -- ------------------------------------------------------------------------
   function Get_Synthesis_Procedure return String is
      Params : constant Fabrication_Parameters := Compute_Fabrication_Parameters;
      Props  : constant Alloy_Properties := Compute_Alloy_Properties;
   begin
      return "== SYNTHÈSE DE L'ALLIAGE Nb₀.₃ Ta₀.₂ Ti₀.₂ Zr₀.₁₅ Hf₀.₀₅ ==" &
             ASCII.LF &
             "" &
             ASCII.LF &
             "1. MÉTHODE : FUSION SOUS ARC (ARC MELTING)" &
             ASCII.LF &
             "   - Atmosphère : Argon pur (99.999%)" &
             ASCII.LF &
             "   - Pression : 10⁻⁵ mbar (vide primaire puis balayage Ar)" &
             ASCII.LF &
             "   - Température de fusion : " & Float'Image (Params.Arc_Melting_Temp_C) & " °C" &
             ASCII.LF &
             "   - Durée de maintien : " & Float'Image (Params.Holding_Time_Hours) & " heures" &
             ASCII.LF &
             "" &
             ASCII.LF &
             "2. COMPOSITION (fractions atomiques) :" &
             ASCII.LF &
             "   - Nb  : 0.30" &
             ASCII.LF &
             "   - Ta  : 0.20" &
             ASCII.LF &
             "   - Ti  : 0.20" &
             ASCII.LF &
             "   - Zr  : 0.15" &
             ASCII.LF &
             "   - Hf  : 0.05" &
             ASCII.LF &
             "" &
             ASCII.LF &
             "3. PROPRIÉTÉS PRÉDITES (V3) :" &
             ASCII.LF &
             "   - Densité : " & Float'Image (Props.Density_gpcm3) & " g/cm³" &
             ASCII.LF &
             "   - Module d'élasticité : " & Float'Image (Props.Elastic_Modulus_GPa) & " GPa" &
             ASCII.LF &
             "   - Point de fusion : " & Float'Image (Props.Melting_Point_C) & " °C" &
             ASCII.LF &
             "   - Dureté : " & Float'Image (Props.Hardness_HV) & " HV" &
             ASCII.LF &
             "   - Résistance à la traction : " & Float'Image (Props.Tensile_Strength_MPa) & " MPa" &
             ASCII.LF &
             "   - Ductilité : " & Float'Image (Props.Ductility_Percent) & " %" &
             ASCII.LF &
             "   - Phase : " & Props.Phase &
             ASCII.LF &
             "" &
             ASCII.LF &
             "4. ÉTAPES DE FABRICATION :" &
             ASCII.LF &
             "   a. Pesée des poudres (> 99.9%) selon la composition nominale." &
             ASCII.LF &
             "   b. Mélange sous argon pendant 30 min." &
             ASCII.LF &
             "   c. FUSION SOUS ARC : 3 cycles de fusion + retournement." &
             ASCII.LF &
             "   d. Maintien à " & Float'Image (Params.Arc_Melting_Temp_C) & " °C pendant " &
                 Float'Image (Params.Holding_Time_Hours) & " h." &
             ASCII.LF &
             "   e. RECUIT : " & Float'Image (Params.Annealing_Temp_C) & " °C pendant 12 h." &
             ASCII.LF &
             "   f. Refroidissement : " & Float'Image (Params.Cooling_Rate_Cpmin) & " °C/min." &
             ASCII.LF &
             "" &
             ASCII.LF &
             "5. CARACTÉRISATION :" &
             ASCII.LF &
             "   - DRX (phase BCC)" &
             ASCII.LF &
             "   - MEB + EDS (homogénéité)" &
             ASCII.LF &
             "   - Dureté Vickers" &
             ASCII.LF &
             "   - Traction (éprouvettes miniatures)" &
             ASCII.LF &
             "" &
             ASCII.LF &
             "== FIN DE LA PROCÉDURE ==" &
             ASCII.LF;
   end Get_Synthesis_Procedure;

end Alloy_NbTaTiZrHf;
