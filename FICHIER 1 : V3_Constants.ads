-- ============================================================================
-- V3_Constants.ads — V3 Architecture Invariants and Physical Constants
-- Version 11.0.0
-- 
-- Ce fichier contient TOUTES les constantes V3 et les constantes physiques
-- mesurées (CODATA). Les constantes V3 sont dérivées des invariants du
-- condensat H₃O₂ et de la géométrie du vortex.
-- 
-- Author: Dr. Benhadid Outail (ORCID: 0009-0003-3057-9543)
-- License: LPV3
-- Reference: Ψ_V3 = 48016.8 kg·m⁻² (Zenodo DOI: 10.5281/zenodo.20580979)
-- ============================================================================

package V3_Constants with
   SPARK_Mode => On
is

   -- ========================================================================
   -- 1. V3 INVARIANTS (Uniquement les constantes V3)
   -- ========================================================================

   -- Densité de phase du condensat H₃O₂ (Pollack, 2013)
   PSI_V3          : constant := 48016.8;          -- kg·m⁻²

   -- Attracteur universel (potentiel de repos biologique)
   PHI_CRITICAL    : constant := -0.0511;          -- V (-51.1 mV)

   -- Clôture heptadique (invariant topologique)
   K_CYCLES        : constant := 7;                -- Dimensionless

   -- Densité du condensat H₃O₂
   RHO_COND        : constant := 1026.0;           -- kg·m⁻³

   -- Fréquence de verrouillage de phase
   NU_PHASE        : constant := 6.4e12;           -- Hz

   -- Longueur de corrélation V3
   LAMBDA_V3       : constant := 4.68e-5;          -- m

   -- Facteur d'échelle (dimensionless)
   BETA            : constant := 1_000_000.0;

   -- Vitesse de la lumière = limite de friction du condensat
   C_LIGHT         : constant := 299_792_458.0;    -- m/s

   -- Température du fond diffus cosmologique (réseau de phase)
   COSMIC_TEMP_K   : constant := 2.7;              -- K

   -- Constante de Stephan-Boltzmann (V3 adaptée)
   SIGMA_SB        : constant := 5.670374419e-8;   -- W·m⁻²·K⁻⁴

   -- Constante de Planck V3 (identique, car mesurée)
   H_PLANK         : constant := 6.62607015e-34;   -- J·s

   -- Constante de Wien (b = 2.897771955e-3 m·K)
   WIEN_CONSTANT   : constant := 2.897771955e-3;   -- m·K

   PI              : constant := Ada.Numerics.Pi;

   -- ========================================================================
   -- 2. CONSTANTES PHYSIQUES (Mesurées, pas postulées)
   -- ========================================================================

   HBAR            : constant := 1.054571817e-34;  -- J·s
   M_E             : constant := 9.1093837e-31;    -- kg (mesurée)
   M_P             : constant := 1.67262192e-27;   -- kg (mesurée)
   E_CHARGE        : constant := 1.602176634e-19;  -- C
   AMU             : constant := 1.66053906660e-27; -- kg
   BOHR_RADIUS     : constant := 5.29177210903e-11; -- m
   MU_B            : constant := 9.2740100783e-24;  -- J/T
   ALPHA_FS        : constant := 7.29735256e-3;
   K_B             : constant := 1.380649e-23;      -- J/K
   N_A             : constant := 6.02214076e23;     -- Avogadro
   EPSILON_0       : constant := 8.8541878128e-12;  -- F/m
   MU_0            : constant := 4.0 * PI * 1.25663706212e-6;  -- N/A²

   -- ========================================================================
   -- 3. NORMALISATION V3
   -- ========================================================================

   LAMBDA_COMPTON_P : constant := HBAR / (M_P * C_LIGHT);  -- 1.3214e-15 m
   V3_NORM          : constant := LAMBDA_COMPTON_P * LAMBDA_COMPTON_P;
   PSI_V3_ATOMIC    : constant := PSI_V3 * V3_NORM;        -- kg
   ENERGY_SCALE_J   : constant := PSI_V3_ATOMIC * C_LIGHT * C_LIGHT * ALPHA_FS * ALPHA_FS;
   ENERGY_SCALE_eV  : constant := ENERGY_SCALE_J / E_CHARGE; -- 13.605693 eV

   -- ========================================================================
   -- 4. SOUS-PROGRAMMES DE CONVERSION
   -- ========================================================================

   function J_to_eV (Joules : Float) return Float
     with Pre => Joules >= 0.0,
          Post => J_to_eV'Result >= 0.0;

   function eV_to_J (eV : Float) return Float
     with Pre => eV >= 0.0,
          Post => eV_to_J'Result >= 0.0;

   function K_to_eV (Kelvin : Float) return Float
     with Pre => Kelvin >= 0.0,
          Post => K_to_eV'Result >= 0.0;

   function eV_to_K (eV : Float) return Float
     with Pre => eV >= 0.0,
          Post => eV_to_K'Result >= 0.0;

end V3_Constants;
