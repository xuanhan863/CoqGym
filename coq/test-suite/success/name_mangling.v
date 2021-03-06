(* -*- coq-prog-args: ("-mangle-names" "_") -*- *)

(* Check that refine policy of redefining previous names make these names private *)
(* abstract can change names in the environment! See bug #3146 *)

Goal True -> True.
intro.
Fail exact H.
exact _0.
Abort.

Unset Mangle Names.
Goal True -> True.
intro; exact H.
Abort.

Set Mangle Names.
Set Mangle Names Prefix "baz".
Goal True -> True.
intro.
Fail exact H.
Fail exact _0.
exact baz0.
Abort.

Goal True -> True.
intro; assumption.
Abort.

Goal True -> True.
intro x; exact x.
Abort.

Goal forall x y, x+y=0.
intro x.
refine (fun x => _).
Fail Check x0.
Check x.
Abort.

(* Example from Emilio *)

Goal forall b : False, b = b.
intro b.
refine (let b := I in _).
Fail destruct b0.
Abort.

(* Example from Cyprien *)

Goal True -> True.
Proof.
  refine (fun _ => _).
  Fail exact t.
Abort.

(* Example from Jason *)

Goal False -> False.
intro H.
Fail abstract exact H.
Abort.

(* Variant *)

Goal False -> False.
intro.
Fail abstract exact H.
Abort.

(* Example from Jason *)

Goal False -> False.
intro H.
(* Name H' is from Ltac here, so it preserves the privacy *)
(* But abstract messes everything up *)
Fail let H' := H in abstract exact H'.
let H' := H in exact H'.
Qed.

(* Variant *)

Goal False -> False.
intro.
Fail let H' := H in abstract exact H'.
Abort.

(* Indirectly testing preservation of names by move (derived from Jason) *)

Inductive nat2 := S2 (_ _ : nat2).
Goal forall t : nat2, True.
  intro t.
  let IHt1 := fresh "IHt1" in
  let IHt2 := fresh "IHt2" in
  induction t as [? IHt1 ? IHt2].
  Fail exact IHt1.
Abort.

(* Example on "pose proof" (from Jason) *)

Goal False -> False.
intro; pose proof I as H0.
Fail exact H.
Abort.

(* Testing the approach for which non alpha-renamed quantified names are user-generated *)

Section foo.
Context (b : True).
Goal forall b : False, b = b.
Fail destruct b0.
Abort.

Goal forall b : False, b = b.
now destruct b.
Qed.
End foo.

(* Test stability of "fix" *)

Lemma a : forall n, n = 0.
Proof.
fix a 1.
Check a.
Fail fix a 1.
Abort.

(* Test stability of "induction" *)

Lemma a : forall n : nat, n = n.
Proof.
intro n; induction n as [ | n IHn ].
- auto.
- Check n.
  Check IHn.
Abort.

Inductive I := C : I -> I -> I.

Lemma a : forall n : I, n = n.
Proof.
intro n; induction n as [ n1 IHn1 n2 IHn2 ].
Check n1.
Check n2.
apply f_equal2.
+ apply IHn1.
+ apply IHn2.
Qed.

(* Testing remember *)

Lemma c : 0 = 0.
Proof.
remember 0 as x eqn:Heqx.
Check Heqx.
Abort.

Lemma c : forall Heqx, Heqx -> 0 = 0.
Proof.
intros Heqx X.
remember 0 as x.
Fail Check Heqx0. (* Heqx0 is not canonical *)
Abort.

(* An example by Jason from the discussion for PR #268 *)

Goal nat -> Set -> True.
  intros x y.
  match goal with
  | [ x : _, y : _ |- _ ]
    => let z := fresh "z" in
      rename y into z, x into y;
        let x' := fresh "x" in
        rename z into x'
  end.
  revert y. (* x has been explicitly moved to y *)
  Fail revert x. (* x comes from "fresh" *)
Abort.

Goal nat -> Set -> True.
  intros.
  match goal with
  | [ x : _, y : _ |- _ ]
    => let z := fresh "z" in
      rename y into z, x into y;
        let x' := fresh "x" in
        rename z into x'
  end.
  Fail revert y. (* generated by intros *)
  Fail revert x. (* generated by intros *)
Abort.
