/-
Copyright (c) 2019 Scott Morrison. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Scott Morrison
-/
import category_theory.monoidal.functor
import category_theory.functorial

open category_theory

universes v₁ v₂ v₃ u₁ u₂ u₃

open category_theory.category
open category_theory.functor

namespace category_theory

open monoidal_category

variables {C : Type u₁} [category.{v₁} C] [𝒞 : monoidal_category.{v₁} C]
          {D : Type u₂} [category.{v₂} D] [𝒟 : monoidal_category.{v₂} D]
include 𝒞 𝒟

/-- An unbundled description of lax monoidal functors. -/
-- Perhaps in the future we'll redefine `lax_monoidal_functor` in terms of this, but that isn't the
-- immediate plan.
class lax_monoidal (F : C → D) [functorial.{v₁ v₂} F] :=
-- unit morphism
(ε               : 𝟙_ D ⟶ F (𝟙_ C))
-- tensorator
(μ                : Π X Y : C, (F X) ⊗ (F Y) ⟶ F (X ⊗ Y))
(μ_natural'       : ∀ {X Y X' Y' : C}
  (f : X ⟶ Y) (g : X' ⟶ Y'),
  ((map F f) ⊗ (map F g)) ≫ μ Y Y' = μ X X' ≫ map F (f ⊗ g)
  . obviously)
-- associativity of the tensorator
(associativity'   : ∀ (X Y Z : C),
    (μ X Y ⊗ 𝟙 (F Z)) ≫ μ (X ⊗ Y) Z ≫ map F (α_ X Y Z).hom
  = (α_ (F X) (F Y) (F Z)).hom ≫ (𝟙 (F X) ⊗ μ Y Z) ≫ μ X (Y ⊗ Z)
  . obviously)
-- unitality
(left_unitality'  : ∀ X : C,
    (λ_ (F X)).hom
  = (ε ⊗ 𝟙 (F X)) ≫ μ (𝟙_ C) X ≫ map F (λ_ X).hom
  . obviously)
(right_unitality' : ∀ X : C,
    (ρ_ (F X)).hom
  = (𝟙 (F X) ⊗ ε) ≫ μ X (𝟙_ C) ≫ map F (ρ_ X).hom
  . obviously)

restate_axiom lax_monoidal.μ_natural'
attribute [simp] lax_monoidal.μ_natural
restate_axiom lax_monoidal.left_unitality'
attribute [simp] lax_monoidal.left_unitality
restate_axiom lax_monoidal.right_unitality'
attribute [simp] lax_monoidal.right_unitality
restate_axiom lax_monoidal.associativity'
attribute [simp] lax_monoidal.associativity

namespace lax_monoidal_functor

def of (F : C → D) [I₁ : functorial.{v₁ v₂} F] [I₂ : lax_monoidal.{v₁ v₂} F] : lax_monoidal_functor.{v₁ v₂} C D :=
{ obj := F,
  ..I₁, ..I₂ }

end lax_monoidal_functor

instance (F : lax_monoidal_functor.{v₁ v₂} C D) : lax_monoidal.{v₁ v₂} (F.obj) := { .. F }

section
omit 𝒟

instance lax_monoidal_id : lax_monoidal.{v₁ v₁} (id : C → C) :=
{ ε := 𝟙 _,
  μ := λ X Y, 𝟙 _ }

end
-- TODO instances for composition

-- TODO monoidal, as well as lax monoidal (... but it seems for enriched categories I'll only need unbundled lax monoidal functors at first)

end category_theory