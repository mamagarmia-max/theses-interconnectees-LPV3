-- ============================================================================
-- V3_Predict_New_Elements.adb
-- Implémentation des prédictions V3 pour les éléments Z = 119 à 126
-- ============================================================================

package body V3_Predict_New_Elements with
   SPARK_Mode => On
is

   -- ------------------------------------------------------------------------
   -- Predict_Stability
   -- Calcule la probabilité de stabilité à partir de la pression et cohérence
   -- ------------------------------------------------------------------------
   function Predict_Stability (Z, N : Integer) return Float is
      A      : constant Integer := Z + N;
      R_m    : constant Float := Vortex_Radius (A);
      P_int  : constant Float := Vortex_Pressure (Z, N, R_m);
      P_crit : constant Float := Critical_Pressure (R_m);
      Phi    : constant Float := Phase_Potential (R_m, 1.0e-10);
      Coh    : constant Float := Compute_Coherence (Phi);
   begin
      if P_int = 0.0 then
         return 0.0;
      end if;
      return (Coh / 100.0) * (P_crit / P_int);
   end Predict_Stability;

   -- ------------------------------------------------------------------------
   -- Predict_Utilisation
   -- Décrit l'utilisation potentielle de l'élément selon ses propriétés V3
   -- ------------------------------------------------------------------------
   function Predict_Utilisation (Z : Integer) return String is
   begin
      case Z is
         when 119 =>
            return "Potentiel pour la catalyse nucléaire et les réacteurs de 4e génération.";
         when 120 =>
            return "Utilisable comme source d'énergie compacte pour les missions spatiales.";
         when 121 =>
            return "Applicable en médecine nucléaire pour la thérapie ciblée des tumeurs.";
         when 122 =>
            return "Matériau pour les blindages légers contre les radiations cosmiques.";
         when 123 =>
            return "Isotope prometteur pour la datation géologique des roches anciennes.";
         when 124 =>
            return "Utilisable comme marqueur isotopique en biologie structurale.";
         when 125 =>
            return "Potentiel pour les batteries nucléaires à longue durée de vie.";
         when 126 =>
            return "Pertinent pour les réactions de fusion catalysée par phase.";
         when others =>
            return "Inconnu. À explorer.";
      end case;
   end Predict_Utilisation;

   -- ------------------------------------------------------------------------
   -- Predict_New_Elements
   -- Génère le tableau complet des 8 éléments (Z = 119 à 126)
   -- ------------------------------------------------------------------------
   function Predict_New_Elements return New_Element_Array is
      Elements : New_Element_Array;
      Z        : Integer;
      N        : Integer;
      A        : Integer;
      Sym      : String (1 .. 3);
      Symbol_List : constant array (119 .. 126) of String (1 .. 3) :=
        ("Uue", "Ubn", "Ubu", "Ubb", "Ubt", "Ubq", "Ubp", "Ubh");

      N_List : constant array (119 .. 126) of Integer :=
        (178, 184, 188, 192, 196, 200, 204, 208);

   begin
      for Z in 119 .. 126 loop
         N := N_List (Z);
         A := Z + N;
         Sym := Symbol_List (Z);

         declare
            R_m    : constant Float := Vortex_Radius (A);
            P_int  : constant Float := Vortex_Pressure (Z, N, R_m);
            P_crit : constant Float := Critical_Pressure (R_m);
            Phi    : constant Float := Phase_Potential (R_m, 1.0e-10);
            Coh    : constant Float := Compute_Coherence (Phi);
            Stab   : constant Float := Predict_Stability (Z, N);
            HL     : constant Float := Phase_Relaxation_Time (Z, N);
            E_alpha : constant Float := (P_int - P_crit) * (4.0/3.0) * PI * R_m**3 / E_CHARGE * 1.0e-6;
            Mass   : constant Float := Float (A) * AMU / 1.66053906660e-27;
            Stable : constant Boolean := (Coh >= 90.0 and P_int < P_crit);
         begin
            Elements (Z) := New_Element_Record'
              (Z                  => Z,
               N                  => N,
               A                  => A,
               Symbol             => Sym,
               Mass_u             => Mass,
               Radius_fm          => R_m * 1.0e15,
               Half_Life_Seconds  => HL,
               Alpha_Energy_MeV   => E_alpha,
               Coherence          => Coh,
               Stability_Prob     => Stab,
               Is_Stable          => Stable,
               Phase_Group        => Phase_Group (Z),
               Phase_Period       => Phase_Period (Z),
               Utilisation        => Predict_Utilisation (Z));
         end;
      end loop;

      return Elements;
   end Predict_New_Elements;

end V3_Predict_New_Elements;
